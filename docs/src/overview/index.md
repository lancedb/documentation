---
title: LanceDB Open Source Vector Database
description: Comprehensive documentation for LanceDB, a vector database for AI applications. Includes guides, tutorials, API references, and best practices for vector search and data management.
hide:
  - toc
---

# LanceDB Open Source

**LanceDB OSS** is an open-source, batteries-included embedded vector database that you can run on your own infrastructure. "Embedded" means that it runs *in-process*, making it incredibly simple to self-host your own AI retrieval workflows for RAG and more. No servers, no hassle.

It is a multimodal vector database for AI that's designed to store, manage, query and retrieve embeddings on large-scale data of different modalities. Most existing vector databases that store and query just the embeddings and their metadata. The actual data is stored elsewhere, requiring you to manage their storage and versioning separately.

LanceDB supports storage of the *actual data itself*, alongside the embeddings and metadata. You can persist your images, videos, text documents, audio files and more in the Lance format, which provides automatic data versioning and blazing fast retrievals and filtering via LanceDB.

The core of LanceDB is written in Rust 🦀 and is built on top of [Lance](https://github.com/lancedb/lance), an open-source columnar data format designed for performant ML workloads and fast random access.

Both the database and the underlying data format are designed from the ground up to be **easy-to-use**, **scalable** and **cost-effective**.








