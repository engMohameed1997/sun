-- Migration 020: Link Technicians directly to Users Table (Normalization)
-- Makes redundant identity columns in technicians nullable so users table is the single source of truth.

ALTER TABLE technicians 
    ALTER COLUMN full_name DROP NOT NULL,
    ALTER COLUMN role DROP NOT NULL,
    ALTER COLUMN role SET DEFAULT 'technician';

-- Ensure user_id constraint exists and is foreign key to users(id)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'technicians_user_id_fkey' AND table_name = 'technicians'
    ) THEN
        ALTER TABLE technicians 
            ADD CONSTRAINT technicians_user_id_fkey 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;
