-- Portfolio 2: Query Processing and Optimization
-- Case Study: Nigeria Social Insurance Trust Fund
-- Student Name: Wanka Zaharaddeen Babayo
-- Student ID: 301909094

-- Clear tables and reset auto-increments
TRUNCATE TABLE employers, monthly_payrolls, contribution_payments, compliance_certificates RESTART IDENTITY CASCADE;

-- Insert 30 entries in Employers table
INSERT into employers(
    ecs_number, company_name, rc_number, business_sector, company_address, state_zone, contact_person, contact_email, 
    contact_phone, registration_date, registration_fee, registration_fee_status, employer_status
)
SELECT 
    LPAD((1700000000 + g)::text, 10, '0'),
    'Company ' || g || ' Nigeria Ltd',
    'RC-' || (500000 + g),
    CASE (g % 3)
        WHEN 0 THEN 'Manufacturing'
        WHEN 1 THEN 'Construction'
        ELSE 'Healthcare'
    END,
    'Plot ' || g || ' Industrial Zone',
    CASE (g % 3)
        WHEN 0 THEN 'Kano'
        WHEN 1 THEN 'Lagos'
        ELSE 'FCT, Abuja'
    END,
    'Officer ' || g,
    'hr' || g || '@company.ng',
    '0803000' || LPAD(g::text, 4,'1'),
    DATE '2021-01-10' + (g * INTERVAL '15 days'),
    20000.00,
    CASE g % 5 = 0 THEN 'Unpaid' ELSE 'Paid',
    CASE 
        WHEN g % 10 = 0 THEN 'Recalcitrant'
        WHEN g % 5 = 0 THEN 'Defaulting'
        ELSE 'Compliant'
    END
FROM generate_series(1,30) AS g;


-- Insert 90 entries in to Monthly Payrolls (3 months per employer)
INSERT INTO monthly_payrolls(
    ecs_number, assessment_year, assessment_month, employee_count, total_gross_emolument, assessment_fee
)
SELECT 
    e.ecs_number,
    2025,
    m.month_num,
    10 + (RIGHT(e.ecs_number,2)::int % 30),
    (10 + (RIGHT(e.ecs_number,2)::int % 30)) * 100000.00,
    ROUND(((10 + (RIGHT(e.ecs_number,2)::int % 30)) * 100000.00)* 0.01,2)
FROM employers e 
CROSS JOIN generate_series(1,3) AS m(month_num)


-- Insert 60 entries into Contribution Payments (60 Paying, 30 owing)
INSERT INTO contribution_payments(
    payment_id, ecs_number, payroll_id, payment_reference, amount_paid, payment_date, payment_channel, payment_status
)
SELECT
    'PAY-2025-' || p.payroll_id,
    p.ecs_number,
    p.payroll_id,
    'RRR-' || (20000 + p.payroll_id),
    p.assessment_fee,
    DATE '2025-01-25' ((p.assessment_month - 1) * INTERVAL '1 month'),
    CASE WHEN p.payroll_id % 2 = 0 THEN 'Remita' ELSE 'NIBSS' END,
    CASE WHEN p.payroll_id % 10 = 0 THEN 'Failed' ELSE 'Successful' END
FROM monthly_payrolls p 
WHERE p.payroll_id < 100060; -- first 60 entries paying


-- QUERY OPTIMIZATION

-- DROP SECONDARY INDEXES
DROP INDEX IF EXISTS idx_employers_state_zone;
DROP INDEX IF EXISTS idx_employers_status;
DROP INDEX IF EXISTS idx_payrolls_ecs_period;
DROP INDEX IF EXISTS idx_payments_ecs_date;
DROP INDEX IF EXISTS idx_certificates_ecs_status;
DROP INDEX IF EXISTS idx_opt_emp_zone_status;
DROP INDEX IF EXISTS idx_opt_payroll_ecs_year;
DROP INDEX IF EXISTS idx_opt_payment_payroll_status;

ANALYZE;

-- [QUERY UNOPTIMIZED] Total 2025 Assessment Fees by State Zone for Compliant Employers
SELECT
    e.state_zone,
    COUNT(DISTINCT e.ecs_number) AS compliant_employer,
    SUM(p.assessment_fee) AS total_assessment_fee
FROM employers e 
JOIN monthly_payrolls p ON e.ecs_number = p.ecs_number
WHERE e.employer_status = 'Compliant'
AND p.assessment_year = 2025
GROUP BY e.state_zone
ORDER BY total_assessment_fee DESC

EXPLAIN ANALYZE
SELECT
    e.state_zone,
    COUNT(DISTINCT e.ecs_number) AS compliant_employer,
    SUM(p.assessment_fee) AS total_assessment_fee
FROM employers e 
JOIN monthly_payrolls p ON e.ecs_number = p.ecs_number
WHERE e.employer_status = 'Compliant'
AND p.assessment_year = 2025
GROUP BY e.state_zone
ORDER BY total_assessment_fee DESC


-- [QUERY OPTIMIZED] Total 2025 Assessment Fees by State Zone for Compliant Employers with INDEXES
CREATE INDEX idx_opt_emp_zone_status ON employers(state_zone, employer_status);
CREATE INDEX idx_opt_payroll_ecs_year ON monthly_payrolls(ecs_number, assessment_year);

EXPLAIN ANALYZE
SELECT
    e.state_zone,
    COUNT(DISTINCT e.ecs_number) AS compliant_employer,
    SUM(p.assessment_fee) AS total_assessment_fee
FROM employers e 
JOIN monthly_payrolls p ON e.ecs_number = p.ecs_number
WHERE e.employer_status = 'Compliant'
AND p.assessment_year = 2025
GROUP BY e.state_zone
ORDER BY total_assessment_fee DESC
