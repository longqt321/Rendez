package catalog

import (
	"context"
	"encoding/json"
	"net/http"
	"regexp"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"rendez-backend/internal/auth"
	"rendez-backend/internal/httpx"
)

var uuid = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

const placeJSON = `SELECT jsonb_build_object(
 'id',p.id,'name',p.name,'address',p.address,'city',c.name_vi,'category',cat.name_vi,
 'opening_hours',COALESCE(p.opening_hours,''),'latitude',p.latitude,'longitude',p.longitude,
 'cover_image_url',p.cover_image_url,'vibes',p.vibes,'description',p.description,'is_verified',p.is_verified,
 'price_updated_at',(SELECT MAX(updated_at) FROM menu_items WHERE place_id=p.id),
 'menu_images',COALESCE((SELECT jsonb_agg('/v1/menu-images/'||i.id ORDER BY c.created_at,i.display_order) FROM contribution_images i JOIN contributions c ON c.id=i.contribution_id WHERE c.place_id=p.id AND c.type='menu_photo' AND c.status='approved'),'[]'::jsonb),
 'bill_examples',COALESCE((SELECT jsonb_agg(jsonb_build_object('total',bill_total,'guests',guests_count,'captured_at',captured_at)) FROM contributions WHERE place_id=p.id AND type='bill_photo' AND status='approved'),'[]'::jsonb),
 'min_price',COALESCE((SELECT MIN(price) FROM menu_items WHERE place_id=p.id),0),
 'max_price',COALESCE((SELECT MAX(price) FROM menu_items WHERE place_id=p.id),0),
 'full_menu',COALESCE((SELECT jsonb_agg(jsonb_build_object('id',m.id,'name',m.name,'price',m.price,'category',m.category,'observed_at',e.captured_at,'reviewed_at',e.reviewed_at) ORDER BY m.name) FROM menu_items m LEFT JOIN contributions e ON e.id=m.contribution_id WHERE m.place_id=p.id),'[]'::jsonb))
 FROM places p JOIN cities c ON c.code=p.city_code JOIN categories cat ON cat.code=p.category_code
 WHERE p.publication_state='published' AND p.deleted_at IS NULL`

func Register(r chi.Router, pool *pgxpool.Pool) {
	registerAdmin(r, pool)
	registerContributions(r, pool)
	r.Get("/v1/places", func(w http.ResponseWriter, req *http.Request) {
		rows, err := pool.Query(req.Context(), placeJSON+` ORDER BY EXISTS(SELECT 1 FROM menu_items WHERE place_id=p.id) DESC,p.is_verified DESC,p.name,p.id`)
		if err != nil {
			auth.WriteAccessError(w, err)
			return
		}
		defer rows.Close()
		result := []json.RawMessage{}
		for rows.Next() {
			var raw []byte
			if err := rows.Scan(&raw); err != nil {
				auth.WriteAccessError(w, err)
				return
			}
			result = append(result, json.RawMessage(raw))
		}
		if err := rows.Err(); err != nil {
			auth.WriteAccessError(w, err)
			return
		}
		httpx.JSON(w, 200, result)
	})
	r.Get("/v1/places/{id}", func(w http.ResponseWriter, req *http.Request) {
		id := chi.URLParam(req, "id")
		if !validID(w, id) {
			return
		}
		rows, err := pool.Query(req.Context(), placeJSON+` AND p.id=$1`, id)
		if err != nil {
			auth.WriteAccessError(w, err)
			return
		}
		defer rows.Close()
		if !rows.Next() {
			if err := rows.Err(); err != nil {
				auth.WriteAccessError(w, err)
				return
			}
			httpx.Error(w, 404, "not_found", "Không tìm thấy địa điểm", false)
			return
		}
		var raw []byte
		if err := rows.Scan(&raw); err != nil {
			auth.WriteAccessError(w, err)
			return
		}
		httpx.JSON(w, 200, json.RawMessage(raw))
	})
	r.Get("/v1/favorites", func(w http.ResponseWriter, req *http.Request) {
		user, err := auth.Current(req, pool)
		if err != nil {
			auth.WriteAccessError(w, err)
			return
		}
		rows, err := pool.Query(req.Context(), `SELECT f.place_id::text FROM favorites f JOIN places p ON p.id=f.place_id WHERE f.user_id=$1 AND p.publication_state='published' AND p.deleted_at IS NULL ORDER BY f.created_at`, user.ID)
		if err != nil {
			auth.WriteAccessError(w, err)
			return
		}
		defer rows.Close()
		ids := []string{}
		for rows.Next() {
			var id string
			if err := rows.Scan(&id); err != nil {
				auth.WriteAccessError(w, err)
				return
			}
			ids = append(ids, id)
		}
		if err := rows.Err(); err != nil {
			auth.WriteAccessError(w, err)
			return
		}
		httpx.JSON(w, 200, ids)
	})
	for _, method := range []string{http.MethodPut, http.MethodDelete} {
		r.MethodFunc(method, "/v1/favorites/{id}", func(w http.ResponseWriter, req *http.Request) {
			user, err := auth.Current(req, pool)
			if err != nil {
				auth.WriteAccessError(w, err)
				return
			}
			id := chi.URLParam(req, "id")
			if !validID(w, id) {
				return
			}
			if req.Method == http.MethodPut {
				tag, err := pool.Exec(req.Context(), `INSERT INTO favorites(user_id,place_id) SELECT $1,id FROM places WHERE id=$2 AND publication_state='published' AND deleted_at IS NULL ON CONFLICT(user_id,place_id) DO UPDATE SET place_id=EXCLUDED.place_id`, user.ID, id)
				if err != nil {
					auth.WriteAccessError(w, err)
					return
				}
				if tag.RowsAffected() == 0 {
					httpx.Error(w, 404, "not_found", "Không tìm thấy địa điểm", false)
					return
				}
			} else {
				if _, err := pool.Exec(req.Context(), `DELETE FROM favorites WHERE user_id=$1 AND place_id=$2`, user.ID, id); err != nil {
					auth.WriteAccessError(w, err)
					return
				}
			}
			w.WriteHeader(http.StatusNoContent)
		})
	}
}
func validID(w http.ResponseWriter, id string) bool {
	if !uuid.MatchString(id) {
		httpx.Error(w, 422, "invalid_id", "ID địa điểm không hợp lệ", false)
		return false
	}
	return true
}

// Seed writes sample records into PostgreSQL; APIs never return embedded fixtures.
func Seed(ctx context.Context, pool *pgxpool.Pool, adminID string) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	_, err = tx.Exec(ctx, `INSERT INTO cities(code,name_vi) VALUES('danang','Đà Nẵng & Hội An'),('hanoi','Hà Nội'),('hochiminh','TP. Hồ Chí Minh') ON CONFLICT DO NOTHING;
 INSERT INTO categories(code,name_vi) VALUES('cafe','Cà phê'),('food','Quán ăn'),('milktea','Trà sữa'),('restaurant','Nhà hàng'),('entertainment','Vui chơi') ON CONFLICT DO NOTHING;`)
	if err != nil {
		return err
	}
	for _, p := range []struct {
		id, name, address, category, vibe string
		lat, lng                          float64
	}{
		{"00000000-0000-4000-8000-000000000101", "Rendez Demo Café", "12 Nguyễn Văn Linh, Đà Nẵng", "cafe", "Chạy deadline", 16.0601, 108.2208},
		{"00000000-0000-4000-8000-000000000102", "Rendez Demo Kitchen", "28 Trần Phú, Đà Nẵng", "food", "Tụ tập nhóm", 16.067, 108.224},
	} {
		_, err = tx.Exec(ctx, `INSERT INTO places(id,name,address,city_code,category_code,opening_hours,latitude,longitude,vibes,publication_state,first_published_at,created_by,updated_by) VALUES($1,$2,$3,'danang',$4,'08:00–22:00',$5,$6,ARRAY[$7]::text[],'published',now(),$8,$8) ON CONFLICT(id) DO NOTHING`, p.id, p.name, p.address, p.category, p.lat, p.lng, p.vibe, adminID)
		if err != nil {
			return err
		}
	}
	_, err = tx.Exec(ctx, `INSERT INTO menu_items(place_id,name,category,price) VALUES
 ('00000000-0000-4000-8000-000000000101','Cà phê sữa','Đồ uống',35000),
 ('00000000-0000-4000-8000-000000000101','Trà đào','Đồ uống',45000),
 ('00000000-0000-4000-8000-000000000102','Cơm gà','Món ăn',55000),
 ('00000000-0000-4000-8000-000000000102','Bún bò','Món ăn',60000)
 ON CONFLICT(place_id,name) DO NOTHING`)
	if err != nil {
		return err
	}
	return tx.Commit(ctx)
}
