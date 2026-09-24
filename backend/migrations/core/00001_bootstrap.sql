-- +goose Up
-- M0 has no application schema. Goose records this bootstrap version itself.
SELECT 1;

-- +goose Down
SELECT 1;
