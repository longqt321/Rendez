package catalog

import (
	"context"
	"encoding/json"
	"errors"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// ponytail: one synchronous Tesseract pass, bounded to 25 seconds for all images.
// Add a background job only if measured demo processing cannot fit this budget.
func runContributionOCR(ctx context.Context, pool *pgxpool.Pool, id string) error {
	var status, kind string
	var originalDraft []byte
	err := pool.QueryRow(ctx, `SELECT status,type,draft_items FROM contributions WHERE id=$1`, id).Scan(&status, &kind, &originalDraft)
	if err != nil {
		return err
	}
	if status != "pending_admin" {
		return errReviewConflict
	}
	rows, err := pool.Query(ctx, `SELECT storage_name FROM contribution_images WHERE contribution_id=$1 ORDER BY display_order`, id)
	if err != nil {
		return err
	}
	names := []string{}
	for rows.Next() {
		var name string
		if err = rows.Scan(&name); err != nil {
			rows.Close()
			return err
		}
		names = append(names, name)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return err
	}
	ocrCtx, cancel := context.WithTimeout(ctx, 25*time.Second)
	defer cancel()
	text := ""
	message := ""
	var ocrErr error
	for _, name := range names {
		cmd := exec.CommandContext(ocrCtx, "tesseract", filepath.Join(storageDir(), filepath.Base(name)), "stdout", "-l", "vie+eng", "--psm", "6")
		out, e := cmd.Output()
		if e != nil {
			ocrErr = e
			message = "OCR không khả dụng; thử lại hoặc nhập thủ công"
			if errors.Is(ocrCtx.Err(), context.DeadlineExceeded) {
				message = "OCR quá thời gian; thử lại hoặc nhập thủ công"
			}
			break
		}
		if len(out) > 64000 {
			out = out[:64000]
		}
		text += string(out) + "\n"
	}
	items := []menuDraft{}
	if kind == "menu_photo" {
		items = parseMenu(text)
	}
	raw, _ := json.Marshal(items)
	tag, err := pool.Exec(ctx, `UPDATE contributions SET ocr_text=$2,ocr_error=$3,draft_items=CASE WHEN $3='' THEN $4::jsonb ELSE draft_items END WHERE id=$1 AND status='pending_admin' AND draft_items=$5::jsonb`, id, text, message, raw, originalDraft)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return errReviewConflict
	}
	return ocrErr
}

var priceLine = regexp.MustCompile(`(?i)^(.+?)\s+([0-9]{1,3}(?:[., ][0-9]{3})+|[0-9]+(?:[.,][0-9]+)?\s*[kK]|[0-9]{4,9})\s*(?:vnd|vnđ|đ|dong|₫)?\s*$`)

func parseMenu(text string) []menuDraft {
	result := []menuDraft{}
	seen := map[string]bool{}
	for _, line := range strings.Split(text, "\n") {
		m := priceLine.FindStringSubmatch(strings.TrimSpace(line))
		if m == nil {
			continue
		}
		name := strings.Trim(strings.TrimSpace(m[1]), " .:-|_")
		if len(name) == 0 || len(name) > 200 {
			continue
		}
		number := strings.ToLower(strings.ReplaceAll(m[2], " ", ""))
		var price int64
		if strings.HasSuffix(number, "k") {
			value, err := strconv.ParseFloat(strings.ReplaceAll(strings.TrimSuffix(number, "k"), ",", "."), 64)
			if err != nil {
				continue
			}
			price = int64(value * 1000)
		} else {
			number = strings.NewReplacer(".", "", ",", "").Replace(number)
			price, _ = strconv.ParseInt(number, 10, 64)
		}
		key := strings.ToLower(name)
		if price < 0 || price > 1000000000 || seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, menuDraft{Name: name, Price: price, Category: "Menu"})
		if len(result) == 200 {
			break
		}
	}
	return result
}
