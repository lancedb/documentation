# **Getting Started with LanceDB**

![LanceDB Hero Image](../assets/quickstart/quickstart.png)

This is a minimal tutorial for Python users. In [**Basic Usage**](../quickstart/basic-usage.md), we'll show you how to work with our Typescript and Rust SDKs. 

[![Open in Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/lancedb/vectordb-recipes/blob/main/examples/saas_examples/python_notebook/LanceDB_Cloud_quickstart.ipynb).

## **1. Install LanceDB**

LanceDB requires Python 3.8+ and can be installed via `pip`. The `pandas` package is optional but recommended for data manipulation. **By default, you can manage data using Python lists or dictionaries.** LanceDB also integrates seamlessly with popular data libraries like `pyarrow`, `pydantic`, and `polars` to provide flexible data handling options.

```python
pip install lancedb pandas
```

## **2. Import Libraries**

Import the libraries. LanceDB provides the core vector database functionality, while `pandas` helps with data handling.

```python
import lancedb
import pandas as pd
```

## **3. Connect to LanceDB**

LanceDB supports both managed and local deployments. The connection `uri` determines where your data is stored. We recommend using [**LanceDB Cloud**](../cloud/index.md) or [**Enterprise**](../enterprise/index.md) for production workloads as they provide a managed infrastructure, security, and automatic backups. 

=== "Cloud"

    === "Sync API"
        ```python
        db = lancedb.connect(
            uri="db://your-project-slug",
            api_key="your-api-key",
            region="us-east-1"
        )
        ```

    === "Async API"
        ```python
        db = await lancedb.connect_async(
            uri="db://your-project-slug",
            api_key="your-api-key",
            region="us-east-1"
        )
        ```

=== "Enterprise"

    For LanceDB Enterprise, set the host override to your private cloud endpoint.

    === "Sync API"
        ```python
        host_override = os.environ.get("LANCEDB_HOST_OVERRIDE")

        db = lancedb.connect(
            uri=uri,
            api_key=api_key,
            region=region,
            host_override=host_override
        )
        ```

    === "Async API"
        ```python
        host_override = os.environ.get("LANCEDB_HOST_OVERRIDE")

        db = await lancedb.connect_async(
            uri=uri,
            api_key=api_key,
            region=region,
            host_override=host_override
        )
        ```

=== "Open Source"

    === "Sync API"
        ```python
        uri = "data/sample-lancedb"
        db = lancedb.connect(uri)
        ```

    === "Async API"
        ```python
        uri = "data/sample-lancedb"
        db = await lancedb.connect_async(uri)
        ```

## **4. Add Data**

Create a `pandas` DataFrame with your data. Each row must contain a vector field (list of floats) and can include additional metadata. 

```python
data = pd.DataFrame([
    {"id": "1", "vector": [0.9, 0.4, 0.8], "text": "knight"},    
    {"id": "2", "vector": [0.8, 0.5, 0.3], "text": "ranger"},  
    {"id": "3", "vector": [0.5, 0.9, 0.6], "text": "cleric"},    
    {"id": "4", "vector": [0.3, 0.8, 0.7], "text": "rogue"},     
    {"id": "5", "vector": [0.2, 1.0, 0.5], "text": "thief"},     
])
```

## **5. Create a Table**

Create a table in the database. The table takes on the schema of your ingested data.

=== "Sync API"
    ```python
    table = db.create_table("adventurers", data)
    ```

=== "Async API"
    ```python
    table = await db.create_table_async("adventurers", data)
    ```

## **6. Vector Search**

Perform a vector similarity search. The query vector should have the same dimensionality as your data vectors. The search returns the most similar vectors based on **euclidean distance**.

Our query is **"warrior" - [0.8, 0.3, 0.8]**. Let's find the most similar adventurer:  

=== "Sync API"
    ```python
    query_vector = [0.8, 0.3, 0.8]  
    results = table.search(query_vector).limit(3).to_pandas()
    print(results)
    ```

=== "Async API"
    ```python
    query_vector = [0.8, 0.3, 0.8]  
    results = await table.search(query_vector).limit(3).to_pandas()
    print(results)
    ```

## **7. Results**

The results show the most similar vectors to your query, sorted by similarity score (distance). Lower distance means higher similarity.

```python
| id | vector          | text    | distance  |
|----|-----------------|---------|-----------|
| 1  | [0.9, 0.4, 0.8] | knight  | 0.02      |
| 2  | [0.8, 0.5, 0.3] | ranger  | 0.29      |
| 3  | [0.5, 0.9, 0.6] | cleric  | 0.49      |
```

## **What's Next?**

Check out some [**Basic Usage tips**](../quickstart/basic-usage.md). After that, we'll teach you how to build a small app.
