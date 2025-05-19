

# Build HNSW Index

There are three key parameters to set when constructing an HNSW index:

* `metric`: Use an `l2` euclidean distance metric. We also support `dot` and `cosine` distance.
* `m`: The number of neighbors to select for each vector in the HNSW graph.
* `ef_construction`: The number of candidates to evaluate during the construction of the HNSW graph.


We can combine the above concepts to understand how to build and query an HNSW index in LanceDB.

### Construct index

```python
import lancedb
import numpy as np
uri = "/tmp/lancedb"
db = lancedb.connect(uri)

# Create 10,000 sample vectors
data = [
    {"vector": row, "item": f"item {i}"}
    for i, row in enumerate(np.random.random((10_000, 1536)).astype('float32'))
]

# Add the vectors to a table
tbl = db.create_table("my_vectors", data=data)

# Create and train the HNSW index for a 1536-dimensional vector
# Make sure you have enough data in the table for an effective training step
tbl.create_index(index_type=IVF_HNSW_SQ)

```

### Query the index

```python
# Search using a random 1536-dimensional embedding
tbl.search(np.random.random((1536))) \
    .limit(2) \
    .to_pandas()
```


## Putting it all together

We can combine the above concepts to understand how to build and query an IVF-PQ index in LanceDB.

### Construct index

There are three key parameters to set when constructing an IVF-PQ index:

* `metric`: Use an `l2` euclidean distance metric. We also support `dot` and `cosine` distance.
* `num_partitions`: The number of partitions in the IVF portion of the index.
* `num_sub_vectors`: The number of sub-vectors that will be created during Product Quantization (PQ).

In Python, the index can be created as follows:

```python
# Create and train the index for a 1536-dimensional vector
# Make sure you have enough data in the table for an effective training step
tbl.create_index(metric="l2", num_partitions=256, num_sub_vectors=96)
```
!!! note
    `num_partitions`=256 and `num_sub_vectors`=96 does not work for every dataset. Those values needs to be adjusted for your particular dataset.

The `num_partitions` is usually chosen to target a particular number of vectors per partition. `num_sub_vectors` is typically chosen based on the desired recall and the dimensionality of the vector. See [here](../ann_indexes.md/#how-to-choose-num_partitions-and-num_sub_vectors-for-ivf_pq-index) for best practices on choosing these parameters.


### Query the index

```python
# Search using a random 1536-dimensional embedding
tbl.search(np.random.random((1536))) \
    .limit(2) \
    .nprobes(20) \
    .refine_factor(10) \
    .to_pandas()
```

The above query will perform a search on the table `tbl` using the given query vector, with the following parameters:

* `limit`: The number of results to return
* `nprobes`: The number of probes determines the distribution of vector space. While a higher number enhances search accuracy, it also results in slower performance. Typically, setting `nprobes` to cover 5–10% of the dataset proves effective in achieving high recall with minimal latency.
* `refine_factor`: Refine the results by reading extra elements and re-ranking them in memory. A higher number makes the search more accurate but also slower (see the [FAQ](../faq.md#do-i-need-to-set-a-refine-factor-when-using-an-index) page for more details on this).
* `to_pandas()`: Convert the results to a pandas DataFrame

And there you have it! You now understand what an IVF-PQ index is, and how to create and query it in LanceDB.
To see how to create an IVF-PQ index in LanceDB, take a look at the [ANN indexes](../ann_indexes.md) section.
