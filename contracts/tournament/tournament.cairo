# SPDX-License-Identifier: Apache-2.0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from contracts.models.common import ShipInit, Vector2
from contracts.tournament.library import Tournament

# -----
# VIEWS
# -----
@view
func tournament_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tournament_id : felt
):
    return Tournament.tournament_id()
end

@view
func tournament_name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tournament_name : felt
):
    return Tournament.tournament_name()
end

@view
func reward_token_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    reward_token_address : felt
):
    return Tournament.reward_token_address()
end

@view
func boarding_pass_token_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (boarding_pass_token_address : felt):
    return Tournament.boarding_pass_token_address()
end

@view
func rand_contract_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    rand_contract_address : felt
):
    return Tournament.rand_contract_address()
end

@view
func are_tournament_registrations_open{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (are_tournament_registrations_open : felt):
    return Tournament.are_tournament_registrations_open()
end

@view
func reward_total_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    reward_total_amount : Uint256
):
    return Tournament.reward_total_amount()
end

@view
func ships_per_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    ships_per_battle : felt
):
    return Tournament.ships_per_battle()
end

@view
func max_ships_per_tournament{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (max_ships_per_tournament : felt):
    return Tournament.max_ships_per_tournament()
end

@view
func grid_size{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    grid_size : felt
):
    return Tournament.grid_size()
end

@view
func turn_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    turn_count : felt
):
    return Tournament.turn_count()
end

@view
func max_dust{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    max_dust : felt
):
    return Tournament.max_dust()
end

@view
func player_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    player_count : felt
):
    return Tournament.player_count()
end

@view
func player_ship{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player_address : felt
) -> (player_ship : felt):
    return Tournament.player_ship(player_address)
end

@view
func ship_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ship_address : felt
) -> (ship_player : felt):
    return Tournament.ship_player(ship_address)
end

@view
func player_score{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player_address : felt
) -> (player_score : felt):
    return Tournament.player_score(player_address)
end

@view
func played_battle_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    played_battle_count : felt
):
    return Tournament.played_battle_count()
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
    space_contract_address : felt,
    ships_per_battle : felt,
    max_ships_per_tournament : felt,
    grid_size : felt,
    turn_count : felt,
    max_dust : felt,
):
    return Tournament.constructor(
        owner,
        tournament_id,
        tournament_name,
        reward_token_address,
        boarding_pass_token_address,
        rand_contract_address,
        space_contract_address,
        ships_per_battle,
        max_ships_per_tournament,
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
    return Tournament.open_registrations()
end

# Close tournament registrations
@external
func close_registrations{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    success : felt
):
    return Tournament.close_registrations()
end

# Start the tournament
@external
func start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (success : felt):
    return Tournament.start()
end

# Play the next battle of the tournament
@external
func play_next_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    return Tournament.play_next_battle()
end

# Register a ship for the caller address
# @param ship_address: the address of the ship smart contract
@external
func register{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ship_address : felt
) -> (success : felt):
    return Tournament.register(ship_address)
end
