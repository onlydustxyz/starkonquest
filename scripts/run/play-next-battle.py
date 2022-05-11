from nile.nre import NileRuntimeEnvironment
from nile import cli


def run(nre: NileRuntimeEnvironment):
    print("Play next battle")

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")
    res = admin.send("tournament", "play_next_battle", [])
    print(res)
