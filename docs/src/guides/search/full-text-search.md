---
title: Full-Text Search in LanceDB | Text Search Guide
description: Learn how to implement full-text search in LanceDB. Includes text indexing, search capabilities, and best practices for efficient text search operations.
---

# Full-text search (Native FTS)

LanceDB provides support for full-text search via Lance, allowing you to incorporate keyword-based search (based on BM25) in your retrieval solutions.

!!! note
    The Python SDK uses tantivy-based FTS by default, need to pass `use_tantivy=False` to use native FTS.

## Example

Consider that we have a LanceDB table named `my_table`, whose string column `text` we want to index and query via keyword search, the FTS index must be created before you can search via keywords.

=== "Python"
    === "Sync API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_search.py:import-lancedb-fts"
        --8<-- "python/python/tests/docs/test_search.py:basic_fts"
        ```
    === "Async API"

        ```python
        --8<-- "python/python/tests/docs/test_search.py:import-lancedb"
        --8<-- "python/python/tests/docs/test_search.py:import-lancedb-fts"
        --8<-- "python/python/tests/docs/test_search.py:basic_fts_async"
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
    await tbl.createIndex("text", {
        config: lancedb.Index.fts(),
    });

    await tbl
        .search("puppy", "fts")
        .select(["text"])
        .limit(10)
        .toArray();
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
    tbl
        .create_index(&["text"], Index::FTS(FtsIndexBuilder::default()))
        .execute()
        .await?;

    tbl
        .query()
        .full_text_search(FullTextSearchQuery::new("puppy".to_owned()))
        .select(lancedb::query::Select::Columns(vec!["text".to_owned()]))
        .limit(10)
        .execute()
        .await?;
    ```

It would search on all indexed columns by default, so it's useful when there are multiple indexed columns.

Passing `fts_columns="text"` if you want to specify the columns to search.

!!! note
    LanceDB automatically searches on the existing FTS index if the input to the search is of type `str`. If you provide a vector as input, LanceDB will search the ANN index instead.

## Tokenization
By default the text is tokenized by splitting on punctuation and whitespaces, and would filter out words that are with length greater than 40, and lowercase all words.

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

## Filtering

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

## Phrase queries vs. terms queries

!!! warning "Warn"
    Lance-based FTS doesn't support queries using boolean operators `OR`, `AND`.

For full-text search you can specify either a **phrase** query like `"the old man and the sea"`,
or a **terms** search query like `old man sea`. For more details on the terms
query syntax, see Tantivy's [query parser rules](https://docs.rs/tantivy/latest/tantivy/query/struct.QueryParser.html).

To search for a phrase, the index must be created with `with_position=True`:
=== "Sync API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:fts_with_position"
    ```
=== "Async API"

    ```python
    --8<-- "python/python/tests/docs/test_search.py:fts_with_position_async"
    ```
This will allow you to search for phrases, but it will also significantly increase the index size and indexing time.






---
title: "Full-Text Search in LanceDB | Text Search Guide"
description: "Learn how to implement full-text search in LanceDB. Includes text indexing, query syntax, and performance optimization for text search."
---

# Full Text Search with LanceDB

The full-text search allows you to 
incorporate keyword-based search (based on BM25) in your retrieval solutions.
LanceDB can deliver **26ms** query latency for full-text search. 
[Our benchmark tests](../enterprise/benchmark.md) have more details.

=== "Python"
    ```python
    import lancedb

    # connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    # let's use the table created from quickstart
    table_name = "lancedb-cloud-quickstart"
    table = db.open_table(table_name)

    table.create_fts_index("text")
    # Wait for FTS index to be ready
    fts_index_name = f"{text_column}_idx"
    wait_for_index(table, fts_index_name)

    query_text = "football"
    fts_results = table.search(query_text, query_type="fts").select(["text", "keywords", "label"]).limit(5).to_pandas()
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    // Open table and perform search
    const tableName = "lancedb-cloud-quickstart";
    const table = await db.openTable(tableName);
    const textColumn = "text";

    // Create a full-text search index
    await table.createIndex(textColumn, {
      config: Index.fts()
    });

    // Wait for the index to be ready
    const ftsIndexName = textColumn + "_idx";
    await waitForIndex(table, ftsIndexName);

    const queryText = "football";
    const ftsResults = await table.query()
      .fullTextSearch(queryText, {
        columns: [textColumn]
      })
      .select(["text", "keywords", "label"])
      .limit(5)
      .toArray();
    ```

!!! info "Automatic Index Updates"
    Newly added or modified records become searchable immediately. 
    The full-text search (FTS) index updates automatically in the background, 
    ensuring continuous search availability without blocking queries.

## Advanced Search Features

### Fuzzy Search
Fuzzy search allows you to find matches even when the search terms contain typos or slight variations. 
LanceDB uses the classic [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) 
to find similar terms within a specified edit distance.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| fuzziness | int | 0 | Maximum edit distance allowed for each term. If not specified, automatically set based on term length: 0 for length ≤ 2, 1 for length ≤ 5, 2 for length > 5 |
| max_expansions | int | 50 | Maximum number of terms to consider for fuzzy matching. Higher values may improve recall but increase search time |

Let's create a sample table and build full-text search indices to demonstrate 
fuzzy search capabilities and relevance boosting features.

=== "Python"
    ```python
    import lancedb

    # connect to LanceDB
    db = lancedb.connect(
      uri="db://your-project-slug",
      api_key="your-api-key",
      region="us-east-1"
    )

    table_name = "fts-fuzzy-boosting-test"
    vectors = [np.random.randn(128) for _ in range(100)]
    text_nouns = ("puppy", "car")
    text2_nouns = ("rabbit", "girl", "monkey")
    verbs = ("runs", "hits", "jumps", "drives", "barfs")
    adv = ("crazily.", "dutifully.", "foolishly.", "merrily.", "occasionally.")
    adj = ("adorable", "clueless", "dirty", "odd", "stupid")
    text = [
        " ".join(
            [
                text_nouns[random.randrange(0, len(text_nouns))],
                verbs[random.randrange(0, 5)],
                adv[random.randrange(0, 5)],
                adj[random.randrange(0, 5)],
            ]
        )
        for _ in range(100)
    ]
    text2 = [
        " ".join(
            [
                text2_nouns[random.randrange(0, len(text2_nouns))],
                verbs[random.randrange(0, 5)],
                adv[random.randrange(0, 5)],
                adj[random.randrange(0, 5)],
            ]
        )
        for _ in range(100)
    ]
    count = [random.randint(1, 10000) for _ in range(100)]

    table = db.create_table(
        table_name,
        data=pd.DataFrame(
            {
                "vector": vectors,
                "id": [i % 2 for i in range(100)],
                "text": text,
                "text2": text2,
                "count": count,
            }
        ),
        mode="overwrite"
    )

    table.create_fts_index("text")
    wait_for_index(table, "text_idx")
    table.create_fts_index("text2")
    wait_for_index(table, "text2_idx")
    ```

=== "TypeScript"
    ```typescript
    import * as lancedb from "@lancedb/lancedb"

    const db = await lancedb.connect({
      uri: "db://your-project-slug",
      apiKey: "your-api-key",
      region: "us-east-1"
    });

    const tableName = "fts-fuzzy-boosting-test-ts";
      
    // Generate sample data
    const n = 100;
    const vectors = Array.from({ length: n }, () => 
      Array.from({ length: 128 }, () => Math.random() * 2 - 1)
    );

    const textNouns = ["puppy", "car"];
    const text2Nouns = ["rabbit", "girl", "monkey"];
    const verbs = ["runs", "hits", "jumps", "drives", "barfs"];
    const adverbs = ["crazily", "dutifully", "foolishly", "merrily", "occasionally"];
    const adjectives = ["adorable", "clueless", "dirty", "odd", "stupid"];

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

    // Create table with data
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
    console.log(`Created table: ${tableName}`);

    // Create FTS indices
    console.log("Creating FTS indices...");
    await table.createIndex("text", { config: Index.fts() });
    await waitForIndex(table, "text_idx");
    await table.createIndex("text2", { config: Index.fts() });
    await waitForIndex(table, "text2_idx");
    ```

To demonstrate fuzzy search's ability to handle typos and misspellings, let's perform 
a search with a deliberately misspelled word. The search engine will attempt to match 
similar terms within the specified edit distance.

=== "Python"
    ```python
    from lancedb.query import MatchQuery

    print("\n=== Match Query Examples ===")
    # Basic match
    print("\n1. Basic Match Query for 'crazily':")
    basic_match_results = (
        table.search(MatchQuery("crazily", "text"), query_type="fts")
        .select(["id", "text"])
        .limit(100)
        .to_pandas()
    )

    # Fuzzy match (allows typos)
    print("\n2. Fuzzy Match Query for 'crazi~1' (with typo):")
    fuzzy_results = (
        table.search(MatchQuery("crazi~1", "text", fuzziness=2), query_type="fts")
        .select(["id", "text"])
        .limit(100)
        .to_pandas()
    )
    ```

=== "TypeScript"
    ```typescript
    import { MatchQuery } from "@lancedb/lancedb";

    // Basic match
    console.log("\n1. Basic Match Query for 'crazily':");
    const basicMatchResults = await table.query()
      .fullTextSearch(new MatchQuery("crazily", "text"))
      .select(["id", "text"])
      .limit(100)
      .toArray();
    console.log(basicMatchResults);

    // Fuzzy match
    console.log("\n2. Fuzzy Match Query for 'crazi~1' (with typo):");
    const fuzzyResults = await table.query()
      .fullTextSearch(new MatchQuery("crazi~1", "text", {
        fuzziness: 2,
      }))  // fuzziness of 2
      .select(["id", "text"])
      .limit(100)
      .toArray();
    console.log(fuzzyResults);
    ```

### Phrase Match

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
        table.search(PhraseQuery("puppy runs", "text"), query_type="fts")
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

### Search with Boosting

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
          query_type="fts",
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
        table.search(MultiMatchQuery("crazily", ["text", "text2"]), query_type="fts")
        .select(["id", "text", "text2"])
        .limit(100)
        .to_pandas()
    )

    # Search with field boosting
    print("\n2. Searching with boosted text2 field:")
    multi_match_boosting_results = (
        table.search(
            MultiMatchQuery("crazily", ["text", "text2"], boosts=[1.0, 2.0]),
            query_type="fts",
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

### Full-Text Search on Array Fields

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
    result = table.search(MatchQuery("learnin", column="tags", fuzziness=1), query_type="fts").select(['id', 'tags', 'description']).to_arrow()

    print("\nSearching for 'machine learning' in tags:")
    result = table.search(PhraseQuery("machine learning", column="tags"), query_type="fts").select(['id', 'tags', 'description']).to_arrow()
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


# Full-text search (Tantivy-based FTS)

LanceDB also provides support for full-text search via [Tantivy](https://github.com/quickwit-oss/tantivy), allowing you to incorporate keyword-based search (based on BM25) in your retrieval solutions.

The tantivy-based FTS is only available in Python synchronous APIs and does not support building indexes on object storage or incremental indexing. If you need these features, try native FTS [native FTS](fts.md).

## Installation

To use full-text search, install the dependency [`tantivy-py`](https://github.com/quickwit-oss/tantivy-py):

```sh
# Say you want to use tantivy==0.20.1
pip install tantivy==0.20.1
```

## Example

Consider that we have a LanceDB table named `my_table`, whose string column `content` we want to index and query via keyword search, the FTS index must be created before you can search via keywords.

```python
import lancedb

uri = "data/sample-lancedb"
db = lancedb.connect(uri)

table = db.create_table(
    "my_table",
    data=[
        {"id": 1, "vector": [3.1, 4.1], "title": "happy puppy", "content": "Frodo was a happy puppy", "meta": "foo"},
        {"id": 2, "vector": [5.9, 26.5], "title": "playing kittens", "content": "There are several kittens playing around the puppy", "meta": "bar"},
    ],
)

# passing `use_tantivy=False` to use lance FTS index
# `use_tantivy=True` by default
table.create_fts_index("content", use_tantivy=True)
table.search("puppy").limit(10).select(["content"]).to_list()
# [{'text': 'Frodo was a happy puppy', '_score': 0.6931471824645996}]
# ...
```

It would search on all indexed columns by default, so it's useful when there are multiple indexed columns.

!!! note
    LanceDB automatically searches on the existing FTS index if the input to the search is of type `str`. If you provide a vector as input, LanceDB will search the ANN index instead.

## Tokenization
By default the text is tokenized by splitting on punctuation and whitespaces and then removing tokens that are longer than 40 chars. For more language specific tokenization then provide the argument tokenizer_name with the 2 letter language code followed by "_stem". So for english it would be "en_stem".

```python
table.create_fts_index("content", use_tantivy=True, tokenizer_name="en_stem", replace=True)
```

the following [languages](https://docs.rs/tantivy/latest/tantivy/tokenizer/enum.Language.html) are currently supported.

## Index multiple columns

If you have multiple string columns to index, there's no need to combine them manually -- simply pass them all as a list to `create_fts_index`:

```python
table.create_fts_index(["title", "content"], use_tantivy=True, replace=True)
```

Note that the search API call does not change - you can search over all indexed columns at once.

## Filtering

Currently the LanceDB full text search feature supports *post-filtering*, meaning filters are
applied on top of the full text search results (see [native FTS](fts.md) if you need pre-filtering). This can be invoked via the familiar
`where` syntax:

```python
table.search("puppy").limit(10).where("meta='foo'").to_list()
```

## Sorting

You can pre-sort the documents by specifying `ordering_field_names` when
creating the full-text search index. Once pre-sorted, you can then specify
`ordering_field_name` while searching to return results sorted by the given
field. For example,

```python
table.create_fts_index(["content"], use_tantivy=True, ordering_field_names=["id"], replace=True)

(table.search("puppy", ordering_field_name="id")
 .limit(20)
 .to_list())
```

!!! note
    If you wish to specify an ordering field at query time, you must also
    have specified it during indexing time. Otherwise at query time, an
    error will be raised that looks like `ValueError: The field does not exist: xxx`

!!! note
    The fields to sort on must be of typed unsigned integer, or else you will see
    an error during indexing that looks like
    `TypeError: argument 'value': 'float' object cannot be interpreted as an integer`.

!!! note
    You can specify multiple fields for ordering at indexing time.
    But at query time only one ordering field is supported.


## Phrase queries vs. terms queries

For full-text search you can specify either a **phrase** query like `"the old man and the sea"`,
or a **terms** search query like `"(Old AND Man) AND Sea"`. For more details on the terms
query syntax, see Tantivy's [query parser rules](https://docs.rs/tantivy/latest/tantivy/query/struct.QueryParser.html).

!!! tip "Note"
    The query parser will raise an exception on queries that are ambiguous. For example, in the query `they could have been dogs OR cats`, `OR` is capitalized so it's considered a keyword query operator. But it's ambiguous how the left part should be treated. So if you submit this search query as is, you'll get `Syntax Error: they could have been dogs OR cats`.

    ```py
    # This raises a syntax error
    table.search("they could have been dogs OR cats")
    ```

    On the other hand, lowercasing `OR` to `or` will work, because there are no capitalized logical operators and
    the query is treated as a phrase query.

    ```py
    # This works!
    table.search("they could have been dogs or cats")
    ```

It can be cumbersome to have to remember what will cause a syntax error depending on the type of
query you want to perform. To make this simpler, when you want to perform a phrase query, you can
enforce it in one of two ways:

1. Place the double-quoted query inside single quotes. For example, `table.search('"they could have been dogs OR cats"')` is treated as
a phrase query.
1. Explicitly declare the `phrase_query()` method. This is useful when you have a phrase query that
itself contains double quotes. For example, `table.search('the cats OR dogs were not really "pets" at all').phrase_query()`
is treated as a phrase query.

In general, a query that's declared as a phrase query will be wrapped in double quotes during parsing, with nested
double quotes replaced by single quotes.


## Configurations

By default, LanceDB configures a 1GB heap size limit for creating the index. You can
reduce this if running on a smaller node, or increase this for faster performance while
indexing a larger corpus.

```python
# configure a 512MB heap size
heap = 1024 * 1024 * 512
table.create_fts_index(["title", "content"], use_tantivy=True, writer_heap_size=heap, replace=True)
```

## Current limitations

1. New data added after creating the FTS index will appear in search results, but with increased latency due to a flat search on the unindexed portion. Re-indexing with `create_fts_index` will reduce latency. LanceDB Cloud automates this merging process, minimizing the impact on search speed. 

2. We currently only support local filesystem paths for the FTS index.
   This is a tantivy limitation. We've implemented an object store plugin
   but there's no way in tantivy-py to specify to use it.
