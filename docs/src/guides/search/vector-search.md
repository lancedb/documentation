---
title: "Vector Search in LanceDB | Search Implementation Guide"
description: "Learn how to implement vector search in LanceDB. Includes similarity search, nearest neighbor queries, and performance optimization."
---

# Vector Search with LanceDB 

A vector search finds the approximate or exact nearest neighbors to a given query vector.

- In a recommendation system or search engine, you can find similar records to
  the one you searched.
- In LLM and other AI applications,
  each data point can be represented by [embeddings generated from existing models](embeddings/index.md),
  following which the search returns the most relevant features.

## Distance metrics

Distance metrics are a measure of the similarity between a pair of vectors.
Currently, LanceDB supports the following metrics:

| Metric    | Description                                                                 |
| --------- | --------------------------------------------------------------------------- |
| `l2`      | [Euclidean / l2 distance](https://en.wikipedia.org/wiki/Euclidean_distance) |
| `cosine`  | [Cosine Similarity](https://en.wikipedia.org/wiki/Cosine_similarity)        |
| `dot`     | [Dot Production](https://en.wikipedia.org/wiki/Dot_product)                 |
| `hamming` | [Hamming Distance](https://en.wikipedia.org/wiki/Hamming_distance)          |

!!! note
    The `hamming` metric is only available for binary vectors.

## Exhaustive search (kNN)

If you do not create a vector index, LanceDB exhaustively scans the _entire_ vector space
and computes the distance to every vector in order to find the exact nearest neighbors. This is effectively a kNN search.

<!-- Setup Code
```python
import lancedb
import numpy as np
uri = "data/sample-lancedb"
db = lancedb.connect(uri)

data = [{"vector": row, "item": f"item {i}"}
     for i, row in enumerate(np.random.random((10_000, 1536)).astype('float32'))]

db.create_table("my_vectors", data=data)
```
-->

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:exhaustive_search"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:exhaustive_search_async"
        ```

=== "TypeScript"

    === "@lancedb/lancedb"

        ```ts
        --8<-- "nodejs/examples/search.test.ts:import"

        --8<-- "nodejs/examples/search.test.ts:search1"
        ```


    === "vectordb (deprecated)"

        ```ts
        --8<-- "docs/src/search_legacy.ts:import"

        --8<-- "docs/src/search_legacy.ts:search1"
        ```

By default, `l2` will be used as metric type. You can specify the metric type as
`cosine` or `dot` if required.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:exhaustive_search_cosine"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:exhaustive_search_async_cosine"
        ```

=== "TypeScript"

    === "@lancedb/lancedb"

        ```ts
        --8<-- "nodejs/examples/search.test.ts:search2"
        ```

    === "vectordb (deprecated)"

        ```javascript
        --8<-- "docs/src/search_legacy.ts:search2"
        ```

## Approximate nearest neighbor (ANN) search

To perform scalable vector retrieval with acceptable latencies, it's common to build a vector index.
While the exhaustive search is guaranteed to always return 100% recall, the approximate nature of
an ANN search means that using an index often involves a trade-off between recall and latency.

See the [IVF_PQ index](./concepts/index_ivfpq.md) for a deeper description of how `IVF_PQ`
indexes work in LanceDB.

## Binary vector

LanceDB supports binary vectors as a data type, and has the ability to search binary vectors with hamming distance. The binary vectors are stored as uint8 arrays (every 8 bits are stored as a byte):

!!! note
    The dim of the binary vector must be a multiple of 8. A vector of dim 128 will be stored as a uint8 array of size 16.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_binary_vector.py:imports"

        --8<-- "python/python/tests/docs/test_binary_vector.py:sync_binary_vector"
        ```

    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_binary_vector.py:imports"

        --8<-- "python/python/tests/docs/test_binary_vector.py:async_binary_vector"
        ```

    === "TypeScript"

        ```ts
        --8<-- "nodejs/examples/search.test.ts:import"

        --8<-- "nodejs/examples/search.test.ts:import_bin_util"

        --8<-- "nodejs/examples/search.test.ts:ingest_binary_data"

        --8<-- "nodejs/examples/search.test.ts:search_binary_data"
        ```


## Search with distance range

You can also search for vectors within a specific distance range from the query vector. This is useful when you want to find vectors that are not just the nearest neighbors, but also those that are within a certain distance. This can be done by using the `distance_range` method.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_distance_range.py:imports"

        --8<-- "python/python/tests/docs/test_distance_range.py:sync_distance_range"
        ```

    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_distance_range.py:imports"

        --8<-- "python/python/tests/docs/test_distance_range.py:async_distance_range"
        ```

=== "TypeScript"

    === "@lancedb/lancedb"

        ```ts
        --8<-- "nodejs/examples/search.test.ts:import"

        --8<-- "nodejs/examples/search.test.ts:distance_range"
        ```


## Output search results

LanceDB returns vector search results via different formats commonly used in python.
Let's create a LanceDB table with a nested schema:

=== "Python"
    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:import-datetime"
        --8<-- "python/python/tests/docs/test_search.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_search.py:import-lancedb-pydantic"
        --8<-- "python/python/tests/docs/test_search.py:import-numpy"
        --8<-- "python/python/tests/docs/test_search.py:import-pydantic-base-model"
        --8<-- "python/python/tests/docs/test_search.py:class-definition"
        --8<-- "python/python/tests/docs/test_search.py:create_table_with_nested_schema"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:import-datetime"
        --8<-- "python/python/tests/docs/test_search.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_search.py:import-lancedb-pydantic"
        --8<-- "python/python/tests/docs/test_search.py:import-numpy"
        --8<-- "python/python/tests/docs/test_search.py:import-pydantic-base-model"
        --8<-- "python/python/tests/docs/test_search.py:class-definition"
        --8<-- "python/python/tests/docs/test_search.py:create_table_async_with_nested_schema"
        ```

    ### As a PyArrow table

    Using `to_arrow()` we can get the results back as a pyarrow Table.
    This result table has the same columns as the LanceDB table, with
    the addition of an `_distance` column for vector search or a `score`
    column for full text search.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:search_result_as_pyarrow"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:search_result_async_as_pyarrow"
        ```

    ### As a Pandas DataFrame

    You can also get the results as a pandas dataframe.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:search_result_as_pandas"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:search_result_async_as_pandas"
        ```

    While other formats like Arrow/Pydantic/Python dicts have a natural
    way to handle nested schemas, pandas can only store nested data as a
    python dict column, which makes it difficult to support nested references.
    So for convenience, you can also tell LanceDB to flatten a nested schema
    when creating the pandas dataframe.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:search_result_as_pandas_flatten_true"
        ```

    If your table has a deeply nested struct, you can control how many levels
    of nesting to flatten by passing in a positive integer.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:search_result_as_pandas_flatten_1"
        ```
    !!! note
        `flatten` is not yet supported with our asynchronous client.

    ### As a list of Python dicts

    You can of course return results as a list of python dicts.

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:search_result_as_list"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:search_result_async_as_list"
        ```

    ### As a list of Pydantic models

    We can add data using Pydantic models, and we can certainly
    retrieve results as Pydantic models

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:search_result_as_pydantic"
        ```
    !!! note
        `to_pydantic()` is not yet supported with our asynchronous client.

    Note that in this case the extra `_distance` field is discarded since
    it's not part of the LanceSchema.

## Vector search with metadata prefiltering

=== "Python"
    ```python
    import lancedb
    from datasets import load_dataset

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    # Load query vector from dataset
    query_dataset = load_dataset("sunhaozhepy/ag_news_sbert_keywords_embeddings", split="test[5000:5001]")
    print(f"Query keywords: {query_dataset[0]['keywords']}")
    query_embed = query_dataset["keywords_embeddings"][0]

    # Open table and perform search
    table_name = "lancedb-cloud-quickstart"
    table = db.open_table(table_name)

    # Vector search with filters (pre-filtering is the default)
    search_results = (
        table.search(query_embed)
        .where("label > 2")
        .select(["text", "keywords", "label"])
        .limit(5)
        .to_pandas()
    )

    print("Search results (with pre-filtering):")
    print(search_results)
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb";

    // Connect to LanceDB
    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    // Generate a sample 768-dimension embedding vector (typical for BERT-based models)
    // In real applications, you would get this from an embedding model
    const dimensions = 768;
    const queryEmbed = Array.from({ length: dimensions }, () => Math.random() * 2 - 1);

    // Open table and perform search
    const tableName = "lancedb-cloud-quickstart";
    const table = await db.openTable(tableName);

    // Vector search with filters (pre-filtering is the default)
    const vectorResults = await table.search(queryEmbed)
      .where("label > 2")
      .select(["text", "keywords", "label"])
      .limit(5)
      .toArray();

    console.log("Search results (with pre-filtering):");
    console.log(vectorResults);
    ```

## Vector search with metadata postfiltering

By default, pre-filtering is performed to filter prior to vector search. This can be useful to narrow down the search space of a very large dataset to reduce query latency. Post-filtering is also an option that performs the filter on the results returned by the vector search. You can use post-filtering as follows:

=== "Python"
    ```python
    results_post_filtered = (
        table.search(query_embed)
        .where("label > 1", prefilter=False)
        .select(["text", "keywords", "label"])
        .limit(5)
        .to_pandas()
    )

    print("Vector search results with post-filter:")
    print(results_post_filtered)
    ```

=== "TypeScript"
    ```typescript
    const vectorResultsWithPostFilter = await (table.search(queryEmbed) as VectorQuery)
      .where("label > 2")
      .postfilter()
      .select(["text", "keywords", "label"])
      .limit(5)
      .toArray();

    console.log("Vector search results with post-filter:");
    console.log(vectorResultsWithPostFilter);
    ```

## Batch query

LanceDB can process multiple similarity search requests simultaneously in a single operation, rather than handling each query individually. 

=== "Python"
    ```python
    # Load a batch of query embeddings
    query_dataset = load_dataset(
        "sunhaozhepy/ag_news_sbert_keywords_embeddings", split="test[5000:5005]"
    )
    query_embeds = query_dataset["keywords_embeddings"]
    batch_results = table.search(query_embeds).limit(5).to_pandas()
    print(batch_results)
    ```

=== "TypeScript"
    ```typescript
     // Batch query
    console.log("Performing batch vector search...");
    const batchSize = 5;
    const queryVectors = Array.from(
      { length: batchSize },
      () => Array.from(
        { length: dimensions },
        () => Math.random() * 2 - 1,
      ),
    );
    let batchQuery = table.search(queryVectors[0]) as VectorQuery;
    for (let i = 1; i < batchSize; i++) {
      batchQuery = batchQuery.addQueryVector(queryVectors[i]);
    }
    const batchResults = await batchQuery
      .select(["text", "keywords", "label"])
      .limit(5)
      .toArray();
    console.log("Batch vector search results:");
    console.log(batchResults);
    ```

!!! info "Batch Query Results"
    When processing batch queries, the results include a `query_index` field 
    to explicitly associate each result set with its corresponding query in 
    the input batch. 

## Other search options

### Fast search

While vector indexing occurs asynchronously, newly added vectors are immediately 
searchable through a fallback brute-force search mechanism. This ensures zero 
latency between data insertion and searchability, though it may temporarily 
increase query response times. To optimize for speed over completeness, 
enable the `fast_search` flag in your query to skip searching unindexed data.

=== "Python"
    ```python
    # sync API
    table.search(embedding, fast_search=True).limit(5).to_pandas()

    # async API
    await table.query().nearest_to(embedding).fast_search().limit(5).to_pandas()
    ```

=== "TypeScript"
    ```typescript
    await table
      .query()
      .nearestTo(embedding)
      .fastSearch()
      .limit(5)
      .toArray();
    ```

### Bypass Vector Index

The bypass vector index feature prioritizes search accuracy over query speed by performing 
an exhaustive search across all vectors. Instead of using the approximate nearest neighbor 
(ANN) index, it compares the query vector against every vector in the table directly. 

While this approach increases query latency, especially with large datasets, it provides 
exact, ground-truth results. This is particularly useful when:
- Evaluating ANN index quality
- Calculating recall metrics to tune `nprobes` parameter
- Verifying search accuracy for critical applications
- Benchmarking approximate vs exact search results

=== "Python"
    ```python
    # sync API
    table.search(embedding).bypass_vector_index().limit(5).to_pandas()

    # async API
    await table.query().nearest_to(embedding).bypass_vector_index().limit(5).to_pandas()
    ```

=== "TypeScript"
    ```typescript
    await table
      .query()
      .nearestTo(embedding)
      .bypassVectorIndex()
      .limit(5)
      .toArray();
    ```
