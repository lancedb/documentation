---
title: Scalar Indexes in LanceDB | Optimized Metadata Filtering
description: Learn how to use scalar indexes in LanceDB for efficient metadata filtering and query optimization.
---

# **Scalar Index in LanceDB**

Scalar indexes organize data by scalar attributes (e.g., numbers, categories) and enable fast filtering of vector data. They accelerate retrieval of scalar data associated with vectors, thus enhancing query performance.

LanceDB supports three types of scalar indexes:

- `BTREE`: Stores column data in sorted order for binary search. Best for columns with many unique values.
- `BITMAP`: Uses bitmaps to track value presence. Ideal for columns with few unique values (e.g., categories, tags).
- `LABEL_LIST`: Special index for `List<T>` columns supporting `array_contains_all` and `array_contains_any` queries.

## **Choosing the Right Index Type**

| Data Type                                                       | Filter                                    | Index Type   |
| --------------------------------------------------------------- | ----------------------------------------- | ------------ |
| Numeric, String, Temporal                                       | `<`, `=`, `>`, `in`, `between`, `is null` | `BTREE`      |
| Boolean, numbers or strings with fewer than 1,000 unique values | `<`, `=`, `>`, `in`, `between`, `is null` | `BITMAP`     |
| List of low cardinality of numbers or strings                   | `array_has_any`, `array_has_all`          | `LABEL_LIST` |

## Scalar Index Operations

### **1. Build the Index**

You can create multiple scalar indexes within a table. By default, the index will be `BTREE`, but you can always configure another type like `BITMAP`

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_index.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_index.py:import-lancedb-btree-bitmap"
        --8<-- "python/python/tests/docs/test_guide_index.py:basic_scalar_index"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_index.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_index.py:import-lancedb-btree-bitmap"
        --8<-- "python/python/tests/docs/test_guide_index.py:basic_scalar_index_async"
        ```

=== "Typescript"

    === "@lancedb/lancedb"

        ```typescript
        const db = await lancedb.connect("data");
        const tbl = await db.openTable("my_vectors");

        await tbl.create_index("book_id");
        await tbl.create_index("publisher", { config: lancedb.Index.bitmap() })
        ```

!!! note "LanceDB Cloud and Enterprise"

    If you are using Cloud or Enterprise, the `create_scalar_index` API returns immediately, but the building of the scalar index is asynchronous. To wait until all data is fully indexed, you can specify the `wait_timeout` parameter on `create_scalar_index()` or call `wait_for_index()` on the table.

### **2. Check Index Status**

You can use the UI Dashboard in Cloud or just call the API:

=== "Python"
    ```python
    index_name = "label_idx"
    table.wait_for_index([index_name])
    ```

=== "TypeScript"
    ```typescript
    const indexName = "label_idx"
    await table.waitForIndex([indexName], 60)
    ```

### **3. Update the Index**

Updating the table data (adding, deleting, or modifying records) requires that you also update the scalar index. This can be done by calling `optimize`, which will trigger an update to the existing scalar index.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_index.py:update_scalar_index"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_index.py:update_scalar_index_async"
        ```

=== "TypeScript"

    ```typescript
    await tbl.add([{ vector: [7, 8], book_id: 4 }]);
    await tbl.optimize();
    ```

=== "Rust"

    ```rust
    let more_data: Box<dyn RecordBatchReader + Send> = create_some_records()?;
    tbl.add(more_data).execute().await?;
    tbl.optimize(OptimizeAction::All).execute().await?;
    ```

!!! note "LanceDB Cloud"

    New data added after creating the scalar index will still appear in search results if optimize is not used, but with increased latency due to a flat search on the unindexed portion. LanceDB Cloud automates the optimize process, minimizing the impact on search speed.

### **4. Run Indexed Search**

The following scan will be faster if the column `book_id` has a scalar index:

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_index.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_index.py:search_with_scalar_index"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_index.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_index.py:search_with_scalar_index_async"
        ```

=== "Typescript"

    === "@lancedb/lancedb"

        ```js
        const db = await lancedb.connect("data");
        const tbl = await db.openTable("books");

        await tbl
          .query()
          .where("book_id = 2")
          .limit(10)
          .toArray();
        ```

Scalar indexes can also speed up scans containing a vector search or full text search, and a prefilter:

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_index.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_index.py:vector_search_with_scalar_index"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_index.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_index.py:vector_search_with_scalar_index_async"
        ```

=== "Typescript"

    === "@lancedb/lancedb"

        ```js
        const db = await lancedb.connect("data/lance");
        const tbl = await db.openTable("book_with_embeddings");

        await tbl.search(Array(1536).fill(1.2))
          .where("book_id != 3")  // prefilter is default behavior.
          .limit(10)
          .toArray();
        ```

## **Advanced: Index UUID Columns**

LanceDB supports scalar indexes on UUID columns (stored as `FixedSizeBinary(16)`), enabling efficient lookups and filtering on UUID-based primary keys.

!!! note

    To use FixedSizeBinary, ensure you have:

    - Python SDK version [0.22.0-beta.4](https://github.com/lancedb/lancedb/releases/tag/python-v0.22.0-beta.4) or later
    - TypeScript SDK version [0.19.0-beta.4](https://github.com/lancedb/lancedb/releases/tag/v0.19.0-beta.4) or later

### **1. Define UUID Type**

First, create a custom Arrow extension type for UUIDs:

=== "Python"
    ```python
    import pyarrow as pa

    class UuidType(pa.ExtensionType):
        def __init__(self):
            super().__init__(pa.binary(16), "my.uuid")

        def __arrow_ext_serialize__(self):
            return b'uuid-metadata'

        @classmethod
        def __arrow_ext_deserialize__(cls, storage_type, serialized):
            return UuidType()

    pa.register_extension_type(UuidType())
    ```

=== "TypeScript"
    ```typescript
    import { Schema, Field, FixedSizeBinary } from "apache-arrow"

    // UUID is stored as FixedSizeBinary(16)
    const schema = new Schema([
        new Field("id", new FixedSizeBinary(16), true),
        new Field("name", new Utf8(), false),
    ]);
    ```

### **2. Generate UUID Data**

Create helper functions to generate UUIDs and sample data:

=== "Python"
    ```python
    import uuid
    import random
    import string

    def generate_random_string(length=10):
        return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

    def generate_uuids(num_items):
        return [uuid.uuid4().bytes for _ in range(num_items)]

    # Generate sample data
    n = 100
    uuids = generate_uuids(n)
    names = [generate_random_string() for _ in range(n)]
    ```

=== "TypeScript"
    ```typescript
    import { v4 as uuidv4 } from "uuid"

    function uuidToBuffer(uuid: string): Buffer {
        return Buffer.from(uuid.replace(/-/g, ''), 'hex');
    }

    function generateUuids(numItems: number): Buffer[] {
        return Array.from({ length: numItems }, () => uuidToBuffer(uuidv4()));
    }

    function generateRandomString(length: number = 10): string {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        return Array.from(
            { length },
            () => chars.charAt(Math.floor(Math.random() * chars.length))
        ).join('');
    }

    // Generate sample data
    const n = 100;
    const uuids = generateUuids(n);
    const names = Array.from({ length: n }, () => generateRandomString());
    ```

### **3. Create Table with UUID Column**

Create a table with the UUID column and sample data:

=== "Python"
    ```python
    import lancedb

    # Connect to LanceDB
    db = lancedb.connect(
        uri="db://your-project-slug",
        api_key="your-api-key",
        region="us-east-1"
    )

    # Create arrays
    uuid_array = pa.array(uuids, pa.binary(16))
    name_array = pa.array(names, pa.string())
    extension_array = pa.ExtensionArray.from_storage(UuidType(), uuid_array)

    # Create schema
    schema = pa.schema([
        pa.field('id', UuidType()),
        pa.field('name', pa.string())
    ])

    # Create table
    data_table = pa.Table.from_arrays([extension_array, name_array], schema=schema)
    table_name = "index-on-uuid-test"
    table = db.create_table(table_name, data=data_table, mode="overwrite")
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

    // Create data array
    const data = makeArrowTable(
        uuids.map((id, index) => ({
            id,
            name: names[index],
        })),
        { schema }
    );

    // Create table
    const tableName = "index-on-uuid-test-ts";
    const table = await db.createTable(tableName, data, { mode: "overwrite" });
    ```

### **4. Create and Wait for Index**

Create a scalar index on the UUID column and wait for it to complete:

=== "Python"
    ```python
    # Create index
    table.create_scalar_index("id")
    index_name = "id_idx"
    wait_for_index(table, index_name)
    ```

=== "TypeScript"
    ```typescript
    // Create scalar index
    await table.createIndex("id", {
        config: Index.bitmap(),
    });

    // Wait for index
    const scalarIndexName = "id_idx";
    await waitForIndex(table, scalarIndexName);
    ```

### **5. Perform Operations with UUID Index**

Example of upserting new records with UUIDs:

=== "Python"
    ```python
    # Upsert example
    new_users = [
        {"id": uuid.uuid4().bytes, "name": "Bobby"},
        {"id": uuid.uuid4().bytes, "name": "Charlie"},
    ]

    table.merge_insert("id") \
        .when_matched_update_all() \
        .when_not_matched_insert_all() \
        .execute(new_users)
    ```

=== "TypeScript"
    ```typescript
    // Upsert example
    const newUsers = [
        { id: uuidToBuffer(uuidv4()), name: "Bobby" },
        { id: uuidToBuffer(uuidv4()), name: "Charlie" },
    ];

    await table.mergeInsert("id")
        .whenMatchedUpdateAll()
        .whenNotMatchedInsertAll()
        .execute(newUsers);
    ```


