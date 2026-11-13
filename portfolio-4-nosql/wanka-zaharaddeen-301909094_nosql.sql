-- Portfolio 4: NoSQL & Advanced Data Models
-- Case Study: Nigeria Social Insurance Trust Fund
-- Student Name: Wanka Zaharaddeen Babayo
-- Student ID: 301909094

-- We will make use of the Document Store model with GIN Index, we will create a Document Store, insert values and run a query
DROP TABLE IF EXISTS nsitf_employer_documents;

-- Create Document Store & index
CREATE TABLE nsitf_employer_documents (
    ecs_number  VARCHAR(10) PRIMARY KEY,
    profile_doc JSONB NOT NULL
);

CREATE INDEX idx_nsitf_doc_gin ON nsitf_employer_documents USING GIN (profile_doc);

-- Insert values
INSERT INTO nsitf_employer_documents (ecs_number, profile_doc) VALUES
('1700000001', '{
    "company_name": "Kano Agro Processing Ltd",
    "business_sector": "Manufacturing",
    "state_zone": "Kano",
    "employer_status": "Compliant",
    "payrolls": [
        {"period": "2025-01", "employee_count": 25, "assessment_fee": 25000.00, "payment_status": "Successful"},
        {"period": "2025-02", "employee_count": 25, "assessment_fee": 25000.00, "payment_status": "Successful"}
    ],
    "certificate": {
        "certificate_id": "CERT-2026-0001",
        "certificate_status": "Issued",
        "expiration_date": "2026-12-31"
    }
}'::jsonb),

('1700000003', '{
    "company_name": "Lagos Metro Builders Ltd",
    "business_sector": "Construction",
    "state_zone": "Lagos",
    "employer_status": "Defaulting",
    "payrolls": [
        {"period": "2025-01", "employee_count": 40, "assessment_fee": 40000.00, "payment_status": "Unpaid"}
    ],
    "certificate": null
}'::jsonb);

-- Query Document Store
-- Retrieve full employer summary & nested certificate status
SELECT
    ecs_number,
    profile_doc ->> 'company_name' AS company_name,
    profile_doc ->> 'state_zone' AS state_zone,
    profile_doc ->> 'employer_status' AS status,
    jsonb_array_length(profile_doc -> 'payrolls') AS payroll_months_logged,
    COALESCE(profile_doc -> 'certificate' ->> 'certificate_id', 'Not Issued') AS certificate_id
FROM nsitf_employer_documents
ORDER BY ecs_number;
