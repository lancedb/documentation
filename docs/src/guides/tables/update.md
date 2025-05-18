---
title: Modifying Tables in LanceDB
description: Learn how to add, update, and delete data in LanceDB tables.
---

# Modifying Tables in LanceDB

## Adding to a table

After a table has been created, you can always add more data to it using the `add` method

=== "Python"
    You can add any of the valid data structures accepted by LanceDB table, i.e, `dict`, `list[dict]`, `pd.DataFrame`, or `Iterator[pa.RecordBatch]`. Below are some examples.

    ### Add a Pandas DataFrame

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_from_pandas"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_async_from_pandas"
        ```

    ### Add a Polars DataFrame

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_from_polars"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_async_from_polars"
        ```

    ### Add an Iterator

    You can also add a large dataset batch in one go using Iterator of any supported data types.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:make_batches_for_add"
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_from_batch"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:make_batches_for_add"
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_async_from_batch"
        ```

    ### Add a PyArrow table

    If you have data coming in as a PyArrow table, you can add it directly to the LanceDB table.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_from_pyarrow"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_async_from_pyarrow"
        ```

    ### Add a Pydantic Model

    Assuming that a table has been created with the correct schema as shown in [Creating Tables](creating_tables.md#from-pydantic-models), you can add data items that are valid Pydantic models to the table.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_from_pydantic"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:add_table_async_from_pydantic"
        ```

    ??? "Ingesting Pydantic models with LanceDB embedding API"
        When using LanceDB's embedding API, you can add Pydantic models directly to the table. LanceDB will automatically convert the `vector` field to a vector before adding it to the table. You need to specify the default value of `vector` field as None to allow LanceDB to automatically vectorize the data.

        === "Sync API"

            ```python
            --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
            --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb-pydantic"
            --8<-- "python/python/tests/docs/test_guide_tables.py:import-embeddings"
            --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_with_embedding"
            ```
        === "Async API"

            ```python
            --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
            --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb-pydantic"
            --8<-- "python/python/tests/docs/test_guide_tables.py:import-embeddings"
            --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_with_embedding"
            ```

=== "Typescript[^1]"

    ```javascript
    await tbl.add(
        [
            {vector: [1.3, 1.4], item: "fizz", price: 100.0},
            {vector: [9.5, 56.2], item: "buzz", price: 200.0}
        ]
    )
    ```

## Upserting into a table

Upserting lets you insert new rows or update existing rows in a table. To upsert
in LanceDB, use the merge insert API.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_merge_insert.py:upsert_basic"
        ```
        **API Reference**: [lancedb.table.Table.merge_insert][]

    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_merge_insert.py:upsert_basic_async"
        ```
        **API Reference**: [lancedb.table.AsyncTable.merge_insert][]

=== "Typescript[^1]"

    === "@lancedb/lancedb"

        ```typescript
        --8<-- "nodejs/examples/merge_insert.test.ts:upsert_basic"
        ```
        **API Reference**: [lancedb.Table.mergeInsert](../../js/classes/Table.md/#mergeInsert)

Read more in the guide on [merge insert](merge_insert.md).

## Deleting from a table

Use the `delete()` method on tables to delete rows from a table. To choose which rows to delete, provide a filter that matches on the metadata columns. This can delete any number of rows that match the filter.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:delete_row"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:delete_row_async"
        ```

    ### Deleting row with specific column value

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:delete_specific_row"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:delete_specific_row_async"
        ```

    ### Delete from a list of values
    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:delete_list_values"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:delete_list_values_async"
        ```

=== "Typescript[^1]"

    ```ts
    await tbl.delete('item = "fizz"')
    ```

    ### Deleting row with specific column value

    ```ts
    const con = await lancedb.connect("./.lancedb")
    const data = [
      {id: 1, vector: [1, 2]},
      {id: 2, vector: [3, 4]},
      {id: 3, vector: [5, 6]},
    ];
    const tbl = await con.createTable("my_table", data)
    await tbl.delete("id = 2")
    await tbl.countRows() // Returns 2
    ```

    ### Delete from a list of values

    ```ts
    const to_remove = [1, 5];
    await tbl.delete(`id IN (${to_remove.join(",")})`)
    await tbl.countRows() // Returns 1
    ```

## Drop a table

Use the `drop_table()` method on the database to remove a table.

=== "Python"
    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:drop_table"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:drop_table_async"
        ```

      This permanently removes the table and is not recoverable, unlike deleting rows.
      By default, if the table does not exist an exception is raised. To suppress this,
      you can pass in `ignore_missing=True`.

=== "TypeScript"

      ```typescript
      --8<-- "docs/src/basic_legacy.ts:drop_table"
      ```

      This permanently removes the table and is not recoverable, unlike deleting rows.
      If the table does not exist an exception is raised.

## Updating a table

This can be used to update zero to all rows depending on how many rows match the where clause. The update queries follow the form of a SQL UPDATE statement. The `where` parameter is a SQL filter that matches on the metadata columns. The `values` or `values_sql` parameters are used to provide the new values for the columns.

| Parameter   | Type | Description |
|---|---|---|
| `where` | `str` | The SQL where clause to use when updating rows. For example, `'x = 2'` or `'x IN (1, 2, 3)'`. The filter must not be empty, or it will error. |
| `values` | `dict` | The values to update. The keys are the column names and the values are the values to set. |
| `values_sql` | `dict` | The values to update. The keys are the column names and the values are the SQL expressions to set. For example, `{'x': 'x + 1'}` will increment the value of the `x` column by 1. |

!!! info "SQL syntax"

    See [SQL filters](../../sql.md) for more information on the supported SQL syntax.

!!! warning "Warning"

    Updating nested columns is not yet supported.

=== "Python"

    API Reference: [lancedb.table.Table.update][]
    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-pandas"
        --8<-- "python/python/tests/docs/test_guide_tables.py:update_table"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-pandas"
        --8<-- "python/python/tests/docs/test_guide_tables.py:update_table_async"
        ```

    Output
    ```shell
        x  vector
    0  1  [1.0, 2.0]
    1  3  [5.0, 6.0]
    2  2  [10.0, 10.0]
    ```

=== "Typescript[^1]"

    === "@lancedb/lancedb"

        API Reference: [lancedb.Table.update](../../js/classes/Table.md/#update)

        ```ts
        import * as lancedb from "@lancedb/lancedb";

        const db = await lancedb.connect("./.lancedb");

        const data = [
            {x: 1, vector: [1, 2]},
            {x: 2, vector: [3, 4]},
            {x: 3, vector: [5, 6]},
        ];
        const tbl = await db.createTable("my_table", data)

        await tbl.update({ 
            values: { vector: [10, 10] },
            where: "x = 2"
        });
        ```

    === "vectordb (deprecated)"

        API Reference: [vectordb.Table.update](../../javascript/interfaces/Table.md/#update)

        ```ts
        const lancedb = require("vectordb");

        const db = await lancedb.connect("./.lancedb");

        const data = [
            {x: 1, vector: [1, 2]},
            {x: 2, vector: [3, 4]},
            {x: 3, vector: [5, 6]},
        ];
        const tbl = await db.createTable("my_table", data)

        await tbl.update({ 
            where: "x = 2", 
            values: { vector: [10, 10] } 
        });
        ```

### Updating using a sql query

  The `values` parameter is used to provide the new values for the columns as literal values. You can also use the `values_sql` / `valuesSql` parameter to provide SQL expressions for the new values. For example, you can use `values_sql="x + 1"` to increment the value of the `x` column by 1.

=== "Python"
    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:update_table_sql"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:update_table_sql_async"
        ```

    Output
    ```shell
        x  vector
    0  2  [1.0, 2.0]
    1  4  [5.0, 6.0]
    2  3  [10.0, 10.0]
    ```

=== "Typescript[^1]"

    === "@lancedb/lancedb"

        Coming Soon!

    === "vectordb (deprecated)"

        ```ts
        await tbl.update({ valuesSql: { x: "x + 1" } })
        ```

!!! info "Note"

    When rows are updated, they are moved out of the index. The row will still show up in ANN queries, but the query will not be as fast as it would be if the row was in the index. If you update a large proportion of rows, consider rebuilding the index afterwards.

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

## What's next?

Learn about [managing schemas](schema_management.md) in your tables.

[^1]: The `vectordb` package is a legacy package that is deprecated in favor of `@lancedb/lancedb`. The `vectordb` package will continue to receive bug fixes and security updates until September 2024. We recommend all new projects use `@lancedb/lancedb`. See the [migration guide](../../migration.md) for more information. 