# Portfolio 5: Distributed and Cloud Database Exercise (Horizontal Sharding)
**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** Nigeria Social Insurance Trust Fund (NSITF)  
**Student Name:** Zaharaddeen Wanka  
**Student ID:** 301909094  

---

## 1. Distributed Cloud Architecture & Sharding Strategy

As NSITF scales nationwide across Nigeria's geopolitical zones (~124,000+ employers), storing all employer records on a single monolithic server creates storage bottlenecks and high network latency for regional branch offices. 

To address this in a cloud database environment (such as AWS RDS / Aurora or Azure Database for PostgreSQL), **Horizontal Sharding (List Partitioning)** was selected as the core distribution strategy:
* **Shard Key (`state_zone`):** Employers are partitioned geographically by their registered NSITF zonal office (`Kano`, `Lagos`, `Abuja HQ`).
* **Data Locality:** Regional compliance officers in Kano, Lagos, and Abuja primarily query and audit employers within their own jurisdiction. Keeping each zone's records in a dedicated shard reduces local query latency and isolates regional workloads.

---

## 2. Implementation & Verification Evidence

The sharded schema, sample data routing, and execution plan verification are stored in `wanka-zaharaddeen-301909094_distributed.sql` and captured in `wanka-zaharaddeen-301909094_distributed_logs.txt`.

### 2.1 Declarative List Sharding Setup
A partitioned parent table (`nsitf_sharded_employers`) routes incoming `INSERT` statements automatically into three isolated regional shards:

```sql
CREATE TABLE nsitf_sharded_employers (
    ecs_number      VARCHAR(10) NOT NULL,
    company_name    VARCHAR(150) NOT NULL,
    state_zone      VARCHAR(30) NOT NULL,
    employer_status VARCHAR(20) NOT NULL,
    PRIMARY KEY (ecs_number, state_zone)
) PARTITION BY LIST (state_zone);

CREATE TABLE shard_kano_employers  PARTITION OF nsitf_sharded_employers FOR VALUES IN ('Kano');
CREATE TABLE shard_lagos_employers PARTITION OF nsitf_sharded_employers FOR VALUES IN ('Lagos');
CREATE TABLE shard_abuja_employers PARTITION OF nsitf_sharded_employers FOR VALUES IN ('Abuja HQ');
```

### 2.2 Shard Routing & Partition Pruning Proof
1. **Automatic Routing (`tableoid::regclass`):** Querying the system `tableoid` column confirmed that inserting 6 employers automatically placed the 2 Kano companies into `shard_kano_employers`, the 2 Lagos companies into `shard_lagos_employers`, and the 2 Abuja companies into `shard_abuja_employers`.
2. **Partition Pruning (`EXPLAIN`):** Running `EXPLAIN SELECT ... FROM nsitf_sharded_employers WHERE state_zone = 'Kano'` verified that PostgreSQL's query planner scanned **only `shard_kano_employers`** and completely pruned (skipped) the Lagos and Abuja shards, avoiding unnecessary disk and network I/O.

---

## 3. Architectural Benefits & Trade-offs

* **Key Advantage (Scalability & Query Isolation):** Regional queries only touch a fraction of the total national dataset, and individual shards can be hosted on cloud nodes geographically closer to regional offices.
* **Key Trade-off (Cross-Shard Queries):** Queries that omit the `state_zone` shard key (such as nationwide revenue aggregations across all states) must fan out across every shard (`Append` node) and merge results, increasing network coordination overhead compared to single-shard lookups.