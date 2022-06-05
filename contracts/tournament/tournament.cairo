# SPDX-License-Identifier: Apache-2.0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from contracts.models.common import ShipInit, Vector2, Player
from contracts.tournament.library import tournament

# -----
# VIEWS
# -----
@view
func tournament_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tournament_id : felt
):
    return tournament.tournament_id()
end

@view
func tournament_name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tournament_name : felt
):
    return tournament.tournament_name()
end

@view
func tournament_winner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tournament_winner : Player
):
    return tournament.tournament_winner()
end

@view
func reward_token_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    reward_token_address : felt
):
    return tournament.reward_token_address()
end

@view
func boarding_pass_token_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (boarding_pass_token_address : felt):
    return tournament.boarding_pass_token_address()
end

@view
func rand_contract_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    rand_contract_address : felt
):
    return tournament.rand_contract_address()
end

@view
func stage{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (stage : felt):
    return tournament.stage()
end

@view
func reward_total_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    reward_total_amount : Uint256
):
    return tournament.reward_total_amount()
end

@view
func ship_count_per_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    ship_count_per_battle : felt
):
    return tournament.ship_count_per_battle()
end

@view
func required_total_ship_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (required_total_ship_count : felt):
    return tournament.required_total_ship_count()
end

@view
func grid_size{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    grid_size : felt
):
    return tournament.grid_size()
end

@view
func turn_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    turn_count : felt
):
    return tournament.turn_count()
end

@view
func max_dust{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    max_dust : felt
):
    return tournament.max_dust()
end

@view
func ship_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    ship_count : felt
):
    return tournament.ship_count()
end

@view
func player_ship{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player_address : felt
) -> (player_ship : felt):
    return tournament.player_ship(player_address)
end

@view
func ship_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ship_address : felt
) -> (ship_player : felt):
    return tournament.ship_player(ship_address)
end

@view
func player_score{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player_address : felt
) -> (player_score : felt):
    return tournament.player_score(player_address)
end

@view
func played_battle_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    played_battle_count : felt
):
    return tournament.played_battle_count()
end

# -----------
# CONSTRUCTOR
# -----------

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt,
    tournament_id : felt,
    tournament_name : felt,
    reward_token_address : felt,
    boarding_pass_token_address : felt,
    rand_contract_address : felt,
    battle_contract_address : felt,
    ships_per_battle : felt,
    required_total_ship_count : felt,
    grid_size : felt,
    turn_count : felt,
    max_dust : felt,
):
    return tournament.constructor(
        owner,
        tournament_id,
        tournament_name,
        reward_token_address,
        boarding_pass_token_address,
        rand_contract_address,
        battle_contract_address,
        ships_per_battle,
        required_total_ship_count,
        grid_size,
        turn_count,
        max_dust,
    )
end

# ---------
# EXTERNALS
# ---------

# Open tournament registrations
@external
func open_registrations{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    success : felt
):
    return tournament.open_registrations()
end

# Close tournament registrations
@external
func close_registrations{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    success : felt
):
    return tournament.close_registrations()
end

# Start the tournament
@external
func start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (success : felt):
    return tournament.start()
end

# Play the next battle of the tournament
@external
func play_next_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    return tournament.play_next_battle()
end

# Register a ship for the caller address
# @param ship_address: the address of the ship smart contract
@external
func register{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ship_address : felt
) -> (success : felt):
    return tournament.register(ship_address)
end

# Deposit ERC20 tokens to the tournament as reward
# @param amount: the amount of tokens to deposit
@external
func deposit_rewards{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : Uint256
) -> (success : felt):
    return tournament.deposit_rewards(amount)
end

# Winner withdraws ERC20 tokens rewards for the tournament
@external
func winner_withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    success : felt
):
    return tournament.winner_withdraw()
end
