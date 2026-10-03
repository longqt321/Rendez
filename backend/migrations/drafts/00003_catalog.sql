-- +goose Up
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE TABLE cities (
    code text PRIMARY KEY,
    name_vi text NOT NULL CHECK (length(trim(name_vi)) BETWEEN 1 AND 200),
    enabled boolean NOT NULL DEFAULT true
);

CREATE TABLE categories (
    code text PRIMARY KEY,
    name_vi text NOT NULL CHECK (length(trim(name_vi)) BETWEEN 1 AND 200),
    enabled boolean NOT NULL DEFAULT true
);

CREATE TABLE places (
    id uuid PRIMARY KEY,
    name text NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 200),
    address text NOT NULL CHECK (length(trim(address)) BETWEEN 1 AND 500),
    city_code text NOT NULL REFERENCES cities(code) ON DELETE RESTRICT,
    category_code text REFERENCES categories(code) ON DELETE RESTRICT,
    opening_hours text,
    latitude double precision,
    longitude double precision,
    publication_state text NOT NULL DEFAULT 'draft'
        CHECK (publication_state IN ('draft', 'published', 'hidden')),
    revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
    created_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    updated_by uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    first_published_at timestamptz,
    deleted_at timestamptz,
    state_reason text,
    CHECK ((latitude IS NULL) = (longitude IS NULL)),
    CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CHECK (opening_hours IS NULL OR length(opening_hours) <= 500),
    CHECK (publication_state <> 'published' OR
           (category_code IS NOT NULL AND first_published_at IS NOT NULL AND deleted_at IS NULL))
);

CREATE INDEX places_public_name_idx ON places (name, id)
    WHERE publication_state = 'published' AND deleted_at IS NULL;
CREATE INDEX places_admin_state_idx ON places (publication_state, created_at DESC, id);

-- +goose Down
DROP TABLE places;
DROP TABLE categories;
DROP TABLE cities;
DROP EXTENSION IF EXISTS unaccent;
