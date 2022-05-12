import os
import sys
from nile.nre import NileRuntimeEnvironment
from nile import deployments
from nile.core.call_or_invoke import call_or_invoke

sys.path.append(os.path.dirname(__file__))
from utils import get_tournament_address


def run(nre: NileRuntimeEnvironment):
    print("Register ship")

    player = nre.get_or_deploy_account("PKEYPLAYER")
    print(f"Player account address: {player.address}")

    ship_address = os.getenv("SHIP_ADDRESS")
    assert len(ship_address) > 0
    print(f"Ship address: {ship_address}")

    res = send(player, get_tournament_address(), "register", [ship_address])
    print(res)

def send(account, to, method, calldata, nonce=None):
    """Execute a tx going through an Account contract."""
    target_address, _ = next(deployments.load(to, account.network)) or to
    calldata = [int(x, base=16) for x in calldata]

    if nonce is None:
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
        type="invoke",
        method="__execute__",
        params=params,
        network=account.network,
        signature=[str(sig_r), str(sig_s)],
    )