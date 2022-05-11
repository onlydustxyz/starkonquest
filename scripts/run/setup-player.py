import os
import random
import sys
from nile.nre import NileRuntimeEnvironment
from nile import accounts, deployments
from nile.core.call_or_invoke import call_or_invoke
from nile.core.deploy import deploy

sys.path.append(os.path.dirname(__file__))
from utils import send


def run(nre: NileRuntimeEnvironment):
    print("Setup player account and mint boarding pass")

    player = nre.get_or_deploy_account("PKEYPLAYER")
    print(f"Player account address: {player.address}")

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")
    res = send(admin, "starkonquest_boarding_pass", "mint", [player.address, str(random.randrange(2^64)), "0"])
    print(res)