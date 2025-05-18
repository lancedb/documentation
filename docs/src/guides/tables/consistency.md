---
title: Consistency in LanceDB
description: Learn about consistency settings and versioning in LanceDB tables.
---

# Consistency in LanceDB

In LanceDB OSS, users can set the `read_consistency_interval` parameter on connections to achieve different levels of read consistency. This parameter determines how frequently the database synchronizes with the underlying storage system to check for updates made by other processes. If another process updates a table, the database will not see the changes until the next synchronization.

There are three possible settings for `read_consistency_interval`:

1. **Unset (default)**: The database does not check for updates to tables made by other processes. This provides the best query performance, but means that clients may not see the most up-to-date data. This setting is suitable for applications where the data does not change during the lifetime of the table reference.
2. **Zero seconds (Strong consistency)**: The database checks for updates on every read. This provides the strongest consistency guarantees, ensuring that all clients see the latest committed data. However, it has the most overhead. This setting is suitable when consistency matters more than having high QPS.
3. **Custom interval (Eventual consistency)**: The database checks for updates at a custom interval, such as every 5 seconds. This provides eventual consistency, allowing for some lag between write and read operations. Performance wise, this is a middle ground between strong consistency and no consistency check. This setting is suitable for applications where immediate consistency is not critical, but clients should see updated data eventually.

!!! tip "Consistency in LanceDB Cloud"

    This is only tune-able in LanceDB OSS. In LanceDB Cloud, readers are always eventually consistent.

=== "Python"

    To set strong consistency, use `timedelta(0)`:

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-datetime"
        --8<-- "python/python/tests/docs/test_guide_tables.py:table_strong_consistency"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-datetime"
        --8<-- "python/python/tests/docs/test_guide_tables.py:table_async_strong_consistency"
        ```

    For eventual consistency, use a custom `timedelta`:

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-datetime"
        --8<-- "python/python/tests/docs/test_guide_tables.py:table_eventual_consistency"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-datetime"
        --8<-- "python/python/tests/docs/test_guide_tables.py:table_async_eventual_consistency"
        ```

    By default, a `Table` will never check for updates from other writers. To manually check for updates you can use `checkout_latest`:

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:table_checkout_latest"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:table_async_checkout_latest"
        ```

=== "Typescript[^1]"

    To set strong consistency, use `0`:

    ```ts
    const db = await lancedb.connect({ uri: "./.lancedb", readConsistencyInterval: 0 });
    const tbl = await db.openTable("my_table");
    ```

    For eventual consistency, specify the update interval as seconds:

    ```ts
    const db = await lancedb.connect({ uri: "./.lancedb", readConsistencyInterval: 5 });
    const tbl = await db.openTable("my_table");
    ```

## What's next?

Learn about [vector indexing](../ann_indexes.md) to optimize your vector search performance.

[^1]: The `vectordb` package is a legacy package that is deprecated in favor of `@lancedb/lancedb`. The `vectordb` package will continue to receive bug fixes and security updates until September 2024. We recommend all new projects use `@lancedb/lancedb`. See the [migration guide](../../migration.md) for more information. 