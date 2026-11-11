-- Portfolio 1: Database Design & Modelling
-- Case Study: Nigeria Social Insurance Trust Fund
-- Student Name: Wanka Zaharaddeen Babayo
-- Student ID: 301909094

-- Drop Existing Tables
DROP TABLE IF EXISTS employers CASCADE;
DROP TABLE IF EXISTS monthly_payrolls CASCADE;
DROP TABLE IF EXISTS contribution_payments CASCADE;
DROP TABLE IF EXISTS compliance_certificates CASCADE;

-- TABLE 1: EMPLOYERS
CREATE TABLE employers (
    ecs_number VARCHAR(10) PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    rc_number VARCHAR(20) NOT NULL UNIQUE,
    sector VARCHAR(80) NOT NULL,
    company_address TEXT NOT NULL,
    state_zone VARCHAR(50) NOT NULL,
    contact_person VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100) NOT NULL UNIQUE,
    contact_phone VARCHAR(15) NOT NULL,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    registration_fee DECIMAL (10,2) NOT NULL DEFAULT 20000.00,
    registration_fee_status VARCHAR(20) NOT NULL DEFAULT 'Unpaid',
    employer_status VARCHAR(20) NOT NULL DEFAULT 'Compliant',
    CONSTRAINT chk_employer_status CHECK (employer_status IN ('Compliant', 'Defaulting', 'Recalcitrant', 'Closed')),
    CONSTRAINT chk_registration_fee_status CHECK (registration_fee_status IN ('Unpaid', 'Paid'))
);