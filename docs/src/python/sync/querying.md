# Querying (Synchronous)

Queries allow you to return data from your database. Basic queries can be created with the [Table.query][lancedb.table.Table.query] method to return the entire (typically filtered) table. Vector searches return the rows nearest to a query vector and can be created with the [Table.vector_search][lancedb.table.Table.vector_search] method.

::: lancedb.query.Query

::: lancedb.query.LanceQueryBuilder

::: lancedb.query.LanceVectorQueryBuilder

::: lancedb.query.LanceFtsQueryBuilder
    options:
      inherited_members: true
    description: |
      A query builder for Full Text Search operations. This provides a fluent interface for building FTS queries.
      For the core FTS functionality (creating indices, etc.), see the [Full Text Search](../features/fts.md) section.

::: lancedb.query.LanceHybridQueryBuilder
