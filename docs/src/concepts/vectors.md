---
title: Vector Embeddings in LanceDB | Complete Guide to Vector Representations
description: Master vector embeddings in LanceDB with our comprehensive guide. Learn how to convert raw data into vector representations and understand the power of semantic similarity in vector space.
---

# **Vector Embeddings in LanceDB**

## **Understanding Vector Representations**

Modern machine learning models can be trained to convert raw data into embeddings, represented as arrays (or vectors) of floating point numbers of fixed dimensionality. What makes embeddings useful in practice is that the position of an embedding in vector space captures some of the semantics of the data, depending on the type of model and how it was trained. Points that are close to each other in vector space are considered similar (or appear in similar contexts), and points that are far away are considered dissimilar.

Large datasets of multi-modal data (text, audio, images, etc.) can be converted into embeddings with the appropriate model. Projecting the vectors' principal components in 2D space results in groups of vectors that represent similar concepts clustering together, as shown below.

![](../assets/embedding_intro.png)

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