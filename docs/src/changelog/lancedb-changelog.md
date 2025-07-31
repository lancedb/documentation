---
title: LanceDB Changelog | Release History & Updates
description: Track LanceDB's latest features, improvements, and bug fixes. Stay updated with our vector database's development progress and new capabilities.
hide:
  - navigation
---
# **LanceDB Changelog**

## July 2025

Performance improvements across vector search and indexing and enhanced Cloud UI.

### Features

#### Performance Optimizations
* **HNSW-Accelerated Partition Computation:** Partition computation is now accelerated with HNSW (Hierarchical Navigable Small World), cutting end-to-end indexing time by up to 50%. The optimization maintains high recall while significantly reducing CPU and memory usage during index creation. [lance#4089](https://github.com/lancedb/lance/pull/4089)

* **Up to 500× Faster Range Queries:** Range queries like "value >= 1000 and value < 2000" on 1M int32 values now execute in 100µs instead of 50ms, dramatically boosting hybrid search performance. [lance#4248](https://github.com/lancedb/lance/pull/4248)

* **Faster L2 Distance Computation:** >10% speedup in vector search by optimizing common-dimension batch L2 operations. [lance#4321](https://github.com/lancedb/lance/pull/4321)

* **B-tree Index Prewarm:** Frequently accessed index pages are now proactively cached in memory, improving query latency. [lance#4235](https://github.com/lancedb/lance/pull/4235)

* **Faster Merge Insert Updates:** Improved update-only operations with optimized join strategy—speeding up data merges with conditional logic. [lance#4253](https://github.com/lancedb/lance/pull/4253)

#### Infrastructure and Deployment Enhancements
* **Improved Cloud Load Balancing:** Better tenant isolation and fault tolerance across query nodes.

* **Streaming Ingestion with Automatic Index Optimization:** Automatic index updates during streaming ingestion for consistent performance. No block on other operations on the table, such as compaction.

* **Storage Handle Reuse:** Reduced overhead for bulk table creation by fixing excessive object store handle creation. [lancedb#2505](https://github.com/lancedb/lancedb/pull/2505)

* **GCP Autoscaling Support:** Enabled autoscaling in GCP deployments to automatically adjust resources based on demand, ensuring optimal performance and cost efficiency for customer's workloads. #enterprise

#### SDK and API 
* **Session-Based Cache Control:**  Python and TypeScript users can now customize caching behavior per session—ideal for large datasets and enterprise deployments. [lancedb#2530](https://github.com/lancedb/lancedb/pull/2530). Specifically:

* **Automatic Conflict Resolution for Updates:** Update operations now support retries with exponential backoff to handle concurrent writes. [lance#4167](https://github.com/lancedb/lance/pull/4167)

* **Multi-Vector Support (JavaScript):** Added multivector support to the JavaScript/TypeScript SDK. [lancedb#2527](https://github.com/lancedb/lancedb/pull/2527)

* **Ngram Tokenizer for FTS:** Flexible tokenization for full-text search, supporting languages and use cases with partial or fuzzy matches. [lancedb#2507](https://github.com/lancedb/lancedb/pull/2507)

#### Cloud UI and User Experience
* **LanceDB Cloud UI Improvements:**  
    * **Enhanced Table Data Preview:** Added column filtering capabilities to the table data preview, enabling users to filter data with SQL and select only the columns they want to view.
    * **Multi-Organization Support:** Seamlessly switch between orgs at login for easier team collaboration and access control.

#### Documentation & Guides
* **[Multimodal Lakehouse Documentation](https://lancedb.github.io/geneva/):** New examples and guides for Geneva-powered feature engineering and multimodal workflows.

---

### Bug Fixes

#### Full-Text Search (FTS) Fixes
* **Index Creation Stability:** Fixed errors when entire FTS posting lists were deleted.[lance#4156](https://github.com/lancedb/lance/pull/4156)

* **Token Set Remapping:** Ensures proper index consistency when updating FTS data.[lance#4180](https://github.com/lancedb/lance/pull/4180)

* **Phrase Query Precision Fix:** Addressed floating point precision issues to avoid missed results; also fixed decompression edge cases. [lance#4223](https://github.com/lancedb/lance/pull/4223)

* **Phrase Query Error Message Fix:** Returns more informative error when phrase queries lack position support. [lance#4342](https://github.com/lancedb/lance/pull/4342) 

#### Index and Query 
* **B-tree Redundant Page Loads:** Eliminated duplicate page loads for better scalar index performance. [lance#4246](https://github.com/lancedb/lance/pull/4246)

* **Filtered Read Pagination Fix:** Respects `offset`/`limit` for pagination even when rows are deleted. [lance#4351](https://github.com/lancedb/lance/pull/4351)

#### SDK and API
* **Schema Alignment with Missing Columns:** Fixed a Node.js bug where schema alignment would fail when using embedding functions with Arrow table inputs that had missing columns. [lancedb#2516](https://github.com/lancedb/lancedb/pull/2516)

* **Python nprobes Fix:** Resolves validation errors when setting both min and max nprobes. [lancedb#2556](https://github.com/lancedb/lancedb/pull/2556)

* **Empty List Table Creation Fix:** Fixed crashes when creating tables from empty lists with predefined schemas.

 [lancedb#2548](https://github.com/lancedb/lancedb/pull/2548)

#### Data Consistency
* **Dataset Version Race Condition:** Prevents version rollbacks during concurrent queries. [lancedb#2479](https://github.com/lancedb/lancedb/pull/2479)

* **Case-Insensitive Filter Comparison Fix:** Ensures accurate matching for string filters regardless of text case.[lance#4278](https://github.com/lancedb/lance/pull/4278)

## June 2025

More advanced features added to Full-text Search and optimized BYOC deployment.

### Features

* **Full-Text Search (FTS) Enhancements:**  
  Expanded FTS capabilities with:
    * [Boolean logic for FTS](../guides/search/full-text-search.html#boolean-queries): Combine filters using `SHOULD`, `MUST`, and `MUST_NOT` for expressive, intuitive search. (Python users can also use `AND`/`OR` or `&`/`|`.)
    * [Flexible phrase matching](../guides/search/full-text-search.html#flexible-phrase-match): Phrase queries now support the `slop` parameter, allowing matches where terms are close together but not necessarily adjacent or in exact order, enabling typo-tolerant and flexible phrase search.
    * [Autocomplete-ready prefix search](../guides/search/full-text-search.html#prefix-based-match): Search for documents containing words that start with a specific prefix, enabling partial word and autocomplete-style queries (e.g., searching for "mach" matches "machine", "machinery", etc.).
    * Faster, smarter full-text indexing: Compression and optimized algorithms speed up index builds and boost search performance at scale.

* **Native Helm Chart Support:**  
  Added native Helm chart deployment for Kubernetes, streamlining BYOC (Bring Your Own Cloud) deployments and improving infrastructure management. #enterprise

* **KNN Scan Pushdown Optimization:**  
  Improved vector search performance and reduced memory usage by supporting KNN scan pushdown. #enterprise

* **Query Resource Limits:**  
  Introduced concurrent request limits and scan row constraints to prevent resource exhaustion and maintain system stability under high load. #enterprise

* **Improved Vector Search with Selective Filters:**  
  Split `nprobes` into `minimum_nprobes` and `maximum_nprobes` for more efficient vector search. The system starts with `minimum_nprobes` and increases up to `maximum_nprobes` if not enough results are found. [lancedb#2430](https://github.com/lancedb/lancedb/pull/2430)

* **Cloud Guardrails:**  
  Enforced API payload limits (100MB) to prevent heavy workloads from degrading cloud service quality, with extra checks on `merge_insert` to avoid introducing large workloads.

---

### Bug Fixes

* **Embedding Function Error with Existing Vector Column:**  
  Fixed a TypeScript SDK error when adding data that already includes the vector column and a registered embedding function is present. [lancedb#2433](https://github.com/lancedb/lancedb/pull/2433)

* **`create_table` Errors with Existing Tables:**  
  Fixed errors when using `create_table` with `mode=overwrite` or `exists_ok=true` on an existing table.

* **Indexing Skipped with Certain Compaction Configurations:**  
  Fixed an issue where indexing criteria were not included in `lance_agent`, causing the index to not be created as expected under certain compaction settings.

* **Failed Login After Changing Account:**  
  Fixed a login failure that occurred when a user signed up for LanceDB Cloud, dropped out, and then rejoined an organization with the same email via an invite.

* **Column Disordering in KNN Scanning:**  
  Fixed an error in plans that union indexed and unindexed data, where the KNNScan node returned data in a different order than its output schema. #enterprise

* **Divide-by-Zero on Empty Table:**  
  Fixed an issue where creating an index failed on an empty table, either after deleting the last row or when creating an index on an already empty table.


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
    * Fixed incremental indexing for `