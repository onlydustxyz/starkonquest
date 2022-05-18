import os
import sys
from nile.nre import NileRuntimeEnvironment
from nile import deployments
from nile.core.call_or_invoke import call_or_invoke

sys.path.append(os.path.dirname(__file__))
from utils import get_tournament_address
from utils import send


def run(nre: NileRuntimeEnvironment):
    print("Register ship")

    player = nre.get_or_deploy_account("PKEYPLAYER")
    print(f"Player account address: {player.address}")

    ship_address = os.getenv("SHIP_ADDRESS")
    assert len(ship_address) > 0
    print(f"Ship address: {ship_address}")

    res = send(player, get_tournament_address(), "register", [ship_address])
    print(res)
