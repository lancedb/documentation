---
title: "Data Updates in LanceDB | Data Modification Guide"
description: "Learn how to update and modify data in LanceDB. Includes incremental updates, batch modifications, and best practices for data maintenance."
---

# Updating Data with LanceDB 

Our enterprise solution efficiently manages updates across millions of tables, 
supporting several hundred transactions per second (TPS) per table.

LanceDB supports various data modification operations:

- **Basic Operations**: Update and delete existing data
- **Merge Insert Operations**: Upsert, insert-if-not-exists, and replace range

## Basic Operations

### Update

Update existing rows that match a condition.

=== "Python"
    ```python
    import lancedb

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    data = [
        {"vector": [3.1, 4.1], "item": "foo", "price": 10.0},
        {"vector": [5.9, 26.5], "item": "bar", "price": 20.0},
        {"vector": [2.9, 18.2], "item": "zoo", "price": 30.0},
    ]

    table = db.create_table("update_table_example", data, mode="overwrite")

    # Update with direct values
    table.update(where="price < 20.0", values={"vector": [2, 2], "item": "foo-updated"})

    # Update using SQL expression
    table.update(where="price < 20.0", values_sql={"price": "price * 1.1"})
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    // Connect to LanceDB
    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    // Create a table with sample data
    const data = [
      { vector: [3.1, 4.1], item: "foo", price: 10.0 },
      { vector: [5.9, 26.5], item: "bar", price: 20.0 },
      { vector: [2.9, 18.2], item: "zoo", price: 30.0},
    ];

    const table = await db.createTable("update_table_example", data, { mode: "overwrite" });

    // Update with direct values
    await table.update({
      where: "price < 20.0",
      values: { vector: [2, 2], item: "foo-updated" },
    });

    // Update using SQL expression
    await table.update({
      where: "price < 20.0", 
      valuesSql: { price: "price * 1.1" },
    });
    ```

!!! info "Index Updates"
    When rows are updated, LanceDB will update the existing index on the column. 
    The updated data is available for search immediately.

Check out the details of `update` from [Python SDK](https://lancedb.github.io/lancedb/python/python/#lancedb.table.Table.update) and [TypeScript SDK](https://lancedb.github.io/lancedb/js/classes/Table/#update).

### Delete

Remove rows that match a condition.

=== "Python"
    ```python
    import lancedb

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )
    table = db.open_table("update_table_example")

    # delete data
    predicate = "price = 30.0"
    table.delete(predicate)
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    // Connect to LanceDB
    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });
    table = await db.openTable("update_table_example");

    // delete data
    const predicate = "price = 30.0";
    await table.delete(predicate);
    ```

!!! warning "Permanent Deletion"
    Delete operations are permanent and cannot be undone. Always ensure you have backups or are certain before deleting data.

Check out the details of `delete` from [Python SDK](https://lancedb.github.io/lancedb/python/python/#lancedb.table.Table.delete) and [TypeScript SDK](https://lancedb.github.io/lancedb/js/classes/Table/#delete).


## Merge Operations

The merge insert command is a flexible API that can be used to perform _upsert_, 
_insert_if_not_exists_, and _replace_range_ operations.

!!! tip "Update Performance Optimization"
    For optimal update performance:
    - Use batch updates when possible (add multiple rows at once)
    - Consider creating a [scalar index](../guides/build-index.md#scalar-index) on your ID column if updating by ID frequently
    - For large-scale updates, consider using multiple concurrent connections

!!! info "Embedding Functions"
    Like the create table and add APIs, the merge insert API will automatically compute embeddings 
    if the table has an embedding definition in its schema. If the input data doesn't contain the 
    source column, or the vector column is already filled, the embeddings won't be computed.

### Upsert

`upsert` updates rows if they exist and inserts them if they don't. To do this with merge insert, 
enable both `when_matched_update_all()` and `when_not_matched_insert_all()`.

=== "Python"
    ```python
    import lancedb

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    # Create example table
    users_table_name = "users_example"
    table = db.create_table(
        users_table_name,
        [
            {"id": 0, "name": "Alice"},
            {"id": 1, "name": "Bob"},
        ],
        mode="overwrite",
    )
    print(f"Created users table with {table.count_rows()} rows")

    # Prepare data for upsert
    new_users = [
        {"id": 1, "name": "Bobby"},  # Will update existing record
        {"id": 2, "name": "Charlie"},  # Will insert new record
    ]

    # Upsert by id
    (
        users_table.merge_insert("id")
        .when_matched_update_all()
        .when_not_matched_insert_all()
        .execute(new_users)
    )

    # Verify results - should be 3 records total
    print(f"Total users: {users_table.count_rows()}")  # 3
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    // Connect to LanceDB
    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    // Create example table
    const table = await db.createTable("users", [
      { id: 0, name: "Alice" },
      { id: 1, name: "Bob" },
    ]);

    // Prepare data for upsert
    const newUsers = [
      { id: 1, name: "Bobby" },  // Will update existing record
      { id: 2, name: "Charlie" },  // Will insert new record
    ];

    // Upsert by id
    await table
      .mergeInsert("id")
      .whenMatchedUpdateAll()
      .whenNotMatchedInsertAll()
      .execute(newUsers);

    // Verify results - should be 3 records total
    const count = await table.countRows();
    console.log(`Total users: ${count}`);  // 3
    ```

### Insert-if-not-exists

This will only insert rows that do not have a match in the target table, thus 
preventing duplicate rows. To do this with merge insert, enable just 
`when_not_matched_insert_all()`.

=== "Python"
    ```python
    import lancedb

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    # Create example table
    table = db.create_table(
        "domains",
        [
            {"domain": "google.com", "name": "Google"},
            {"domain": "github.com", "name": "GitHub"},
        ],
    )

    # Prepare new data - one existing and one new record
    new_domains = [
        {"domain": "google.com", "name": "Google"},
        {"domain": "facebook.com", "name": "Facebook"},
    ]

    # Insert only if domain doesn't exist
    table.merge_insert("domain").when_not_matched_insert_all().execute(new_domains)

    # Verify count - should be 3 (original 2 plus 1 new)
    print(f"Total domains: {table.count_rows()}")  # 3
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    // Connect to LanceDB
    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    // Create example table
    const table = await db.createTable(
      "domains", 
      [
        { domain: "google.com", name: "Google" },
        { domain: "github.com", name: "GitHub" },
      ]
    );

    // Prepare new data - one existing and one new record
    const newDomains = [
      { domain: "google.com", name: "Google" },
      { domain: "facebook.com", name: "Facebook" },
    ];

    // Insert only if domain doesn't exist
    await table.merge_insert("domain")
      .whenNotMatchedInsertAll()
      .execute(newDomains);

    // Verify count - should be 3 (original 2 plus 1 new)
    const count = await table.countRows();
    console.log(`Total domains: ${count}`);  // 3
    ```

### Replace range

You can also replace a range of rows in the target table with the input data. 
For example, if you have a table of document chunks, where each chunk has both 
a `doc_id` and a `chunk_id`, you can replace all chunks for a given `doc_id` with updated chunks. 

This can be tricky otherwise because if you try to use `upsert` when the new data has fewer 
chunks you will end up with extra chunks. To avoid this, add another clause to delete any chunks 
for the document that are not in the new data, with `when_not_matched_by_source_delete`.

=== "Python"
    ```python
    import lancedb

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    # Create example table with document chunks
    table = db.create_table(
        "chunks",
        [
            {"doc_id": 0, "chunk_id": 0, "text": "Hello"},
            {"doc_id": 0, "chunk_id": 1, "text": "World"},
            {"doc_id": 1, "chunk_id": 0, "text": "Foo"},
            {"doc_id": 1, "chunk_id": 1, "text": "Bar"},
            {"doc_id": 2, "chunk_id": 0, "text": "Baz"},
        ],
    )

    # New data - replacing all chunks for doc_id 1 with just one chunk
    new_chunks = [
        {"doc_id": 1, "chunk_id": 0, "text": "Zoo"},
    ]

    # Replace all chunks for doc_id 1
    (
        table.merge_insert(["doc_id"])
        .when_matched_update_all()
        .when_not_matched_insert_all()
        .when_not_matched_by_source_delete("doc_id = 1")
        .execute(new_chunks)
    )

    # Verify count for doc_id = 1 - should be 2 
    print(f"Chunks for doc_id = 1: {table.count_rows('doc_id = 1')}")  # 2
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    // Connect to LanceDB
    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    // Create example table with document chunks
    const table = await db.createTable(
      "chunks", 
      [
        { doc_id: 0, chunk_id: 0, text: "Hello" },
        { doc_id: 0, chunk_id: 1, text: "World" },
        { doc_id: 1, chunk_id: 0, text: "Foo" },
        { doc_id: 1, chunk_id: 1, text: "Bar" },
        { doc_id: 2, chunk_id: 0, text: "Baz" },
      ]
    );

    // New data - replacing all chunks for doc_id 1 with just one chunk
    const newChunks = [
      { doc_id: 1, chunk_id: 0, text: "Zoo" }
    ];

    // Replace all chunks for doc_id 1
    await table.merge_insert(["doc_id"])
      .whenMatchedUpdateAll()
      .whenNotMatchedInsertAll()
      .whenNotMatchedBySourceDelete("doc_id = 1")
      .execute(newChunks);

    // Verify count for doc_id = 1 - should be 2 
    const count = await table.countRows("doc_id = 1");
    console.log(`Chunks for doc_id =1: ${count}`);  // 2
    ```

For more detailed information, refer to the [`merge_insert` from Python SDK](https://lancedb.github.io/lancedb/python/python/#lancedb.table.Table.merge_insert)
and [`mergeInsert from TypeScript SDK`](https://lancedb.github.io/lancedb/js/classes/Table/#mergeinsert)



---
title: Merge Insert in LanceDB | Upsert, Insert-if-Not-Exists & Replace Range
description: Learn how to use the merge insert command in LanceDB for upserts, insert-if-not-exists, and range replacements. Covers performance tips, embedding functions, and API usage in Python and TypeScript.
---

The merge insert command is a flexible API that can be used to perform:

1. Upsert
2. Insert-if-not-exists
3. Replace range

It works by joining the input data with the target table on a key you provide.
Often this key is a unique row id key. You can then specify what to do when
there is a match and when there is not a match. For example, for upsert you want
to update if the row has a match and insert if the row doesn't have a match.
Whereas for insert-if-not-exists you only want to insert if the row doesn't have
a match.

You can also read more in the API reference:

* Python
    * Sync: [lancedb.table.Table.merge_insert][]
    * Async: [lancedb.table.AsyncTable.merge_insert][]
* Typescript: [lancedb.Table.mergeInsert](../../js/classes/Table.md/#mergeinsert)

!!! tip "Use scalar indices to speed up merge insert"

    The merge insert command needs to perform a join between the input data and the
    target table on the `on` key you provide. This requires scanning that entire
    column, which can be expensive for large tables. To speed up this operation,
    you can create a scalar index on the `on` column, which will allow LanceDB to
    find matches without having to scan the whole tables.

    Read more about scalar indices in [Building a Scalar Index](../scalar_index.md)
    guide.

!!! info "Embedding Functions"

    Like the create table and add APIs, the merge insert API will automatically
    compute embeddings if the table has a embedding definition in its schema.
    If the input data doesn't contain the source column, or the vector column
    is already filled, then the embeddings won't be computed. See the
    [Embedding Functions](../../embeddings/embedding_functions.md) guide for more
    information.

## Upsert

Upsert updates rows if they exist and inserts them if they don't. To do this
with merge insert, enable both `when_matched_update_all()` and
`when_not_matched_insert_all()`.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_merge_insert.py:upsert_basic"
        ```

    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_merge_insert.py:upsert_basic_async"
        ```

=== "Typescript"

    === "@lancedb/lancedb"

        ```typescript
        --8<-- "nodejs/examples/merge_insert.test.ts:upsert_basic"
        ```

!!! note "Providing subsets of columns"

    If a column is nullable, it can be omitted from input data and it will be
    considered `null`. Columns can also be provided in any order.

## Insert-if-not-exists

To avoid inserting duplicate rows, you can use the insert-if-not-exists command.
This will only insert rows that do not have a match in the target table. To do
this with merge insert, enable just `when_not_matched_insert_all()`.


=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_merge_insert.py:insert_if_not_exists"
        ```

    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_merge_insert.py:insert_if_not_exists_async"
        ```

=== "Typescript"

    === "@lancedb/lancedb"

        ```typescript
        --8<-- "nodejs/examples/merge_insert.test.ts:insert_if_not_exists"
        ```


## Replace range

You can also replace a range of rows in the target table with the input data.
For example, if you have a table of document chunks, where each chunk has
both a `doc_id` and a `chunk_id`, you can replace all chunks for a given
`doc_id` with updated chunks. This can be tricky otherwise because if you
try to use upsert when the new data has fewer chunks you will end up with
extra chunks. To avoid this, add another clause to delete any chunks for
the document that are not in the new data, with
`when_not_matched_by_source_delete`.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_merge_insert.py:replace_range"
        ```

    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_merge_insert.py:replace_range_async"
        ```

=== "Typescript"

    === "@lancedb/lancedb"

        ```typescript
        --8<-- "nodejs/examples/merge_insert.test.ts:replace_range"
        ```




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