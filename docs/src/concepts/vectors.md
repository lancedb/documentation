---
title: Vector Embeddings in LanceDB | Complete Guide to Vector Representations
description: Master vector embeddings in LanceDB with our comprehensive guide. Learn how to convert raw data into vector representations and understand the power of semantic similarity in vector space.
---

# Types of Vector Embeddings Supported by LanceDB

## Vectors

Modern machine learning models convert raw data into vector embeddings, which are fixed-length arrays of floating-point numbers. These embeddings capture semantic meaning through their position in vector space, where proximity indicates similarity. Points close together represent similar concepts, while distant points represent dissimilar ones.

Multimodal data (text, audio, images, etc.) can be transformed into embeddings using appropriate models. 

**Figure 1:** When projected into 2D space, semantically similar items will naturally cluster together.

![](../assets/concepts/vectors/embedding_intro.png)

## Multivectors

LanceDB natively supports multivector data types, enabling advanced search scenarios where 
a single data item is represented by multiple embeddings (e.g., using models like ColBERT 
or CoLPali). 

In this framework, documents and queries are encoded as collections of 
contextualized vectors—precomputed for documents and indexed for queries.

Key features:

- Indexing on multivector column: store and index multiple vectors per row
- Supporting queries with either a single vector or multiple vectors
- Optimized search performance with [XTR](https://arxiv.org/abs/2501.17788) with improved recall

!!! info "Multivector Search Limitations"
    Currently, only the `cosine` metric is supported for multivector search. 
    The vector value type can be `float16`, `float32`, or `float64`.

## Binary Vectors

LanceDB supports binary vectors - vectors composed solely of 0s and 1s that are commonly used to represent categorical data or presence/absence information in a compact way. Binary vectors in LanceDB are stored efficiently as uint8 arrays, with every 8 bits packed into a single byte.

!!! note "Dimension Requirements"
    Binary vector dimensions must be multiples of 8. For example, a 128-dimensional binary vector is stored as a uint8 array of size 16 (128/8 = 16 bytes).

LanceDB provides specialized support for searching binary vectors using Hamming distance, which measures the number of positions at which two binary vectors differ. This makes binary vectors particularly efficient for:

- Document fingerprinting and deduplication
- Binary hash codes for image similarity search  
- Compressed vector representations for large-scale retrieval
- Categorical feature encoding

While LanceDB's primary focus is on dense floating-point vectors for semantic search, its Apache Arrow-based architecture and hardware acceleration optimizations make it equally well-suited for binary vector operations. The compact nature of binary vectors combined with efficient Hamming distance calculations enables fast similarity comparisons while minimizing storage requirements.

