CREATE TABLE IF NOT EXISTS contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contributor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    place_id UUID REFERENCES places(id) ON DELETE SET NULL,
    type VARCHAR(30) NOT NULL CHECK (type IN ('bill', 'menu_photo')),
    image_path TEXT NOT NULL,
    captured_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(30) NOT NULL DEFAULT 'pending_auto' CHECK (status IN ('pending_auto', 'pending_manual', 'approved', 'rejected_auto', 'rejected_manual')),
    reject_reason TEXT,
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_contributions_contributor ON contributions(contributor_id);
CREATE INDEX IF NOT EXISTS idx_contributions_place ON contributions(place_id);
CREATE INDEX IF NOT EXISTS idx_contributions_status ON contributions(status);
