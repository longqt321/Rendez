package catalog

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"rendez-backend/internal/auth"
	"rendez-backend/internal/httpx"
)

const maxImageBytes = 10 * 1024 * 1024

func storageDir() string {
	if dir := os.Getenv("UPLOAD_DIR"); dir != "" {
		return dir
	}
	return "data/uploads"
}

type storedImage struct {
	Name, ContentType string
	Size              int
}

// Decode and re-encode accepted images: filenames and EXIF never enter public storage.
func storeImage(raw []byte) (storedImage, error) {
	cfg, format, err := image.DecodeConfig(bytes.NewReader(raw))
	if err != nil || (format != "png" && format != "jpeg") || cfg.Width < 100 || cfg.Height < 100 || int64(cfg.Width)*int64(cfg.Height) > 20000000 {
		return storedImage{}, errors.New("Chỉ nhận JPG/PNG đọc được, tối thiểu 100×100, tối đa 20 triệu pixel")
	}
	img, _, err := image.Decode(bytes.NewReader(raw))
	if err != nil {
		return storedImage{}, errors.New("Ảnh bị hỏng, không đọc được")
	}
	var out bytes.Buffer
	extension := ".png"
	contentType := "image/png"
	if format == "jpeg" {
		err = jpeg.Encode(&out, img, &jpeg.Options{Quality: 90})
		extension = ".jpg"
		contentType = "image/jpeg"
	} else {
		err = png.Encode(&out, img)
	}
	if err != nil {
		return storedImage{}, err
	}
	if out.Len() >= maxImageBytes {
		return storedImage{}, errors.New("Ảnh sau xử lý vượt 10MB")
	}
	var id [16]byte
	if _, err = rand.Read(id[:]); err != nil {
		return storedImage{}, err
	}
	name := hex.EncodeToString(id[:]) + extension
	if err = os.MkdirAll(storageDir(), 0700); err != nil {
		return storedImage{}, err
	}
	f, err := os.OpenFile(filepath.Join(storageDir(), name), os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		return storedImage{}, err
	}
	_, err = f.Write(out.Bytes())
	closeErr := f.Close()
	if err == nil {
		err = closeErr
	}
	if err != nil {
		os.Remove(filepath.Join(storageDir(), name))
		return storedImage{}, err
	}
	return storedImage{name, contentType, out.Len()}, nil
}

const contributionJSON = `SELECT jsonb_build_object('id',c.id,'place_id',c.place_id,'place_name',p.name,'type',c.type,'status',c.status,'captured_at',c.captured_at,'created_at',c.created_at,'reviewed_at',c.reviewed_at,'rejection_reason',c.rejection_reason,'ocr_text',c.ocr_text,'ocr_error',c.ocr_error,'draft_items',c.draft_items,'bill_total',c.bill_total,'guests_count',c.guests_count,'images',COALESCE((SELECT jsonb_agg(jsonb_build_object('id',i.id,'url','/v1/contributions/'||c.id||'/images/'||i.id) ORDER BY i.display_order) FROM contribution_images i WHERE i.contribution_id=c.id),'[]'::jsonb)) FROM contributions c JOIN places p ON p.id=c.place_id`

func registerContributions(r chi.Router, pool *pgxpool.Pool) {
	r.Post("/v1/contributions", func(w http.ResponseWriter, req *http.Request) {
		user, err := auth.Current(req, pool)
		if err != nil {
			auth.WriteAccessError(w, err)
			return
		}
		req.Body = http.MaxBytesReader(w, req.Body, 5*maxImageBytes+64*1024)
		if err = req.ParseMultipartForm(1024 * 1024); err != nil {
			httpx.Error(w, 413, "invalid_upload", "Tối đa 5 ảnh JPG/PNG, mỗi ảnh nhỏ hơn 10MB", false)
			return
		}
		defer req.MultipartForm.RemoveAll()
		headers := req.MultipartForm.File["images"]
		kind := req.FormValue("type")
		captured, err := time.Parse(time.RFC3339, req.FormValue("captured_at"))
		if len(headers) < 1 || len(headers) > 5 || (kind != "menu_photo" && kind != "bill_photo") || err != nil || captured.After(time.Now().Add(5*time.Minute)) {
			httpx.Error(w, 422, "validation_error", "Chọn 1–5 ảnh, loại ảnh và ngày chụp hợp lệ", false)
			return
		}
		placeID := req.FormValue("place_id")
		var input placeInput
		if placeID != "" {
			if !validID(w, placeID) {
				return
			}
		} else {
			input = placeInput{Name: req.FormValue("place_name"), Address: req.FormValue("address"), City: req.FormValue("city_code"), Category: req.FormValue("category_code"), State: "draft"}
			if !input.valid() {
				httpx.Error(w, 422, "validation_error", "Địa điểm mới cần tên, địa chỉ, thành phố và loại hình", false)
				return
			}
		}
		files := []storedImage{}
		committed := false
		defer func() {
			if !committed {
				for _, f := range files {
					os.Remove(filepath.Join(storageDir(), f.Name))
				}
			}
		}()
		for _, h := range headers {
			if h.Size >= maxImageBytes {
				httpx.Error(w, 413, "file_too_large", "Mỗi ảnh phải nhỏ hơn 10MB", false)
				return
			}
			f, e := h.Open()
			if e != nil {
				httpx.Error(w, 422, "invalid_image", "Không đọc được ảnh", false)
				return
			}
			raw, e := io.ReadAll(io.LimitReader(f, maxImageBytes))
			f.Close()
			if e != nil || len(raw) >= maxImageBytes {
				httpx.Error(w, 413, "file_too_large", "Mỗi ảnh phải nhỏ hơn 10MB", false)
				return
			}
			saved, e := storeImage(raw)
			if e != nil {
				httpx.Error(w, 422, "invalid_image", "Ảnh JPG/PNG phải đọc được, từ 100×100 đến 20 triệu pixel, nhỏ hơn 10MB", false)
				return
			}
			files = append(files, saved)
		}
		tx, err := pool.Begin(req.Context())
		if err != nil {
			writeDBError(w, err)
			return
		}
		defer tx.Rollback(req.Context())
		if placeID == "" {
			err = tx.QueryRow(req.Context(), `INSERT INTO places(id,name,address,city_code,category_code,publication_state,created_by,updated_by) VALUES(gen_random_uuid(),$1,$2,$3,$4,'draft',$5,$5) RETURNING id::text`, input.Name, input.Address, input.City, input.Category, user.ID).Scan(&placeID)
		} else {
			err = tx.QueryRow(req.Context(), `SELECT id::text FROM places WHERE id=$1 AND deleted_at IS NULL AND (publication_state='published' OR $2='admin') FOR SHARE`, placeID, user.Role).Scan(&placeID)
		}
		if err != nil {
			writeDBError(w, err)
			return
		}
		var id string
		err = tx.QueryRow(req.Context(), `INSERT INTO contributions(user_id,place_id,type,captured_at,ocr_error) VALUES($1,$2,$3,$4,'Chưa chạy OCR; Admin có thể thử lại') RETURNING id::text`, user.ID, placeID, kind, captured).Scan(&id)
		if err != nil {
			writeDBError(w, err)
			return
		}
		for i, f := range files {
			_, err = tx.Exec(req.Context(), `INSERT INTO contribution_images(contribution_id,storage_name,content_type,file_size,display_order) VALUES($1,$2,$3,$4,$5)`, id, f.Name, f.ContentType, f.Size, i)
			if err != nil {
				writeDBError(w, err)
				return
			}
		}
		if err = tx.Commit(req.Context()); err != nil {
			writeDBError(w, err)
			return
		}
		committed = true
		// OCR failures keep a private, reviewable contribution; no fabricated rejection.
		runContributionOCR(req.Context(), pool, id)
		httpx.JSON(w, 201, map[string]string{"id": id, "status": "pending_admin"})
	})
	for _, path := range []string{"/v1/contributions/my", "/v1/admin/contributions"} {
		r.Get(path, func(w http.ResponseWriter, req *http.Request) {
			user, err := auth.Current(req, pool)
			if err != nil {
				auth.WriteAccessError(w, err)
				return
			}
			admin := req.URL.Path == "/v1/admin/contributions"
			if admin && user.Role != "admin" {
				httpx.Error(w, 403, "forbidden", "Chỉ Admin được xem hàng chờ", false)
				return
			}
			rows, err := pool.Query(req.Context(), contributionJSON+` WHERE ($1 OR c.user_id=$2) ORDER BY c.created_at DESC,c.id`, admin, user.ID)
			if err != nil {
				writeDBError(w, err)
				return
			}
			defer rows.Close()
			result := []json.RawMessage{}
			for rows.Next() {
				var raw []byte
				if err = rows.Scan(&raw); err != nil {
					writeDBError(w, err)
					return
				}
				result = append(result, raw)
			}
			if err = rows.Err(); err != nil {
				writeDBError(w, err)
				return
			}
			httpx.JSON(w, 200, result)
		})
	}
	r.Get("/v1/contributions/{id}", func(w http.ResponseWriter, req *http.Request) {
		user, err := auth.Current(req, pool)
		if err != nil {
			auth.WriteAccessError(w, err)
			return
		}
		id := chi.URLParam(req, "id")
		if !validID(w, id) {
			return
		}
		var raw []byte
		err = pool.QueryRow(req.Context(), contributionJSON+` WHERE c.id=$1 AND (c.user_id=$2 OR $3='admin')`, id, user.ID, user.Role).Scan(&raw)
		if err != nil {
			writeDBError(w, err)
			return
		}
		httpx.JSON(w, 200, json.RawMessage(raw))
	})
	for _, path := range []string{"/v1/contributions/{id}/images/{imageID}", "/v1/menu-images/{imageID}"} {
		r.Get(path, func(w http.ResponseWriter, req *http.Request) {
			imageID := chi.URLParam(req, "imageID")
			if !validID(w, imageID) {
				return
			}
			var name, contentType string
			var err error
			if strings.HasPrefix(req.URL.Path, "/v1/menu-images/") {
				err = pool.QueryRow(req.Context(), `SELECT i.storage_name,i.content_type FROM contribution_images i JOIN contributions c ON c.id=i.contribution_id JOIN places p ON p.id=c.place_id WHERE i.id=$1 AND c.type='menu_photo' AND c.status='approved' AND p.publication_state='published' AND p.deleted_at IS NULL`, imageID).Scan(&name, &contentType)
			} else {
				user, e := auth.Current(req, pool)
				if e != nil {
					auth.WriteAccessError(w, e)
					return
				}
				id := chi.URLParam(req, "id")
				if !validID(w, id) {
					return
				}
				err = pool.QueryRow(req.Context(), `SELECT i.storage_name,i.content_type FROM contribution_images i JOIN contributions c ON c.id=i.contribution_id WHERE i.id=$1 AND c.id=$2 AND (c.user_id=$3 OR $4='admin')`, imageID, id, user.ID, user.Role).Scan(&name, &contentType)
			}
			if err != nil {
				writeDBError(w, err)
				return
			}
			file, err := os.Open(filepath.Join(storageDir(), filepath.Base(name)))
			if err != nil {
				httpx.Error(w, 404, "image_unavailable", "Ảnh không còn khả dụng", false)
				return
			}
			defer file.Close()
			info, err := file.Stat()
			if err != nil {
				httpx.Error(w, 503, "storage_unavailable", "Không đọc được ảnh", true)
				return
			}
			w.Header().Set("Content-Type", contentType)
			w.Header().Set("Cache-Control", "no-store")
			w.Header().Set("X-Content-Type-Options", "nosniff")
			http.ServeContent(w, req, name, info.ModTime(), file)
		})
	}
	r.Post("/v1/admin/contributions/{id}/ocr", func(w http.ResponseWriter, req *http.Request) {
		if _, ok := auth.RequireAdmin(w, req, pool); !ok {
			return
		}
		id := chi.URLParam(req, "id")
		if !validID(w, id) {
			return
		}
		err := runContributionOCR(req.Context(), pool, id)
		if err != nil {
			if errors.Is(err, errReviewConflict) {
				httpx.Error(w, 409, "review_conflict", "Đóng góp đã xử lý hoặc bản nháp vừa được sửa", false)
			} else if errors.Is(err, pgx.ErrNoRows) {
				writeDBError(w, err)
			} else {
				httpx.Error(w, 503, "ocr_unavailable", "OCR chưa thành công; có thể thử lại hoặc nhập thủ công", true)
			}
			return
		}
		w.WriteHeader(204)
	})
	r.Put("/v1/admin/contributions/{id}/draft", func(w http.ResponseWriter, req *http.Request) {
		if _, ok := auth.RequireAdmin(w, req, pool); !ok {
			return
		}
		id := chi.URLParam(req, "id")
		if !validID(w, id) {
			return
		}
		var input struct {
			Items     []menuDraft `json:"items"`
			BillTotal *int64      `json:"bill_total"`
			Guests    *int        `json:"guests_count"`
		}
		if !decode(w, req, &input) {
			return
		}
		var kind string
		err := pool.QueryRow(req.Context(), `SELECT type FROM contributions WHERE id=$1`, id).Scan(&kind)
		if err != nil {
			writeDBError(w, err)
			return
		}
		if (kind == "menu_photo" && len(input.Items) > 0 && !validMenu(input.Items)) || (input.BillTotal != nil && (*input.BillTotal <= 0 || *input.BillTotal > 1000000000)) || (input.Guests != nil && (*input.Guests < 1 || *input.Guests > 100)) {
			httpx.Error(w, 422, "validation_error", "Dữ liệu bản nháp không hợp lệ", false)
			return
		}
		if input.Items == nil || kind == "bill_photo" {
			input.Items = []menuDraft{}
		}
		raw, _ := json.Marshal(input.Items)
		tag, err := pool.Exec(req.Context(), `UPDATE contributions SET draft_items=$2,bill_total=$3,guests_count=$4 WHERE id=$1 AND status='pending_admin'`, id, raw, input.BillTotal, input.Guests)
		if err != nil {
			writeDBError(w, err)
			return
		}
		if tag.RowsAffected() == 0 {
			httpx.Error(w, 409, "review_conflict", "Đóng góp đã được xử lý", false)
			return
		}
		w.WriteHeader(204)
	})
	r.Post("/v1/admin/contributions/{id}/review", func(w http.ResponseWriter, req *http.Request) {
		admin, ok := auth.RequireAdmin(w, req, pool)
		if !ok {
			return
		}
		id := chi.URLParam(req, "id")
		if !validID(w, id) {
			return
		}
		var input struct {
			Decision  string      `json:"decision"`
			Reason    string      `json:"reason"`
			Items     []menuDraft `json:"items"`
			BillTotal *int64      `json:"bill_total"`
			Guests    *int        `json:"guests_count"`
		}
		if !decode(w, req, &input) {
			return
		}
		input.Reason = strings.TrimSpace(input.Reason)
		if (input.Decision != "approved" && input.Decision != "rejected") || len(input.Reason) > 2000 || (input.Decision == "rejected" && input.Reason == "") {
			httpx.Error(w, 422, "validation_error", "Chọn quyết định và nhập lý do nếu từ chối", false)
			return
		}
		tx, err := pool.Begin(req.Context())
		if err != nil {
			writeDBError(w, err)
			return
		}
		defer tx.Rollback(req.Context())
		var state, kind, placeID string
		err = tx.QueryRow(req.Context(), `SELECT status,type,place_id::text FROM contributions WHERE id=$1 FOR UPDATE`, id).Scan(&state, &kind, &placeID)
		if err != nil {
			writeDBError(w, err)
			return
		}
		if state != "pending_admin" {
			httpx.Error(w, 409, "review_conflict", "Đóng góp đã được xử lý", false)
			return
		}
		// Lock the place before updating its menu/publication, so concurrent approvals serialize.
		var placeState string
		err = tx.QueryRow(req.Context(), `SELECT publication_state FROM places WHERE id=$1 AND deleted_at IS NULL FOR UPDATE`, placeID).Scan(&placeState)
		if err != nil {
			writeDBError(w, err)
			return
		}
		if input.Decision == "approved" {
			if kind == "menu_photo" {
				if !validMenu(input.Items) {
					httpx.Error(w, 422, "invalid_menu", "Menu cần 1–200 món, tên duy nhất và giá 0–1 tỷ VNĐ", false)
					return
				}
				// Add/update only reviewed names; unrelated approved menu rows remain intact.
				for _, item := range input.Items {
					_, err = tx.Exec(req.Context(), `INSERT INTO menu_items(place_id,name,category,price,contribution_id,updated_at) VALUES($1,$2,$3,$4,$5,now()) ON CONFLICT(place_id,name) DO UPDATE SET price=EXCLUDED.price,category=EXCLUDED.category,contribution_id=EXCLUDED.contribution_id,updated_at=now()`, placeID, strings.TrimSpace(item.Name), item.Category, item.Price, id)
					if err != nil {
						writeDBError(w, err)
						return
					}
				}
			} else if input.BillTotal == nil || *input.BillTotal <= 0 || *input.BillTotal > 1000000000 || input.Guests == nil || *input.Guests < 1 || *input.Guests > 100 {
				httpx.Error(w, 422, "invalid_bill", "Hóa đơn cần tổng tiền hợp lệ và số khách 1–100", false)
				return
			}
			// A hidden place stays hidden; approving evidence must not override an Admin hide.
			_, err = tx.Exec(req.Context(), `UPDATE places SET publication_state=CASE WHEN publication_state='draft' THEN 'published' ELSE publication_state END,first_published_at=COALESCE(first_published_at,now()),is_verified=true,updated_by=$2,updated_at=now(),revision=revision+1 WHERE id=$1`, placeID, admin.ID)
			if err != nil {
				writeDBError(w, err)
				return
			}
		}
		if input.Decision == "rejected" || kind == "menu_photo" {
			input.BillTotal = nil
			input.Guests = nil
		}
		draft, _ := json.Marshal(input.Items)
		if kind == "bill_photo" || input.Decision == "rejected" {
			draft = []byte("[]")
		}
		_, err = tx.Exec(req.Context(), `UPDATE contributions SET status=$2,rejection_reason=$3,draft_items=$4,bill_total=$5,guests_count=$6,reviewed_by=$7,reviewed_at=now() WHERE id=$1`, id, input.Decision, input.Reason, draft, input.BillTotal, input.Guests, admin.ID)
		if err == nil {
			err = tx.Commit(req.Context())
		}
		if err != nil {
			writeDBError(w, err)
			return
		}
		w.WriteHeader(204)
	})
}

type menuDraft struct {
	Name     string `json:"name"`
	Price    int64  `json:"price"`
	Category string `json:"category"`
}

func validMenu(items []menuDraft) bool {
	if len(items) == 0 || len(items) > 200 {
		return false
	}
	seen := map[string]bool{}
	for _, i := range items {
		n := strings.TrimSpace(i.Name)
		key := strings.ToLower(n)
		if n == "" || len(n) > 200 || len(i.Category) > 200 || i.Price < 0 || i.Price > 1000000000 || seen[key] {
			return false
		}
		seen[key] = true
	}
	return true
}

var errReviewConflict = fmt.Errorf("contribution already reviewed")
