---
title: Schema Management in LanceDB
description: Learn how to manage table schemas in LanceDB, including adding, altering, and dropping columns.
---

# Schema Management in LanceDB

While tables must have a schema specified when they are created, you can
change the schema over time. There's three methods to alter the schema of
a table:

* `add_columns`: Add new columns to the table
* `alter_columns`: Alter the name, nullability, or data type of a column
* `drop_columns`: Drop columns from the table

## Adding new columns

You can add new columns to the table with the `add_columns` method. New columns
are filled with values based on a SQL expression. For example, you can add a new
column `y` to the table, fill it with the value of `x * 2` and set the expected
data type for it.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:add_columns"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:add_columns_async"
        ```
    **API Reference:** [lancedb.table.Table.add_columns][]

=== "Typescript"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:add_columns"
    ```
    **API Reference:** [lancedb.Table.addColumns](../../js/classes/Table.md/#addcolumns)

If you want to fill it with null, you can use `cast(NULL as <data_type>)` as
the SQL expression to fill the column with nulls, while controlling the data
type of the column. Available data types are base on the
[DataFusion data types](https://datafusion.apache.org/user-guide/sql/data_types.html).
You can use any of the SQL types, such as `BIGINT`:

```sql
cast(NULL as BIGINT)
```

Using Arrow data types and the `arrow_typeof` function is not yet supported.

## Altering existing columns

You can alter the name, nullability, or data type of a column with the `alter_columns`
method.

Changing the name or nullability of a column just updates the metadata. Because
of this, it's a fast operation. Changing the data type of a column requires
rewriting the column, which can be a heavy operation.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
        --8<-- "python/python/tests/docs/test_basic.py:alter_columns"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
        --8<-- "python/python/tests/docs/test_basic.py:alter_columns_async"
        ```
    **API Reference:** [lancedb.table.Table.alter_columns][]

=== "Typescript"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:alter_columns"
    ```
    **API Reference:** [lancedb.Table.alterColumns](../../js/classes/Table.md/#altercolumns)

## Dropping columns

You can drop columns from the table with the `drop_columns` method. This will
will remove the column from the schema.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:drop_columns"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:drop_columns_async"
        ```
    **API Reference:** [lancedb.table.Table.drop_columns][]

=== "Typescript"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:drop_columns"
    ```
    **API Reference:** [lancedb.Table.dropColumns](../../js/classes/Table.md/#altercolumns)

## What's next?

Learn about [consistency settings](consistency.md) in LanceDB.

[^1]: The `vectordb` package is a legacy package that is deprecated in favor of `@lancedb/lancedb`. The `vectordb` package will continue to receive bug fixes and security updates until September 2024. We recommend all new projects use `@lancedb/lancedb`. See the [migration guide](../../migration.md) for more information. 