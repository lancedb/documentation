---
title: "Reindexing and Incremental Indexing in LanceDB"
description: "Learn how to efficiently update and manage indexes in LanceDB using incremental indexing. Includes best practices for adding new records without full reindexing."
keywords: "LanceDB incremental indexing, index updates, database optimization, vector search indexing, index management"
---

# Reindexing and Incremental Indexing

## Incremental Indexing in LanceDB Cloud

**LanceDB Cloud & Enterprise** support incremental reindexing through an automated background process. When new data is added to a table, the system automatically triggers a new index build. As the dataset grows, indexes are continuously updated in the background.

> While indexes are being rebuilt, queries use brute force methods on unindexed rows, which may temporarily increase latency. To avoid this, set `fast_search=True` to search only indexed data.

!!! note "Checking Index Status"
    Use `index_stats()` to view the number of unindexed rows. This will be zero when indexes are fully up-to-date.

## Incremental Indexing in LanceDB OSS

LanceDB OSS supports incremental indexing, which means you can add new records to the table without reindexing the entire table.

This can make the query more efficient, especially when the table is large and the new records are relatively small.

=== "Python"
    === "Sync API"
        ```python
        --8<-- "python/python/tests/docs/test_search.py:fts_incremental_index"
        ```
    === "Async API"
        ```python
        --8<-- "python/python/tests/docs/test_search.py:fts_incremental_index_async"
        ```

=== "TypeScript"
    ```typescript
    await tbl.add([{ vector: [3.1, 4.1], text: "Frodo was a happy puppy" }]);
    await tbl.optimize();
    ```

=== "Rust"
    ```rust
    let more_data: Box<dyn RecordBatchReader + Send> = create_some_records()?;
    tbl.add(more_data).execute().await?;
    tbl.optimize(OptimizeAction::All).execute().await?;
    ```

!!! note "Performance Considerations"
    New data added after creating the FTS index will appear in search results while the incremental index is still in progress, but with increased latency due to a flat search on the unindexed portion. LanceDB Cloud & Enterprise automate this merging process, minimizing the impact on search speed.

## FTS Index Reindexing

FTS Reindexing is **supported in LanceDB OSS, Cloud & Enterprise**. However, it requires manual rebuilding when a significant amount of new data needs to be reindexed.

We [updated](https://github.com/lancedb/lancedb/pull/762) Tantivy's default heap size from 128MB to 1GB in LanceDB, making reindexing up to 10x faster than with default settings.



