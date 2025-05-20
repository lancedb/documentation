---
title: "Full-Text Search (FTS) Index | LanceDB Documentation"
description: "Learn how to implement performant full-text search in LanceDB using BM25. Includes configuration options, API examples in Python and TypeScript, and best practices for text search optimization."
keywords: "LanceDB full-text search, BM25 search, text search index, FTS configuration, text tokenization, search optimization, Python TypeScript search API"
---

# Full-Text Search Index

LanceDB Cloud and Enterprise provide performant full-text search based on BM25, allowing you to incorporate keyword-based search in your retrieval solutions.

!!! note
    The `create_fts_index` API returns immediately, but the building of the FTS index is asynchronous.

=== "Python"
    ```python
    import lancedb

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    table_name = "lancedb-cloud-quickstart"
    table = db.open_table(table_name)
    table.create_fts_index("text")
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    const tableName = "lancedb-cloud-quickstart"
    const table = openTable(tableName);
    await table.createIndex("text", {
      config: lancedb.Index.fts()
    });
    ```

Check FTS index status using the [methods above](#check-index-status).

=== "Python"
    ```python
    index_name = "text_idx"
    table.wait_for_index([index_name])
    ```

=== "TypeScript"
    ```typescript
    const indexName = "text_idx"
    await table.waitForIndex([indexName], 60)
    ```

### FTS Configuration Parameters

LanceDB supports the following configurable parameters for full-text search:

| Parameter         | Type | Default   | Description                                                                                                                                   |
| ----------------- | ---- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| with_position     | bool | True      | Store token positions (required for phrase queries)                                                                                           |
| base_tokenizer    | str  | "simple"  | Text splitting method:  - "simple": Split by whitespace/punctuation  - "whitespace": Split by whitespace only  - "raw": Treat as single token |
| language          | str  | "English" | Language for tokenization (stemming/stop words)                                                                                               |
| max_token_length  | int  | 40        | Maximum token size in bytes; tokens exceeding this length are omitted from the index                                                          |
| lower_case        | bool | True      | Convert tokens to lowercase                                                                                                                   |
| stem              | bool | False     | Apply stemming (e.g., "running" → "run")                                                                                                      |
| remove_stop_words | bool | False     | Remove common stop words                                                                                                                      |
| ascii_folding     | bool | False     | Normalize accented characters                                                                                                                 |
!!! note
    - The `max_token_length` parameter helps optimize indexing performance by filtering out non-linguistic content like base64 data and long URLs
    - When `with_position` is disabled, phrase queries will not work, but index size is reduced and indexing is faster
    - `ascii_folding` is useful for handling international text (e.g., "café" → "cafe")