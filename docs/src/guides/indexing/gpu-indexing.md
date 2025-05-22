---
title: "GPU-Powered Vector Indexing in LanceDB"
description: "Learn about LanceDB's high-performance GPU-based vector indexing capabilities. Scale your vector search to billions of rows with accelerated indexing performance."
keywords: "LanceDB GPU indexing, vector database acceleration, enterprise vector search, GPU-powered indexing, large-scale vector search, enterprise features"
---

# GPU-Powered Vector Indexing 

With LanceDB's GPU-powered indexing you can create vector indexes for billions of rows in just a few hours. This can significantly accelerate your vector search operations. 

> In our tests, LanceDB's GPU-powered indexing can process billions of vectors in under four hours, providing significant performance improvements over CPU-based indexing.

## Automatic GPU Indexing in LanceDB Enterprise

!!! info "LanceDB Enterprise Only"
    Automatic GPU Indexing is currently only available in LanceDB Enterprise. Please [contact us](mailto:contact@lancedb.com) to enable this feature for your deployment.

GPU indexing is automatic in LanceDB Enterprise and it is used to build either the IVF or HNSW indexes. 

> Whenever you `create_index`, the backend will use GPU resources to build either the IVF or HNSW indexes. The system automatically selects the optimal GPU configuration based on your data size and available hardware.

This process is also asynchronous by default, but you can use `wait_for_index` to convert it into a synchronous process by waiting until the index is built.

## Manual GPU Indexing in LanceDB OSS

You can use the Python SDK to manually create the IVF_PQ index. You will need [PyTorch>2.0](https://pytorch.org/). Please keep in mind that GPU based indexing is currently only supported by the synchronous SDK.

You can specify the GPU device to train IVF partitions via `accelerator`. Specify parameters `cuda` or `mps` (on Apple Silicon) to enable GPU training.

=== "Linux"

    <!-- skip-test -->
    ``` { .python .copy }
    # Create index using CUDA on Nvidia GPUs.
    tbl.create_index(
        num_partitions=256,
        num_sub_vectors=96,
        accelerator="cuda"
    )
    ```

=== "MacOS"

    <!-- skip-test -->
    ```python
    # Create index using MPS on Apple Silicon.
    tbl.create_index(
        num_partitions=256,
        num_sub_vectors=96,
        accelerator="mps"
    )
    ```

## Performance Considerations

- GPU memory usage scales with `num_partitions` and vector dimensions
- For optimal performance, ensure GPU memory exceeds dataset size
- Batch size is automatically tuned based on available GPU memory
- Indexing speed improves with larger batch sizes

## Troubleshooting

If you encounter the error `AssertionError: Torch not compiled with CUDA enabled`, you need to [install PyTorch with CUDA support](https://pytorch.org/get-started/locally/).