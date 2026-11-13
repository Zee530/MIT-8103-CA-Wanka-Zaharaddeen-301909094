# Portfolio 3: Transactions & Concurrency Control
**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** Nigeria Social Insurance Trust Fund (NSITF)  
**Student Name:** Zaharaddeen Wanka  
**Student ID:** 301909094  

---

## 1. Overview & Transactional Integrity in NSITF

In NSITF's statutory contribution workflow, confirming a Remita payment requires updating three separate tables simultaneously: logging the settlement in `contribution_payments`, updating the employer's status in `employers` from `'Defaulting'` to `'Compliant'`, and issuing a certificate in `compliance_certificates`. Wrapping these dependent steps inside explicit SQL transaction boundaries (`BEGIN ... COMMIT` / `ROLLBACK`) prevents partial writes and race conditions.

All SQL demonstrations are stored in `wanka-zaharaddeen-301909094_transactions.sql` with verified terminal outputs recorded in `wanka-zaharaddeen-301909094_transaction_logs.txt`.

---

## 2. Transaction & Concurrency Mechanisms Implemented

### 2.1 Atomicity & Rollback (`BEGIN ... ROLLBACK`)
To prove all-or-nothing execution, an incoming Remita payment (`PAY-P3-001`) and an employer status update (`'Compliant'`) were executed inside an explicit `BEGIN` block and deliberately aborted using `ROLLBACK` before certificate issuance:

```sql
BEGIN;

INSERT INTO contribution_payments (
    payment_id, ecs_number, payroll_id, payment_reference,
    amount_paid, payment_channel, payment_status
) VALUES (
    'PAY-P3-001', '1000000099', 100999, 'RRR-999000111',
    30000.00, 'Remita', 'Successful'
);

UPDATE employers
SET employer_status = 'Compliant'
WHERE ecs_number = '1000000099';

ROLLBACK;
```

* **Verification Outcome:** Post-rollback queries confirmed that `employer_status` remained `'Defaulting'` and `aborted_payment_count` returned `0`, proving that interrupted workflows leave zero partial data behind.

### 2.2 Atomic Commit (`BEGIN ... COMMIT`)
When validation succeeds across all three workflow stages, `COMMIT` persists the payment record, compliance status upgrade, and annual certificate (`CERT-P3-2026-01`) as a single indivisible unit:

```sql
BEGIN;

INSERT INTO contribution_payments (...) VALUES ('PAY-P3-002', '1000000099', 100999, 'RRR-999000222', 30000.00, 'Remita', 'Successful');

UPDATE employers
SET employer_status = 'Compliant'
WHERE ecs_number = '1000000099';

INSERT INTO compliance_certificates (...) VALUES ('CERT-P3-2026-01', '1000000099', DATE '2026-01-10', DATE '2026-12-31', 30000.00, 'Issued');

COMMIT;
```

* **Verification Outcome:** A three-table `JOIN` across `employers`, `contribution_payments`, and `compliance_certificates` confirmed all three records persisted together cleanly.

### 2.3 Isolation & Concurrency Control (`SERIALIZABLE` + `SELECT ... FOR UPDATE`)
When multiple NSITF zonal officers or automated payment webhooks access the same employer record simultaneously, concurrent updates risk **Lost Updates** or **Write Skew**. To prevent concurrency anomalies, the transaction enforces PostgreSQL's strictest isolation level (`SERIALIZABLE`) paired with pessimistic row-level locking (`FOR UPDATE`):

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT ecs_number, employer_status
FROM employers
WHERE ecs_number = '1000000099'
FOR UPDATE;

UPDATE employers
SET company_address = 'Plot 99 Ahmadu Bello Way, Phase II, Bauchi'
WHERE ecs_number = '1000000099';

COMMIT;
```

* **`SERIALIZABLE` Isolation:** Enforces strict serial equivalence via Serializable Snapshot Isolation (SSI), ensuring concurrent transactions never produce outcomes that violate one-at-a-time execution order.
* **`SELECT ... FOR UPDATE`:** Acquires an exclusive row-level lock on employer `'1000000099'`, forcing any concurrent session attempting to modify that specific employer to wait until `COMMIT` releases the lock, while allowing non-conflicting reads via MVCC.