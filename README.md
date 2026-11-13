# Advanced Database Systems Portfolio: Nigeria Social Insurance Trust Fund (NSITF)

**Course:** MIT 8103 – Advanced Database Systems  
**Student Name:** Zaharaddeen Wanka  
**Student ID:** 301909094  
**Database Engine:** PostgreSQL 16 (GitHub Codespaces)  
**Case Study Organisation:** Nigeria Social Insurance Trust Fund (NSITF)  

---

## 1. Project Overview

This repository contains the complete database engineering portfolio for **MIT 8103 (Advanced Database Systems)**, modeled on the statutory operations of the **Nigeria Social Insurance Trust Fund (NSITF)** under the *Employees' Compensation Act (ECA) 2010*.

Across five progressive modules, the project builds, optimizes, secures against concurrency anomalies, extends into NoSQL document structures, and horizontally partitions a production-style PostgreSQL database (`nsitf_db`) handling core NSITF workflows:
* **Employer Registry:** Managing unique 10-digit Employees' Compensation Scheme (`ECS`) numbers, Corporate Affairs Commission (`RC`) registrations, zonal office assignments (`Kano`, `Lagos`, `FCT`, `Rivers`, `Bauchi`), and compliance classifications (`Compliant`, `Defaulting`, `Recalcitrant`, `Closed`).
* **Statutory Payroll Assessments:** Enforcing the mandatory **1% monthly payroll assessment fee** (`assessment_fee = 0.01 * total_gross_emolument`) across employee headcounts.
* **Payment Reconciliation & Certification:** Tracking settlements via Remita (`RRR`) and NIBSS channels and issuing annual NSITF Compliance Certificates.

---

## 2. Repository Structure

All deliverables follow the standardized `wanka_zaharaddeen_301909094_` naming convention and are organized by portfolio module:

```text
├── README.md
├── portfolio-1-schema-design/
│   ├── wanka_zaharaddeen_301909094_schema.sql
│   ├── wanka_zaharaddeen_301909094_erd.png
│   └── wanka_zaharaddeen_301909094_readme.md
├── portfolio-2-query-optimisation/
│   ├── wanka_zaharaddeen_301909094_queries.sql
│   ├── wanka_zaharaddeen_301909094_execution_plans.txt
│   └── wanka_zaharaddeen_301909094_readme.md
├── portfolio-3-transactions-concurrency/
│   ├── wanka_zaharaddeen_301909094_transactions.sql
│   ├── wanka_zaharaddeen_301909094_transaction_logs.txt
│   └── wanka_zaharaddeen_301909094_readme.md
├── portfolio-4-nosql-advanced-models/
│   ├── wanka_zaharaddeen_301909094_nosql.sql
│   ├── wanka_zaharaddeen_301909094_nosql_logs.txt
│   └── wanka_zaharaddeen_301909094_readme.md
└── portfolio-5-distributed-cloud/
    ├── wanka_zaharaddeen_301909094_cloud.sql
    ├── wanka_zaharaddeen_301909094_cloud_logs.txt
    └── wanka_zaharaddeen_301909094_readme.md
```

---

## 3. Portfolio Modules Summary

| Module | Topic & Focus | Key Technical Deliverables | Documentation |
| :--- | :--- | :--- | :--- |
| **Portfolio 1** | **Relational Schema Design & Normalization** | Normalized (1NF/2NF/3NF) 4-table PostgreSQL schema (`employers`, `monthly_payrolls`, `contribution_payments`, `compliance_certificates`) with `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `CHECK` constraints, identity sequences, and ERD. | [View Portfolio 1 README](./portfolio-1-schema-design/wanka_zaharaddeen_301909094_readme.md) |
| **Portfolio 2** | **Query Processing & Optimisation** | Deterministic lab dataset generation (`generate_series`), composite B-Tree index engineering (`idx_opt_emp_zone_status`, `idx_opt_payroll_ecs_year`), and `EXPLAIN ANALYZE` execution plan benchmarking (`0.144 ms` $\rightarrow$ `0.129 ms`). | [View Portfolio 2 README](./portfolio-2-query-optimisation/wanka_zaharaddeen_301909094_readme.md) |
| **Portfolio 3** | **Transactions & Concurrency Control** | ACID transaction blocks demonstrating atomic `ROLLBACK` on aborted payments, multi-table `COMMIT` for remittance/certification, and concurrency control using `SERIALIZABLE` isolation with `SELECT ... FOR UPDATE` row locking. | [View Portfolio 3 README](./portfolio-3-transactions-concurrency/wanka_zaharaddeen_301909094_readme.md) |
| **Portfolio 4** | **NoSQL & Advanced Data Models** | Document-oriented data model (`nsitf_employer_documents`) implemented via PostgreSQL `JSONB` and a `GIN` inverted index, embedding payroll arrays and certificate sub-documents to eliminate multi-table `JOIN`s. | [View Portfolio 4 README](./portfolio-4-nosql-advanced-models/wanka_zaharaddeen_301909094_readme.md) |
| **Portfolio 5** | **Distributed & Cloud Database Exercise** | Horizontal sharding via declarative list partitioning (`PARTITION BY LIST (state_zone)`) across `Kano`, `Lagos`, and `Abuja HQ` regional shards, verifying automatic shard routing (`tableoid`) and query partition pruning (`EXPLAIN`). | [View Portfolio 5 README](./portfolio-5-distributed-cloud/wanka_zaharaddeen_301909094_readme.md) |

---

## 4. Reproducing the Database Environment

To recreate `nsitf_db` and run all five portfolio scripts sequentially in PostgreSQL:

```bash
# 1. Create the target database
createdb nsitf_db

# 2. Execute Portfolio 1 through Portfolio 5 in order
psql -v ON_ERROR_STOP=1 -d nsitf_db -f portfolio-1-schema-design/wanka_zaharaddeen_301909094_schema.sql
psql -v ON_ERROR_STOP=1 -d nsitf_db -f portfolio-2-query-optimisation/wanka_zaharaddeen_301909094_queries.sql
psql -v ON_ERROR_STOP=1 -d nsitf_db -f portfolio-3-transactions-concurrency/wanka_zaharaddeen_301909094_transactions.sql
psql -v ON_ERROR_STOP=1 -d nsitf_db -f portfolio-4-nosql-advanced-models/wanka_zaharaddeen_301909094_nosql.sql
psql -v ON_ERROR_STOP=1 -d nsitf_db -f portfolio-5-distributed-cloud/wanka_zaharaddeen_301909094_distributed.sql
```