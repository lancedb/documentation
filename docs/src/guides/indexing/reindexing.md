---
title: "Updating Indexes in LanceDB | Index Updates Guide"
description: "Learn how to efficiently update and manage indexes in LanceDB using incremental indexing. Includes best practices for adding new records without full reindexing."
keywords: "LanceDB incremental indexing, index updates, database optimization, vector search indexing, index management"
---

# Updating Indexes with New Data in LanceDB Cloud

When new data is added to a table, LanceDB Cloud automatically updates indices in the background.

To check index status, use `index_stats()` to view the number of unindexed rows. This will be zero when indices are fully up-to-date.

While indices are being updated, queries use brute force methods for unindexed rows, which may temporarily increase latency. To avoid this, set `fast_search=True` to search only indexed data.

OSS______________

## Incremental Indexing in LanceDB OSS

LanceDB supports incremental indexing, which means you can add new records to the table without reindexing the entire table.

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
!!! note

    New data added after creating the FTS index will appear in search results while incremental index is still progress, but with increased latency due to a flat search on the unindexed portion. LanceDB Cloud automates this merging process, minimizing the impact on search speed. 