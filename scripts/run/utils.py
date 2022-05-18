import os
import subprocess

from nile import deployments
from nile.common import GATEWAYS


def get_tournament_address():
    return os.getenv("TOURNAMENT_ADDRESS", "tournament")


def send(account, to, method, calldata, type="invoke"):
    """Execute a tx going through an Account contract."""
    target_address, _ = next(deployments.load(to, account.network)) or to
    calldata = [int(x, base=16) for x in calldata]

    nonce = int(
        call_or_invoke(account.address, "call", "get_nonce", [], account.network)
    )

    (call_array, calldata, sig_r, sig_s) = account.signer.sign_transaction(
        sender=account.address, calls=[[target_address, method, calldata]], nonce=nonce
    )

    params = []
    params.append(str(len(call_array)))
    params.extend([str(elem) for sublist in call_array for elem in sublist])
    params.append(str(len(calldata)))
    params.extend([str(param) for param in calldata])
    params.append(str(nonce))

    return call_or_invoke(
        contract=account.address,
        type=type,
        method="__execute__",
        params=params,
        network=account.network,
        signature=[str(sig_r), str(sig_s)],
    )


def call_or_invoke(contract, type, method, params, network, signature=None):
    """Call or invoke functions of StarkNet smart contracts."""
    address, abi = next(deployments.load(contract, network))

    command = [
        "starknet",
        "--no_wallet",
        type,
        "--address",
        address,
        "--abi",
        abi,
        "--function",
        method,
    ]

    if network == "mainnet":
        os.environ["STARKNET_NETWORK"] = "alpha-mainnet"
    elif network == "goerli":
        os.environ["STARKNET_NETWORK"] = "alpha-goerli"
    else:
        gateway_prefix = "feeder_gateway" if type == "call" else "gateway"
        command.append(f"--{gateway_prefix}_url={GATEWAYS.get(network)}")

    if len(params) > 0:
        command.append("--inputs")
        command.extend(params)

    if signature is not None:
        command.append("--signature")
        command.extend(signature)

    return subprocess.check_output(command).strip().decode("utf-8")
