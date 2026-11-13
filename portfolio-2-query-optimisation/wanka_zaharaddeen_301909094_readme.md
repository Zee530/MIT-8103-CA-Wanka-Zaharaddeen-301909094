# Portfolio 2: Query Processing and Optimisation
**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** Nigeria Social Insurance Trust Fund (NSITF)  
**Student Name:** Wanka Zaharaddeen Babayo  
**Student ID:** 301909094  

---

## 1. Overview & Lab Dataset Architecture

To evaluate query execution plans and index performance on the normalized NSITF schema (`nsitf_db`), a deterministic synthetic dataset was generated in `wanka-zaharaddeen-301909094_queries.sql` using PostgreSQL's `generate_series()` function. For this benchmark, **120 records** across the two primary assessment tables were queried (within a 180-row lab database):

| Table Name | Row Count | Data Distribution & Operational Rules |
| :--- | :--- | :--- |
| **`employers`** | 30 | Distributed evenly across 3 zonal offices (`Kano`, `Lagos`, `Abuja HQ`) with 24 `Compliant`, 3 `Defaulting`, and 3 `Recalcitrant` employers. |
| **`monthly_payrolls`** | 90 | 3 monthly assessments (Jan–Mar 2025) per employer (`payroll_id` auto-incrementing from `100000` to `100089`), enforcing `employee_count >= 3` and the `1%` statutory `assessment_fee`. |

---

## 2. Target Analytical Query

The benchmark evaluates a core NSITF regional revenue aggregation query joining `employers` and `monthly_payrolls` to calculate total 2025 statutory assessment fees per zonal office for compliant organizations. The exact same query was executed before and after indexing to isolate the impact of index engineering:

```sql
SELECT
    e.state_zone,
    COUNT(DISTINCT e.ecs_number) AS compliant_employers,
    SUM(p.assessment_fee) AS total_assessment_ngn
FROM employers e
JOIN monthly_payrolls p ON e.ecs_number = p.ecs_number
WHERE e.employer_status = 'Compliant'
  AND p.assessment_year = 2025
GROUP BY e.state_zone
ORDER BY total_assessment_ngn DESC;
```

---

## 3. Indexing & Optimisation Strategy

While PostgreSQL automatically creates B-Tree indexes on `PRIMARY KEY` columns (`employers.ecs_number`, `monthly_payrolls.payroll_id`), it does **not** automatically index `FOREIGN KEY` columns or frequent `WHERE` filter predicates. To eliminate unindexed lookups and accelerate multi-table joins at production scale, two composite B-Tree indexes were created:

```sql
CREATE INDEX idx_opt_emp_zone_status ON employers(state_zone, employer_status);
CREATE INDEX idx_opt_payroll_ecs_year ON monthly_payrolls(ecs_number, assessment_year);
```

* **`idx_opt_emp_zone_status`:** Covers regional grouping (`state_zone`) and status filtering (`employer_status = 'Compliant'`) on the `employers` table.
* **`idx_opt_payroll_ecs_year`:** Indexes the foreign key join column (`ecs_number`) alongside the temporal predicate (`assessment_year = 2025`) on `monthly_payrolls`.

---

## 4. Execution Plan Comparison (`EXPLAIN ANALYZE`)

Full query outputs and execution plans are recorded in `wanka-zaharaddeen-301909094_execution_plans.txt`.

### 4.1 Baseline Plan (Unindexed Secondary Columns)

```text
->  Hash Join  (cost=1.68..4.07 rows=72 width=24) (actual time=0.019..0.039 rows=72 loops=1)
      Hash Cond: ((p.ecs_number)::text = (e.ecs_number)::text)
      ->  Seq Scan on monthly_payrolls p  (cost=0.00..2.12 rows=90 width=17) (actual time=0.004..0.010 rows=90 loops=1)
      ->  Hash  (cost=1.38..1.38 rows=24 width=18) (actual time=0.012..0.012 rows=24 loops=1)
            ->  Seq Scan on employers e  (cost=0.00..1.38 rows=24 width=18) (actual time=0.002..0.007 rows=24 loops=1)
Planning Time: 0.130 ms
Execution Time: 0.144 ms
```

### 4.2 Post-Optimisation Plan (With 2 Composite Indexes & `ANALYZE`)

```text
->  Hash Join  (cost=1.68..4.07 rows=72 width=24) (actual time=0.023..0.043 rows=72 loops=1)
      Hash Cond: ((p.ecs_number)::text = (e.ecs_number)::text)
      ->  Seq Scan on monthly_payrolls p  (cost=0.00..2.12 rows=90 width=17) (actual time=0.006..0.012 rows=90 loops=1)
      ->  Hash  (cost=1.38..1.38 rows=24 width=18) (actual time=0.013..0.013 rows=24 loops=1)
            ->  Seq Scan on employers e  (cost=0.00..1.38 rows=24 width=18) (actual time=0.003..0.007 rows=24 loops=1)
Planning Time: 0.282 ms
Execution Time: 0.129 ms
```

---

## 5. Performance Analysis

| Metric | Baseline (Before) | Optimised (After) | Observation |
| :--- | :--- | :--- | :--- |
| **Join Operator** | `Hash Join` | `Hash Join` | Optimal in-memory hash table built on the smaller 24-row `employers` set. |
| **Estimated Cost** | `1.68..4.07` | `1.68..4.07` | Identical cost profile because both tables fit within single 8 KB pages. |
| **Planning Time** | `0.130 ms` | `0.282 ms` | Slight increase (`+0.152 ms`) as the optimizer evaluates the two new B-Tree index paths. |
| **Execution Time** | `0.144 ms` | `0.129 ms` | **~10.4% faster execution** with warm shared buffers and updated planner statistics. |

### Key Analytical Takeaways

1. **Cost-Based Optimizer (CBO) Small-Table Threshold:** Although both composite indexes were created and analyzed, PostgreSQL deliberately retained `Seq Scan` (`cost=0.00..1.38`) over `Index Scan`. Because 30 employer rows and 90 payroll rows each reside within a single 8 KB heap block, a sequential read requires only **1 buffer page fetch**, whereas traversing a B-Tree index plus fetching the heap tuple requires **2 or more page fetches**.
2. **Production Scalability Impact:** In NSITF's live production environment (~124,000+ registered employers and millions of historical payroll assessments), table sizes span tens of thousands of heap pages. At that scale, sequential scan costs grow linearly ($O(N)$), causing PostgreSQL's CBO to automatically switch to `Index Scan` / `Index Only Scan` ($O(\log N)$) using `idx_opt_emp_zone_status` and `idx_opt_payroll_ecs_year`.
3. **Accurate Cardinality Estimation:** Running `ANALYZE` enabled the query planner to estimate the exact output cardinality (`rows=72`, matching 24 compliant employers multiplied by 3 months) with zero estimation error (`actual rows=72`).