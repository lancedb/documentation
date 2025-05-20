---
title: "Building Indexes in LanceDB | Index Creation Guide"
description: "Learn how to build and optimize indexes in LanceDB. Includes vector indexes, scalar indexes, and best practices for index management."
---

# Building an Index with LanceDB

LanceDB provides a comprehensive suite of indexing strategies to optimize query performance across diverse workloads:

- **Vector Index**: Optimized for searching high-dimensional data (like images, audio, or text embeddings) by efficiently finding the most similar vectors
- **Scalar Index**: Accelerates filtering and sorting of structured numeric or categorical data (e.g., timestamps, prices)
- **Full-Text Search Index**: Enables fast keyword-based searches by indexing words and phrases

!!! tip
    Scalar indices serve as a foundational optimization layer, accelerating filtering across diverse search workloads. They can be combined with:

    - Vector search (prefilter or post-filter results using metadata)
    - Full-text search (combining keyword matching with structured filters) 
    - SQL scans (optimizing WHERE clauses on scalar columns)
    - Key-value lookups (enabling rapid primary key-based retrievals)


Compared to our open source version, LanceDB Cloud/Enterprise automates data indexing with low-latency, asynchronous indexing performed in the cloud:

- **Auto-Indexing**: Automates index optimization for all types of indices as soon as data is updated
- **Automatic Index Creation**: When a table contains a single vector column named `vector`, LanceDB automatically:
    - Infers the vector column from the table schema
    - Creates an optimized IVF-PQ index without manual configuration
- **Parameter Autotuning**: LanceDB analyzes your data distribution to automatically configure indexing parameters

## Vector Index

LanceDB implements state-of-the-art indexing algorithms ([IVF-PQ](https://lancedb.github.io/lancedb/concepts/index_ivfpq/) and [HNSW](https://lancedb.github.io/lancedb/concepts/index_hnsw/)) with acceleration from our optimized infrastructure. We support multiple distance metrics:

- L2 (default)
- Cosine
- Dot
- Hamming (for binary vectors only)

You can create multiple vector indices within a table.

!!! note

    The `create_index` API returns immediately, but the building of the vector index is asynchronous. To wait until all data is fully indexed, you can specify the`wait_timeout`parameter.

=== "Python"
    ```python
    import lancedb
    from datetime import timedelta

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    # Use the table from quickstart
    table_name = "lancedb-cloud-quickstart"
    table = db.open_table(table_name)

    # Create index with cosine similarity
    # Note: vector_column_name only needed for multiple vector columns or non-default names
    # Supported index types: IVF_PQ (default) and IVF_HNSW_SQ
    table.create_index(metric="cosine", vector_column_name="keywords_embeddings", wait_timeout=timedelta(seconds=60))
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    const tableName = "myTable"
    const table = await db.openTable(tableName);

    // Create index with cosine similarity
    // Note: vector_column_name only needed for multiple vector columns or non-default names
    // Supported index types: IVF_PQ (default) and IVF_HNSW_SQ
    await table.createIndex("keywords_embeddings", {
      config: lancedb.Index.ivfPq({
        distanceType: 'cosine'
      })
    });
    ```
!!! note

    - If your vector column is named `vector` and contains more than 256 vectors, an IVF_PQ index with L2 distance is automatically created
    - You can create a new index with different parameters using `create_index` - this replaces any existing index
    - When using cosine similarity, distances range from 0 (identical vectors) to 2 (maximally dissimilar)
    - Available index types:
        - `IVF_PQ`: Default index type, optimized for high-dimensional vectors
        - `IVF_HNSW_SQ`: Combines IVF clustering with HNSW graph for improved search quality

### Check Index Status

Vector index creation is fast - typically a few minutes for 1 million vectors with 1536 dimensions. You can check index status in two ways:

#### Option 1: Dashboard

Navigate to your table page - the "Index" column shows index status. It remains blank if no index exists or if creation is in progress.
![index_status](../assets/index_status.png)

#### Option 2: API

Use `list_indices()` and `index_stats()` to check index status. The index name is formed by appending "\_idx" to the column name. Note that `list_indices()` only returns information after the index is fully built.
To wait until all data is fully indexed, you can specify the `wait_timeout` parameter on `create_index()` or call `wait_for_index()` on the table.

=== "Python"
    ```python
    import time

    index_name = "keywords_embeddings_idx"
    table.wait_for_index([index_name])
    print(table.index_stats(index_name))
    # IndexStatistics(num_indexed_rows=3000, num_unindexed_rows=0, index_type='IVF_PQ', 
    #   distance_type='cosine', num_indices=None)
    ```

=== "TypeScript"
    ```typescript
    const indexName = "keywords_embeddings_idx"
    await table.waitForIndex([indexName], 60)
    console.log(await table.indexStats(indexName))
    // {
    //   numIndexedRows: 1000,
    //   numUnindexedRows: 0,
    //   indexType: 'IVF_PQ',
    //   distanceType: 'cosine'
    // }
    ```

### Index Binary Vectors

Binary vectors are useful for hash-based retrieval, fingerprinting, or any scenario where data can be represented as bits.

Key points for binary vectors:

- Store as fixed-size binary data (uint8 arrays, with 8 bits per byte)
- Use Hamming distance for similarity search
- Pack binary vectors into bytes to save space

!!! info

    The dimension of binary vectors must be a multiple of 8. For example, a 128-dimensional vector is stored as a uint8 array of size 16.

=== "Python"
    ```python
    import lancedb
    import numpy as np
    import pyarrow as pa

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    # Create schema with binary vector field
    table_name = "test-hamming"
    ndim = 256
    schema = pa.schema([
        pa.field("id", pa.int64()),
        # For dim=256, store every 8 bits in a byte (32 bytes total)
        pa.field("vector", pa.list_(pa.uint8(), 32)),
    ])

    table = db.create_table(table_name, schema=schema, mode="overwrite")

    # Generate and add data
    data = []
    for i in range(1024):
        vector = np.random.randint(0, 2, size=ndim)
        vector = np.packbits(vector)  # Optional: pack bits to save space
        data.append({"id": i, "vector": vector})
    table.add(data)

    # Create index with Hamming distance
    table.create_index(
        metric="hamming",
        vector_column_name="vector",
        index_type="IVF_FLAT"
    )

    # Search example
    query = np.random.randint(0, 2, size=256)
    query = np.packbits(query)
    df = table.search(query).metric("hamming").limit(10).to_pandas()
    df.vector = df.vector.apply(np.unpackbits)
    ```

=== "TypeScript"
    ```typescript
    // Create schema with binary vector field
    const binaryTableName = "test-hamming-ts";
    const ndim = 256;
    const bytesPerVector = ndim / 8; // 32 bytes for 256 bits

    const binarySchema = new Schema([
      new Field("id", new Int32(), true),
      new Field("vector", new FixedSizeList(32, new Field("item", new Uint8()))),
    ]);

    // Generate random binary vectors
    const data = makeArrowTable(
      Array(1_000).fill(0).map((_, i) => ({
        id: i,
        vector: packBits(Array(ndim).fill(0).map(() => Math.floor(Math.random() * 2))),
      })),
      { schema: binarySchema },
    );

    // Create and populate table
    const table = await db.createTable(binaryTableName, data);
    console.log(`Created table: ${binaryTableName}`);

    // Create index with Hamming distance
    console.log("Creating binary vector index...");
    await table.createIndex("vector", {
      config: Index.ivfFlat({
        distanceType: "hamming",
      }),
    });

    // Wait for index
    const binaryIndexName = "vector_idx";
    await table.waitForIndex([binaryIndexName], 60)

    // Generate query and search
    const query = packBits(Array(ndim).fill(0).map(() => Math.floor(Math.random() * 2)));
    console.log("Performing binary vector search...");
    const binaryResults = await table
      .query()
      .nearestTo(query)
      .limit(10)
      .toArray();

    // Unpack vectors for display
    const unpackedResults = binaryResults.map(row => ({
      ...row,
      vector: Array.from(row.vector)
    }));
    console.log("Binary vector search results:", unpackedResults);
    ```

!!! note
    `IVF_FLAT` with Hamming distance is used for indexing binary vectors.


OSS_________

# Build HNSW Index

There are three key parameters to set when constructing an HNSW index:

* `metric`: Use an `l2` euclidean distance metric. We also support `dot` and `cosine` distance.
* `m`: The number of neighbors to select for each vector in the HNSW graph.
* `ef_construction`: The number of candidates to evaluate during the construction of the HNSW graph.


We can combine the above concepts to understand how to build and query an HNSW index in LanceDB.

### Construct index

```python
import lancedb
import numpy as np
uri = "/tmp/lancedb"
db = lancedb.connect(uri)

# Create 10,000 sample vectors
data = [
    {"vector": row, "item": f"item {i}"}
    for i, row in enumerate(np.random.random((10_000, 1536)).astype('float32'))
]

# Add the vectors to a table
tbl = db.create_table("my_vectors", data=data)

# Create and train the HNSW index for a 1536-dimensional vector
# Make sure you have enough data in the table for an effective training step
tbl.create_index(index_type=IVF_HNSW_SQ)

```

### Query the index

```python
# Search using a random 1536-dimensional embedding
tbl.search(np.random.random((1536))) \
    .limit(2) \
    .to_pandas()
```


## Putting it all together

We can combine the above concepts to understand how to build and query an IVF-PQ index in LanceDB.

### Construct index

There are three key parameters to set when constructing an IVF-PQ index:

* `metric`: Use an `l2` euclidean distance metric. We also support `dot` and `cosine` distance.
* `num_partitions`: The number of partitions in the IVF portion of the index.
* `num_sub_vectors`: The number of sub-vectors that will be created during Product Quantization (PQ).

In Python, the index can be created as follows:

```python
# Create and train the index for a 1536-dimensional vector
# Make sure you have enough data in the table for an effective training step
tbl.create_index(metric="l2", num_partitions=256, num_sub_vectors=96)
```
!!! note
    `num_partitions`=256 and `num_sub_vectors`=96 does not work for every dataset. Those values needs to be adjusted for your particular dataset.

The `num_partitions` is usually chosen to target a particular number of vectors per partition. `num_sub_vectors` is typically chosen based on the desired recall and the dimensionality of the vector. See [here](../ann_indexes.md/#how-to-choose-num_partitions-and-num_sub_vectors-for-ivf_pq-index) for best practices on choosing these parameters.


### Query the index

```python
# Search using a random 1536-dimensional embedding
tbl.search(np.random.random((1536))) \
    .limit(2) \
    .nprobes(20) \
    .refine_factor(10) \
    .to_pandas()
```

The above query will perform a search on the table `tbl` using the given query vector, with the following parameters:

* `limit`: The number of results to return
* `nprobes`: The number of probes determines the distribution of vector space. While a higher number enhances search accuracy, it also results in slower performance. Typically, setting `nprobes` to cover 5–10% of the dataset proves effective in achieving high recall with minimal latency.
* `refine_factor`: Refine the results by reading extra elements and re-ranking them in memory. A higher number makes the search more accurate but also slower (see the [FAQ](../faq.md#do-i-need-to-set-a-refine-factor-when-using-an-index) page for more details on this).
* `to_pandas()`: Convert the results to a pandas DataFrame

And there you have it! You now understand what an IVF-PQ index is, and how to create and query it in LanceDB.
To see how to create an IVF-PQ index in LanceDB, take a look at the [ANN indexes](../ann_indexes.md) section.


