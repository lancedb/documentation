---
title: LanceDB Data Management Guide | Versioning, Schema Evolution & Organization
description: Master LanceDB's data management with our comprehensive guide. Learn about versioning, schema evolution, data organization, and best practices for efficient vector data storage and retrieval.
---

# **Data Management in LanceDB**

This section covers essential concepts for managing your data effectively in LanceDB.

## Understanding Lance Data Format

Because LanceDB is built on top of the [Lance](https://lancedb.github.io/lance/) data format, it helps to understand some of its core ideas. Just like Apache Arrow, Lance is a fast columnar data format, but it has the added benefit of being versionable, query and train ML models on. Lance is designed to be used with simple and complex data types, like tabular data, images, videos audio, 3D point clouds (which are deeply nested) and more.

The following concepts are important to keep in mind:

- Data storage is columnar and is interoperable with other columnar formats (such as Parquet) via Arrow
- Data is divided into fragments that represent a subset of the data
- Data is versioned, with each insert operation creating a new version of the dataset and an update to the manifest that tracks versions via metadata

!!! note
    1. First, each version contains metadata and just the new/updated data in your transaction. So if you have 100 versions, they aren't 100 duplicates of the same data. However, they do have 100x the metadata overhead of a single version, which can result in slower queries.  
    2. Second, these versions exist to keep LanceDB scalable and consistent. We do not immediately blow away old versions when creating new ones because other clients might be in the middle of querying the old version. It's important to retain older versions for as long as they might be queried.

## Understanding Data Fragments

Fragments are chunks of data in a Lance dataset. Each fragment includes multiple files that contain several columns in the chunk of data that it represents.

## Data Compaction and Performance

As you insert more data, your dataset will grow and you'll need to perform *compaction* to maintain query throughput (i.e., keep latencies down to a minimum). Compaction is the process of merging fragments together to reduce the amount of metadata that needs to be managed, and to reduce the number of files that need to be opened while scanning the dataset.

### Performance Optimization Through Compaction

Compaction performs the following tasks in the background:

- Removes deleted rows from fragments
- Removes dropped columns from fragments
- Merges small fragments into larger ones

Depending on the use case and dataset, optimal compaction will have different requirements. As a rule of thumb:

- It's always better to use *batch* inserts rather than adding 1 row at a time (to avoid too small fragments). If single-row inserts are unavoidable, run compaction on a regular basis to merge them into larger fragments.
- Keep the number of fragments under 100, which is suitable for most use cases (for *really* large datasets of >500M rows, more fragments might be needed)

## Data Deletion and Recovery

Although Lance allows you to delete rows from a dataset, it does not actually delete the data immediately. It simply marks the row as deleted in the `DataFile` that represents a fragment. For a given version of the dataset, each fragment can have up to one deletion file (if no rows were ever deleted from that fragment, it will not have a deletion file). This is important to keep in mind because it means that the data is still there, and can be recovered if needed, as long as that version still exists based on your backup policy.

