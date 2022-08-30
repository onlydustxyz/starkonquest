# scripts/deploy-starkonquest-boarding-pass.py
import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import prepare_nile_deploy


def run(nre: NileRuntimeEnvironment):
    print("Deploying account-erc721 contract…")
    prepare_nile_deploy()

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")

    name = str(str_to_felt("StarKonquestAccount"))
    symbol = str(str_to_felt("SKA"))
    owner = admin.address
    params = [name, symbol, owner]
    address, abi = nre.deploy(
        "account",
        params,
        alias="account",
        overriding_path=("build", "build"),
    )
    print(f"ABI: {abi},\Account contract address: {address}")


# Auxiliary functions
def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def uint(a):
    return (a, 0)
