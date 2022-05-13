# scripts/deploy-only-dust-erc20.py
import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import prepare_nile_deploy


def run(nre: NileRuntimeEnvironment):
    print("Deploying OnlyDust ERC20 contract…")
    prepare_nile_deploy()

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")

    name = str(str_to_felt("OnlyDust"))
    symbol = str(str_to_felt("ODUST"))
    decimals = "18"
    recipient = admin.address
    params = [name, symbol, decimals, "10000000000000000000000", "0", recipient]
    address, abi = nre.deploy(
        "only_dust", params, alias="only_dust_token", overriding_path=("build", "build")
    )
    print(f"ABI: {abi},\nOnlyDust ERC20 contract address: {address}")


# Auxiliary functions
def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def uint(a):
    return (a, 0)
