import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import get_tournament_address
from utils import send


def run(nre: NileRuntimeEnvironment):
    print("Start tournament")

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")
    res = send(admin, get_tournament_address(), "start", [])
    print(res)
