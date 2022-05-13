# scripts/deploy-starkonquest-boarding-pass.py
import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import prepare_nile_deploy


def run(nre: NileRuntimeEnvironment):
    print("Deploying starkonquest_boarding_pass contract…")
    prepare_nile_deploy()

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")

    name = str(str_to_felt("StarKonquestBoardingPass"))
    symbol = str(str_to_felt("SKBP"))
    owner = admin.address
    params = [name, symbol, owner]
    address, abi = nre.deploy(
        "starkonquest_boarding_pass",
        params,
        alias="starkonquest_boarding_pass",
        overriding_path=("build", "build"),
    )
    print(f"ABI: {abi},\nBoardingPass contract address: {address}")


# Auxiliary functions
def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def uint(a):
    return (a, 0)
