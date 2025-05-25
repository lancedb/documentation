---
title: Getting Started with LanceDB | Quick Start Guide
description: Start using LanceDB with this comprehensive guide. Learn core concepts, installation, basic operations, and best practices for vector database management.
alias: quickstart
---

# **Ingesting a Dataset into LanceDB**

In this tutorial, you will ingest a dataset from Huggingface into your **LanceDB Cloud** table. For interactive code, check out the [**Python Notebook**](https://colab.research.google.com/github/lancedb/vectordb-recipes/blob/main/examples/saas_examples/python_notebook/LanceDB_Cloud_quickstart.ipynb)  or the [**TypeScript Example**](https://github.com/lancedb/vectordb-recipes/tree/main/examples/saas_examples/ts_example/quickstart)

## **Prerequisites**

You will connect to a remote LanceDB cluster, ingest data and run some searches. Before you start, make sure you [**sign up for LanceDB Cloud**](https://accounts.lancedb.com/sign-up) and get your API key and cluster URI.

## **1. Installation**

Install the [**LanceDB SDK**](../api/index.md) with your preferred language.

=== "Python"
    ```python
    pip install lancedb datasets
    ```

=== "TypeScript"
    ```typescript
    npm install @lancedb/lancedb
    ```

## **2. Connect to LanceDB**

For **LanceDB Cloud** users, the database URI (which starts with `db://`) and API key can both be retrieved from the LanceDB Cloud UI. For step-by-step instructions, refer to our [**onboarding tutorial**](https://app.storylane.io/share/pudefwx54tun).

For **LanceDB Enterprise** users, please contact [**our team**](mailto:contact@lancedb.com) to obtain your database URI, API key, and host_override URL.

=== "Python"
    ```python
    import lancedb
    import numpy as np
    import pyarrow as pa
    import os
    
    # Connect to LanceDB Cloud/Enterprise
    uri = "db://your-database-uri"
    api_key = "your-api-key"
    region = "us-east-1"
    
    # (Optional) For LanceDB Enterprise, set the host override to your enterprise endpoint
    host_override = os.environ.get("LANCEDB_HOST_OVERRIDE")
    
    db = lancedb.connect(
      uri=uri,
      api_key=api_key,
      region=region,
      host_override=host_override
    )
    ```

=== "TypeScript"
    ```typescript
    import { connect, Index, Table } from '@lancedb/lancedb';
    import { FixedSizeList, Field, Float32, Schema, Utf8 } from 'apache-arrow';
    
    // Connect to LanceDB Cloud/Enterprise
    const dbUri = process.env.LANCEDB_URI || 'db://your-database-uri';
    const apiKey = process.env.LANCEDB_API_KEY;
    const region = process.env.LANCEDB_REGION;
    
    // (Optional) For LanceDB Enterprise, set the host override to your enterprise endpoint
    const hostOverride = process.env.LANCEDB_HOST_OVERRIDE;
    
    const db = await connect(dbUri, { 
      apiKey,
      region,
      hostOverride
    });
    ```

## **3. Load Dataset**

For large datasets, the operation should be performed in batches to optimize memory usage.
Let's see how it looks when we try to load a larger dataset.

=== "Python"

    ```python
    from datasets import load_dataset

    # Load a sample dataset from HuggingFace with pre-computed embeddings
    sample_dataset = load_dataset("sunhaozhepy/ag_news_sbert_keywords_embeddings", split="test[:1000]")
    print(f"Loaded {len(sample_dataset)} samples")
    print(f"Sample features: {sample_dataset.features}")
    print(f"Column names: {sample_dataset.column_names}")

    # Preview the first sample
    print(sample_dataset[0])

    # Get embedding dimension
    vector_dim = len(sample_dataset[0]["keywords_embeddings"])
    print(f"Embedding dimension: {vector_dim}")
    ```

=== "TypeScript"

    ```typescript
    const BATCH_SIZE = 100; // HF API default limit
    const POLL_INTERVAL = 10000; // 10 seconds
    const MAX_RETRIES = 5;
    const INITIAL_RETRY_DELAY = 1000; // 1 second

    interface Document {
        text: string;
        label: number;
        keywords: string[];
        embeddings?: number[];
        [key: string]: unknown;
    }

    interface HfDatasetResponse {
        rows: {
            row: {
                text: string;
                label: number;
                keywords: string[];
                keywords_embeddings?: number[];
            };
        }[];
    }

    /**
     * Loads documents from the Hugging Face dataset API in batches
     */
    async function loadDataset(datasetName: string, split: string = 'train', targetSize: number = 1000, offset: number = 0): Promise<Document[]> {    
        try {
            console.log('Fetching dataset...');
            const batches = Math.ceil(targetSize / BATCH_SIZE);
            let allDocuments: Document[] = [];
            const hfToken = process.env.HF_TOKEN; // Optional Hugging Face token

            for (let i = 0; i < batches; i++) {
                const offset = i * BATCH_SIZE;
                const url = `https://datasets-server.huggingface.co/rows?dataset=${datasetName}&config=default&split=${split}&offset=${offset}&limit=${BATCH_SIZE}`;
                console.log(`Fetching batch ${i + 1}/${batches} from offset ${offset}...`);
                
                // Add retry logic with exponential backoff
                let retries = 0;
                let success = false;
                let data: HfDatasetResponse | null = null;

                while (!success && retries < MAX_RETRIES) {
                    try {
                        const headers: HeadersInit = {
                            'Content-Type': 'application/json',
                        };
                        
                        // Add authorization header if token is available
                        if (hfToken) {
                            headers['Authorization'] = `Bearer ${hfToken}`;
                        }
                        
                        const fetchOptions = {
                            method: 'GET',
                            headers,
                            timeout: 30000, // 30 second timeout
                        };
                        
                        const response = await fetch(url, fetchOptions);
                        if (!response.ok) {
                            const errorText = await response.text();
                            console.error(`Error response (attempt ${retries + 1}):`, errorText);
                            throw new Error(`HTTP error! status: ${response.status}, body: ${errorText}`);
                        }
                        
                        data = JSON.parse(await response.text()) as HfDatasetResponse;
                        if (!data.rows) {
                            throw new Error('No rows found in response');
                        }
                        
                        success = true;
                    } catch (error) {
                        retries++;
                        if (retries >= MAX_RETRIES) {
                            console.error(`Failed after ${MAX_RETRIES} retries:`, error);
                            throw error;
                        }
                        
                        const delay = INITIAL_RETRY_DELAY * Math.pow(2, retries - 1);
                        console.log(`Retry ${retries}/${MAX_RETRIES} after ${delay}ms...`);
                        await new Promise(resolve => setTimeout(resolve, delay));
                    }
                }
                
                // Ensure data is defined before using it
                if (!data || !data.rows) {
                    throw new Error('No data received after retries');
                }
                
                console.log(`Received ${data.rows.length} rows in batch ${i + 1}`);
                const documents = data.rows.map(({ row }) => ({
                    text: row.text,
                    label: row.label,
                    keywords: row.keywords,
                    embeddings: row.keywords_embeddings
                }));
                allDocuments = allDocuments.concat(documents);
                
                if (data.rows.length < BATCH_SIZE) {
                    console.log('Reached end of dataset');
                    break;
                }
            }

            console.log(`Total documents loaded: ${allDocuments.length}`);
            return allDocuments;
        } catch (error) {
            console.error("Failed to load dataset:", error);
            throw error;
        }
    }

    // Load dataset
    console.log('Loading AG News dataset...');
    const datasetName = "sunhaozhepy/ag_news_sbert_keywords_embeddings";
    const split = "test";
    const targetSize = 1000;
    const sampleData = await loadDataset(datasetName, split, targetSize);
    console.log(`Loaded ${sampleData.length} examples from AG News dataset`);
    ```
## **4. Ingest Data**

=== "Python"

    ```python
    import pyarrow as pa

    # Create a table with the dataset
    table_name = "lancedb-cloud-quickstart"
    table = db.create_table(table_name, data=sample_dataset, mode="overwrite")

    # Convert list to fixedsizelist on the vector column
    table.alter_columns(dict(path="keywords_embeddings", data_type=pa.list_(pa.float32(), vector_dim)))
    print(f"Table '{table_name}' created successfully")
    ```


=== "TypeScript"

    ```typescript
    const tableName = "lancedb-cloud-quickstart";

    const dataWithEmbeddings: Document[] = sampleData;
    const firstDocWithEmbedding = dataWithEmbeddings.find((doc: Document) => 
        (doc.embeddings && Array.isArray(doc.embeddings) && doc.embeddings.length > 0));
        
    if (!firstDocWithEmbedding || !firstDocWithEmbedding.embeddings || !Array.isArray(firstDocWithEmbedding.embeddings)) {
        throw new Error('No document with valid embeddings found in the dataset. Please check if keywords_embeddings field exists.');
    }
    const embeddingDimension = firstDocWithEmbedding.embeddings.length;

    // Create schema
    const schema = new Schema([
        new Field('text', new Utf8(), true),
        new Field('label', new Float32(), true),
        new Field('keywords', new Utf8(), true),
        new Field('embeddings', new FixedSizeList(embeddingDimension, new Field('item', new Float32(), true)), true)
    ]);

    // Create table with data
    const table = await db.createTable(tableName, dataWithEmbeddings, { 
        schema,
        mode: "overwrite" 
    });
    console.log('Successfully created table');
    ```

## **5. Build an Index**

After creating a table with vector data, you'll want to create an index to enable fast similarity searches. The index creation process optimizes the data structure for efficient vector similarity lookups, significantly improving query performance for large datasets.

!!! note Asynchronous Operation
    As opposed to LanceDB OSS, the `create_index`/`createIndex` operation executes asynchronously in LanceDB Cloud/Enterprise. To ensure the index is fully built, you can use the `wait_timeout` parameter or call `wait_for_index` on the table.

=== "Python"

    ```python
    from datetime import timedelta

    # Create a vector index and wait for it to complete
    table.create_index("cosine", vector_column_name="keywords_embeddings", wait_timeout=timedelta(seconds=120))
    print(table.index_stats("keywords_embeddings_idx"))
    ```

=== "TypeScript"

    ```typescript
    // Create a vector index
    await table.createIndex("embeddings", {
    config: Index.ivfPq({
        distanceType: "cosine",
    }),
    });

    // Wait for the index to be ready
    const indexName = "embeddings_idx";
    await table.waitForIndex([indexName], 120);
    console.log(await table.indexStats(indexName));
    ```

## **6. Vector Search**

Once you have created and indexed your table, you can perform vector similarity searches. LanceDB provides a flexible search API that allows you to find similar vectors, apply filters, and select specific columns to return. The examples below demonstrate basic vector searches as well as filtered searches that combine vector similarity with traditional SQL-style filtering.

=== "Python"

    ```python
    query_dataset = load_dataset("sunhaozhepy/ag_news_sbert_keywords_embeddings", split="test[5000:5001]")
    print(f"Query keywords: {query_dataset[0]['keywords']}")
    query_embed = query_dataset["keywords_embeddings"][0]

    # A vector search
    result = (
        table.search(query_embed)
        .select(["text", "keywords", "label"])
        .limit(5)
        .to_pandas()
    )
    print("Search results:")
    print(result)
    ```

=== "TypeScript"

    ```typescript
    // Perform semantic search with a new query
    const queryDocs = await loadDataset(datasetName, split, 1, targetSize);
    if (queryDocs.length === 0) {
        throw new Error("Failed to load a query document");
    }
    const queryDoc = queryDocs[0];
    if (!queryDoc.embeddings || !Array.isArray(queryDoc.embeddings)) {
        throw new Error("Query document doesn't have a valid embedding after processing");
    }
    const results = await table.search(queryDoc.embeddings)
        .limit(5)
        .select(['text','keywords','label'])
        .toArray();

    console.log('Search Results:');
    console.log(results);
    ```

## **7. Filtered Search**

Add filter to your vector search query. Your can use SQL statements, like `where` for filtering.

=== "Python"

    ```python
    filtered_result = (
        table.search(query_embed)
        .where("label > 2")
        .select(["text", "keywords", "label"])
        .limit(5)
        .to_pandas()
    )
    print("Filtered search results (label > 2):")
    print(filtered_result)
    ```

=== "TypeScript"

    ```typescript
    const filteredResultsesults = await table.search(queryDoc.embeddings)
        .where("label > 2")
        .limit(5)
        .select(['text', 'keywords','label'])
        .toArray();

    console.log('Search Results with filter:');
    console.log(filteredResultsesults);
    ```

## **What's Next?**

That's pretty much it for the **Getting Started** section.

To learn more about vector databases, you may want to read about [**Indexing**](../concepts/indexing.md) to get familiar with the concepts.

If you've already worked with other vector databases, dive into the [**Table Guide**](../guides/tables/index.md) to learn how to work with LanceDB in more detail.