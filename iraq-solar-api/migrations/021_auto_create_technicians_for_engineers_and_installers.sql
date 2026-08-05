-- Migration 021: Automatically populate technicians profiles for existing engineer and installer users
-- Ensures all users with workforce roles have a linked technicians record.

INSERT INTO technicians (
    id, user_id, full_name, role, governorate_id, district_id, availability_status, level_id
)
SELECT 
    u.id,
    u.id,
    u.full_name,
    CASE 
        WHEN u.role IN ('engineer', 'installer', 'technician', 'worker') THEN u.role 
        ELSE 'technician' 
    END,
    u.governorate_id,
    u.district_id,
    'offline',
    (SELECT id FROM technician_levels ORDER BY sort_order LIMIT 1)
FROM users u
LEFT JOIN technicians t ON t.user_id = u.id
WHERE t.id IS NULL 
  AND u.role IN ('engineer', 'installer', 'technician', 'worker')
ON CONFLICT (user_id) DO NOTHING;

-- Also initialize wallet, ranking, and availability records for any orphan technicians
INSERT INTO technician_availability (technician_id, status)
SELECT id, 'offline' FROM technicians ON CONFLICT (technician_id) DO NOTHING;

INSERT INTO technician_wallet (technician_id)
SELECT id FROM technicians ON CONFLICT (technician_id) DO NOTHING;

INSERT INTO technician_ranking (technician_id)
SELECT id FROM technicians ON CONFLICT (technician_id) DO NOTHING;
