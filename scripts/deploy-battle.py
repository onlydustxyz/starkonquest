# scripts/deploy.py
import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import prepare_nile_deploy


def run(nre: NileRuntimeEnvironment):
    print("Deploying battle contract…")
    prepare_nile_deploy()

    address, abi = nre.deploy(
        "battle", alias="battle", overriding_path=("build", "build")
    )
    print(f"ABI: {abi},\nBattle contract address: {address}")
