---
title: LanceDB Changelog | Release History & Updates
description: Track LanceDB's latest features, improvements, and bug fixes. Stay updated with our vector database's development progress and new capabilities.
hide:
  - navigation
---
# **LanceDB Changelog**

## May 2025

Revamped LanceDB Cloud onboarding, added Umap visualization and improved performance for `upsert` 

### Features
* **Reduced Commit Conflict Upsert**: Upsert operations to the same table are now designed to be conflict-free under typical concurrent workloads, enabling more reliable and higher-throughput parallel data ingestion and updates.
    *  Added timeout parameter for `merge_insert` for better control over long-running upserts [\[lancedb#2378\]](https://github.com/lancedb/lancedb/pull/2378)
* **Reduced IOPS to object store**:
    * Optimized I/O Patterns for small tables: Significant improvements reduce total IOPS to the object store by up to 95%, especially benefiting small-table workloads. [\[lance#3764\]](https://github.com/lancedb/lance/pull/3764)
    * Scan cache: Introduced a scan cache to further minimize object store IOPS and accelerate query performance. #enterprise 
* **Faster & More Reliable Indexing**: 
    * Indexing is now more robust and efficient, with dynamic job sizing based on table and row size, plus increased retry logic for reliability.
    * IVF_PQ indexing performance: Eliminated unnecessary data copying during index creation, resulting in faster PQ training and reduced memory usage. [\[lance#3894\]](https://github.com/lancedb/lance/pull/3894)
* **Configurable Scan Concurrency**: Query nodes now support configurable concurrency limits for scan requests to plan executors, allowing for better resource management in enterprise deployments. #enterprise
    * New `grpc.concurrency_limit_per_connection` setting in the plan executor for fine-grained control.
performance. #enterprise
* **Improved Enterprise Deployment**:
    * Automate deployment for AWS environments, making setup and scaling easier for enterprise users. 
    * GCP deployments now support configuration of weak consistency and concurrency limits for greater flexibility and cost control.
* **Filter on `large_binary` column**: Users can now filter on large binary columns in their queries. [\[lance#3797\]](https://github.com/lancedb/lance/pull/3797)
* **LanceDB Cloud UI**:
    * Revamped Cloud Onboarding: Streamlined LanceDB Cloud onboarding for a smoother user experience.
    * Added UMAP visualization to help users visually explore embeddings in their tables.


### Bug Fixes
* **Upsert Page Size Calculation**: Page size for upsert operations now correctly considers pod memory instead of node memory, reducing the risk of out-of-memory errors in the plan executor. #enterprise
* **Scalar Index**: 
    * Fixed incremental indexing for `LABEL_LIST` columns, ensuring scalar indices are updated correctly on data changes.
    * Addressed a bug in bitmap scalar index remapping, so partial remapping during compaction no longer drops rows unexpectedly.
* **Partition Count for Small Tables**: Improved partitioning logic ensures the correct number of partitions for small tables, leading to more efficient queries.
* **Accurate Error for Non-Existent Index**: Dropping a non-existent index now returns an IndexNotFound error (instead of a TableNotFound error). [\[lancedb#2380\]](https://github.com/lancedb/lancedb/pull/2380)
* **Index Consistency After Horizontal `merge_insert`**:Any index fragments associated with modified data are now properly removed during a horizontal merge_insert, preventing index corruption and ensuring indices always reflect the current state of the data. [\[lancedb#3863\]](https://github.com/lancedb/lancedb/pull/3863)
* **Fixed issues in create_index with empty tables**: 
    * Resolved an error that could occur when performing operations such as deleting the last row or creating an index on an empty table. The function now safely handles empty tables, preventing division-by-zero errors during these events.
    * Corrected a bug where events could be dropped if processed in the same batch as other events for empty tables. This was caused by Lance datasets evaluating to False when empty; the check now properly distinguishes between None and empty datasets, ensuring all events are processed as intended.

## April 2025

Enhanced Performance and Improved Version Control

### Features
* **Reduced Commit Conflicts**: Mitigated upsert-induced table conflicts through client/server-side retry mechanisms.
* **New SDK APIs**:
    * `table.tags.create/list/update/delete/checkout`: Enables semantic versioning through intuitive tagging instead of numeric versioning
    * `wait_for_index`: Ensures complete data indexing with configurable `wait_timeout`.
* **Performance Improvements**:
    * **Query Latency**: Eliminated full cache ring scans when nodes < replication factor.
    * **Full-Text Search**: Introduced configurable FTS index prewarming to accelerate search operations. `enterprise`
    * **Table Creation**: Leveraged cached database connections to reduce overhead—ideal for bulk table creation scenarios.
* **Session-Level Object Store Caching**: Shared connection pools via weak references to object stores. Example: 100 tables → 1 S3 connection pool.
* **IVF_PQ float64 support**: Expanded vector indexing to float64 datasets (previously limited to float16/32).
* **Full-text search on string arrays**: Extended full-text search to support string array columns for efficient multi-value keyword search.
* **UI - Enhanced Table Preview**:
    * One-click vector copying from cells
    * Full row expansion on click (no truncation)
    * Consistent right-panel binary data display
* **UI - Direct Page Navigation**: Added page selector for instant access to specific data pages in table preview.

### Bug Fixes
* **Query Performance**:
    * Fixed hybrid search distance range filtering to properly respect lower and upper bounds. [\[lancedb#2356\]](https://github.com/lancedb/lancedb/pull/2356)
    * Enforced valid `k` parameters to prevent overflow. [\[lancedb#2354\]](https://github.com/lancedb/lancedb/pull/2354)
    * `BETWEEN clause`: Improved BETWEEN query handling to return 0 results when `start` > `end` instead of panicking. [\[lance#3706\]](https://github.com/lancedb/lance/pull/3706)
* **SDK/API Fixes**:
    * Fixed TypeScript SDK support for FTS advanced features (fuzzy search and boosting). [\[lancedb#2314\]](https://github.com/lancedb/lancedb/pull/2314)
    * Added scalar index support for small FixedSizeBinary columns (e.g., UUID). [\[lancedb#2297\]](https://github.com/lancedb/lancedb/pull/2297)
* **Index**:
    * Fixed IVF_PQ index on vector columns with NaN/INFs. [\[lance#3648\]](https://github.com/lancedb/lance/pull/3648)
    * Resolved GPU-based indexing crashes on non-contiguous arrays. [\[lance#3675\]](https://github.com/lancedb/lance/pull/3675) `enterprise`
    * Fixed B-tree index corruption during null remapping. [\[lance#3704\]](https://github.com/lancedb/lance/pull/3704)
* **Cloud Dashboard**: Optimized chart rendering for better visibility in the Cloud usage dashboard.

## March 2025

Enhanced Full-Text Search and Advanced Query Debugging Features

### Features
* **Enhanced Full-Text Search (FTS): Fuzzy Search & Boosting Now Available**: it improves user experience with resilient, typo-tolerant searches and can surface the most contextually relevant results faster.
* **New SDK APIs**: 
    * `explain_plan`: Diagnose query performance and debug unexpected results by inspecting the execution plan.
    * `analyze_plan`: Analyze query execution metrics to optimize performance and resource usage. Such metrics include execution time, number of rows processed, I/O stats, and more.
    * `restore`: Revert to a specific prior version of your dataset and modify it from a verified, stable state.
* **Scalar Indexing for Extended Data Types**: LanceDB now supports scalar indexing on UUID columns of FixedSizeBinary type.
* **Binary vector support in TypeScript SDK**: LanceDB's TypeScript SDK now natively supports binary vector indexing and querying with production-grade efficiency.
* **Support S3-compatible object store**: Extended LanceDB Enterprise deployment to work with S3-compatible object stores, such as Tigris, Minio and etc. `enterprise`

### Bug Fixes
* **Improved Merge insert performance**: Enhanced the merge-insert operation to reduce error rates during upsert operations, improving data reliability.[\[lance#3603\]](https://github.com/lancedb/lance/pull/3603).
* **Batch Ingestion Error**: Updated error codes for batch ingestion failures from 500 to 409 to accurately reflect resource conflict scenarios.
* **Cloud Signup Workflow Fix**: Resolved an issue where users encountered a blank page after organization creation during the Cloud signup process.
* **Table Preview Data Display Issue**: Fixed a bug causing the table preview page to show a generic "Something went wrong" error for datasets containing `datetime` columns, which previously prevented data inspection.
* **Rate Limit Error Clarity**: Added explicit error messaging for system rate limits (e.g., API keys per table), replacing vague notifications that confused users.

## February 2025

Multivector Search ready and Table data preview available in Cloud UI

### Features
* **Multivector Search is now live**: documents can be stored as contextualized vector lists. Fast multi-vector queries are supported at scale, powered by our XTR optimization.
* **`Drop_index` added to SDK**: users can remove unused or outdated indexes from your tables.
* **Explore Your Data at a Glance**: preview sample data from any table with a single click. `lancedb-cloud`
* **Search by Project/Table in Cloud UI**: allow users to quickly locate the desired project/table. `lancedb-cloud`

### Bug Fixes
* **FTS stability fix**: Resolved a crash in Full Text Search (FTS) during flat-mode searches.
* **`prefilter` parameter enforcement**: Fixed a bug where the prefilter parameter was not honored in FTS queries.
* **Vector index bounds error**: Addressed an out-of-bounds indexing issue during vector index creation.
* **`distance_range()` compatibility**: Fixed errors when performing vector searches with `distance_range()` on unindexed rows.
* **Error messaging improvements**: Replaced generic HTTP 500 errors with detailed, actionable error messages for easier debugging.

## January 2025

Support Hamming Distance and GPU based indexing ready

### Features
* **Support Hamming distance and binary vector**: Added `hamming` as a distance metric (joining `l2`, `cosine`, `dot`) for binary vector similarity search.
* **GPU-Accelerated IVF-PQ indexing**: Build IVF-PQ indexes 10x faster. `enterprise`
* **AWS Graviton 4 & Google Axion build optimizations**: ARM64 SIMD acceleration cuts query costs. `enterprise`
* **float16 Vector Index Supports**: reduce storage size while maintaining search quality.
* **Self-Serve Cloud Onboarding**: new workflow-based UI guides users for smooth experience. `lancedb-cloud`

### Bug Fixes
* `list_indices` and `index_stats` now always fetch the latest version of the table by default unless a specific version is explicitly provided.
* **Error message fix**: Improved clarity for cases where `create_index` is called to create a vector index on tables with fewer than 256 rows.
* **TypeScript SDK fixes**: Resolved an issue where `createTable()` failed to correctly save embeddings and for `mergeInsert` not utilizing saved embeddings. [lancedb#2065](https://github.com/lancedb/lancedb/pull/2065)
* **Multi-vector schema inference**: Addressed an issue where the vector column could not be inferred for multi-vector indexes. [lancedb#2026](https://github.com/lancedb/lancedb/pull/2026)
* **Hybrid search consistency**: Fixed a discrepancy where hybrid search returned distance values inconsistent with standalone vector search. [lancedb#2061](https://github.com/lancedb/lancedb/pull/2061)

## December 2024

Performant SQL queries at scale and more cost-effective vector search

### Features
* **Run SQL with massive datasets**: added Apache Arrow flight-SQL protocol to run SQL queries with billions of data and return in seconds. `enterprise`.
* **Accelerate vector search**: added our Quantinized-IVF algorithm and other optimization techniques to improve QPS/core. `enterprise`
* **Azure Stack Router Deployment**: route traffic efficiently to serve low query latency. `enterprise`
* **Distance range filtering**: filter query results using `distance_range()` to return search results with a lowerbound, upperbound or a range [\[lance#3326\]](https://github.com/lancedb/lance/pull/3326).
* **Full-Text Search(FTS) indexing options**: configure tokenizers, stopword lists and more at FTS index creation.

### Bug Fixes
* **Full-text search parameters**: Fixed an issue where full-text search index configurations were not applied correctly. [lancedb#1928](https://github.com/lancedb/lancedb/pull/1928)
* **Float16 vector queries**: Addressed a bug preventing the use of lists of Float16 values in vector queries. [lancedb#1931](https://github.com/lancedb/lancedb/pull/1931)
* **Versioned `checkout` API**: Resolved inconsistencies in the `checkout` method when specifying the `version` parameter. [lancedb#1988](https://github.com/lancedb/lancedb/pull/1988)
* **Table recreation error**: Fixed an issue where dropping and recreating a table with the same name resulted in a table creation error.