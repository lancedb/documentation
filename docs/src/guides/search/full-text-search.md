---
title: "Full-Text Search in LanceDB | Text Search Guide"
description: "Learn how to implement full-text search in LanceDB. Includes text indexing, query syntax, and performance optimization for text search."
---

# **Full-Text Search in LanceDB (Native)**

LanceDB provides support for full-text search via Lance, allowing you to incorporate keyword-based search (based on BM25) in your retrieval solutions.

!!! note
    The Python SDK uses our native FTS implementation by default, you need to pass `use_tantivy=True` to use tantivy-based FTS.

## **Basic Usage**

Consider that we have a LanceDB table named `my_table`, whose string column `text` we want to index and query via keyword search, the FTS index must be created before you can search via keywords.

### **1. Open Table**

First, open or create the table you want to search:

=== "Python"

    === "Sync API"

        ```python
        import lancedb
        from lancedb.index import FTS

        uri = "data/sample-lancedb"
        db = lancedb.connect(uri)

        table = db.create_table(
            "my_table_fts",
            data=[
                {"vector": [3.1, 4.1], "text": "Frodo was a happy puppy"},
                {"vector": [5.9, 26.5], "text": "There are several kittens playing"},
            ],
        )
        ```

    === "Async API"

        ```python
        import lancedb
        from lancedb.index import FTS

        uri = "data/sample-lancedb"
        async_db = await lancedb.connect_async(uri)

        async_tbl = await async_db.create_table(
            "my_table_fts_async",
            data=[
                {"vector": [3.1, 4.1], "text": "Frodo was a happy puppy"},
                {"vector": [5.9, 26.5], "text": "There are several kittens playing"},
            ],
        )
        ```
=== "TypeScript"

    ```typescript
    import * as lancedb from "@lancedb/lancedb";
    const uri = "data/sample-lancedb"
    const db = await lancedb.connect(uri);

    const data = [
        { vector: [3.1, 4.1], text: "Frodo was a happy puppy" },
        { vector: [5.9, 26.5], text: "There are several kittens playing" },
    ];
    const tbl = await db.createTable("my_table", data, { mode: "overwrite" });
    ```

=== "Rust"

    ```rust
    let uri = "data/sample-lancedb";
    let db = connect(uri).execute().await?;
    let initial_data: Box<dyn RecordBatchReader + Send> = create_some_records()?;
    let tbl = db
        .create_table("my_table", initial_data)
        .execute()
        .await?;
    ```

### **2. Construct FTS Index**

Create a full-text search index on your text column:

=== "Python"

    === "Sync API"

        ```python
        # passing `use_tantivy=False` to use lance FTS index
        # `use_tantivy=True` by default
        table.create_fts_index("text", use_tantivy=False)
        ```

    === "Async API"

        ```python
        # async API uses our native FTS algorithm
        await async_tbl.create_index("text", config=FTS())
        ```
=== "TypeScript"

    ```typescript
    await tbl.createIndex("text", {
        config: lancedb.Index.fts(),
    });
    ```

=== "Rust"

    ```rust
    tbl
        .create_index(&["text"], Index::FTS(FtsIndexBuilder::default()))
        .execute()
        .await?;
    ```

### **3. Full Text Search**

Perform the search and retrieve results:

=== "Python"
    === "Sync API"
        ```python
        results = table.search("puppy")
            .limit(10)
            .select(["text"])
            .to_list()
        # [{'text': 'Frodo was a happy puppy', '_score': 0.6931471824645996}]
        ```

    === "Async API"
        ```python
        results = await (await async_tbl.search("puppy"))
            .select(["text"])
            .limit(10)
            .to_list()
        # [{'text': 'Frodo was a happy puppy', '_score': 0.6931471824645996}]
        ```

=== "TypeScript"
    ```typescript
    const results = await tbl
        .search("puppy", "fts")
        .select(["text"])
        .limit(10)
        .toArray();
    ```

=== "Rust"
    ```rust
    let results = tbl
        .query()
        .full_text_search(FullTextSearchQuery::new("puppy".to_owned()))
        .select(lancedb::query::Select::Columns(vec!["text".to_owned()]))
        .limit(10)
        .execute()
        .await?;
    ```

The search is conducted on all indexed columns by default, so it's useful when there are multiple indexed columns.

If you want to specify which columns to search us `fts_columns="text"`

!!! note
    LanceDB automatically searches on the existing FTS index if the input to the search is of type `str`. If you provide a vector as input, LanceDB will search the ANN index instead.

## **Advanced Usage**

### **Tokenize Table Data**

By default, the text is tokenized by splitting on punctuation and whitespaces, and would filter out words that are longer than 40 characters. All words are converted to lowercase.

Stemming is useful for improving search results by reducing words to their root form, e.g. "running" to "run". LanceDB supports stemming for multiple languages, you can specify the tokenizer name to enable stemming by the pattern `tokenizer_name="{language_code}_stem"`, e.g. `en_stem` for English.

For example, to enable stemming for English:

=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:fts_config_stem"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:fts_config_stem_async"
    ```

the following [languages](https://docs.rs/tantivy/latest/tantivy/tokenizer/enum.Language.html) are currently supported.

The tokenizer is customizable, you can specify how the tokenizer splits the text, and how it filters out words, etc.

For example, for language with accents, you can specify the tokenizer to use `ascii_folding` to remove accents, e.g. 'é' to 'e':
=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:fts_config_folding"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:fts_config_folding_async"
    ```

### **Filtering Options**

LanceDB full text search supports to filter the search results by a condition, both pre-filtering and post-filtering are supported.

This can be invoked via the familiar `where` syntax.
 
With pre-filtering:
=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:fts_prefiltering"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:fts_prefiltering_async"
        ```

=== "TypeScript"

    ```typescript
    await tbl
    .search("puppy")
    .select(["id", "doc"])
    .limit(10)
    .where("meta='foo'")
    .prefilter(true)
    .toArray();
    ```

=== "Rust"

    ```rust
    table
        .query()
        .full_text_search(FullTextSearchQuery::new("puppy".to_owned()))
        .select(lancedb::query::Select::Columns(vec!["doc".to_owned()]))
        .limit(10)
        .only_if("meta='foo'")
        .execute()
        .await?;
    ```

With post-filtering:

=== "Python"

    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:fts_postfiltering"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:fts_postfiltering_async"
        ```

=== "TypeScript"

    ```typescript
    await tbl
    .search("apple")
    .select(["id", "doc"])
    .limit(10)
    .where("meta='foo'")
    .prefilter(false)
    .toArray();
    ```

=== "Rust"

    ```rust
    table
        .query()
        .full_text_search(FullTextSearchQuery::new(words[0].to_owned()))
        .select(lancedb::query::Select::Columns(vec!["doc".to_owned()]))
        .postfilter()
        .limit(10)
        .only_if("meta='foo'")
        .execute()
        .await?;
    ```

### **Phrase vs. Terms Queries**

!!! warning "Warn"
    Lance-based FTS doesn't support queries using boolean operators `OR`, `AND`.

For full-text search you can specify either a **phrase** query like `"the old man and the sea"`,
or a **terms** search query like `old man sea`. For more details on the terms
query syntax, see Tantivy's [query parser rules](https://docs.rs/tantivy/latest/tantivy/query/struct.QueryParser.html).

To search for a phrase, the index must be created with `with_position=True` and `remove_stop_words=False`:
=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:fts_with_position"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:fts_with_position_async"
    ```
This will allow you to search for phrases, but it will also significantly increase the index size and indexing time.

### **Fuzzy Search**

Fuzzy search allows you to find matches even when the search terms contain typos or slight variations. 
LanceDB uses the classic [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) 
to find similar terms within a specified edit distance.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| fuzziness | int | 0 | Maximum edit distance allowed for each term. If not specified, automatically set based on term length: 0 for length ≤ 2, 1 for length ≤ 5, 2 for length > 5 |
| max_expansions | int | 50 | Maximum number of terms to consider for fuzzy matching. Higher values may improve recall but increase search time |

Let's create a sample table and build full-text search indices to demonstrate 
fuzzy search capabilities and relevance boosting features.

## **Example: Fuzzy Search**


### **1. Generate Data**

First, let's create a table with sample text data for testing fuzzy search:

=== "Python"
    ```python
    import lancedb
    import numpy as np
    import pandas as pd
    import random

    # Connect to LanceDB
    db = lancedb.connect(
        uri="db://your-project-slug",
        api_key="your-api-key",
        region="us-east-1"
    )

    # Generate sample data
    table_name = "fts-fuzzy-boosting-test"
    vectors = [np.random.randn(128) for _ in range(100)]
    text_nouns = ("puppy", "car")
    text2_nouns = ("rabbit", "girl", "monkey")
    verbs = ("runs", "hits", "jumps", "drives", "barfs")
    adv = ("crazily.", "dutifully.", "foolishly.", "merrily.", "occasionally.")
    adj = ("adorable", "clueless", "dirty", "odd", "stupid")

    # Generate random text combinations
    text = [
        " ".join([
            text_nouns[random.randrange(0, len(text_nouns))],
            verbs[random.randrange(0, 5)],
            adv[random.randrange(0, 5)],
            adj[random.randrange(0, 5)],
        ])
        for _ in range(100)
    ]
    text2 = [
        " ".join([
            text2_nouns[random.randrange(0, len(text2_nouns))],
            verbs[random.randrange(0, 5)],
            adv[random.randrange(0, 5)],
            adj[random.randrange(0, 5)],
        ])
        for _ in range(100)
    ]
    count = [random.randint(1, 10000) for _ in range(100)]
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    const db = await lancedb.connect({
        uri: "db://your-project-slug",
        apiKey: "your-api-key",
        region: "us-east-1"
    });

    // Generate sample data
    const tableName = "fts-fuzzy-boosting-test-ts";
    const n = 100;
    const vectors = Array.from({ length: n }, () => 
        Array.from({ length: 128 }, () => Math.random() * 2 - 1)
    );

    const textNouns = ["puppy", "car"];
    const text2Nouns = ["rabbit", "girl", "monkey"];
    const verbs = ["runs", "hits", "jumps", "drives", "barfs"];
    const adverbs = ["crazily", "dutifully", "foolishly", "merrily", "occasionally"];
    const adjectives = ["adorable", "clueless", "dirty", "odd", "stupid"];

    // Generate random text combinations
    const generateText = (nouns: string[]) => {
        const noun = nouns[Math.floor(Math.random() * nouns.length)];
        const verb = verbs[Math.floor(Math.random() * verbs.length)];
        const adv = adverbs[Math.floor(Math.random() * adverbs.length)];
        const adj = adjectives[Math.floor(Math.random() * adjectives.length)];
        return `${noun} ${verb} ${adv} ${adj}`;
    };

    const text = Array.from({ length: n }, () => generateText(textNouns));
    const text2 = Array.from({ length: n }, () => generateText(text2Nouns));
    const count = Array.from({ length: n }, () => Math.floor(Math.random() * 10000) + 1);
    ```

### **2. Create Table**

=== "Python"
    ```python
    # Create table with sample data
    table = db.create_table(
        table_name,
        data=pd.DataFrame({
            "vector": vectors,
            "id": [i % 2 for i in range(100)],
            "text": text,
            "text2": text2,
            "count": count,
        }),
        mode="overwrite"
    )
    ```

=== "TypeScript"
    ```typescript
    // Create table with sample data
    const data = makeArrowTable(
        vectors.map((vector, i) => ({
            vector,
            id: i % 2,
            text: text[i],
            text2: text2[i],
            count: count[i],
        }))
    );

    const table = await db.createTable(tableName, data, { mode: "overwrite" });
    ```

### **3. Construct FTS Index**

Create a full-text search index on the first text column:

=== "Python"
    ```python
    # Create FTS index on first text column
    table.create_fts_index("text")
    wait_for_index(table, "text_idx")
    ```

=== "TypeScript"
    ```typescript
    // Create FTS index on first text column
    await table.createIndex("text", { config: Index.fts() });
    await waitForIndex(table, "text_idx");
    ```

Then, create an index on the second text column:

=== "Python"
    ```python
    # Create FTS index on second text column
    table.create_fts_index("text2")
    wait_for_index(table, "text2_idx")
    ```

=== "TypeScript"
    ```typescript
    // Create FTS index on second text column
    await table.createIndex("text2", { config: Index.fts() });
    await waitForIndex(table, "text2_idx");
    ```

### **4. Basic and Fuzzy Search**

Now we can perform basic, fuzzy, and prefix match searches:

#### **Basic Exact Search**

=== "Python"
    ```python
    from lancedb.query import MatchQuery

    # Basic match (exact search)
    basic_match_results = (
        table.search(MatchQuery("crazily", "text"))
        .select(["id", "text"])
        .limit(100)
        .to_pandas()
    )
    ```

=== "TypeScript"
    ```typescript
    import { MatchQuery } from "@lancedb/lancedb";

    // Basic match (exact search)
    const basicMatchResults = await table.query()
        .fullTextSearch(new MatchQuery("crazily", "text"))
        .select(["id", "text"])
        .limit(100)
        .toArray();
    ```

#### **Fuzzy Search with Typos**

=== "Python"
    ```python
    # Fuzzy match (allows typos)
    fuzzy_results = (
        table.search(MatchQuery("craziou", "text", fuzziness=2))
        .select(["id", "text"])
        .limit(100)
        .to_pandas()
    )
    ```

=== "TypeScript"
    ```typescript
    // Fuzzy match (allows typos)
    const fuzzyResults = await table.query()
        .fullTextSearch(new MatchQuery("craziou", "text", {
            fuzziness: 2,
        }))
        .select(["id", "text"])
        .limit(100)
        .toArray();
    ```

#### **Prefix based Match**

Prefix-based match allows you to search for documents containing words that start with a specific prefix. 

=== "Python"
    ```python
    # Fuzzy match (allows typos)
    fuzzy_results = (
        table.search(MatchQuery("cra", "text", prefix_length=3))
        .select(["id", "text"])
        .limit(100)
        .to_pandas()
    )
    ```

=== "TypeScript"
    ```typescript
    // Fuzzy match (allows typos)
    const fuzzyResults = await table.query()
        .fullTextSearch(new MatchQuery("cra", "text", {
            prefixLength: 3,
        }))
        .select(["id", "text"])
        .limit(100)
        .toArray();
    ```

### **Phrase Match**

Phrase matching enables you to search for exact sequences of words. Unlike regular text search 
which matches individual terms independently, phrase matching requires words to appear in the 
specified order with no intervening terms. 

Phrase matching is particularly useful for:

- Searching for specific multi-word expressions
- Matching exact titles or quotes  
- Finding precise word combinations in a specific order

=== "Python"
    ```python
    # Exact phrase match
    from lancedb.query import PhraseQuery

    print("\n1. Exact phrase match for 'puppy runs':")
    phrase_results = (
        table.search(PhraseQuery("puppy runs", "text"))
        .select(["id", "text"])
        .limit(100)
        .to_pandas()
    )
    ```

=== "TypeScript"
    ```typescript
    import { PhraseQuery } from "@lancedb/lancedb";

    // Exact phrase match
    console.log("\n1. Exact phrase match for 'puppy runs':");
    const phraseResults = await table.query()
      .fullTextSearch(new PhraseQuery("puppy runs", "text"))
      .select(["id", "text"])
      .limit(100)
      .toArray();
    ```

#### **Flexible Phrase Match**
To provide more flexible phrase matching, LanceDB supports the `slop` parameter. This allows you to match phrases where the terms appear close to each other, even if they are not directly adjacent or in the exact order, as long as they are within the specified `slop` value.

For example, the phrase query "puppy merrily" would not return any results by default. However, if you set `slop=1`, it will match phrases like "puppy jumps merrily", "puppy runs merrily", and similar variations where one word appears between "puppy" and "merrily".

=== "Python"
    ```python
    # Flexible phrase match with slop=1 for 'puppy merrily'
    from lancedb.query import PhraseQuery

    print("\n1. Flexible phrase match for 'puppy merrily' with slop=1:")
    phrase_results = (
        table.search(PhraseQuery("puppy merrily", "text", slop=1))
        .select(["id", "text"])
        .limit(100)
        .to_pandas()
    )
    ```

=== "TypeScript"
    ```typescript
    import { PhraseQuery } from "@lancedb/lancedb";

    // Flexible phrase match with slop=1 for 'puppy runs'
    console.log("\n1. Flexible phrase match for 'puppy runs' with slop=1:");
    const phraseResults = await table.query()
      .fullTextSearch(new PhraseQuery("puppy runs", "text", { slop: 1 }))
      .select(["id", "text"])
      .limit(100)
      .toArray();
    ```


### **Search with Boosting**

Boosting allows you to control the relative importance of different search terms or fields 
in your queries. This feature is particularly useful when you need to:

* Prioritize matches in certain columns
* Promote specific terms while demoting others 
* Fine-tune relevance scoring for better search results

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| positive | Query | required | The primary query terms to match and promote in results |
| negative | Query | required | Terms to demote in the search results |
| negative_boost | float | 0.5 | Multiplier for negative matches (lower values = stronger demotion) |

=== "Python"
    ```python
    from lancedb.query import MatchQuery, BoostQuery, MultiMatchQuery

    # Boost data with 'runs' in text more than 'puppy' in text
    print("\n2. Boosting data with 'runs' in text:")
    boosting_results = (
      table.search(
          BoostQuery(
              MatchQuery("runs", "text"),
              MatchQuery("puppy", "text"),
              negative_boost=0.2,
          ),
      )
      .select(["id", "text"])
      .limit(100)
      .to_pandas()
    )

    """Test searching across multiple fields."""
    print("\n=== Multi Match Query Examples ===")
    # Search across both text and text2
    print("\n1. Searching 'crazily' in both text and text2:")
    multi_match_results = (
        table.search(MultiMatchQuery("crazily", ["text", "text2"]))
        .select(["id", "text", "text2"])
        .limit(100)
        .to_pandas()
    )

    # Search with field boosting
    print("\n2. Searching with boosted text2 field:")
    multi_match_boosting_results = (
        table.search(
            MultiMatchQuery("crazily", ["text", "text2"], boosts=[1.0, 2.0]),
        )
        .select(["id", "text", "text2"])
        .limit(100)
        .to_pandas()
    )
    ```

=== "TypeScript"
    ```typescript
    import { MatchQuery, BoostQuery, MultiMatchQuery } from "@lancedb/lancedb";

    // Boosting Example
    console.log("\n2. Boosting data with 'runs' in text:");
    const boostingResults = await table.query()
      .fullTextSearch(new BoostQuery(new MatchQuery("runs", "text"), new MatchQuery("puppy", "text"), {
        negativeBoost: 0.2,
      }))
      .select(["id", "text"])
      .limit(100)
      .toArray();

    // Multi Match Query Examples
    console.log("\n=== Multi Match Query Examples ===");

    // Search across both text fields
    console.log("\n1. Searching 'crazily' in both text and text2:");
    const multiMatchResults = await table.query()
      .fullTextSearch(new MultiMatchQuery("crazily", ["text", "text2"]))
      .select(["id", "text", "text2"])
      .limit(100)
      .toArray();

    // Search with field boosting
    console.log("\n2. Searching with boosted text2 field:");
    const multiMatchBoostingResults = await table.query()
      .fullTextSearch(new MultiMatchQuery("crazily", ["text", "text2"], {
        boosts: [1.0, 2.0],
      }))
      .select(["id", "text", "text2"])
      .limit(100)
      .toArray();
    ```

!!! tip "Best Practices"
    - Use fuzzy search when handling user input that may contain typos or variations
    - Apply field boosting to prioritize matches in more important columns
    - Combine fuzzy search with boosting for robust and precise search results

    **Recommendations for optimal FTS performance:**

    - Create full-text search indices on text columns that will be frequently searched
    - For hybrid search combining text and vectors, see our [hybrid search guide](./hybrid-search.md)
    - For performance benchmarks, check our [benchmark results](../enterprise/benchmark.md)
    - For complex queries, use SQL to combine FTS with other filter conditions

### **Boolean Queries**
LanceDB supports boolean logic in full-text search, allowing you to combine multiple queries using `and` and `or` operators. This is useful when you want to match documents that satisfy multiple conditions (intersection) or at least one of several conditions (union).

#### **Combining Two Match Queries**

In Python, you can combine two MatchQuery objects using either the `and` function or the `&` operator (e.g., `MatchQuery("puppy", "text") and MatchQuery("merrily", "text")`); both methods are supported and yield the same result. Similarly, you can use either the `or` function or the `|` operator to perform an or query. 

In TypeScript, boolean queries are constructed using the `BooleanQuery` class with a list of [Occur, subquery] pairs. For example, to perform an AND query:(e.g. 
    `new BooleanQuery([
            [Occur.Must, new MatchQuery("puppy", "text")],
            [Occur.Must, new MatchQuery("merrily", "text")],
          ])`)
This approach allows you to specify complex boolean logic by combining multiple subqueries with different Occur values (such as Must, Should, or MustNot).

!!! note
    A boolean query must include at least one `SHOULD` or `MUST` clause. Queries that contain only a `MUST_NOT` clause are not allowed.

=== "Python"
    ```python
    from lancedb.query import MatchQuery

    # Example: Find documents containing both "puppy" and "merrily"
    and_query = MatchQuery("puppy", "text") & MatchQuery("merrily", "text")
    and_results = (
        table.search(and_query)
        .select(["id", "text"])
        .limit(100)
        .to_pandas()
    )
    print("\nDocuments containing both 'puppy' and 'merrily':")
    print(and_results)

    # Example: Find documents containing either "puppy" or "merrily"
    or_query = MatchQuery("puppy", "text") | MatchQuery("merrily", "text")
    or_results = (
        table.search(or_query)
        .select(["id", "text"])
        .limit(100)
        .to_pandas()
    )
    print("\nDocuments containing either 'puppy' OR 'merrily':")
    print(or_results)
    ```

=== "TypeScript"
    ```typescript
    import { MatchQuery, BooleanQuery, Occur } from "@lancedb/lancedb";

    // Flexible boolean queries with MatchQuery

    // Find documents containing both "puppy" and "merrily"
    const mustResults = await table
        .search(
          new BooleanQuery([
            [Occur.Must, new MatchQuery("puppy", "text")],
            [Occur.Must, new MatchQuery("merrily", "text")],
          ]),
        )
        .select(["id", "text"])
        .limit(100)
        .toArray();
    console.log("\nDocuments containing both 'puppy' and 'merrily':");
    console.log(mustResults);

    // Find documents containing either "puppy" or "merrily"
    const shouldResults = await table
        .search(
          new BooleanQuery([
            [Occur.Should, new MatchQuery("puppy", "text")],
            [Occur.Should, new MatchQuery("merrily", "text")],
          ]),
        )
        .select(["id", "text"])
        .limit(100)
        .toArray();
    console.log("\nDocuments containing either 'puppy' or 'merrily':");
    console.log(shouldResults);
    ```

!!! tip 
    - Use `and`/`&`(Python), `Occur.Must`(Typescript) for intersection (documents must match all queries).
    - Use `or`/`|`(Python), `Occur.Should`(Typescript) for union (documents must match at least one query).


## **Full-Text Search on Array Fields**

LanceDB supports full-text search on string array columns, enabling efficient keyword-based search across multiple values within a single field (e.g., tags, keywords).

=== "Python"
    ```python
    import lancedb

    # Connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    table_name = "fts-array-field-test"
    schema = pa.schema([
        pa.field("id", pa.string()),
        pa.field("tags", pa.list_(pa.string())),
        pa.field("description", pa.string())
    ])

    # Generate sample data
    data = {
        "id": [f"doc_{i}" for i in range(10)],
        "tags": [
            ["python", "machine learning", "data science"],
            ["deep learning", "neural networks", "AI"],
            ["database", "indexing", "search"],
            ["vector search", "embeddings", "AI"],
            ["full text search", "indexing", "database"],
            ["python", "web development", "flask"],
            ["machine learning", "deep learning", "pytorch"],
            ["database", "SQL", "postgresql"],
            ["search engine", "elasticsearch", "indexing"],
            ["AI", "transformers", "NLP"]
        ],
        "description": [
            "Python for data science projects",
            "Deep learning fundamentals",
            "Database indexing techniques",
            "Vector search implementations",
            "Full-text search guide",
            "Web development with Python",
            "Machine learning with PyTorch",
            "Database management systems",
            "Search engine optimization",
            "AI and NLP applications"
        ]
    }

    # Create table and add data
    table = db.create_table(table_name, schema=schema, mode="overwrite")
    table_data = pa.Table.from_pydict(data, schema=schema)
    table.add(table_data)

    # Create FTS index
    table.create_fts_index("tags")
    wait_for_index(table, "tags_idx")

    # Search examples
    print("\nSearching for 'learning' in tags with a typo:")
    result = (
        table.search(MatchQuery("learnin", column="tags", fuzziness=1))
        .select(['id', 'tags', 'description'])
        .to_arrow()
    )

    print("\nSearching for 'machine learning' in tags:")
    result = (
        table.search(PhraseQuery("machine learning", column="tags"))
        .select(['id', 'tags', 'description'])
        .to_arrow()
    )
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    const tableName = "fts-array-field-test-ts";

    // Create schema
    const schema = new Schema([
      new Field("id", new Utf8(), false),
      new Field("tags", new List(new Field("item", new Utf8()))),
      new Field("description", new Utf8(), false)
    ]);

    // Generate sample data
    const data = makeArrowTable(
      Array(10).fill(0).map((_, i) => ({
        id: `doc_${i}`,
        tags: [
          ["python", "machine learning", "data science"],
          ["deep learning", "neural networks", "AI"],
          ["database", "indexing", "search"],
          ["vector search", "embeddings", "AI"],
          ["full text search", "indexing", "database"],
          ["python", "web development", "flask"],
          ["machine learning", "deep learning", "pytorch"],
          ["database", "SQL", "postgresql"],
          ["search engine", "elasticsearch", "indexing"],
          ["AI", "transformers", "NLP"]
        ][i],
        description: [
          "Python for data science projects",
          "Deep learning fundamentals",
          "Database indexing techniques",
          "Vector search implementations",
          "Full-text search guide",
          "Web development with Python",
          "Machine learning with PyTorch",
          "Database management systems",
          "Search engine optimization",
          "AI and NLP applications"
        ][i]
      })),
      { schema }
    );

    // Create table
    const table = await db.createTable(tableName, data, { mode: "overwrite" });
    console.log(`Created table: ${tableName}`);

    // Create FTS index
    console.log("Creating FTS index on 'tags' column...");
    await table.createIndex("tags", {
      config: Index.fts()
    });

    // Wait for index
    const ftsIndexName = "tags_idx";
    await waitForIndex(table, ftsIndexName);

    // Search examples
    console.log("\nSearching for 'learning' in tags with a typo:");
    const fuzzyResults = await table.query()
      .fullTextSearch(new MatchQuery("learnin", "tags", {
        fuzziness: 2,
      }))
      .select(["id", "tags", "description"])
      .toArray();
    console.log(fuzzyResults);

    console.log("\nSearching for 'machine learning' in tags:");
    const phraseResults = await table.query()
      .fullTextSearch(new PhraseQuery("machine learning", "tags"))
      .select(["id", "tags", "description"])
      .toArray();
    console.log(phraseResults);
    ```


