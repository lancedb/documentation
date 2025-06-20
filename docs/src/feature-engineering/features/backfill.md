

## Triggering backfill

Triggering backfill creates a distributed job to run the UDF and populate the column values in your LanceDB table. The Geneva framework simplifies several aspects of distributed execution.

* **Environment management**:  Geneva automatically packages and deploys your Python execution environment to worker nodes.  This ensures that distributed execution occurs in the same environment and depedencies as your prototype.
* **Checkpoints**:  Each batch of UDF execution is checkpointed so that partial results are not lost in case of job failures.  Jobs can resume and avoid most of the expense of having to recalculate values.

We currently support one processing backend: [Ray](https://www.anyscale.com/product/open-source/ray).  This is deployed on an existing Ray cluster or on a kubernetes cluster on demand.

!!! Note
    If you are using a remote Ray cluster, you will need to have the notebook or script that code is packaged on running the same CPU architecture / OS.  By default, Ray clusters are run in Linux.   If you host a jupyter service on a Mac, Geneva will attempt to deploy Mac shared libraries to a linux cluster and result in `Module not found` errors.  You can instead host your jupyter or python envrionment on a Linux VM or container.

=== "Ray on Kubernetes"

    Geneva uses KubeRay to deploy Ray on Kubernetes.  You can define a `RayCluster` by specifying the pod name, the Kubernetes namespace, credentials to use for deploying Ray, and characteristics of your workers.

    This approach makes it easy to tailor resource requirements to your particular UDFs.

    You can then wrap your table backfill call with the RayCluster context.

    ```python
    from geneva.runners.ray.raycluster import _HeadGroupSpec, _WorkerGroupSpec
    from geneva.runners._mgr import ray_cluster

    override_config(from_kv({"uploader.upload_dir": images_path + "/zips"}))

    with ray_cluster(
            name=k8s_name,  # prefix of your k8s pod
            namespace=k8s_namespace,
            skip_site_packages=False, # optionally skip shipping python site packages if already in image
            use_portforwarding=True,  # required for kuberay to expose ray ports
            head_group=_HeadGroupSpec(
                service_account="geneva-integ-test", # k8s service account bound geneva runs as
                image="rayproject/ray:latest-py312" # optionally specified custom docker image
                num_cpus=8,
                node_selector={"geneva.lancedb.com/ray-head":""}, # k8s label required for head
            ),
            worker_groups=[
                _WorkerGroupSpec(  # specification per worker for cpu-only nodes
                    name="cpu",
                    num_cpus=60,
                    memory="120G",
                    service_account="geneva-integ-test",
                    image="rayproject/ray:latest-py312"
                    node_selector={"geneva.lancedb.com/ray-worker-cpu":""}, # k8s label for cpu worker
                ),
                _WorkerGroupSpec( # specification per worker for gpu nodes
                    name="gpu",
                    num_cpus=8,
                    memory="32G",
                    num_gpus=1,
                    service_account="geneva-integ-test",
                    image="rayproject/ray:latest-py312-gpu"
                    node_selector={"geneva.lancedb.com/ray-worker-gpu":""}, # k8s label for gpu worker
                ),
            ],
        ):

        tbl.backfill("xy_product")
    ```

    For more interactive usage, you can use this pattern:

    ```python
    # this is a k8s pod spec.
    raycluster = ray_cluster(...)
    raycluster.__enter__() # equivalent of ray.init()

    #  trigger the backfill on column "filename_len" 
    tbl.backfill("filename_len") 

    raycluster.__exit__()
    ```

    Whne you become more confident with your feature, you can trigger the backfill by specifying the `backfill` kwarg on `Table.add_columns()`.

    ```python
    tbl.add_columns({"filename_len": filename_len}, ["prompt"], backfill=True)
    ```

=== "Existing Ray Cluster"

    !!! Warning

        This is a work in progress


=== "Ray Auto Connect"

    To use ray, you can just trigger the `Table.backfill` method or the `Table.add_columns(..., backfill=True)` method.   This will autocreate a local Ray cluster and is only suitable prototyping on small datasets.

    ```python
    tbl.backfill("area")
    ```

    ```python
    # add column 'filename_len' and trigger the job
    tbl.backfill("filename_len")  # trigger the job
    ```

    Whne you become more confident with your feature, you can trigger the backfill by specifying the `backfill` kwarg on `Table.add_columns()`.

    ```python
    tbl.add_column({"filename_len": filename_len}, ["prompt"], backfill=True)
    ```



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
