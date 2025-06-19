# Querying (Asynchronous)

Queries allow you to return data from your database. Basic queries can be created with the [AsyncTable.query][lancedb.table.AsyncTable.query] method to return the entire (typically filtered) table. Vector searches return the rows nearest to a query vector and can be created with the [AsyncTable.vector_search][lancedb.table.AsyncTable.vector_search] method.

::: lancedb.query.AsyncQuery
    options:
      inherited_members: true

::: lancedb.query.AsyncVectorQuery
    options:
      inherited_members: true

::: lancedb.query.AsyncHybridQuery
    options:
      inherited_members: true
