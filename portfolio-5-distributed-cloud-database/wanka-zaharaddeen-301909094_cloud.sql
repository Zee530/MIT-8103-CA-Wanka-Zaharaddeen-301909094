-- Portfolio 5:  Distributed and Cloud Database
-- Case Study: Nigeria Social Insurance Trust Fund
-- Student Name: Wanka Zaharaddeen Babayo
-- Student ID: 301909094

-- We will simulate a cloud/Distributed database with Horizontal Sharding capabilities
DROP TABLE IF EXISTS nsitf_sharded_employers CASCADE;

-- Create a table with Horizontal Sharding by State Zone, PARTITION BY command will assist us to Shard
CREATE TABLE nsitf_sharded_employers (
    ecs_number VARCHAR(10) NOT NULL,
    company_name VARCHAR(150) NOT NULL,
    state_zone VARCHAR(30) NOT NULL,
    employer_status VARCHAR(20) NOT NULL,
    PRIMARY KEY (ecs_number, state_zone)
) PARTITION BY LIST (state_zone);

-- Create 3 Regional Shards
CREATE TABLE shard_kano_employers  PARTITION OF nsitf_sharded_employers FOR VALUES IN ('Kano');
CREATE TABLE shard_lagos_employers PARTITION OF nsitf_sharded_employers FOR VALUES IN ('Lagos');
CREATE TABLE shard_abuja_employers PARTITION OF nsitf_sharded_employers FOR VALUES IN ('FCT');

-- Insert Employers Across Regional Shards
INSERT INTO nsitf_sharded_employers (ecs_number, company_name, state_zone, employer_status) VALUES
('1000000001', 'Kano Textile Mills Ltd',       'Kano',     'Compliant'),
('1000000002', 'Dala Foods Nigeria Ltd',       'Kano',     'Defaulting'),
('1000000003', 'Ikeja Industrial Bottlers',    'Lagos',    'Compliant'),
('1000000004', 'Apapa Maritime Services Ltd',  'Lagos',    'Compliant'),
('1000000005', 'Abuja Infrastructure Corp',    'FCT', 'Compliant'),
('1000000006', 'Garki Medical Diagnostics',    'FCT', 'Recalcitrant');

-- Verify Partition Pruning, return only Kano state zone Employers
EXPLAIN
SELECT ecs_number, company_name, employer_status
FROM nsitf_sharded_employers
WHERE state_zone = 'Kano';