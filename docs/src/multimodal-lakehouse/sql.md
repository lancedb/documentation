# SQL Exploration

Geneva allows fast SQL exploration over your lance dataset


```sh
pip install geneva
```

Run SQL queries

```python
import geneva
import pyarrow as pa

with geneva.connect("db://mydb", host_override="https://101.101.101.101") \
    as conn:
    tbl: pa.Table = conn.query(
        "SELECT views FROM my_videos WHERE view_count>100 LIMIT 50"
    )
```