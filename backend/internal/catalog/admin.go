package catalog

import (
	"encoding/json"
	"errors"
	"io"
	"math"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"rendez-backend/internal/auth"
	"rendez-backend/internal/httpx"
)

type placeInput struct {
	Name         string   `json:"name"`
	Address      string   `json:"address"`
	City         string   `json:"city_code"`
	Category     string   `json:"category_code"`
	Description  string   `json:"description"`
	OpeningHours string   `json:"opening_hours"`
	Latitude     *float64 `json:"latitude"`
	Longitude    *float64 `json:"longitude"`
	State        string   `json:"publication_state"`
}

func (p *placeInput) valid() bool {
	p.Name = strings.TrimSpace(p.Name)
	p.Address = strings.TrimSpace(p.Address)
	return len(p.Name) > 0 && len(p.Name) <= 200 && len(p.Address) > 0 && len(p.Address) <= 500 && len(p.Description) <= 2000 && len(p.OpeningHours) <= 500 &&
		p.City != "" && p.Category != "" && (p.State == "draft" || p.State == "published" || p.State == "hidden") &&
		((p.Latitude == nil && p.Longitude == nil) || (p.Latitude != nil && p.Longitude != nil && finiteRange(*p.Latitude, -90, 90) && finiteRange(*p.Longitude, -180, 180)))
}
func finiteRange(v, lo, hi float64) bool {
	return !math.IsNaN(v) && !math.IsInf(v, 0) && v >= lo && v <= hi
}
func decode(w http.ResponseWriter, r *http.Request, v any) bool {
	d := json.NewDecoder(http.MaxBytesReader(w, r.Body, 256*1024))
	d.DisallowUnknownFields()
	if d.Decode(v) != nil || d.Decode(new(any)) != io.EOF {
		httpx.Error(w, 400, "invalid_json", "Dữ liệu gửi không hợp lệ", false)
		return false
	}
	return true
}
func writeDBError(w http.ResponseWriter, err error) {
	if errors.Is(err, pgx.ErrNoRows) {
		httpx.Error(w, 404, "not_found", "Không tìm thấy dữ liệu", false)
		return
	}
	var e *pgconn.PgError
	if errors.As(err, &e) && (e.Code == "23503" || e.Code == "23514" || e.Code == "23505") {
		httpx.Error(w, 422, "validation_error", "Dữ liệu không hợp lệ hoặc bị trùng", false)
		return
	}
	auth.WriteAccessError(w, err)
}
func registerAdmin(r chi.Router, pool *pgxpool.Pool) {
	r.Get("/v1/lookups", func(w http.ResponseWriter, req *http.Request) {
		var data []byte
		err := pool.QueryRow(req.Context(), `SELECT jsonb_build_object('cities',COALESCE((SELECT jsonb_agg(jsonb_build_object('code',code,'name',name_vi) ORDER BY name_vi) FROM cities WHERE enabled),'[]'::jsonb),'categories',COALESCE((SELECT jsonb_agg(jsonb_build_object('code',code,'name',name_vi) ORDER BY name_vi) FROM categories WHERE enabled),'[]'::jsonb))`).Scan(&data)
		if err != nil {
			writeDBError(w, err)
			return
		}
		httpx.JSON(w, 200, json.RawMessage(data))
	})
	r.Get("/v1/admin/places", func(w http.ResponseWriter, req *http.Request) {
		if _, ok := auth.RequireAdmin(w, req, pool); !ok {
			return
		}
		rows, err := pool.Query(req.Context(), `SELECT row_to_json(p) FROM (SELECT id,name,address,city_code,category_code,description,opening_hours,latitude,longitude,publication_state,is_verified FROM places WHERE deleted_at IS NULL ORDER BY name,id) p`)
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
	for _, method := range []string{"POST", "PUT"} {
		path := "/v1/admin/places"
		if method == "PUT" {
			path += "/{id}"
		}
		r.MethodFunc(method, path, func(w http.ResponseWriter, req *http.Request) {
			admin, ok := auth.RequireAdmin(w, req, pool)
			if !ok {
				return
			}
			var input placeInput
			if !decode(w, req, &input) {
				return
			}
			if !input.valid() {
				httpx.Error(w, 422, "validation_error", "Nhập tên, địa chỉ, thành phố, loại hình và tọa độ hợp lệ", false)
				return
			}
			var id string
			var err error
			if req.Method == "POST" {
				err = pool.QueryRow(req.Context(), `INSERT INTO places(id,name,address,city_code,category_code,description,opening_hours,latitude,longitude,publication_state,first_published_at,created_by,updated_by,is_verified) VALUES(gen_random_uuid(),$1,$2,$3,$4,$5,$6,$7,$8,$9,CASE WHEN $9='published' THEN now() END,$10,$10,true) RETURNING id::text`, input.Name, input.Address, input.City, input.Category, input.Description, input.OpeningHours, input.Latitude, input.Longitude, input.State, admin.ID).Scan(&id)
			} else {
				id = chi.URLParam(req, "id")
				if !validID(w, id) {
					return
				}
				err = pool.QueryRow(req.Context(), `UPDATE places SET name=$2,address=$3,city_code=$4,category_code=$5,description=$6,opening_hours=$7,latitude=$8,longitude=$9,publication_state=$10,first_published_at=CASE WHEN $10='published' THEN COALESCE(first_published_at,now()) ELSE first_published_at END,updated_by=$11,updated_at=now(),revision=revision+1,is_verified=true WHERE id=$1 AND deleted_at IS NULL RETURNING id::text`, id, input.Name, input.Address, input.City, input.Category, input.Description, input.OpeningHours, input.Latitude, input.Longitude, input.State, admin.ID).Scan(&id)
			}
			if err != nil {
				writeDBError(w, err)
				return
			}
			status := 200
			if req.Method == "POST" {
				status = 201
			}
			httpx.JSON(w, status, map[string]string{"id": id})
		})
	}
	r.Delete("/v1/admin/places/{id}", func(w http.ResponseWriter, req *http.Request) {
		admin, ok := auth.RequireAdmin(w, req, pool)
		if !ok {
			return
		}
		id := chi.URLParam(req, "id")
		if !validID(w, id) {
			return
		}
		tx, err := pool.Begin(req.Context())
		if err != nil {
			writeDBError(w, err)
			return
		}
		defer tx.Rollback(req.Context())
		var exists string
		err = tx.QueryRow(req.Context(), `SELECT id::text FROM places WHERE id=$1 AND deleted_at IS NULL FOR UPDATE`, id).Scan(&exists)
		if err != nil {
			writeDBError(w, err)
			return
		}
		var pending bool
		err = tx.QueryRow(req.Context(), `SELECT EXISTS(SELECT 1 FROM contributions WHERE place_id=$1 AND status='pending_admin')`, id).Scan(&pending)
		if err != nil {
			writeDBError(w, err)
			return
		}
		if pending {
			httpx.Error(w, 409, "pending_contributions", "Xử lý các đóng góp chờ duyệt trước khi xóa", false)
			return
		}
		_, err = tx.Exec(req.Context(), `UPDATE places SET publication_state='hidden',deleted_at=now(),updated_at=now(),updated_by=$2 WHERE id=$1`, id, admin.ID)
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
