-- Portfolio 2: Transactions, Concurrency Control & Recovery
-- Case Study: Nigeria Social Insurance Trust Fund
-- Student Name: Wanka Zaharaddeen Babayo
-- Student ID: 301909094

-- PART 1: ATOMIC ROLLBACK
-- We will register one employer into the employers table with status defaulting and input their payroll.
-- We then simulate an app level error by using a BEGIN command and within it add a payment and update their status from 
-- defaulting to complying,we then use a ROLLBACK to cancel the transaction, then check the database to confirm this

-- Clean employer if present in tables
DELETE FROM compliance_certificates WHERE certificate_id LIKE 'CERT-P3-%';
DELETE FROM contribution_payments WHERE payment_id LIKE 'PAY-P3-%';
DELETE FROM monthly_payrolls WHERE ecs_number = '1000000099';
DELETE FROM employers WHERE ecs_number = '1000000099';

-- Insert Employer
INSERT INTO employers (
    ecs_number, company_name, rc_number, business_sector, company_address,
    state_zone, contact_person, contact_email, contact_phone,
    registration_date, registration_fee, registration_fee_status, employer_status
) VALUES (
    '1000000099', 'Bauchi Savanna Logistics Ltd', 'RC-990099', 'Logistics',
    'Plot 99 Ahmadu Bello Way, Bauchi', 'Bauchi', 'Ibrahim Musa',
    'compliance@bauchisavanna.ng', '08039990099',
    DATE '2022-05-10', 20000.00, 'Paid', 'Defaulting'
);

-- Insert Payroll
INSERT INTO monthly_payrolls (
    payroll_id, ecs_number, assessment_year, assessment_month,
    employee_count, total_gross_emolument, assessment_fee
) VALUES (
    100999, '1000000099', 2025, 11, 20, 3000000.00, 30000.00
);

-- Verify Insertions
SELECT ecs_number, company_name, employer_status
FROM employers
WHERE ecs_number = '1000000099';

-- Begin rollback test
BEGIN;

-- Add Contribution
INSERT INTO contribution_payments (
    payment_id, ecs_number, payroll_id, payment_reference,
    amount_paid, payment_channel, payment_status
) VALUES (
    'PAY-P3-001', '1000000099', 100999, 'RRR-999000111',
    30000.00, 'Remita', 'Successful'
);

-- Update status to Compliant
UPDATE employers
SET employer_status = 'Compliant'
WHERE ecs_number = '1000000099';

-- App error -> Rollback
ROLLBACK;

-- Verify Rollback
SELECT ecs_number, employer_status
FROM employers
WHERE ecs_number = '1000000099';

SELECT COUNT(*) AS aborted_payment_count
FROM contribution_payments
WHERE payment_id = 'PAY-P3-001';