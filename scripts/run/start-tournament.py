from nile.nre import NileRuntimeEnvironment
from nile import cli


def run(nre: NileRuntimeEnvironment):
    print("Start tournament")

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")
    res = admin.send("tournament", "start", [])
    print(res)
