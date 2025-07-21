
Geneva automatically packages and deploys your Python execution environment to its worker nodes.  This ensures that distributed execution occurs in the same environment and depedencies as your prototype.

We currently support one processing backend: [Ray](https://www.anyscale.com/product/open-source/ray).  Geneva jobs can be deployed on a kubernetes cluster on demand or on an existing Ray cluster. 

!!! Note
    If you are using a remote Ray cluster, you will need to have the notebook or script that code is packaged on running the same CPU architecture / OS.  By default, Ray clusters are run in Linux.   If you host a jupyter service on a Mac, Geneva will attempt to deploy Mac shared libraries to a linux cluster and result in `Module not found` errors.  You can instead use a hosted jupyter notebook, or host your jupyter or python envrionment on a Linux VM or container.


=== "Ray Auto Connect"

    To execute jobs without an external Ray cluster, you can just trigger the `Table.backfill` method or the `Table.add_columns(..., backfill=True)` method.   This will autocreate a local Ray cluster and is only suitable prototyping on small datasets.

    ```python
    tbl.backfill("area")
    ```

    ```python
    # add column 'filename_len' and trigger the job
    tbl.backfill("filename_len")  # trigger the job
    ```

=== "Existing Ray Cluster"

    Geneva can execute jobs against an existing Ray cluster.  You can define a `RayCluster` by specifying the address of the cluster and packages needed on your workers.

    This approach makes it easy to tailor resource requirements to your particular UDFs.

    You can then wrap your table backfill call with the RayCluster context.

    ```python
    from geneva.runners.ray.raycluster import _HeadGroupSpec, _WorkerGroupSpec
    from geneva.runners._mgr import ray_cluster

    override_config(from_kv({"uploader.upload_dir": images_path + "/zips"}))

    with ray_cluster(
            addr = "ray-head:10001"  # replace ray head with the address of your ray head node
            skip_site_packages=False, # optionally skip shipping python site packages if already in image
            use_portforwarding=False,  # Must be False when byo ray cluster
            pip=[], # list of pip package or urls to install on each image.
        ):

        tbl.backfill("xy_product")
    ```

    !!! Note

        If your ray cluster is managed by kuberay, you'll need to setup kubectl port forwarding setup so geneva can connect.  


    For more interactive usage, you can use this pattern:

    ```python
    # this is a k8s pod spec.
    raycluster = ray_cluster(...)
    raycluster.__enter__() # equivalent of ray.init()

    #  trigger the backfill on column "filename_len" 
    tbl.backfill("filename_len") 

    raycluster.__exit__(None, None, None)
    ```

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
