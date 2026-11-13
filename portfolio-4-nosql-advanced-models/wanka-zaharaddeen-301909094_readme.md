# Portfolio 4: NoSQL & Advanced Data Models
**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** Nigeria Social Insurance Trust Fund (NSITF)  
**Student Name:** Zaharaddeen Wanka  
**Student ID:** 301909094  

---

## 1. Document Data Model Design (NSITF Case Study)

In Portfolio 1, NSITF data was normalized across four relational tables (`employers`, `monthly_payrolls`, `contribution_payments`, and `compliance_certificates`). For Portfolio 4, the same domain is modeled using a **Document-Oriented NoSQL architecture** (implemented in PostgreSQL using native `JSONB` and a `GIN` inverted index, equivalent to MongoDB BSON collections).

Instead of splitting a single company's compliance profile across multiple tables, each employer is stored as one self-contained JSON document keyed by `ecs_number`, embedding their monthly payroll history as a nested array and their active certificate as a nested sub-document:

```json
{
  "ecs_number": "1000000001",
  "company_name": "Kano Agro Processing Ltd",
  "business_sector": "Manufacturing",
  "state_zone": "Kano",
  "employer_status": "Compliant",
  "payrolls": [
    {
      "period": "2025-01",
      "employee_count": 25,
      "assessment_fee": 25000.00,
      "payment_status": "Successful"
    }
  ],
  "certificate": {
    "certificate_id": "CERT-2026-0001",
    "status": "Issued",
    "expiration_date": "2026-12-31"
  }
}
```

---

## 2. Implementation Evidence

All SQL definitions, sample JSON documents, and extraction queries are stored in `wanka-zaharaddeen-301909094_nosql.sql`, with verified terminal output logged in `wanka-zaharaddeen-301909094_nosql_logs.txt`.

* **Schema-Flexible Storage (`JSONB`):** Three employer documents were inserted. Record `'1000000002'` (*Niger Delta Energy Services Ltd*) includes a sector-specific `"dpr_permit_no"` attribute without requiring an `ALTER TABLE` schema migration or leaving `NULL` columns on non-oil employers.
* **Inverted Indexing (`GIN`):** A Generalized Inverted Index (`idx_nsitf_doc_gin`) was created on `profile_doc` to index all nested keys and values inside the JSON documents.
* **Single-Read Retrieval (Zero `JOIN`s):** Using PostgreSQL JSON path operators (`->` and `->>`) and the containment operator (`@>`), queries retrieved nested payroll counts, certificate IDs, and compliant employer lists in a single table lookup without multi-table joins.

---

## 3. Explanation of Suitability for NSITF

### Why the Document Model Fits NSITF Portal & Inspection Workloads
1. **Eliminates Expensive Multi-Table `JOIN`s:** When an employer logs into the NSITF self-service portal—or when a field inspector scans a certificate QR code—the application needs the company profile, recent payroll settlements, and certificate validity at once. Reading one pre-assembled JSON document is faster and simpler than joining four relational tables.
2. **Schema Flexibility Across Industries:** NSITF regulates diverse sectors (Oil & Gas, Construction, Healthcare, Manufacturing) that require different regulatory permits and inspection fields. A document store accommodates sector-specific attributes naturally without sparse `NULL`-heavy tables.
3. **Horizontal Read Scalability:** Because each employer document is self-contained, documents can be easily sharded across servers by `ecs_number` or `state_zone` as employer registrations grow.

### Limitations & Why Relational Remains Primary for Core Accounting
* **Data Redundancy & Cross-Employer Aggregations:** Embedding payroll arrays inside individual employer documents works well for single-company lookups, but calculating nationwide monthly revenue totals across 124,000+ employers requires scanning nested arrays inside every document—a task where Portfolio 1's normalized relational tables and B-Tree indexes perform significantly better.
* **Architectural Conclusion:** NSITF is best served by a **hybrid multi-model approach**—using normalized relational tables as the ACID source of truth for financial settlements, paired with a Document store (`JSONB` / MongoDB) for fast employer portal reads and flexible inspection records.