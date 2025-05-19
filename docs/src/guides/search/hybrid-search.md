---
title: "Hybrid Search in LanceDB | Combined Search Guide"
description: "Learn how to implement hybrid search in LanceDB. Includes combining vector and keyword search, reranking, and optimizing search results."
---

# Hybrid Search with LanceDB

We support hybrid search that combines semantic and full-text search via a 
reranking algorithm of your choice, to get the best of both worlds. LanceDB 
comes with [built-in rerankers](https://lancedb.github.io/lancedb/reranking/) 
and you can implement you own _customized reranker_ as well. 

Explore the complete hybrid search example in our guided walkthroughs: 
- [Python notebook](https://colab.research.google.com/github/lancedb/vectordb-recipes/blob/main/examples/saas_examples/python_notebook/Hybrid_search.ipynb) 
- [TypeScript example](https://github.com/lancedb/vectordb-recipes/tree/main/examples/saas_examples/ts_example/hybrid-search)

=== "Python"
    ```python
    import os

    import lancedb
    import openai
    from lancedb.embeddings import get_registry
    from lancedb.pydantic import LanceModel, Vector
    from lancedb.rerankers import RRFReranker

    # connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    # Configuring the environment variable OPENAI_API_KEY
    if "OPENAI_API_KEY" not in os.environ:
        # OR set the key here as a variable
        openai.api_key = "sk-..."
    embeddings = get_registry().get("openai").create()

    # Define schema for documents with embeddings
    class Documents(LanceModel):
        text: str = embeddings.SourceField()
        vector: Vector(embeddings.ndims()) = embeddings.VectorField()

    # Create a table with the defined schema
    table_name = "hybrid_search_example"
    table = db.create_table(table_name, schema=Documents, mode="overwrite")

    # Add sample data
    data = [
        {"text": "rebel spaceships striking from a hidden base"},
        {"text": "have won their first victory against the evil Galactic Empire"},
        {"text": "during the battle rebel spies managed to steal secret plans"},
        {"text": "to the Empire's ultimate weapon the Death Star"},
    ]
    table.add(data=data)

    table.create_fts_index("text")

    # Wait for indexes to be ready
    wait_for_index(table, "text_idx")

    # Create a reranker for hybrid search
    reranker = RRFReranker()

    # Perform hybrid search with reranking
    results = (
        table.search(
            "flower moon",
            query_type="hybrid",
            vector_column_name="vector",
            fts_columns="text",
        )
        .rerank(reranker)
        .limit(10)
        .to_pandas()
    )

    print("Hybrid search results:")
    print(results)
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb";
    import "@lancedb/lancedb/embedding/openai";
    import { Utf8 } from "apache-arrow";

    if (!process.env.OPENAI_API_KEY) {
      console.log("Skipping hybrid search - OPENAI_API_KEY not set");
      return { success: true, message: "Skipped: OPENAI_API_KEY not set" };
    }
    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1",
    });

    const embedFunc = lancedb.embedding.getRegistry().get("openai")?.create({
      model: "text-embedding-ada-002",
    }) as lancedb.embedding.EmbeddingFunction;

    // Define schema for documents with embeddings
    const documentSchema = lancedb.embedding.LanceSchema({
      text: embedFunc.sourceField(new Utf8()),
      vector: embedFunc.vectorField(),
    });

    // Create a table with the defined schema
    const tableName = "hybrid_search_example";
    const table = await db.createEmptyTable(tableName, documentSchema, {
      mode: "overwrite",
    });

    // Add sample data
    const data = [
      { text: "rebel spaceships striking from a hidden base" },
      { text: "have won their first victory against the evil Galactic Empire" },
      { text: "during the battle rebel spies managed to steal secret plans" },
      { text: "to the Empire's ultimate weapon the Death Star" },
    ];
    await table.add(data);
    console.log(`Created table: ${tableName} with ${data.length} rows`);

    // Create full-text search index
    console.log("Creating full-text search index...");
    await table.createIndex("text", {
      config: lancedb.Index.fts(),
    });

    // Wait for the index to be ready
    await waitForIndex(table as any, "text_idx");

    // Perform hybrid search
    console.log("Performing hybrid search...");
    const queryVector =
      await embedFunc.computeQueryEmbeddings("full moon in May");
    const hybridResults = await table
      .query()
      .fullTextSearch("flower moon")
      .nearestTo(queryVector)
      .rerank(await lancedb.rerankers.RRFReranker.create())
      .select(["text"])
      .limit(10)
      .toArray();

    console.log("Hybrid search results:");
    console.log(hybridResults);
    

---
title: Hybrid Search in LanceDB | Vector & Keyword Search Guide
description: Learn how to implement hybrid search in LanceDB by combining vector and keyword-based search. Includes examples for reranking, score normalization, and best practices for search optimization.
---

# Hybrid Search

LanceDB supports both semantic and keyword-based search (also termed full-text search, or FTS). In real world applications, it is often useful to combine these two approaches to get the best best results. For example, you may want to search for a document that is semantically similar to a query document, but also contains a specific keyword. This is an example of *hybrid search*, a search algorithm that combines multiple search techniques.

## Hybrid search in LanceDB
You can perform hybrid search in LanceDB by combining the results of semantic and full-text search via a reranking algorithm of your choice. LanceDB provides multiple rerankers out of the box. However, you can always write a custom reranker if your use case need more sophisticated logic .

=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:import-os"
    --8<-- "python/python/tests/docs/test_search.py:import-openai"
    --8<-- "python/python/tests/docs/test_search.py:import-lancedb"
    --8<-- "python/python/tests/docs/test_search.py:import-embeddings"
    --8<-- "python/python/tests/docs/test_search.py:import-pydantic"
    --8<-- "python/python/tests/docs/test_search.py:import-lancedb-fts"
    --8<-- "python/python/tests/docs/test_search.py:import-openai-embeddings"
    --8<-- "python/python/tests/docs/test_search.py:class-Documents"
    --8<-- "python/python/tests/docs/test_search.py:basic_hybrid_search"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:import-os"
    --8<-- "python/python/tests/docs/test_search.py:import-openai"
    --8<-- "python/python/tests/docs/test_search.py:import-lancedb"
    --8<-- "python/python/tests/docs/test_search.py:import-embeddings"
    --8<-- "python/python/tests/docs/test_search.py:import-pydantic"
    --8<-- "python/python/tests/docs/test_search.py:import-lancedb-fts"
    --8<-- "python/python/tests/docs/test_search.py:import-openai-embeddings"
    --8<-- "python/python/tests/docs/test_search.py:class-Documents"
    --8<-- "python/python/tests/docs/test_search.py:basic_hybrid_search_async"
    ```

!!! Note
    You can also pass the vector and text query manually. This is useful if you're not using the embedding API or if you're using a separate embedder service.
### Explicitly passing the vector and text query
=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:hybrid_search_pass_vector_text"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:hybrid_search_pass_vector_text_async"
    ```

By default, LanceDB uses `RRFReranker()`, which uses reciprocal rank fusion score, to combine and rerank the results of semantic and full-text search. You can customize the hyperparameters as needed or write your own custom reranker. Here's how you can use any of the available rerankers:


### `rerank()` arguments
* `normalize`: `str`, default `"score"`:
    The method to normalize the scores. Can be "rank" or "score". If "rank", the scores are converted to ranks and then normalized. If "score", the scores are normalized directly.
* `reranker`: `Reranker`, default `RRF()`.
    The reranker to use. If not specified, the default reranker is used.


## Available Rerankers
LanceDB provides a number of rerankers out of the box. You can use any of these rerankers by passing them to the `rerank()` method. 
Go to [Rerankers](../reranking/index.md) to learn more about using the available rerankers and implementing custom rerankers.


