## Converting functions into UDFs

Converting your Python code to a Geneva UDF is simple.  There are three kinds of UDFs that you can provide — scalar UDFs, batched UDFs and stateful UDFs.

In all cases, Geneva uses Python type hints from your functions to infer the input and output
[arrow data types](https://arrow.apache.org/docs/python/api/datatypes.html) that LanceDB uses.

### Scalar UDFs

The **simplest** form is a scalar UDF, which processes one row at a time:

```python
from geneva import udf

@udf
def area_udf(x: int, y: int) -> int:
    return x * y

@udf
def download_udf(filename:str) -> bytes:
    import requests
    resp = requests.get(filename)
    res.raise_for_status()
    return resp.content

```

This UDF will take the value of x and value of y from each row and return the product.  The `@udf` wrapper is all that is needed.

### Batched UDFs

For **better performance**, you can also define batch UDFs that process multiple rows at once.

You can use `pyarrow.Array`s:

```python
import pyarrow as pa
from geneva import udf

@udf(data_type=pa.int32())
def batch_filename_len(filename: pa.Array) -> pa.Array:
    lengths = [len(str(f)) for f in filename]
    return pa.array(lengths, type=pa.int32())
```

Or take entire rows using `pyarrow.RecordBatch`:

```python
import pyarrow as pa
from geneva import udf

@udf(data_type=pa.int32())
def recordbatch_filename_len(batch: pa.RecordBatch) -> pa.Array:
    filenames = batch["filename"] 
    lengths = [len(str(f)) for f in filenames]
    return pa.array(lengths, type=pa.int32())
```

!!! note

    Batch UDFS require you to specify `data_type` in the ``@udf`` decorator for batched UDFs,
    which defines `pyarrow.DataType` of the returned `pyarrow.Array`.


### Stateful UDFs

You can also define a **stateful** UDF that retains its state across calls.

This can be used to share code and **parameterize your UDFs**.  In the example below, the model being used is a parameter that can be specified at UDF registration time.  It can also be used to paramterize input column names of `pa.RecordBatch` batch UDFS.

This also can be used to **optimize expensive initialization** that may require heavy resource on the distributed workers.  For example, this can be used to load an model to the GPU once for all records sent to a worker instead of once per record or per batch of records.

A stateful UDF is a `Callable` class, with `__call__()` method.  The call method can be a scalar function or a batched function.

```python
from typing import Callable
from openai import OpenAI

@udf(data_type=pa.list_(pa.float32(), 1536))
class OpenAIEmbedding(Callable):
    def __init__(self, model: str = "text-embedding-3-small"):
        self.model = model
        # Per-worker openai client
        self.client: OpenAI | None = None

    def __call__(self, text: str) -> pa.Array:
        if self.client is None:
            self.client = OpenAI()

        resp = self.client.embeddings.create(model=self.model, input=text)
        return pa.array(resp.data[0].embeddings)
```

!!! note

    The state is will be independently managed on each distributed Worker.


## Registering Features with UDFs

Registering a feature is done by providing the `Table.add_columns()` function a new column name and the Geneva UDF.

Let's start by obtaining the table `tbl`
```python
import geneva
import numpy as np
import pyarrow as pa

lancedb_uri="gs://bucket/db"
db = geneva.connect(lancedb_uri)

# Define schema for the video table
schema = pa.schema([
    ("filename", pa.string()),
    ("duration_sec", pa.float32()),
    ("x", pa.int32()),
    ("y", pa.int32()),
])
tbl = db.create_table("videos", schema=schema, mode="overwrite")

# Generate fake data
N = 10
data = {
    "filename": [f"video_{i}.mp4" for i in range(N)],
    "duration_sec": np.random.uniform(10, 300, size=N).astype(np.float32),
    "x": np.random.choice([640, 1280, 1920], size=N),
    "y": np.random.choice([360, 720, 1080], size=N),
    "caption": [f"this is video {i}" for i in range(N)]
}

# Convert to Arrow Table and add to LanceDB
batch = pa.table(data, schema=schema)
tbl.add(batch)
```

Here's how to register a simple UDF:
```python
@udf
def area_udf(x: int, y: int) -> int:
    return x * y

@udf
def download_udf(filename: str) -> bytes:
    ...

# {'new column name': <udf>, ...}
# simple_udf's arguments are `x` and `y` so the input columns are
# inferred to be columns `x` amd `y`
tbl.add_columns({"area": area_udf, "content": download_udf })
```

Batched UDFs require return type in their `udf` annotations

```python
@udf(data_type=pa.int32())
def batch_filename_len(filename: pa.Array) -> pa.Array:
    ...

# {'new column name': <udf>}
# batch_filename_len's input, `filename` input column is
# specified by the UDF's argument name.
tbl.add_columns({"filename_len": batch_filename_len})
```

or

```python
@udf(data_type=pa.int32())
def recordbatch_filename_len(batch: pa.RecordBatch) -> pa.Array:
    ...

# {'new column name': <udf>}
# batch_filename_len's input.  pa.RecordBatch typed UDF
# argument pulls in all the column values for each row.
tbl.add_columns({"filename_len": recordbatch_filename_len})
```

Similarly, a stateful UDF is registered by providing an instance of the Callable object.  The call method may be a per-record function or a batch function.
```python
@udf(data_type=pa.list_(pa.float32(), 1536))
class OpenAIEmbedding(Callable):
    ...
    def __call__(self, text: str) -> pa.Array:
        ...

# OpenAIEbmedding's call method input is inferred to be 'text' of
# type string from the __call__'s arguments, and its output type is
# a fixed size list of float32.
tbl.add_columns({"embedding": OpenAIEmbedding()})
```



### UDF API
All UDFs are decorated by ``@geneva.udf``.

::: geneva.udf
    options:
      annotations_path: brief
      show_source: false

