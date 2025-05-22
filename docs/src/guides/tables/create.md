---
title: Working With Tables in LanceDB
description: Learn about different methods to create tables in LanceDB, including from various data sources and empty tables.
---

# Working With Tables in LanceDB

In LanceDB, tables store records with a defined schema that specifies column names and types. You can create LanceDB tables from these data formats:

- Pandas DataFrames
- [Polars](https://pola.rs/) DataFrames
- Apache Arrow Tables

The Python SDK additionally supports:

- PyArrow schemas for explicit schema control
- `LanceModel` for Pydantic-based validation

## Create a LanceDB Table

Initialize a LanceDB connection and create a table

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_tables.py:connect"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_tables.py:connect_async"
        ```

=== "Typescript"

    === "@lancedb/lancedb"

        ```typescript
        import * as lancedb from "@lancedb/lancedb";
        import * as arrow from "apache-arrow";

        const uri = "data/sample-lancedb";
        const db = await lancedb.connect(uri);
        ```

    === "vectordb (deprecated)"

        ```typescript
        const lancedb = require("vectordb");
        const arrow = require("apache-arrow");

        const uri = "data/sample-lancedb";
        const db = await lancedb.connect(uri);
        ```

LanceDB allows ingesting data from various sources - `dict`, `list[dict]`, `pd.DataFrame`, `pa.Table` or a `Iterator[pa.RecordBatch]`. Let's take a look at some of the these.

### From list of tuples or dictionaries

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_table"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async"
        ```

    !!! info "Note"
        If the table already exists, LanceDB will raise an error by default.

        `create_table` supports an optional `exist_ok` parameter. When set to True
        and the table exists, then it simply opens the existing table. The data you
        passed in will NOT be appended to the table in that case.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_exist_ok"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_exist_ok"
        ```

    Sometimes you want to make sure that you start fresh. If you want to
    overwrite the table, you can pass in mode="overwrite" to the createTable function.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_overwrite"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_overwrite"
        ```

=== "Typescript"
    You can create a LanceDB table in JavaScript using an array of records as follows.

    === "@lancedb/lancedb"


        ```ts
        --8<-- "nodejs/examples/basic.test.ts:create_table"
        ```

        This will infer the schema from the provided data. If you want to explicitly provide a schema, you can use `apache-arrow` to declare a schema

        ```ts
        --8<-- "nodejs/examples/basic.test.ts:create_table_with_schema"
        ```

        !!! info "Note"
            `createTable` supports an optional `existsOk` parameter. When set to true
            and the table exists, then it simply opens the existing table. The data you
            passed in will NOT be appended to the table in that case.

        ```ts
        --8<-- "nodejs/examples/basic.test.ts:create_table_exists_ok"
        ```

        Sometimes you want to make sure that you start fresh. If you want to
        overwrite the table, you can pass in mode: "overwrite" to the createTable function.

        ```ts
        --8<-- "nodejs/examples/basic.test.ts:create_table_overwrite"
        ```

    === "vectordb (deprecated)"

        ```ts
        --8<-- "docs/src/basic_legacy.ts:create_table"
        ```

        This will infer the schema from the provided data. If you want to explicitly provide a schema, you can use apache-arrow to declare a schema



        ```ts
        --8<-- "docs/src/basic_legacy.ts:create_table_with_schema"
        ```

        !!! warning
            `existsOk` is not available in `vectordb`



            If the table already exists, vectordb will raise an error by default.
            You can use `writeMode: WriteMode.Overwrite` to overwrite the table.
            But this will delete the existing table and create a new one with the same name.


        Sometimes you want to make sure that you start fresh.

        If you want to overwrite the table, you can pass in `writeMode: lancedb.WriteMode.Overwrite` to the createTable function.

        ```ts
        const table = await con.createTable(tableName, data, {
            writeMode: WriteMode.Overwrite
        })
        ```

### From a Pandas DataFrame


=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-pandas"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_from_pandas"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-pandas"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_from_pandas"
    ```

!!! info "Note"
    Data is converted to Arrow before being written to disk. For maximum control over how data is saved, either provide the PyArrow schema to convert to or else provide a PyArrow Table directly.

The **`vector`** column needs to be a [Vector](../python/pydantic.md#vector-field) (defined as [pyarrow.FixedSizeList](https://arrow.apache.org/docs/python/generated/pyarrow.list_.html)) type.

=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_custom_schema"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_custom_schema"
    ```

### From a Polars DataFrame

LanceDB supports [Polars](https://pola.rs/), a modern, fast DataFrame library
written in Rust. Just like in Pandas, the Polars integration is enabled by PyArrow
under the hood. A deeper integration between LanceDB Tables and Polars DataFrames
is on the way.

=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-polars"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_from_polars"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-polars"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_from_polars"
    ```

### From an Arrow Table
You can also create LanceDB tables directly from Arrow tables.
LanceDB supports float16 data type!

=== "Python"
    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-numpy"
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_from_arrow_table"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-polars"
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-numpy"
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_from_arrow_table"
        ```

=== "Typescript"

    === "@lancedb/lancedb"

        ```typescript
        --8<-- "nodejs/examples/basic.test.ts:create_f16_table"
        ```

    === "vectordb (deprecated)"

        ```typescript
        --8<-- "docs/src/basic_legacy.ts:create_f16_table"
        ```

### From Pydantic Models

When you create an empty table without data, you must specify the table schema.
LanceDB supports creating tables by specifying a PyArrow schema or a specialized
Pydantic model called `LanceModel`.

For example, the following Content model specifies a table with 5 columns:
`movie_id`, `vector`, `genres`, `title`, and `imdb_id`. When you create a table, you can
pass the class as the value of the `schema` parameter to `create_table`.
The `vector` column is a `Vector` type, which is a specialized Pydantic type that
can be configured with the vector dimensions. It is also important to note that
LanceDB only understands subclasses of `lancedb.pydantic.LanceModel`
(which itself derives from `pydantic.BaseModel`).

=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb-pydantic"
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
    --8<-- "python/python/tests/docs/test_guide_tables.py:class-Content"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_from_pydantic"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb-pydantic"
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
    --8<-- "python/python/tests/docs/test_guide_tables.py:class-Content"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_from_pydantic"
    ```

#### Nested schemas

Sometimes your data model may contain nested objects.
For example, you may want to store the document string
and the document source name as a nested Document object:

```python
--8<-- "python/python/tests/docs/test_guide_tables.py:import-pydantic-basemodel"
--8<-- "python/python/tests/docs/test_guide_tables.py:class-Document"
```

This can be used as the type of a LanceDB table column:

=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:class-NestedSchema"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_nested_schema"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:class-NestedSchema"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_nested_schema"
    ```
This creates a struct column called "document" that has two subfields
called "content" and "source":

```
In [28]: tbl.schema
Out[28]:
id: string not null
vector: fixed_size_list<item: float>[1536] not null
    child 0, item: float
document: struct<content: string not null, source: string not null> not null
    child 0, content: string not null
    child 1, source: string not null
```

#### Validators

Note that neither Pydantic nor PyArrow automatically validates that input data
is of the correct timezone, but this is easy to add as a custom field validator:

```python
from datetime import datetime
from zoneinfo import ZoneInfo

from lancedb.pydantic import LanceModel
from pydantic import Field, field_validator, ValidationError, ValidationInfo

tzname = "America/New_York"
tz = ZoneInfo(tzname)

class TestModel(LanceModel):
    dt_with_tz: datetime = Field(json_schema_extra={"tz": tzname})

    @field_validator('dt_with_tz')
    @classmethod
    def tz_must_match(cls, dt: datetime) -> datetime:
        assert dt.tzinfo == tz
        return dt

ok = TestModel(dt_with_tz=datetime.now(tz))

try:
    TestModel(dt_with_tz=datetime.now(ZoneInfo("Asia/Shanghai")))
    assert 0 == 1, "this should raise ValidationError"
except ValidationError:
    print("A ValidationError was raised.")
    pass
```

When you run this code it should print "A ValidationError was raised."

#### Pydantic custom types

LanceDB does NOT yet support converting pydantic custom types. If this is something you need,
please file a feature request on the [LanceDB Github repo](https://github.com/lancedb/lancedb/issues/new).

### Using Iterators / Writing Large Datasets

It is recommended to use iterators to add large datasets in batches when creating your table in one go. This does not create multiple versions of your dataset unlike manually adding batches using `table.add()`

LanceDB additionally supports PyArrow's `RecordBatch` Iterators or other generators producing supported data types.

Here's an example using using `RecordBatch` iterator for creating tables.

=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
    --8<-- "python/python/tests/docs/test_guide_tables.py:make_batches"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_from_batch"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
    --8<-- "python/python/tests/docs/test_guide_tables.py:make_batches"
    --8<-- "python/python/tests/docs/test_guide_tables.py:create_table_async_from_batch"
    ```

You can also use iterators of other types like Pandas DataFrame or Pylists directly in the above example.

## Open existing tables

=== "Python"
    If you forget the name of your table, you can always get a listing of all table names.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:list_tables"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:list_tables_async"
        ```

    Then, you can open any existing tables.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:open_table"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:open_table_async"
        ```

=== "Typescript"

    If you forget the name of your table, you can always get a listing of all table names.

    ```typescript
    console.log(await db.tableNames());
    ```

    Then, you can open any existing tables.

    ```typescript
    const tbl = await db.openTable("my_table");
    ```

## Creating empty table
You can create an empty table for scenarios where you want to add data to the table later. An example would be when you want to collect data from a stream/external file and then add it to a table in batches.

=== "Python"


    An empty table can be initialized via a PyArrow schema.
    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_empty_table"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-pyarrow"
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_empty_table_async"
        ```

    Alternatively, you can also use Pydantic to specify the schema for the empty table. Note that we do not
    directly import `pydantic` but instead use `lancedb.pydantic` which is a subclass of `pydantic.BaseModel`
    that has been extended to support LanceDB specific types like `Vector`.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb-pydantic"
        --8<-- "python/python/tests/docs/test_guide_tables.py:class-Item"
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_empty_table_pydantic"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_guide_tables.py:import-lancedb-pydantic"
        --8<-- "python/python/tests/docs/test_guide_tables.py:class-Item"
        --8<-- "python/python/tests/docs/test_guide_tables.py:create_empty_table_async_pydantic"
        ```

    Once the empty table has been created, you can add data to it via the various methods listed in the [Adding to a table](#adding-to-a-table) section.

=== "Typescript"

    === "@lancedb/lancedb"

        ```typescript
        --8<-- "nodejs/examples/basic.test.ts:create_empty_table"
        ```

    === "vectordb (deprecated)"

        ```typescript
        --8<-- "docs/src/basic_legacy.ts:create_empty_table"
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
