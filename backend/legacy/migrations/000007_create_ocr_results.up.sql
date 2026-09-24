CREATE TABLE IF NOT EXISTS ocr_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contribution_id UUID REFERENCES contributions(id) ON DELETE SET NULL,
    source_image_path TEXT NOT NULL,
    raw_result JSONB,
    status VARCHAR(30) NOT NULL DEFAULT 'pending_review' CHECK (status IN ('pending_review', 'confirmed')),
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ocr_results_contribution ON ocr_results(contribution_id);
CREATE INDEX IF NOT EXISTS idx_ocr_results_status ON ocr_results(status);
