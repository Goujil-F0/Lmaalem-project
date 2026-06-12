-- Fix booking status constraint to include paid_cash
ALTER TABLE bookings
DROP CONSTRAINT IF EXISTS bookings_status_check;

ALTER TABLE bookings
ADD CONSTRAINT bookings_status_check
CHECK (status IN ('pending','accepted','rejected','completed','paid_cash','cancelled'));

-- Verify constraint
SELECT constraint_name, constraint_type, check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'bookings' AND constraint_type = 'CHECK';
