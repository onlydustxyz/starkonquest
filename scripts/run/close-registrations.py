from nile.nre import NileRuntimeEnvironment
from nile import cli


def run(nre: NileRuntimeEnvironment):
    print("Close registrations")

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")
    res = admin.send("tournament", "close_registrations", [])
    print(res)
