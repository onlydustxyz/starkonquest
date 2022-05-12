import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import get_tournament_address


def run(nre: NileRuntimeEnvironment):
    print("Play next battle")

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")
    res = admin.send(get_tournament_address(), "play_next_battle", [])
    print(res)
