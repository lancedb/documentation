---
title: "Metadata Filtering in LanceDB | Query Filtering Guide"
description: "Learn how to implement metadata filtering in LanceDB. Includes scalar filtering, complex conditions, and optimizing filtered queries."
---

# Metadata Filtering with LanceDB

We support rich filtering features of query results based on metadata fields. 
While joint vector and metadata search at scale presents a significant challenge, 
LanceDB achieves sub-100ms latency at thousands of QPS, enabling efficient vector search 
with filtering capabilities even on datasets containing billions of records. 

By default, _pre-filtering_ is applied before executing the vector search to 
narrow the search space within large datasets, thereby reducing query latency. 
Alternatively, _post-filtering_ can be employed to refine results after the 
vector search completes.

!!! tip "Best Practices for Filtering"
    **Scalar Indices**: We strongly recommend creating scalar indices on 
    columns used for filtering, whether combined with a search operation 
    or applied independently (e.g., for updates or deletions).

    **SQL Filters**: Built on DataFusion, LanceDB supports SQL filters. 
    For example: for a column of type LIST(T) can use `LABEL_LIST` to 
    create a [scalar index](../guides/build-index.md#scalar-index). Then leverage DataFusion's 
    [array functions](https://datafusion.apache.org/user-guide/sql/scalar_functions.html#array-functions) 
    like `array_has_any` or `array_has_all` for optimized filtering.

    For best performance with large tables or high query volumes:

    - Build a [scalar index](../guides/build-index.md#scalar-index) on frequently filtered columns
    - Use exact column names in filters (e.g., `user_id` instead of `USER_ID`)
    - Avoid complex transformations in filter expressions (keep them simple)
    - When running concurrent queries, use connection pooling for better throughput

=== "Python"
    ```python
    import lancedb

    # connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )
    # Create sample data
    data = [
        {"vector": [3.1, 4.1], "item": "foo", "price": 10.0},
        {"vector": [5.9, 26.5], "item": "bar", "price": 20.0},
        {"vector": [10.2, 100.8], "item": "baz", "price": 30.0},
        {"vector": [1.4, 9.5], "item": "fred", "price": 40.0},
    ]
    table = db.create_table("metadata_filter_example", data=data, mode="overwrite")

    #  Filters with vector search
    filtered_result = (
        table.search([100, 102])
        .where("(item IN ('foo', 'bar')) AND (price > 9.0)")
        .limit(3)
        .to_arrow()
    )

    # With post-filtering
    post_filtered_result = (
        table.search([100, 102])
        .where("(item IN ('foo', 'bar')) AND (price > 9.0)", prefilter=False)
        .limit(3)
        .to_arrow()
    )

    # Filters without vector search
    filtered_no_search_result = (
        table.search()
        .where("(item IN ('foo', 'bar', 'baz')) AND (price > 9.0)")
        .limit(3)
        .to_arrow()
    )
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });
    const data = [
      { vector: [3.1, 4.1], item: "foo", price: 10.0 },
      { vector: [5.9, 26.5], item: "bar", price: 20.0 },
      { vector: [10.2, 100.8], item: "baz", price: 30.0 },
      { vector: [1.4, 9.5], item: "fred", price: 40.0 },
    ];

    const tableName = "metadata_filter_example";
    const table = await db.createTable(tableName, data, {
      mode: "overwrite",
    });
    const results = await table
      .search([100, 102])
      .where("(item IN ('foo', 'bar')) AND (price > 10.0)")
      .toArray();

    // With post-filtering
    const postFilteredResult = await (table.search([100, 102]) as VectorQuery)
      .where("(item IN ('foo', 'bar')) AND (price > 9.0)")
      .postfilter()
      .limit(3)
      .toArray();

    // Filters without vector search
    const filteredResult = await table
      .query()
      .where("(item IN ('foo', 'bar')) AND (price > 9.0)")
      .limit(3)
      .toArray();
    ```

!!! warning "Resource Usage Warning"
    When querying large tables, omitting a `limit` clause may:
    - Overwhelm Resources: return excessive data.
    - Increase Costs: query pricing scales with data scanned and returned ([LanceDB Cloud pricing](https://lancedb.com/pricing)).

## SQL filters

Because it's built on top of DataFusion, LanceDB embraces the 
utilization of standard SQL expressions as predicates for 
filtering operations. SQL can be used during vector search, 
update, and deletion operations.

| SQL Expression | Description |
|---------------|-------------|
| `>, >=, <, <=, =` | Comparison operators |
| `AND`, `OR`, `NOT` | Logical operators |
| `IS NULL`, `IS NOT NULL` | Null checks |
| `IS TRUE`, `IS NOT TRUE`, `IS FALSE`, `IS NOT FALSE` | Boolean checks |
| `IN` | Value matching from a set |
| `LIKE`, `NOT LIKE` | Pattern matching |
| `CAST` | Type conversion |
| `regexp_match(column, pattern)` | Regular expression matching |
| [DataFusion Functions](https://datafusion.apache.org/user-guide/sql/scalar_functions.html) | Additional SQL functions |

If your column name contains special characters, upper-case characters, 
or is a SQL Keyword, you can use backtick (`) to escape it. 
For nested fields, each segment of the path must be wrapped in 
backticks.

```sql
`CUBE` = 10 AND `UpperCaseName` = '3' AND `column name with space` IS NOT NULL
AND `nested with space`.`inner with space` < 2
```

!!! warning "Field Name Limitation"
    Field names containing periods (.) are NOT supported.


# Filtering & SQL in LanceDB

## Pre and Post-Filtering

LanceDB supports filtering of query results based on metadata fields. By default, post-filtering is
performed on the top-k results returned by the vector search. However, pre-filtering is also an
option that performs the filter prior to vector search. This can be useful to narrow down
the search space of a very large dataset to reduce query latency.

Note that both pre-filtering and post-filtering can yield false positives. For pre-filtering, if the filter is too selective, it might eliminate relevant items that the vector search would have otherwise identified as a good match. In this case, increasing `nprobes` parameter will help reduce such false positives. It is recommended to call `bypass_vector_index()` if you know that the filter is highly selective.

Similarly, a highly selective post-filter can lead to false positives. Increasing both `nprobes` and `refine_factor` can mitigate this issue. When deciding between pre-filtering and post-filtering, pre-filtering is generally the safer choice if you're uncertain.

<!-- Setup Code
```python
import lancedb
import numpy as np

uri = "data/sample-lancedb"
data = [{"vector": row, "item": f"item {i}", "id": i}
    for i, row in enumerate(np.random.random((10_000, 2)))]

# Synchronous client
db = lancedb.connect(uri)
tbl = db.create_table("my_vectors", data=data)

# Asynchronous client
async_db = await lancedb.connect_async(uri)
async_tbl = await async_db.create_table("my_vectors_async", data=data)
```
-->
<!-- Setup Code
```javascript
const vectordb = require('vectordb')
const db = await vectordb.connect('data/sample-lancedb')

let data = []
for (let i = 0; i < 10_000; i++) {
     data.push({vector: Array(1536).fill(i), id: i, item: `item ${i}`, strId: `${i}`})
}
const tbl = await db.createTable('myVectors', data)
```
-->

=== "Python"

    ```python
    # Synchronous client
    result = tbl.search([0.5, 0.2]).where("id = 10", prefilter=True).limit(1).to_arrow()
    # Asynchronous client
    result = await async_tbl.query().where("id = 10").nearest_to([0.5, 0.2]).limit(1).to_arrow()
    ```

=== "TypeScript"

    === "@lancedb/lancedb"

        ```ts
        --8<-- "nodejs/examples/filtering.test.ts:search"
        ```

    === "vectordb (deprecated)"

        ```ts
        --8<-- "docs/src/sql_legacy.ts:search"
        ```

!!! note

    Creating a [scalar index](guides/scalar_index.md) accelerates filtering.

## SQL Filtering

Because it's built on top of [DataFusion](https://github.com/apache/arrow-datafusion), LanceDB
embraces the utilization of standard SQL expressions as predicates for filtering operations.
SQL can be used during vector search, update, and deletion operations.

LanceDB supports a growing list of SQL expressions:

- `>`, `>=`, `<`, `<=`, `=`
- `AND`, `OR`, `NOT`
- `IS NULL`, `IS NOT NULL`
- `IS TRUE`, `IS NOT TRUE`, `IS FALSE`, `IS NOT FALSE`
- `IN`
- `LIKE`, `NOT LIKE`
- `CAST`
- `regexp_match(column, pattern)`
- [DataFusion Functions](https://arrow.apache.org/datafusion/user-guide/sql/scalar_functions.html)

For example, the following filter string is acceptable:

=== "Python"

    ```python
    # Synchronous client
    tbl.search([100, 102]).where(
        "(item IN ('item 0', 'item 2')) AND (id > 10)"
    ).to_arrow()
    # Asynchronous client
    await (
        async_tbl.query()
        .where("(item IN ('item 0', 'item 2')) AND (id > 10)")
        .nearest_to([100, 102])
        .to_arrow()
    )
    ```

=== "TypeScript"

    === "@lancedb/lancedb"

        ```ts
        --8<-- "nodejs/examples/filtering.test.ts:vec_search"
        ```

    === "vectordb (deprecated)"

        ```ts
        --8<-- "docs/src/sql_legacy.ts:vec_search"
        ```

If your column name contains special characters, upper-case characters, or is a [SQL Keyword](https://docs.rs/sqlparser/latest/sqlparser/keywords/index.html),
you can use backtick (`` ` ``) to escape it. For nested fields, each segment of the
path must be wrapped in backticks.

=== "SQL"

    ```sql
    `CUBE` = 10 AND `UpperCaseName` = '3' AND `column name with space` IS NOT NULL
      AND `nested with space`.`inner with space` < 2
    ```

!!!warning "Field names containing periods (`.`) are not supported."

Literals for dates, timestamps, and decimals can be written by writing the string
value after the type name. For example:

=== "SQL"

    ```sql
    date_col = date '2021-01-01'
    and timestamp_col = timestamp '2021-01-01 00:00:00'
    and decimal_col = decimal(8,3) '1.000'
    ```

For timestamp columns, the precision can be specified as a number in the type
parameter. Microsecond precision (6) is the default.

| SQL            | Time unit    |
| -------------- | ------------ |
| `timestamp(0)` | Seconds      |
| `timestamp(3)` | Milliseconds |
| `timestamp(6)` | Microseconds |
| `timestamp(9)` | Nanoseconds  |

LanceDB internally stores data in [Apache Arrow](https://arrow.apache.org/) format.
The mapping from SQL types to Arrow types is:

| SQL type                                                  | Arrow type         |
| --------------------------------------------------------- | ------------------ |
| `boolean`                                                 | `Boolean`          |
| `tinyint` / `tinyint unsigned`                            | `Int8` / `UInt8`   |
| `smallint` / `smallint unsigned`                          | `Int16` / `UInt16` |
| `int` or `integer` / `int unsigned` or `integer unsigned` | `Int32` / `UInt32` |
| `bigint` / `bigint unsigned`                              | `Int64` / `UInt64` |
| `float`                                                   | `Float32`          |
| `double`                                                  | `Float64`          |
| `decimal(precision, scale)`                               | `Decimal128`       |
| `date`                                                    | `Date32`           |
| `timestamp`                                               | `Timestamp` [^1]   |
| `string`                                                  | `Utf8`             |
| `binary`                                                  | `Binary`           |

[^1]: See precision mapping in previous table.

## Filtering without Vector Search

You can also filter your data without search:

=== "Python"

    ```python
    # Synchronous client
    tbl.search().where("id = 10").limit(10).to_arrow()
    # Asynchronous client
    await async_tbl.query().where("id = 10").limit(10).to_arrow()
    ```

=== "TypeScript"

    === "@lancedb/lancedb"

        ```ts
        --8<-- "nodejs/examples/filtering.test.ts:sql_search"
        ```

    === "vectordb (deprecated)"

        ```ts
        --8<---- "docs/src/sql_legacy.ts:sql_search"
        ```

!!!warning "If your table is large, this could potentially return a very large amount of data. Please be sure to use a `limit` clause unless you're sure you want to return the whole result set."
