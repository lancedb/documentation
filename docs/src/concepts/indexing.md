---
title: Vector Indexes in LanceDB
description: Master LanceDB's vector indexing with our comprehensive guide. Learn about IVF-PQ and HNSW indexes, product quantization, clustering, and performance optimization for large-scale vector search.
---

# Indexing Data in LanceDB

An **index** makes embeddings searchable by organizing them in efficient data structures for fast lookups. Without an index, searching through embeddings would require scanning through every single vector in the dataset, which becomes prohibitively slow as the dataset grows.

LanceDB offers a number of indexes, including **IVF, HNSW, Scalar Index and Full-Text Index**. However, a key distinguishing feature of LanceDB is it uses a composite index: **IVF_PQ**, which is a variant of the **Inverted File Index (IVF) that uses Product Quantization (PQ)** to compress the embeddings.

!!! note "Disk-Based Indexing"
    LanceDB is fundamentally different from other vector databases in that it is built on top of [Lance](https://github.com/lancedb/lance), an open-source columnar data format designed for performant ML workloads and fast random access. Due to the design of Lance, LanceDB's indexing philosophy adopts a primarily *disk-based* indexing philosophy.

## Inverted File Index 

**IVF Flat Index**: This index stores raw vectors. These vectors are grouped into partitions of similar vectors. Each partition keeps track of a centroid which is the average value of all vectors in the group.

**IVF-PQ Index**: IVF-PQ is a composite index that combines the Inverted File iIndex (IVF) and product quantization (PQ). The implementation in LanceDB provides several parameters to fine-tune the index's size, query throughput, latency and recall.

## HNSW Index

HNSW (Hierarchically Navigable Small Worlds) is a graph-based algorithm. All graph-based search algorithms rely on the idea of a k-nearest neighbor (or k-approximate nearest neighbor) graph. HNSW also combines this with the ideas behind a classic 1-dimensional search data structure: the skip list.

HNSW is one of the most accurate and fastest ANN search algorithms, It's beneficial in high-dimensional spaces where finding the same nearest neighbor would be too slow and costly.

LanceDB currently supports HNSW_PQ and HNSW_SQL

**HNSW-PQ** is a variant of the HNSW algorithm that uses product quantization to compress the vectors. 

**HNSW_SQ** is a variant of the HNSW algorithm that uses scalar quantization to compress the vectors.

## Scalar Index

Scalar indexes organize data by scalar attributes (e.g. numbers, categorical values), enabling fast filtering of vector data. In vector databases, scalar indices accelerate the retrieval of scalar data associated with vectors, thus enhancing the query performance when searching for vectors that meet certain scalar criteria. 

Similar to many SQL databases, LanceDB supports several types of scalar indices to accelerate search
over scalar columns.

- `BTREE`: The most common type is BTREE. The index stores a copy of the
  column in sorted order. This sorted copy allows a binary search to be used to
  satisfy queries.
- `BITMAP`: this index stores a bitmap for each unique value in the column. It 
  uses a series of bits to indicate whether a value is present in a row of a table
- `LABEL_LIST`: a special index that can be used on `List<T>` columns to
  support queries with `array_contains_all` and `array_contains_any`
  using an underlying bitmap index.
  For example, a column that contains lists of tags (e.g. `["tag1", "tag2", "tag3"]`) can be indexed with a `LABEL_LIST` index.

!!! tips "Which Scalar Index to Use?"

    `BTREE`: This index is good for scalar columns with mostly distinct values and does best when the query is highly selective.
    
    `BITMAP`: This index works best for low-cardinality numeric or string columns, where the number of unique values is small (i.e., less than a few thousands).
    
    `LABEL_LIST`: This index should be used for columns containing list-type data.

| Data Type                                                       | Filter                                    | Index Type   |
| --------------------------------------------------------------- | ----------------------------------------- | ------------ |
| Numeric, String, Temporal                                       | `<`, `=`, `>`, `in`, `between`, `is null` | `BTREE`      |
| Boolean, numbers or strings with fewer than 1,000 unique values | `<`, `=`, `>`, `in`, `between`, `is null` | `BITMAP`     |
| List of low cardinality of numbers or strings                   | `array_has_any`, `array_has_all`          | `LABEL_LIST` |

## Full-Text Index (FTS)



## Reindexing and Incremental Indexing

Reindexing is the process of updating the index to account for new data, keeping good performance for queries. This applies to either a full-text search (FTS) index or a vector index. For ANN search, new data will always be included in query results, but queries on tables with unindexed data will fallback to slower search methods for the new parts of the table. This is another important operation to run periodically as your data grows, as it also improves performance. This is especially important if you're appending large amounts of data to an existing dataset.

!!! tip
    When adding new data to a dataset that has an existing index (either FTS or vector), LanceDB doesn't immediately update the index until a reindex operation is complete.

> Both **LanceDB OSS, Cloud and Enterprise** support reindexing, but the process (at least for now) is different for each, depending on the type of index.

When a reindex job is triggered in the background, the entire data is reindexed, but in the interim as new queries come in, LanceDB will combine results from the existing index with exhaustive kNN search on the new data. This is done to ensure that you're still searching on all your data, but it does come at a performance cost. The more data that you add without reindexing, the impact on latency (due to exhaustive search) can be noticeable.