# Python API Reference

This section contains the API reference for the Python API. LanceDB provides both synchronous and asynchronous API clients.

## Installation

```shell
pip install lancedb
```

## Quick Start

The general flow of using the API is:

1. Use [lancedb.connect][] or [lancedb.connect_async][] to connect to a database.
2. Use the returned [lancedb.DBConnection][] or [lancedb.AsyncConnection][] to create or open tables.
3. Use the returned [lancedb.table.Table][] or [lancedb.AsyncTable][] to query or modify tables.

## API Reference

### Synchronous API
- [Connections](sync/connections.md)
- [Tables](sync/tables.md)
- [Querying](sync/querying.md)

### Asynchronous API
- [Connections](async/connections.md)
- [Tables](async/tables.md)
- [Querying](async/querying.md)

### Features
- [Embeddings](features/embeddings.md)
- [Context](features/context.md)
- [Full Text Search](features/fts.md)
- [Indices](features/indices.md)

### Integrations
- [Pydantic](integrations/pydantic.md)
- [Reranking](integrations/reranking.md)

### SaaS Integration
For information about using LanceDB with SaaS services, see the [SaaS Integration Guide](../saas/index.md).

## Common Issues

Multiprocessing with `fork` is not supported. You should use `spawn` instead.

