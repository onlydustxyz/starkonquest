# scripts/deploy-random.py
import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import prepare_nile_deploy


def run(nre: NileRuntimeEnvironment):
    print("Deploying basic ship contract…")
    prepare_nile_deploy()

    address, abi = nre.deploy("basic_ship", alias="basic_ship", overriding_path=("build", "build"))
    print(f"ABI: {abi},\nBasicShip contract address: {address}")
