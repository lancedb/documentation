---
title: "Multivector Search in LanceDB | Advanced Search Guide"
description: "Learn how to implement multivector search in LanceDB. Includes multiple vector fields, cross-modal search, and complex query patterns."
---

# **Multivector Search with LanceDB**

LanceDB's multivector support enables you to store and search multiple vector embeddings for a single item. This capability is particularly valuable when working with late interaction models like ColBERT and ColPaLi that generate multiple embeddings per document.

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/lancedb/vectordb-recipes/blob/main/examples/saas_examples/python_notebook/Multivector_on_LanceDB_Cloud.ipynb).

## **Multivector Support**

!!! note "Only in Python SDK"
    Multivector search is currently supported in our Python SDK. 

Each item in your dataset can have a column containing multiple vectors, which LanceDB can efficiently index and search. When performing a search, you can query using either a single vector embedding or multiple vector embeddings. 

LanceDB also integrates with [**ConteXtualized Token Retriever (XTR)**](https://arxiv.org/abs/2304.01982), an advanced retrieval model that prioritizes the most semantically important document tokens during search. This integration enhances the quality of search results by focusing on the most relevant token matches.

- Supported similarity metric: **Cosine similarity only**
- Vector value types: **float16, float32, or float64**

### **Computing Similarity**

MaxSim (Maximum Similarity) is a key concept in late interaction models that:

- Computes the maximum similarity between each query embedding and all document embeddings
- Sums these maximum similarities to get the final relevance score
- Effectively captures fine-grained semantic matches between query and document tokens

The MaxSim calculation can be expressed as:

![maxsim](../../assets/maxsim.png)

where `sim` is the similarity function (e.g. cosine).

!!! note "Distance Metric"

    For now, only `cosine` metric is supported for multivector search.
    The vector value type can be `float16`, `float32` or `float64`.

## **Example: Multivector Search**

### **1. Setup**

Connect to LanceDB and import required libraries for data management.

=== "Cloud"

    ```python
    import lancedb
    import numpy as np
    import pyarrow as pa

    db = lancedb.connect(
    uri="db://your-project-slug",
    api_key="your-api-key",
    region="your-cloud-region"
    )
    ```

=== "Open Source"

    ```python
    import lancedb
    import numpy as np
    import pyarrow as pa

    db = lancedb.connect("data/multivector_demo")
    ```

### **2. Define Schema**

Define a schema that specifies a multivector field. A multivector field is a nested list structure where each document contains multiple vectors. In this case, we'll create a schema with:

1. An ID field as an integer (int64)
2. A vector field that is a list of lists of float32 values
   - The outer list represents multiple vectors per document
   - Each inner list is a 256-dimensional vector
   - Using float32 for memory efficiency while maintaining precision

=== "Cloud"

    ```python
    db = lancedb.connect("data/multivector_demo")
    schema = pa.schema(
        [
            pa.field("id", pa.int64()),
            # float16, float32, and float64 are supported
            pa.field("vector", pa.list_(pa.list_(pa.float32(), 256))),
        ]
    )
    ```

=== "Open Source"

    === "Sync API"

        ```python
        db = lancedb.connect("data/multivector_demo")
        schema = pa.schema(
            [
                pa.field("id", pa.int64()),
                # float16, float32, and float64 are supported
                pa.field("vector", pa.list_(pa.list_(pa.float32(), 256))),
            ]
        )
        ```

    === "Aync API"

        ```python
        db = await lancedb.connect_async("data/multivector_demo")
        schema = pa.schema(
            [
                pa.field("id", pa.int64()),
                # float16, float32, and float64 are supported
                pa.field("vector", pa.list_(pa.list_(pa.float32(), 256))),
            ]
        )
        ```
        
### **3. Generate Multivectors**

Generate sample data where each document contains multiple vector embeddings, which could represent different aspects or views of the same document. 

In this example, we create **1024 documents** where each document has **2 random vectors** of **dimension 256**, simulating a real-world scenario where you might have multiple embeddings per item.

=== "Cloud"

    ```python
    data = [
        {
            "id": i,
            "vector": np.random.random(size=(2, 256)).tolist(),  # Each document has 2 vectors
        }
        for i in range(1024)
    ]
    ```

=== "Open Source"

    === "Sync API"

        ```python
        data = [
            {
                "id": i,
                "vector": np.random.random(size=(2, 256)).tolist(),  # Each document has 2 vectors
            }
            for i in range(1024)
        ]
        ```
        
    === "Aync API"

        ```python
        data = [
            {
                "id": i,
                "vector": np.random.random(size=(2, 256)).tolist(),
            }
            for i in range(1024)
        ]
        ```

### **4. Create a Table**

Create a table with the defined schema and sample data, which will store multiple vectors per document for similarity search.

=== "Cloud"

    ```python
    tbl = db.create_table("multivector_example", data=data, schema=schema)
    ```

=== "Open Source"

    === "Sync API"

        ```python
        tbl = db.create_table("multivector_example", data=data, schema=schema)
        ```
        
    === "Aync API"

        ```python
        tbl = await db.create_table("my_table", data=data, schema=schema)
        ```

### **5. Build an Index**

Only cosine similarity is supported as the distance metric for multivector search operations. 
For faster search, build the standard `IVF_PQ` index over your vectors:

=== "Cloud"

    ```python
    tbl.create_index(metric="cosine", vector_column_name="vector")
    ```

=== "Open Source"

    === "Sync API"

        ```python
        tbl.create_index(metric="cosine", vector_column_name="vector")
        ```
        
    === "Aync API"

        ```python
        await tbl.create_index(column="vector", config=IvfPq(distance_type="cosine"))
        ```

### **6. Query a Single Vector**

When searching with a single query vector, it will be compared against all vectors in each document, and the similarity scores will be aggregated to find the most relevant documents.

=== "Cloud"

    ```python
    query = np.random.random(256)
    results_single = tbl.search(query).limit(5).to_pandas()
    ```

=== "Open Source"

    === "Sync API"

        ```python
        query = np.random.random(256)
        results_single = tbl.search(query).limit(5).to_pandas()
        ```
        
    === "Aync API"

        ```python
        query = np.random.random(256)
        await tbl.query().nearest_to(query).to_arrow()
        ```

### **7. Query Multiple Vectors**

With multiple vector queries, LanceDB calculates similarity using late interaction - a technique that computes relevance by finding the best matching pairs between query and document vectors. This approach provides more nuanced matching while maintaining fast retrieval speeds.

=== "Cloud"

    ```python
    query_multi = np.random.random(size=(2, 256))
    results_multi = tbl.search(query_multi).limit(5).to_pandas()
    ```

=== "Open Source"

    === "Sync API"

        ```python
        query_multi = np.random.random(size=(2, 256))
        results_multi = tbl.search(query_multi).limit(5).to_pandas()
        ```
        
    === "Aync API"

        ```python
        query = np.random.random(size=(2, 256))
        await tbl.query().nearest_to(query).to_arrow()
        ```

## **What's Next?**

If you still need more guidance, you can try the complete [**Multivector Search Notebook**](https://colab.research.google.com/github/lancedb/vectordb-recipes/blob/main/examples/saas_examples/python_notebook/Multivector_on_LanceDB_Cloud.ipynb).

For advanced users, we prepared a [**Tutorial on ColPali and LanceDB**](/docs/notebooks/Multivector_on_LanceDB/).



