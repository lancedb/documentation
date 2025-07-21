

## Triggering backfill

Triggering backfill creates a distributed job to run the UDF and populate the column values in your LanceDB table. The Geneva framework simplifies several aspects of distributed execution.

* **Checkpoints**:  Each batch of UDF execution is checkpointed so that partial results are not lost in case of job failures.  Jobs can resume and avoid most of the expense of having to recalculate values.


## Filtered Backfills

Geneva allows you to specify filters on the backfill operation.  This lets you to apply backfills to a specified subset of the table's rows.

```python
    # only backfill video content whose filenames start with 'a'
    tbl.backfill("content", where="starts_with(filename, 'a')")
    # only backfill embeddings of only those videos with content
    tbl.backfill("embedding", where="content is not null")
```

Geneva also allows you to incrementally add more rows or have jobs that just update rows that were previously skipped.

If new rows are added, we can run the same command and the new rows that meet the criteria will be updated.

```python
    # only backfill video content whose filenames start with 'a'
    tbl.backfill("content", where="starts_with(filename, 'a')")
    # only backfill embeddings of only those videos with content
    tbl.backfill("embedding", where="content is not null")
```

Or, you can use filters to add in or overwrite content in rows previously backfilled.

```python
    # only backfill video content whose filenames start with 'a' or 'b' but only if content not pulled previously
    tbl.backfill("content", where="(starts_with(filename, 'a') or starts_with(filename, 'b')) and content is null")
    # only backfill embeddings of only those videos with content and no prevoius embeddings
    tbl.backfill("embedding", where="content is not null and embeddding is not null")
```
