---
title: "Metadata Filtering in LanceDB | Query Filtering Guide"
description: "Learn how to implement metadata filtering in LanceDB. Includes scalar filtering, complex conditions, and optimizing filtered queries."
---

# **Metadata Filtering with LanceDB**

LanceDB supports filtering features of query results based on metadata fields. 
While joint vector and metadata search at scale presents a significant challenge, 
LanceDB achieves sub-100ms latency at thousands of QPS, enabling efficient vector search 
with filtering capabilities even on datasets containing billions of records. 

**Pre-filtering is applied to top-k results by default** before executing the vector search. This narrow down the search space within large datasets, thereby reducing query latency. 
You can also use **post-filtering** to refine results after the vector search completes.

## **Example: Metadata Filtering**

To illustrate filtering capabilities, let's try four data points with combinations of vectors and metadata:

=== "Python"

    ```python
    data = [
        {"vector": [3.1, 4.1], "item": "foo", "price": 10.0},
        {"vector": [5.9, 26.5], "item": "bar", "price": 20.0},
        {"vector": [10.2, 100.8], "item": "baz", "price": 30.0},
        {"vector": [1.4, 9.5], "item": "fred", "price": 40.0},
    ]
    table = db.create_table("metadata_filter_example", data=data, mode="overwrite")
    ```

=== "TypeScript"

    ```typescript
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
    ```

### **Filtering Without Vector Search**

You can always filter your data without search. This is useful when you need to query based on metadata:

=== "Python"

    === "Sync API"

    ```python
    filtered_no_search_result = (
        table.search()
        .where("(item IN ('foo', 'bar', 'baz')) AND (price > 15.0)")
        .limit(3)
        .to_arrow()
    )
    ```

    === "Async API"

    ```python
    filtered_no_search_result = await (
        async_table.query()
        .where("(item IN ('foo', 'bar', 'baz')) AND (price > 15.0)")
        .limit(3)
        .to_arrow()
    )
    ```

=== "TypeScript"

    ```typescript
    const filteredResult = await table
      .query()
      .where("(item IN ('foo', 'bar', 'baz')) AND (price > 15.0)")
      .limit(3)
      .toArray();
    ```

!!! warning "Limit Output"

    If your table is large, this could potentially return a very large amount of data. Please be sure to use a `limit` clause unless you're sure you want to return the whole result set.

### **Pre-Filtering with Vector Search**

=== "Python"

    === "Sync API"

    ```python
    filtered_result = (
        table.search([100, 102])
        .where("(item IN ('foo', 'bar')) AND (price > 15.0)")
        .limit(3)
        .to_arrow()
    )
    ```

    === "Async API"

    ```python
    filtered_result = await (
        async_table.query()
        .where("(item IN ('foo', 'bar')) AND (price > 15.0)")
        .nearest_to([100, 102])
        .limit(3)
        .to_arrow()
    )
    ```

=== "TypeScript"

    ```typescript
    const results = await table
      .search([100, 102])
      .where("(item IN ('foo', 'bar')) AND (price > 15.0)")
      .toArray();
    ```  

### **Post-Filtering with Vector Search**

=== "Python"

    === "Sync API"

    ```python
    post_filtered_result = (
        table.search([100, 102])
        .where("(item IN ('foo', 'bar')) AND (price > 15.0)", prefilter=False)
        .limit(3)
        .to_arrow()
    )
    ```

    === "Async API"

    ```python
    post_filtered_result = await (
        async_table.query()
        .where("(item IN ('foo', 'bar')) AND (price > 15.0)", prefilter=False)
        .nearest_to([100, 102])
        .limit(3)
        .to_arrow()
    )
    ```

=== "TypeScript"

    ```typescript
    const postFilteredResult = await (table.search([100, 102]) as VectorQuery)
      .where("(item IN ('foo', 'bar')) AND (price > 15.0)")
      .postfilter()
      .limit(3)
      .toArray();
    ```

!!! warning "Resource Usage Warning"
    When querying large tables, omitting a `limit` clause may overwhelm resources and return excessive data. It can also increase costs as query pricing scales with data scanned and data returned ([LanceDB Cloud pricing](https://lancedb.com/pricing)).

## **Filtering with SQL**

Because it's built on top of DataFusion, LanceDB embraces the utilization of standard SQL expressions as predicates for filtering operations. SQL can be used during vector search,  update, and deletion operations.

LanceDB supports a growing list of SQL expressions:

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

### **Simple SQL Filters**

For example, the following filter string is acceptable:

=== "Python"

    === "Sync API"

    ```python
    tbl.search([100, 102]).where(
        "(item IN ('foo', 'baz')) AND (price > 20.0)"
    ).to_arrow()
    ```

    === "Async API"

    ```python
    await (
        async_tbl.query()
        .where("(item IN ('foo', 'baz')) AND (price > 20.0)")
        .nearest_to([100, 102])
        .to_arrow()
    )
    ```

=== "TypeScript"

    ```typescript
    await table
      .search([100, 102])
      .where("(item IN ('foo', 'baz')) AND (price > 20.0)")
      .toArray();
    ```

### **Advanced SQL Filters**

If your column name contains special characters, upper-case characters, or is a [SQL Keyword](https://docs.rs/sqlparser/latest/sqlparser/keywords/index.html),
you can use backtick (`` ` ``) to escape it. For nested fields, each segment of the
path must be wrapped in backticks.

=== "SQL"

    ```sql
    `CUBE` = 10 AND `UpperCaseName` = '3' AND `column name with space` IS NOT NULL
    AND `nested with space`.`inner with space` < 2
    ```

!!! warning "Field Name Limitation"
    Field names containing periods (.) are NOT supported.

### **Dates, Timestamps, Decimals**

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

## **Apache Arrow Mapping**

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


## **Best Practices**

**Scalar Indexes**: We strongly recommend creating scalar indices on columns used for filtering, whether combined with a search operation or applied independently (e.g., for updates or deletions).

For best performance with large tables or high query volumes:

- Build a scalar index on frequently filtered columns
- Use exact column names in filters (e.g., `user_id` instead of `USER_ID`)
- Avoid complex transformations in filter expressions (keep them simple)
- When running concurrent queries, use connection pooling for better throughput

For a column of type LIST(T), you can use `LABEL_LIST` to create a scalar index. Then you should leverage DataFusion's [array functions](https://datafusion.apache.org/user-guide/sql/scalar_functions.html#array-functions) like `array_has_any` or `array_has_all` for optimized filtering.

## **Limitations**

Both **pre-filtering** and **post-filtering** can yield false positives. For pre-filtering, if the filter is too selective, it might eliminate relevant items that the vector search would have otherwise identified as a good match. In this case, increasing `nprobes` parameter will help reduce such false positives. It is recommended to call `bypass_vector_index()` if you know that the filter is highly selective.

Similarly, a highly selective post-filter can lead to false positives. Increasing both `nprobes` and `refine_factor` can mitigate this issue. When deciding between pre-filtering and post-filtering, pre-filtering is generally the safer choice if you're uncertain.