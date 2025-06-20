import os
import shutil
import datasets
from huggingface_hub import constants

def show_cache_info():
    """Show detailed cache information"""
    from huggingface_hub import scan_cache_dir
    
    cache_info = scan_cache_dir()
    
    print(f"Total cache size: {cache_info.size_on_disk / (1024**3):.2f} GB")
    print(f"Number of repos: {len(cache_info.repos)}")
    print("\nTop 10 largest repos:")
    
    sorted_repos = sorted(cache_info.repos, key=lambda x: x.size_on_disk, reverse=True)
    for repo in sorted_repos[:10]:
        print(f"  {repo.repo_id}: {repo.size_on_disk / (1024**2):.1f} MB")

def force_clean_all():
    """Force clean all caches without prompts"""
    
    cache_dirs = [
        constants.HUGGINGFACE_HUB_CACHE,
        datasets.config.HF_DATASETS_CACHE
    ]
    
    for cache_dir in cache_dirs:
        if os.path.exists(cache_dir):
            print(f"Removing {cache_dir}")
            shutil.rmtree(cache_dir)
            print(f"Removed {cache_dir}")

if __name__ == "__main__":
    show_cache_info()

    force_clean_all()