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

## Configuring Consistency Parameters

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

## Handling bad vectors

In LanceDB Python, you can use the `on_bad_vectors` parameter to choose how
invalid vector values are handled. Invalid vectors are vectors that are not valid
because:

1. They are the wrong dimension
2. They contain NaN values
3. They are null but are on a non-nullable field

By default, LanceDB will raise an error if it encounters a bad vector. You can
also choose one of the following options:

* `drop`: Ignore rows with bad vectors
* `fill`: Replace bad values (NaNs) or missing values (too few dimensions) with
    the fill value specified in the `fill_value` parameter. An input like
    `[1.0, NaN, 3.0]` will be replaced with `[1.0, 0.0, 3.0]` if `fill_value=0.0`.
* `null`: Replace bad vectors with null (only works if the column is nullable).
    A bad vector `[1.0, NaN, 3.0]` will be replaced with `null` if the column is
    nullable. If the vector column is non-nullable, then bad vectors will cause an
    error
