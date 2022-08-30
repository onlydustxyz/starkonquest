# scripts/deploy-tournament.py
import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import prepare_nile_deploy


def run(nre: NileRuntimeEnvironment):
    print("Deploying tournament contract…")
    prepare_nile_deploy()

    admin = nre.get_or_deploy_account("PKEYADMIN")
    print(f"Admin account address: {admin.address}")

    tournament_id = os.environ["TOURNAMENT_ID"]
    tournament_name = os.environ["TOURNAMENT_NAME"]
    ships_per_battle = os.environ["SHIPS_PER_BATTLE"]
    required_total_ship_count = os.environ["TOTAL_SHIP_COUNT"]
    grid_size = os.environ["GRID_SIZE"]
    turn_count = os.environ["TURN_COUNT"]
    max_dust = os.environ["MAX_DUST"]

    owner = admin.address
    tournament_name = str(str_to_felt(tournament_name))

    reward_token_address, _ = nre.get_deployment("only_dust_token")
    assert reward_token_address != None
    print(f"reward_token_address={reward_token_address}")

    boarding_pass_token_address, _ = nre.get_deployment("starkonquest_boarding_pass")
    assert boarding_pass_token_address != None
    print(f"boarding_pass_token_address={boarding_pass_token_address}")

    battle_address, _ = nre.get_deployment("battle")
    assert battle_address != None
    print(f"battle_address={battle_address}")

    random_address, _ = nre.get_deployment("random")
    assert random_address != None
    print(f"random_address={random_address}")

    account_address, _ = nre.get_deployment("account")
    assert account_address != None
    print(f"account_address={account_address}")

    params = [
        owner,
        tournament_id,
        tournament_name,
        reward_token_address,
        boarding_pass_token_address,
        random_address,
        battle_address,
        account_address,
        ships_per_battle,
        required_total_ship_count,
        grid_size,
        turn_count,
        max_dust,
    ]
    address, abi = nre.deploy(
        "tournament", params, alias="tournament", overriding_path=("build", "build")
    )
    print(f"ABI: {abi},\nTournament contract address: {address}")


# Auxiliary functions
def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def uint(a):
    return (a, 0)
