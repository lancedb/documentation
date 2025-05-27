---
title: LanceDB API Reference | Developer Guide
description: Comprehensive API reference for LanceDB. Includes Python, JavaScript, and Rust SDK documentation, with detailed examples and usage guidelines.
hide:
 - toc
---
# **LanceDB API Reference**

LanceDB provides multiple ways to interact with your vector database:

1. **LanceDB Cloud REST API** - A RESTful API service for cloud-hosted LanceDB instances
2. **Client SDKs** - Native language bindings for direct integration

## LanceDB Cloud REST API

The REST API allows you to interact with LanceDB Cloud instances using standard HTTP requests. This is ideal for building web applications, cross-platform integrations, serverless architectures and anguage-agnostic implementations. The complete API specification is available here:

| LanceDB Cloud | Documentation Link |
|--------------|-------------------|
| REST API | [REST API Documentation](api/cloud.md) |

## Client SDKs

The SDKs provide a type-safe interfaces, native data structure integrations, advanced querying capabilities and better performance through optimized protocols.

For tighter integration with your application code, LanceDB provides native SDK libraries in multiple languages:

| LanceDB SDKs | Documentation Link | Description |
|--------------|-------------------|-------------|
| Python | [Python SDK Documentation](python/python.md) | Full-featured Python client with pandas & numpy integration |
| JavaScript (@lancedb/lancedb package) | [Current JS Documentation](js/globals.md) | Modern JavaScript/TypeScript SDK for Node.js and browsers |
| JavaScript (legacy vectordb package) | [Legacy JS Documentation](javascript/modules.md) | Legacy JavaScript package (deprecated) |
| Rust | [Rust Documentation](https://docs.rs/lancedb/latest/lancedb/index.html) | Native Rust implementation for high performance |


