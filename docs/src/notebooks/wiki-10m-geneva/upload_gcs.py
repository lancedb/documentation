import datasets
from pathlib import Path
from google.cloud.storage import Client, transfer_manager

def upload_directory_with_transfer_manager(bucket_name, source_directory, workers=8):
    storage_client = Client()
    bucket = storage_client.bucket(bucket_name)

    directory_as_path_obj = Path(source_directory)
    paths = directory_as_path_obj.rglob("*")
    file_paths = [path for path in paths if path.is_file()]
    relative_paths = [path.relative_to(source_directory) for path in file_paths]
    string_paths = [str(path) for path in relative_paths]

    print("Found {} files.".format(len(string_paths)))

    results = transfer_manager.upload_many_from_filenames(
        bucket, string_paths, source_directory=source_directory, max_workers=workers
    )

    for name, result in zip(string_paths, results):
        if isinstance(result, Exception):
            print("Failed to upload {} due to exception: {}".format(name, result))
        else:
            print("Uploaded {} to {}.".format(name, bucket.name))

def download_and_upload_dataset(bucket_name):
    dataset = datasets.load_dataset(
        "wikipedia", "20220301.en", num_proc=16, trust_remote_code=True
    )
    dataset.save_to_disk("wikipedia")
    
    upload_directory_with_transfer_manager(bucket_name, "wikipedia")

if __name__ == "__main__":
    download_and_upload_dataset("wikipedia-geneva")