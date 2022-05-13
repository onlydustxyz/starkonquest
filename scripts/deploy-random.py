# scripts/deploy-random.py
import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import prepare_nile_deploy


def run(nre: NileRuntimeEnvironment):
    print("Deploying the random contract…")
    prepare_nile_deploy()

    address, abi = nre.deploy(
        "random", alias="random", overriding_path=("build", "build")
    )
    print(f"ABI: {abi},\nRandom contract address: {address}")
