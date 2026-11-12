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
