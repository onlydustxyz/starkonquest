# scripts/deploy.py
import os
from nile.nre import NileRuntimeEnvironment
from nile.core.call_or_invoke import call_or_invoke


def run(nre: NileRuntimeEnvironment):
    print("Compiling contracts…")

    nre.compile(["contracts/core/space/space.cairo"])

    print("Deploying contracts…")

    print(f"Deploying Space contract")
    spaceAddress, abi = nre.deploy("space", alias="space")
    print(f"ABI: {abi},\nSpace contract address: {spaceAddress}")
