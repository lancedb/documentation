---
title: Getting Started with LanceDB | Quick Start Guide
description: Start using LanceDB with this comprehensive guide. Learn core concepts, installation, basic operations, and best practices for vector database management.
alias: quickstart
---

# **Getting Started with LanceDB: Basic Usage** 

In this section, you'll learn basic operations [**in Python, TypeScript, and Rust SDKs**](../api/index.md). 

For the **LanceDB Cloud/Enterprise** API Reference, check the [**HTTP REST API Specification**](../api/cloud.md).

## **Installation Options**

=== "Python"

      ```shell
      pip install lancedb
      ```

=== "TypeScript"

    ```shell
    npm install @lancedb/lancedb
    ```
    !!! note "Bundling `@lancedb/lancedb` apps with Webpack"

        Since LanceDB contains a prebuilt Node binary, you must configure `next.config.js` to exclude it from webpack. This is required for both using Next.js and deploying a LanceDB app on Vercel.

        ```javascript
        /** @type {import('next').NextConfig} */
        module.exports = ({
        webpack(config) {
            config.externals.push({ '@lancedb/lancedb': '@lancedb/lancedb' })
            return config;
        }
        })
        ```

    !!! note "Yarn users"

        Unlike other package managers, Yarn does not automatically resolve peer dependencies. If you are using Yarn, you will need to manually install 'apache-arrow':

        ```shell
        yarn add apache-arrow
        ```

=== "Rust"

    ```shell
    cargo add lancedb
    ```

    !!! info "To use the lancedb crate, you first need to install protobuf."

    === "macOS"

        ```shell
        brew install protobuf
        ```

    === "Ubuntu/Debian"

        ```shell
        sudo apt install -y protobuf-compiler libssl-dev
        ```

    !!! info "Please also make sure you're using the same version of Arrow as in the [lancedb crate](https://github.com/lancedb/lancedb/blob/main/Cargo.toml)"

### **Preview Releases**

Stable releases are created about every 2 weeks. For the latest features and bug
fixes, you can install the **Preview Release**. These releases receive the same
level of testing as stable releases but are not guaranteed to be available for
more than 6 months after they are released. Once your application is stable, we
recommend switching to stable releases.

=== "Python"

      ```shell
      pip install --pre --extra-index-url https://pypi.fury.io/lancedb/ lancedb
      ```

=== "TypeScript"

    ```shell
    npm install @lancedb/lancedb@preview
    ```

=== "Rust"

    We don't push Preview Releases to crates.io, but you can reference the tag
    in GitHub within your Cargo dependencies:

    ```toml
    [dependencies]
    lancedb = { git = "https://github.com/lancedb/lancedb.git", tag = "vX.Y.Z-beta.N" }
    ```

## **Useful Libraries**

For this tutorial, we use some common libraries to help us work with data.

=== "Python"
    
    ```python
    import lancedb
    import pandas as pd
    import numpy as np
    import pyarrow as pa
    import os
    ```

=== "TypeScript"

    ```typescript
    import { connect, Index, Table } from '@lancedb/lancedb';
    import { FixedSizeList, Field, Float32, Schema, Utf8 } from 'apache-arrow';
    ```

## **Connect to LanceDB**

### **LanceDB Cloud / Enterprise** 

[Don't forget to get your Cloud API key here!](https://accounts.lancedb.com/sign-up) The database cluster is free and serverless.

=== "Python"

    === "Cloud"

        ```python
        uri = "db://your-database-uri"
        api_key = "your-api-key"
        region = "us-east-1"
        ```
        
    === "Enterprise"

        ```python
        host_override = os.environ.get("LANCEDB_HOST_OVERRIDE")

        db = lancedb.connect(
        uri=uri,
        api_key=api_key,
        region=region,
        host_override=host_override
        )
        ```

=== "TypeScript"

    === "Cloud"

        ```typescript
        const dbUri = process.env.LANCEDB_URI || 'db://your-database-uri';
        const apiKey = process.env.LANCEDB_API_KEY;
        const region = process.env.LANCEDB_REGION;
        ```

    === "Enterprise"

        ```typescript
        const hostOverride = process.env.LANCEDB_HOST_OVERRIDE;

        const db = await connect(dbUri, { 
        apiKey,
        region,
        hostOverride
        });
        ```

### **LanceDB OSS**

=== "Python"
    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:set_uri"
        --8<-- "python/python/tests/docs/test_basic.py:connect"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:set_uri"
        --8<-- "python/python/tests/docs/test_basic.py:connect_async"
        ```

=== "TypeScript"

    ```typescript
    import * as lancedb from "@lancedb/lancedb";
    import * as arrow from "apache-arrow";

    --8<-- "nodejs/examples/basic.test.ts:connect"
    ```

=== "Rust"

    ```rust
    #[tokio::main]
    async fn main() -> Result<()> {
        --8<-- "rust/lancedb/examples/simple.rs:connect"
    }
    ```

    !!! info "See [examples/simple.rs](https://github.com/lancedb/lancedb/tree/main/rust/lancedb/examples/simple.rs) for a full working example."

LanceDB will create the directory if it doesn't exist (including parent directories).

If you need a reminder of the URI, you can call `db.uri()`.

## **Tables**

### **Create a Table From Data**

If you have data to insert into the table at creation time, you can simultaneously create a
table and insert the data into it. The schema of the data will be used as the schema of the
table.

=== "Python"

    If the table already exists, LanceDB will raise an error by default.
    If you want to overwrite the table, you can pass in `mode="overwrite"`
    to the `create_table` method.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:create_table"
        ```

        You can also pass in a pandas DataFrame directly:

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:create_table_pandas"
        ```

    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:create_table_async"
        ```

        You can also pass in a pandas DataFrame directly:

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:create_table_async_pandas"
        ```

=== "TypeScript"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:create_table"
    ```

=== "Rust"

    ```rust
    --8<-- "rust/lancedb/examples/simple.rs:create_table"
    ```

    If the table already exists, LanceDB will raise an error by default. See
    [the mode option](https://docs.rs/lancedb/latest/lancedb/connection/struct.CreateTableBuilder.html#method.mode)
    for details on how to overwrite (or open) existing tables instead.

    !!! Providing table records in Rust

        The Rust SDK currently expects data to be provided as an Arrow
        [RecordBatchReader](https://docs.rs/arrow-array/latest/arrow_array/trait.RecordBatchReader.html)
        Support for additional formats (such as serde or polars) is on the roadmap.

!!! info "Under the hood, LanceDB reads in the Apache Arrow data and persists it to disk using the [Lance format](https://www.github.com/lancedb/lance)."

!!! info "Automatic embedding generation with Embedding API"
    When working with embedding models, you should use the LanceDB Embedding API to automatically create vector representations of the data and queries in the background. See the [**Embedding Guide**](../embeddings/index.md) for more detail.

### **Create an Empty Table**

Sometimes you may not have the data to insert into the table at creation time.
In this case, you can create an empty table and specify the schema, so that you can add
data to the table at a later time (as long as it conforms to the schema). This is
similar to a `CREATE TABLE` statement in SQL.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:create_empty_table"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:create_empty_table_async"
        ```

    !!! note "You can define schema in Pydantic"
        LanceDB comes with Pydantic support, which lets you define the schema of your data using Pydantic models. This makes it easy to work with LanceDB tables and data. Learn more about all supported types in the [tables guide](./guides/tables.md).

=== "TypeScript"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:create_empty_table"
    ```

=== "Rust"

    ```rust
    --8<-- "rust/lancedb/examples/simple.rs:create_empty_table"
    ```

### **Open a Table**

Once created, you can open a table as follows:

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:open_table"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:open_table_async"
        ```

=== "TypeScript"
    
    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:open_table"
    ```

=== "Rust"

    ```rust
    --8<-- "rust/lancedb/examples/simple.rs:open_existing_tbl"
    ```

### **List Tables**

If you forget your table's name, you can always get a listing of all table names:

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:table_names"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:table_names_async"
        ```

=== "TypeScript"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:table_names"
    ```

=== "Rust"

    ```rust
    --8<-- "rust/lancedb/examples/simple.rs:list_names"
    ```

### **Drop Table**

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
    By default, if the table does not exist, an exception is raised. To suppress this,
    you can pass in `ignore_missing=True`.

=== "TypeScript"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:drop_table"
    ```

=== "Rust"

    ```rust
    --8<-- "rust/lancedb/examples/simple.rs:drop_table"
    ```

## **Data**

LanceDB supports data in several formats: `pyarrow`, `pandas`, `polars` and `pydantic`. You can also work with regular python lists & dictionaries, as well as json and csv files.


### **Add Data to a Table**

The data will be appended to the existing table. By default, data is added in append mode, but you can also use `mode="overwrite"` to replace existing data.

!!! note "Key things to remember"

    - Vector columns must have consistent dimensions
    - Schema must match the table's schema
    - Data types must be compatible
    - Null values are supported for optional fields

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:add_data"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:add_data_async"
        ```

=== "TypeScript"
    === "@lancedb/lancedb"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:add_data"
    ```

=== "Rust"

    ```rust
    --8<-- "rust/lancedb/examples/simple.rs:add"
    ```

### **Delete Rows**

Use the `delete()` method on tables to delete rows from a table. To choose
which rows to delete, provide a filter that matches on the metadata columns.
This can delete any number of rows that match the filter.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:delete_rows"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:delete_rows_async"
        ```

=== "TypeScript"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:delete_rows"
    ```

=== "Rust"

    ```rust
    --8<-- "rust/lancedb/examples/simple.rs:delete"
    ```

The deletion predicate is a SQL expression that supports the same expressions
as the `where()` clause (`only_if()` in Rust) on a search. They can be as
simple or complex as needed. To see what expressions are supported, see the
[SQL filters](sql.md) section.

=== "Python"

    === "Sync API"
        Read more: [lancedb.table.Table.delete][]
    === "Async API"
        Read more: [lancedb.table.AsyncTable.delete][]

=== "TypeScript"

    Read more: [lancedb.Table.delete](javascript/interfaces/Table.md#delete)

=== "Rust"

    Read more: [lancedb::Table::delete](https://docs.rs/lancedb/latest/lancedb/table/struct.Table.html#method.delete)

## **Vector Search**

Once you've embedded the query, you can find its nearest neighbors as follows. LanceDB uses L2 (Euclidean) distance by default, but supports other distance metrics like cosine similarity and dot product.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:vector_search"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:vector_search_async"
        ```

    This returns a pandas DataFrame with the results.

=== "TypeScript"
    
    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:vector_search"
    ```

=== "Rust"

    ```rust
    use futures::TryStreamExt;

    --8<-- "rust/lancedb/examples/simple.rs:search"
    ```

    !!! Query vectors in Rust
        Rust does not yet support automatic execution of embedding functions. You will need to calculate embeddings yourself. Support for this is on the roadmap and can be tracked at https://github.com/lancedb/lancedb/issues/994

        Query vectors can be provided as Arrow arrays or a Vec/slice of Rust floats.
        Support for additional formats (e.g. `polars::series::Series`) is on the roadmap.


## **Build an Index**

By default, LanceDB runs a brute-force scan over the dataset to find the K nearest neighbors (KNN). For larger datasets, this can be computationally expensive.

**Indexing Threshold:** If your table has more than **50,000 vectors**, you should create an ANN index to speed up search performance. The index uses IVF (Inverted File) partitioning to reduce the search space.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:create_index"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_basic.py:create_index_async"
        ```

=== "TypeScript"

    ```typescript
    --8<-- "nodejs/examples/basic.test.ts:create_index"
    ```

=== "Rust"

    ```rust
    --8<-- "rust/lancedb/examples/simple.rs:create_index"
    ```

!!! question "Why is index creation manual?"
    LanceDB does not automatically create the ANN index for two reasons. **First**, it's optimized for really fast retrievals via a disk-based index, and **second**, data and query workloads can be very diverse, so there's no one-size-fits-all index configuration. LanceDB provides many parameters to fine-tune index size, query latency, and accuracy.

## **Embedding Data**

You can use the Embedding API when working with embedding models. It automatically vectorizes the data at ingestion and query time and comes with built-in integrations with popular embedding models like OpenAI, Hugging Face, Sentence Transformers, CLIP, and more.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_embeddings_optional.py:imports"

        --8<-- "python/python/tests/docs/test_embeddings_optional.py:openai_embeddings"
        ```
    === "Async API"

        Coming soon to the async API.
        https://github.com/lancedb/lancedb/issues/1938

=== "TypeScript"

    === "@lancedb/lancedb"

        ```typescript
        --8<-- "nodejs/examples/embedding.test.ts:imports"
        --8<-- "nodejs/examples/embedding.test.ts:openai_embeddings"
        ```

=== "Rust"

    ```rust
    --8<-- "rust/lancedb/examples/openai.rs:imports"
    --8<-- "rust/lancedb/examples/openai.rs:openai_embeddings"
    ```

Learn about using the existing integrations and creating custom embedding functions in the [**Embedding Guide**](../embeddings/index.md).

## **What's Next?**

This section covered the very basics of using LanceDB. 

We've prepared another example to teach you about [**working with whole datasets**](datasets.md).

To learn more about vector databases, you may want to read about [**Indexing**](../concepts/indexing.md) to get familiar with the concepts.

If you've already worked with other vector databases, dive into the [**Table Guide**](../guides/tables/index.md) to learn how to work with LanceDB in more detail.

