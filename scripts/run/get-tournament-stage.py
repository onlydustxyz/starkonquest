import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import get_tournament_address
from utils import send, call_or_invoke


def run(nre: NileRuntimeEnvironment):
    print("Get tournament stage")

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")
    res = send(admin, get_tournament_address(), "stage", [], "call")
    print(res)
