---
title: "Multivector Search in LanceDB Enterprise | Advanced Search Guide"
description: "Learn how to implement multivector search in LanceDB Enterprise. Includes multiple vector fields, cross-modal search, and complex query patterns."
---

# Multivector Search with LanceDB Enterprise

A complete example for Multivector search is in this [notebook](https://colab.research.google.com/github/lancedb/vectordb-recipes/blob/main/examples/saas_examples/python_notebook/Multivector_on_LanceDB_Cloud.ipynb)

## Multivector Type

LanceDB natively supports multivector data types, enabling advanced search scenarios where 
a single data item is represented by multiple embeddings (e.g., using models like ColBERT 
or CoLPali). In this framework, documents and queries are encoded as collections of 
contextualized vectors—precomputed for documents and indexed for queries.

Key features:
- Indexing on multivector column: store and index multiple vectors per row.
- Supporint query being a single vector or multiple vectors
- Optimized search performance with [XTR](https://arxiv.org/abs/2501.17788) with improved recall.

!!! info "Multivector Search Limitations"
    Currently, only the `cosine` metric is supported for multivector search. 
    The vector value type can be `float16`, `float32`, or `float64`.

## Using Multivector in Python

Currently, multivector search is only support in our Python SDK. 
Below is an example of using multivector search in LanceDB:

```python
import lancedb
import numpy as np
import pyarrow as pa

# Connect to LanceDB Cloud
db = lancedb.connect(
  uri="db://your-project-slug",
  api_key="your-api-key",
  region="your-cloud-region"
)

# Define schema with multivector field
schema = pa.schema(
    [
        pa.field("id", pa.int64()),
        # float16, float32, and float64 are supported
        pa.field("vector", pa.list_(pa.list_(pa.float32(), 256))),
    ]
)

# Create data with multiple vectors per document
data = [
    {
        "id": i,
        "vector": np.random.random(size=(2, 256)).tolist(),  # Each document has 2 vectors
    }
    for i in range(1024)
]

# Create table
tbl = db.create_table("multivector_example", data=data, schema=schema)

# Create index - only cosine similarity is supported for multi-vectors
tbl.create_index(metric="cosine", vector_column_name="vector")

# Query with a single vector
query = np.random.random(256)
results_single = tbl.search(query).limit(5).to_pandas()

# Query with multiple vectors
query_multi = np.random.random(size=(2, 256))
results_multi = tbl.search(query_multi).limit(5).to_pandas()


---
title: Multivector Search in LanceDB | Advanced Vector Operations
description: Learn how to use LanceDB's multi-vector search capabilities for complex vector operations. Includes support for multiple vectors per item, late interaction techniques, and advanced search strategies.
---

# Multivector Search in LanceDB

Late interaction is a technique used in retrieval that calculates the relevance of a query to a document by comparing their multi-vector representations. The key difference between late interaction and other popular methods:

![late interaction vs other methods](https://raw.githubusercontent.com/lancedb/assets/b035a0ceb2c237734e0d393054c146d289792339/docs/assets/integration/colbert-blog-interaction.svg)


[ Illustration from https://jina.ai/news/what-is-colbert-and-late-interaction-and-why-they-matter-in-search/]

<b>No interaction:</b> Refers to independently embedding the query and document, that are compared to calcualte similarity without any interaction between them. This is typically used in vector search operations.

<b>Partial interaction</b> Refers to a specific approach where the similarity computation happens primarily between query vectors and document vectors, without extensive interaction between individual components of each. An example of this is dual-encoder models like BERT.

<b>Early full interaction</b> Refers to techniques like cross-encoders that process query and docs in pairs with full interaction across various stages of encoding. This is a powerful, but relatively slower technique. Because it requires processing query and docs in pairs, doc embeddings can't be pre-computed for fast retrieval. This is why cross encoders are typically used as reranking models combined with vector search. Learn more about [LanceDB Reranking support](https://lancedb.github.io/lancedb/reranking/).

<b>Late interaction</b> Late interaction is a technique that calculates the doc and query similarity independently and then the interaction or evaluation happens during the retrieval process. This is typically used in retrieval models like ColBERT. Unlike early interaction, It allows speeding up the retrieval process without compromising the depth of semantic analysis.

## Internals of ColBERT 
Let's take a look at the steps involved in performing late interaction based retrieval using ColBERT:

• ColBERT employs BERT-based encoders for both queries `(fQ)` and documents `(fD)`
• A single BERT model is shared between query and document encoders and special tokens distinguish input types: `[Q]` for queries and `[D]` for documents

**Query Encoder (fQ):**
• Query q is tokenized into WordPiece tokens: `q1, q2, ..., ql`. `[Q]` token is prepended right after BERT's `[CLS]` token
• If query length < Nq, it's padded with [MASK] tokens up to Nq.
• The padded sequence goes through BERT's transformer architecture
• Final embeddings are L2-normalized.

**Document Encoder (fD):**
• Document d is tokenized into tokens `d1, d2, ..., dm`. `[D]` token is prepended after `[CLS]` token
• Unlike queries, documents are NOT padded with `[MASK]` tokens
• Document tokens are processed through BERT and the same linear layer

**Late Interaction:**
• Late interaction estimates relevance score `S(q,d)` using embedding `Eq` and `Ed`. Late interaction happens after independent encoding
• For each query embedding, maximum similarity is computed against all document embeddings
• The similarity measure can be cosine similarity or squared L2 distance

**MaxSim Calculation:**
```
S(q,d) := Σ max(Eqi⋅EdjT)
          i∈|Eq| j∈|Ed|
```
• This finds the best matching document embedding for each query embedding
• Captures relevance based on strongest local matches between contextual embeddings

## LanceDB Multi Vector Type

LanceDB supports multivector type, this is useful when you have multiple vectors for a single item (e.g. with ColBert and ColPali).

You can index on a column with multivector type and search on it, the query can be single vector or multiple vectors. For now, only cosine metric is supported for multivector search. The vector value type can be float16, float32 or float64. LanceDB integrateds [ConteXtualized Token Retriever(XTR)](https://arxiv.org/abs/2304.01982), which introduces a simple, yet novel, objective function that encourages the model to retrieve the most important document tokens first. 

```python
import lancedb
import numpy as np
import pyarrow as pa

db = lancedb.connect("data/multivector_demo")
schema = pa.schema(
    [
        pa.field("id", pa.int64()),
        # float16, float32, and float64 are supported
        pa.field("vector", pa.list_(pa.list_(pa.float32(), 256))),
    ]
)
data = [
    {
        "id": i,
        "vector": np.random.random(size=(2, 256)).tolist(),
    }
    for i in range(1024)
]
tbl = db.create_table("my_table", data=data, schema=schema)

# only cosine similarity is supported for multi-vectors
tbl.create_index(metric="cosine")

# query with single vector
query = np.random.random(256).astype(np.float16)
tbl.search(query).to_arrow()

# query with multiple vectors
query = np.random.random(size=(2, 256))
tbl.search(query).to_arrow()
```
Find more about vector search in LanceDB [here](https://lancedb.github.io/lancedb/search/#multivector-type).

## Multivector type

LanceDB supports multivector type, this is useful when you have multiple vectors for a single item (e.g. with ColBert and ColPali).

You can index on a column with multivector type and search on it, the query can be single vector or multiple vectors. If the query is multiple vectors `mq`, the similarity (distance) from it to any multivector `mv` in the dataset, is defined as:

![maxsim](assets/maxsim.png)

where `sim` is the similarity function (e.g. cosine).

For now, only `cosine` metric is supported for multivector search.
The vector value type can be `float16`, `float32` or `float64`.

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_multivector.py:imports"

        --8<-- "python/python/tests/docs/test_multivector.py:sync_multivector"
        ```

    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_multivector.py:imports"

        --8<-- "python/python/tests/docs/test_multivector.py:async_multivector"
        ```