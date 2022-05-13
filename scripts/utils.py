# scripts/utils.py
import os
import glob
import shutil

ABI_DIR = "build/abi"


def prepare_nile_deploy():
    print("Copying ABIs into separate directory…")
    if os.path.exists(ABI_DIR):
        shutil.rmtree(ABI_DIR)
    os.mkdir(ABI_DIR)
    abi_files = glob.glob("build/*_abi.json")
    for abi_file in abi_files:
        shutil.copy2(
            abi_file,
            abi_file.replace("build/", "build/abi/").replace("_abi.json", ".json"),
        )
    print("Done.")
