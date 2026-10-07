-- +goose Up
ALTER TABLE users ADD COLUMN email text UNIQUE;
ALTER TABLE users ADD COLUMN password_hash text;
ALTER TABLE places ADD COLUMN cover_image_url text NOT NULL DEFAULT '';
ALTER TABLE places ADD COLUMN vibes text[] NOT NULL DEFAULT '{}';
CREATE TABLE menu_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id uuid NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 200),
    category text NOT NULL DEFAULT 'Menu',
    price bigint NOT NULL CHECK (price >= 0),
    UNIQUE (place_id, name)
);
CREATE TABLE favorites (
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    place_id uuid NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, place_id)
);
-- +goose Down
DROP TABLE favorites;
DROP TABLE menu_items;
ALTER TABLE places DROP COLUMN vibes;
ALTER TABLE places DROP COLUMN cover_image_url;
ALTER TABLE users DROP COLUMN password_hash;
ALTER TABLE users DROP COLUMN email;
