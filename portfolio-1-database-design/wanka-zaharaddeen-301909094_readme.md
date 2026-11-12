# Portfolio 1: Database Design and Modelling
**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** Nigeria Social Insurance Trust Fund (NSITF)  
**Student Name:** Wanka Zaharaddeen Babayo
**Student ID:** 301909094  

## 1. Case Study Description

### 1.1 Organization Profile
**NSITF** is the sole administrator of the Employees Compensation Scheme in Nigeria. The scheme provides an open, fair and no-fault system of guaranteed compensation for every employee — or their dependants — for any death, injury, disease or disability arising out of or in the course of employment.

### 1.2 Nature of Business & Database Operations
NSITF is mandated to pool a statutory contribution equal to **1% of total monthly gross emoluments** from all registered employers in Nigeria. The database manages employer registration, assessment tracking, financial remittances, and compliance verification.

#### Key Operational Rules Enforced:
1. **Standardized ECS Identifier:** Every registered employer is assigned a standardized 10-digit unique ECS number (`VARCHAR(10)`).
2. **Employer Status:** Operational statuses are defined as **Compliant** (up to date payments), **Defaulting** (payments not up to date), **Recalcitrant** (uncooperative/non-responsive), or **Closed** (business inactive).
3. **Registration Fee:** Standardized at **20,000 NGN** (tracked as `Paid` or `Unpaid` without requiring manual user amount entry).
4. **Minimum Employee Requirement:** Enforces a minimum workforce threshold of 3 employees per registered employer.
5. **Historical Inception Limit:** The Employees' Compensation Scheme (ECS) officially commenced in July 2011, the system blocks any prior assessment date.
6. **Certificate Management:** Certificates incur a standard **30,000 NGN** fee and progress through 5 statuses: `Not Requested`, `Processing`, `Issued`, `Expired`, or `Revoked`.
7. **Sequence Identification:** `payroll_id` utilizes a 6-digit auto-incrementing integer sequence starting at `100000`.

## 2. Normalization Proof (UNF to 3NF)

### 2.1 Unnormalized Form (UNF)
In a flat, unnormalized register, employer details and repeating monthly records are stored within a single compound structure:

`NSITF_Unnormalized_Record (ecs_number, company_name, rc_number, business_sector, office_address, state_zone, contact_person, contact_email, contact_phone, registration_date, registration_fee, registration_fee_status, employer_status, monthly_payrolls[payroll_id, assessment_year, assessment_month, employee_count, total_gross_emolument, assessment_fee, submission_date], contribution_payments[payment_id, payment_reference, amount_paid, payment_date, payment_channel, payment_status], compliance_certificates[certificate_id, issue_date, expiry_date, certificate_fee, compliance_status])`

### 2.2 First Normal Form (1NF)
Removed all repeating groups so every attribute holds an atomic value, uniquely identified by a composite key (`ecs_number`, `payroll_id`, `payment_id`, `certificate_id`):

`NSITF_1NF (ecs_number, company_name, rc_number, business_sector, office_address, state_zone, contact_person, contact_email, contact_phone, registration_date, registration_fee, registration_fee_status, employer_status, payroll_id, assessment_year, assessment_month, employee_count, total_gross_emolument, assessment_fee, submission_date, payment_id, payment_reference, amount_paid, payment_date, payment_channel, payment_status, certificate_id, issue_date, expiry_date, certificate_fee, compliance_status)`

### 2.3 Second Normal Form (2NF)
Eliminated partial functional dependencies by decomposing attributes into four distinct tables where every non-key column depends on the entire primary key of its table:
1. `employers` (`ecs_number` [PK], company_name, rc_number, business_sector, office_address, state_zone, contact_person, contact_email, contact_phone, registration_date, registration_fee, registration_fee_status, employer_status)
2. `monthly_payrolls` (`payroll_id` [PK], `ecs_number` [FK], assessment_year, assessment_month, employee_count, total_gross_emolument, assessment_fee, submission_date)
3. `contribution_payments` (`payment_id` [PK], `ecs_number` [FK], `payroll_id` [FK], payment_reference, amount_paid, payment_date, payment_channel, payment_status)
4. `compliance_certificates` (`certificate_id` [PK], `ecs_number` [FK], issue_date, expiry_date, certificate_fee, compliance_status)

### 2.4 Third Normal Form (3NF)
Eliminated transitive dependencies so non-key columns depend exclusively on their respective primary keys:
* In `employers`, `contribution_payments`, and `compliance_certificates`, all non-key attributes depend strictly on their respective primary keys (`ecs_number`, `payment_id`, `certificate_id`).
* In `monthly_payrolls`, `assessment_fee` is mathematically derived from `total_gross_emolument` * 0.01). While pure theoretical 3NF omits derived attributes, `assessment_fee` is retained as a **controlled denormalization** for financial auditability and enforced at the database level via `CHECK (assessment_fee = ROUND(total_gross_emolument * 0.01, 2))`.

---

## 3. Data Dictionary

### 3.1 Table: `employers`
| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `ecs_number` | `VARCHAR(10)` | `PRIMARY KEY`, `CHECK (LENGTH = 10)` | Standardized 10-digit NSITF employer identifier |
| `company_name` | `VARCHAR(150)` | `NOT NULL` | Registered corporate name |
| `rc_number` | `VARCHAR(20)` | `NOT NULL`, `UNIQUE` | Corporate Affairs Commission (CAC) registration number |
| `business_sector` | `VARCHAR(80)` | `NOT NULL` | Economic/industry sector of operation |
| `office_address` | `TEXT` | `NOT NULL` | Physical business address |
| `state_zone` | `VARCHAR(50)` | `NOT NULL` | Regional branch/zone (e.g., Kano, Lagos, Abuja HQ) |
| `contact_person` | `VARCHAR(100)` | `NOT NULL` | Designated compliance liaison officer |
| `contact_email` | `VARCHAR(100)` | `NOT NULL`, `UNIQUE` | Official email address |
| `contact_phone` | `VARCHAR(15)` | `NOT NULL` | Official contact phone number |
| `registration_date` | `DATE` | `NOT NULL`, `DEFAULT CURRENT_DATE` | Date employer registered with NSITF |
| `registration_fee` | `DECIMAL(10,2)` | `NOT NULL`, `DEFAULT 20000.00` | Fixed statutory registration fee (NGN) |
| `registration_fee_status` | `VARCHAR(20)` | `NOT NULL`, `CHECK ('Paid', 'Unpaid')` | Settlement status of registration fee |
| `employer_status` | `VARCHAR(20)` | `NOT NULL`, `CHECK ('Compliant', 'Defaulting', 'Recalcitrant', 'Closed')` | Current employer compliance classification |

### 3.2 Table: `monthly_payrolls`
| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `payroll_id` | `INT` | `PRIMARY KEY`, `IDENTITY(100000, 1)` | 6-digit auto-incrementing payroll assessment ID |
| `ecs_number` | `VARCHAR(10)` | `NOT NULL`, `FOREIGN KEY` | References `employers(ecs_number)` |
| `assessment_year` | `INT` | `NOT NULL`, `CHECK (>= 07/2011)` | Year of payroll assessment |
| `assessment_month` | `INT` | `NOT NULL`, `CHECK (1..12)` | Month of payroll assessment (`1`–`12`) |
| `employee_count` | `INT` | `NOT NULL`, `CHECK (>= 3)` | Total number of staff (minimum 3 required) |
| `total_gross_emolument` | `DECIMAL(14,2)` | `NOT NULL`, `CHECK (>= 0)` | Total monthly gross staff emoluments (NGN) |
| `assessment_fee` | `DECIMAL(14,2)` | `NOT NULL`, `CHECK (= 1% Emolument)` | Calculated 1% statutory contribution due (NGN) |
| `submission_date` | `TIMESTAMP` | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Timestamp when payroll schedule was filed |

### 3.3 Table: `contribution_payments`
| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `payment_id` | `VARCHAR(30)` | `PRIMARY KEY` | Unique internal payment transaction ID |
| `ecs_number` | `VARCHAR(10)` | `NOT NULL`, `FOREIGN KEY` | References `employers(ecs_number)` |
| `payroll_id` | `INT` | `NOT NULL`, `FOREIGN KEY` | References `monthly_payrolls(payroll_id)` |
| `payment_reference` | `VARCHAR(50)` | `NOT NULL`, `UNIQUE` | Remita Retrieval Reference (RRR) |
| `amount_paid` | `DECIMAL(14,2)` | `NOT NULL`, `CHECK (> 0)` | Actual amount remitted (NGN) |
| `payment_date` | `TIMESTAMP` | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP` | Timestamp of payment settlement |
| `payment_channel` | `VARCHAR(40)` | `NOT NULL` | Payment gateway/channel (e.g., Remita, NIBSS) |
| `payment_status` | `VARCHAR(20)` | `NOT NULL`, `CHECK ('Successful', 'Failed', 'Pending', 'Reversed')` | Transaction settlement status |

### 3.4 Table: `compliance_certificates`
| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `certificate_id` | `VARCHAR(30)` | `PRIMARY KEY` | Unique compliance certificate serial number |
| `ecs_number` | `VARCHAR(10)` | `NOT NULL`, `FOREIGN KEY` | References `employers(ecs_number)` |
| `issue_date` | `DATE` | `NULLABLE` | Date certificate was officially issued |
| `expiry_date` | `DATE` | `NULLABLE`, `CHECK (> issue_date)` | Certificate expiration date |
| `certificate_fee` | `DECIMAL(10,2)` | `NOT NULL`, `DEFAULT 30000.00` | Standard certificate processing fee (NGN) |
| `compliance_status` | `VARCHAR(20)` | `NOT NULL`, `CHECK ('Issued', 'Processing', 'Expired', 'Revoked', 'Not Requested')` | Current lifecycle status of the certificate |

---

## 4. Entity-Relationship Diagram (ERD)

```mermaid
erDiagram
    EMPLOYERS ||--o{ MONTHLY_PAYROLLS : submits
    EMPLOYERS ||--o{ CONTRIBUTION_PAYMENTS : remits
    EMPLOYERS ||--o{ COMPLIANCE_CERTIFICATES : requests
    MONTHLY_PAYROLLS ||--o{ CONTRIBUTION_PAYMENTS : settles

    EMPLOYERS {
        string ecs_number PK
        string company_name
        string rc_number
        string business_sector
        string state_zone
        decimal registration_fee
        string registration_fee_status
        string employer_status
    }

    MONTHLY_PAYROLLS {
        int payroll_id PK
        string ecs_number FK
        int assessment_year
        int assessment_month
        int employee_count
        decimal total_gross_emolument
        decimal assessment_fee
    }

    CONTRIBUTION_PAYMENTS {
        string payment_id PK
        string ecs_number FK
        int payroll_id FK
        string payment_reference
        decimal amount_paid
        string payment_status
    }

    COMPLIANCE_CERTIFICATES {
        string certificate_id PK
        string ecs_number FK
        date issue_date
        date expiry_date
        decimal certificate_fee
        string compliance_status
    }