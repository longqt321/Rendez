-- +goose Up
ALTER TABLE places ADD COLUMN description text NOT NULL DEFAULT '' CHECK (length(description) <= 2000);
ALTER TABLE places ADD COLUMN is_verified boolean NOT NULL DEFAULT false;
CREATE TABLE contributions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL REFERENCES users(id),
 place_id uuid NOT NULL REFERENCES places(id),
 type text NOT NULL CHECK (type IN ('menu_photo','bill_photo')),
 captured_at timestamptz NOT NULL,
 status text NOT NULL DEFAULT 'pending_admin' CHECK (status IN ('pending_admin','approved','rejected')),
 rejection_reason text NOT NULL DEFAULT '' CHECK (length(rejection_reason)<=2000),
 ocr_text text NOT NULL DEFAULT '',
 ocr_error text NOT NULL DEFAULT '',
 draft_items jsonb NOT NULL DEFAULT '[]' CHECK (jsonb_typeof(draft_items)='array'),
 bill_total bigint CHECK (bill_total > 0 AND bill_total <= 1000000000),
 guests_count integer CHECK (guests_count BETWEEN 1 AND 100),
 reviewed_by uuid REFERENCES users(id),
 reviewed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 CHECK ((status='pending_admin' AND reviewed_at IS NULL AND reviewed_by IS NULL) OR (status<>'pending_admin' AND reviewed_at IS NOT NULL AND reviewed_by IS NOT NULL)),
 CHECK (status<>'rejected' OR length(trim(rejection_reason))>0),
 CHECK (status<>'approved' OR type<>'bill_photo' OR (bill_total IS NOT NULL AND guests_count IS NOT NULL))
);
CREATE INDEX contributions_owner_idx ON contributions(user_id,created_at DESC);
CREATE INDEX contributions_pending_idx ON contributions(status,created_at);
CREATE TABLE contribution_images (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 contribution_id uuid NOT NULL REFERENCES contributions(id) ON DELETE CASCADE,
 storage_name text NOT NULL UNIQUE,
 content_type text NOT NULL CHECK (content_type IN ('image/png','image/jpeg')),
 file_size integer NOT NULL CHECK (file_size > 0),
 display_order integer NOT NULL CHECK (display_order BETWEEN 0 AND 4)
);
ALTER TABLE menu_items ADD COLUMN contribution_id uuid REFERENCES contributions(id);
ALTER TABLE menu_items ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();
-- +goose Down
ALTER TABLE menu_items DROP COLUMN updated_at;
ALTER TABLE menu_items DROP COLUMN contribution_id;
DROP TABLE contribution_images;
DROP TABLE contributions;
ALTER TABLE places DROP COLUMN is_verified;
ALTER TABLE places DROP COLUMN description;
