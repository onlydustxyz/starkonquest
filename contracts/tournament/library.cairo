# SPDX-License-Identifier: Apache-2.0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_lt, assert_nn, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256, uint256_le
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.alloc import alloc

# OpenZeppeling dependencies
from openzeppelin.access.ownable import Ownable_initializer, Ownable_only_owner
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from contracts.interfaces.ibattle import IBattle
from contracts.models.common import ShipInit, Vector2
from contracts.libraries.math_utils import math_utils

# ------------
# STORAGE VARS
# ------------

# Id of the tournament
@storage_var
func tournament_id_() -> (res : felt):
end

# Name of the tournament
@storage_var
func tournament_name_() -> (res : felt):
end

# ERC20 token address for the reward
@storage_var
func reward_token_address_() -> (res : felt):
end

# ERC721 token address for access control
@storage_var
func boarding_pass_token_address_() -> (res : felt):
end

# Random generator contract address
@storage_var
func rand_contract_address_() -> (res : felt):
end

# Battle contract address
@storage_var
func battle_contract_address_() -> (res : felt):
end

# Whether or not registrations are open
@storage_var
func are_tournament_registrations_open_() -> (res : felt):
end

# Number of ships per battle
@storage_var
func ship_count_per_battle_() -> (res : felt):
end

# Number of ships per tournament
@storage_var
func required_total_ship_count_() -> (res : felt):
end

# Size of the grid
@storage_var
func grid_size_() -> (res : felt):
end

# Turn count per battle
@storage_var
func turn_count_() -> (res : felt):
end

# Max dust in the grid at a given time
@storage_var
func max_dust_() -> (res : felt):
end

# Number of registered ships
@storage_var
func ship_count_() -> (res : felt):
end

# Player registered ship
@storage_var
func player_ship_(player_address : felt) -> (res : felt):
end

# Ship associated player
@storage_var
func ship_player_(ship_address : felt) -> (res : felt):
end

# Ship array
@storage_var
func ships_(index : felt) -> (ship_address : felt):
end

# Array of ships playing during the current round
@storage_var
func playing_ships_(index : felt) -> (ship_address : felt):
end
@storage_var
func playing_ship_count_() -> (res : felt):
end

# Index in playing_ships_ array pointing to the first ship that will play the next battle
@storage_var
func next_playing_ship_index_() -> (index : felt):
end

# Array of ships that won their battle in the current round
@storage_var
func winning_ships_(index : felt) -> (ship_address : felt):
end
@storage_var
func winning_ship_count_() -> (res : felt):
end

# Current round number
@storage_var
func current_round_() -> (res : felt):
end

# Player scores
@storage_var
func player_score_(player_address : felt) -> (res : felt):
end

# Played battle count
@storage_var
func played_battle_count_() -> (res : felt):
end

namespace Tournament:
    # -----
    # VIEWS
    # -----

    func tournament_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        tournament_id : felt
    ):
        let (tournament_id) = tournament_id_.read()
        return (tournament_id)
    end

    func tournament_name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        tournament_name : felt
    ):
        let (tournament_name) = tournament_name_.read()
        return (tournament_name)
    end

    func reward_token_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (reward_token_address : felt):
        let (reward_token_address) = reward_token_address_.read()
        return (reward_token_address)
    end

    func boarding_pass_token_address{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }() -> (boarding_pass_token_address : felt):
        let (boarding_pass_token_address) = boarding_pass_token_address_.read()
        return (boarding_pass_token_address)
    end

    func rand_contract_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (rand_contract_address : felt):
        let (rand_contract_address) = rand_contract_address_.read()
        return (rand_contract_address)
    end

    func are_tournament_registrations_open{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }() -> (are_tournament_registrations_open : felt):
        let (are_tournament_registrations_open) = are_tournament_registrations_open_.read()
        return (are_tournament_registrations_open)
    end

    func reward_total_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (reward_total_amount : Uint256):
        let (reward_token_address) = reward_token_address_.read()
        let (contract_address) = get_contract_address()
        let (reward_total_amount) = IERC20.balanceOf(
            contract_address=reward_token_address, account=contract_address
        )
        return (reward_total_amount)
    end

    func ship_count_per_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (ship_count_per_battle : felt):
        let (ship_count_per_battle) = ship_count_per_battle_.read()
        return (ship_count_per_battle)
    end

    func required_total_ship_count{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }() -> (required_total_ship_count : felt):
        let (required_total_ship_count) = required_total_ship_count_.read()
        return (required_total_ship_count)
    end

    func grid_size{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        grid_size : felt
    ):
        let (grid_size) = grid_size_.read()
        return (grid_size)
    end

    func turn_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        turn_count : felt
    ):
        let (turn_count) = turn_count_.read()
        return (turn_count)
    end

    func max_dust{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        max_dust : felt
    ):
        let (max_dust) = max_dust_.read()
        return (max_dust)
    end

    func ship_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        ship_count : felt
    ):
        let (ship_count) = ship_count_.read()
        return (ship_count)
    end

    func player_ship{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_address : felt
    ) -> (player_ship : felt):
        let (player_ship) = player_ship_.read(player_address)
        return (player_ship)
    end

    func ship_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ship_address : felt
    ) -> (ship_player : felt):
        let (ship_player) = ship_player_.read(ship_address)
        return (ship_player)
    end

    func player_score{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_address : felt
    ) -> (player_score : felt):
        let (player_score) = player_score_.read(player_address)
        return (player_score)
    end

    func played_battle_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (played_battle_count : felt):
        let (played_battle_count) = played_battle_count_.read()
        return (played_battle_count)
    end

    func current_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        current_round : felt
    ):
        let (current_round) = current_round_.read()
        return (current_round)
    end

    # -----------
    # CONSTRUCTOR
    # -----------

    func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt,
        tournament_id : felt,
        tournament_name : felt,
        reward_token_address : felt,
        boarding_pass_token_address : felt,
        rand_contract_address : felt,
        battle_contract_address : felt,
        ship_count_per_battle : felt,
        required_total_ship_count : felt,
        grid_size : felt,
        turn_count : felt,
        max_dust : felt,
    ):
        alloc_locals
        Ownable_initializer(owner)
        let (required_total_ship_count_is_valid) = math_utils.is_power_of(
            required_total_ship_count, ship_count_per_battle
        )
        with_attr error_message(
                "Tournament: total ship count is expected to be a power of ship count per battle"):
            assert required_total_ship_count_is_valid = TRUE
        end

        tournament_id_.write(tournament_id)
        tournament_name_.write(tournament_name)
        reward_token_address_.write(reward_token_address)
        boarding_pass_token_address_.write(boarding_pass_token_address)
        rand_contract_address_.write(rand_contract_address)
        battle_contract_address_.write(battle_contract_address)
        ship_count_per_battle_.write(ship_count_per_battle)
        required_total_ship_count_.write(required_total_ship_count)
        grid_size_.write(grid_size)
        turn_count_.write(turn_count)
        max_dust_.write(max_dust)
        ship_count_.write(0)
        return ()
    end

    # ---------
    # EXTERNALS
    # ---------

    # Open tournament registrations
    func open_registrations{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (success : felt):
        Ownable_only_owner()
        _only_tournament_registrations_closed()
        are_tournament_registrations_open_.write(TRUE)
        return (TRUE)
    end

    # Close tournament registrations
    func close_registrations{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (success : felt):
        Ownable_only_owner()
        _only_tournament_registrations_open()

        # Check that we did reach the expected number of players
        let (current_ship_count) = ship_count_.read()
        let (required_total_ship_count) = required_total_ship_count_.read()
        with_attr error_message("Tournament: ship count not reached"):
            assert current_ship_count = required_total_ship_count
        end

        are_tournament_registrations_open_.write(FALSE)
        return (TRUE)
    end

    # Start the tournament
    func start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        success : felt
    ):
        Ownable_only_owner()
        _only_tournament_registrations_closed()
        _only_tournament_not_started()

        # Prepare the first round
        current_round_.write(1)
        next_playing_ship_index_.write(0)
        winning_ship_count_.write(0)

        return (TRUE)
    end

    # Play the next battle of the tournament
    func play_next_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        Ownable_only_owner()
        _only_tournament_in_progress()

        let (round_finished) = _play_next_battle()
        if round_finished == TRUE:
            # Prepare the next round
            let (round) = current_round_.read()
            current_round_.write(round + 1)
            next_playing_ship_index_.write(0)
            _update_playing_ships_for_next_round()
            return ()
        end

        return ()
    end

    # Register a ship for the caller address
    # @param ship_address: the address of the ship smart contract
    func register{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ship_address : felt
    ) -> (success : felt):
        alloc_locals
        _only_tournament_registrations_open()
        let (player_address) = get_caller_address()
        let (boarding_pass_token_address) = boarding_pass_token_address_.read()
        # Check access control with NFT boarding pass
        let (player_boarding_pass_balance) = IERC721.balanceOf(
            contract_address=boarding_pass_token_address, owner=player_address
        )
        let one = Uint256(1, 0)
        let (is_allowed) = uint256_le(one, player_boarding_pass_balance)
        with_attr error_message("Tournament: player is not allowed to register"):
            assert is_allowed = TRUE
        end
        let (current_ship_count) = ship_count_.read()
        let (required_total_ship_count) = required_total_ship_count_.read()
        # Check that we did not reach the max number of ships
        with_attr error_message("Tournament: ship count already reached"):
            assert_lt(current_ship_count, required_total_ship_count)
        end
        let (player_registerd_ship) = player_ship_.read(player_address)
        # Check if player already registered a ship for this tournament
        with_attr error_message("Tournament: player already registered"):
            assert player_registerd_ship = 0
        end
        let (ship_registered_player) = ship_player_.read(ship_address)
        # Check if ship has not been registered by another player
        with_attr error_message("Tournament: ship already registered"):
            assert ship_registered_player = 0
        end
        ship_count_.write(current_ship_count + 1)
        # Write player => ship association
        player_ship_.write(player_address, ship_address)
        # Write ship => player association
        ship_player_.write(ship_address, player_address)
        # Push ship to array of playing ships
        playing_ships_.write(current_ship_count, ship_address)
        playing_ship_count_.write(current_ship_count + 1)
        return (TRUE)
    end

    # ---------
    # INTERNALS
    # ---------

    func _increase_score{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_address : felt, points : felt
    ):
        let (current_score) = player_score_.read(player_address)
        tempvar new_score
        assert new_score = current_score + points
        player_score_.write(player_address, new_score)
        return ()
    end

    func _decrease_score{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        player_address : felt, points : felt
    ):
        let (current_score) = player_score_.read(player_address)
        tempvar new_score
        assert new_score = current_score - points
        player_score_.write(player_address, new_score)
        return ()
    end

    func _only_tournament_registrations_open{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }():
        let (are_tournament_registrations_open) = are_tournament_registrations_open_.read()
        with_attr error_message("Tournament: tournament is closed"):
            assert are_tournament_registrations_open = TRUE
        end
        return ()
    end

    func _only_tournament_registrations_closed{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }():
        let (are_tournament_registrations_open) = are_tournament_registrations_open_.read()
        with_attr error_message("Tournament: tournament is open"):
            assert are_tournament_registrations_open = FALSE
        end
        return ()
    end

    func _only_tournament_started{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }():
        let (round) = current_round_.read()
        with_attr error_message("Tournament: tournament has not started"):
            assert_not_zero(round)
        end
        return ()
    end

    func _only_tournament_not_started{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }():
        let (round) = current_round_.read()
        with_attr error_message("Tournament: tournament has already started"):
            assert round = 0
        end
        return ()
    end

    func _only_tournament_in_progress{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }():
        _only_tournament_started()
        let (playing_ship_count) = playing_ship_count_.read()
        with_attr error_message("Tournament: tournament is finished"):
            assert_lt(1, playing_ship_count)
        end
        return ()
    end

    func _play_next_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        round_finished : felt
    ):
        alloc_locals

        # Build the list of ships that will play this battle
        let (playing_ship_index) = next_playing_ship_index_.read()
        let (local ships_len : felt, ships : ShipInit*) = _build_battle_ship_array(
            playing_ship_index
        )

        with_attr error_message("Tournament: no more ship playing"):
            assert_not_zero(ships_len)
        end

        # Update the playing ship index for the next battle
        next_playing_ship_index_.write(playing_ship_index + ships_len)

        # Play the battle itself
        let (winner_ship) = _play_battle(ships_len, ships)

        # Add winner ship to the list of winners of this round
        let (winning_ship_count) = winning_ship_count_.read()
        winning_ship_count_.write(winning_ship_count + 1)
        winning_ships_.write(winning_ship_count, winner_ship)

        let (playing_ship_count) = playing_ship_count_.read()
        let (did_all_ships_played_in_this_round) = is_le(
            playing_ship_count, playing_ship_index + ships_len
        )
        if did_all_ships_played_in_this_round == TRUE:
            return (round_finished=TRUE)
        end
        return (round_finished=FALSE)
    end

    # Play the battle entirely
    func _play_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ships_len : felt, ships : ShipInit*
    ) -> (winner_ship : felt):
        alloc_locals
        let (battle_contract) = battle_contract_address_.read()
        let (rand_contract) = rand_contract_address_.read()
        let (grid_size) = grid_size_.read()
        let (turn_count) = turn_count_.read()
        let (max_dust) = max_dust_.read()

        IBattle.play_game(
            battle_contract, rand_contract, grid_size, turn_count, max_dust, ships_len, ships
        )

        let (played_battle_count) = played_battle_count_.read()
        played_battle_count_.write(played_battle_count + 1)

        # TODO: get scores
        # TODO: get winner
        let winner_ship = ships[0]

        return (winner_ship.address)
    end

    # Get the ships that will participate in the next battle
    func _build_battle_ship_array{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(ship_index : felt) -> (ships_len : felt, ships : ShipInit*):
        alloc_locals

        let (local ships : ShipInit*) = alloc()

        let (ships_len) = _recursive_build_battle_ship_array(ship_index, 0, ships)

        return (ships_len, ships)
    end

    func _recursive_build_battle_ship_array{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(ship_index : felt, ships_len : felt, ships : ShipInit*) -> (len : felt):
        alloc_locals
        let (ship_count_per_battle) = ship_count_per_battle_.read()
        if ships_len == ship_count_per_battle:
            return (ships_len)
        end

        let (ship_count) = playing_ship_count_.read()
        if ship_index == ship_count:
            return (ships_len)
        end

        let (ship_address : felt) = playing_ships_.read(ship_index)
        assert_not_zero(ship_address)

        let (initial_position : Vector2) = _get_initial_ship_position(ships_len)

        assert ships[ships_len] = ShipInit(address=ship_address, position=initial_position)

        return _recursive_build_battle_ship_array(ship_index + 1, ships_len + 1, ships)
    end

    func _get_initial_ship_position{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(battle_ship_index : felt) -> (initial_position : Vector2):
        let (grid_size) = grid_size_.read()

        let (y, x) = unsigned_div_rem(battle_ship_index, grid_size)

        return (Vector2(x, y))
    end

    # Update the list of ships that will be playing in the next ground
    func _update_playing_ships_for_next_round{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }():
        let (winning_ship_count) = winning_ship_count_.read()
        playing_ship_count_.write(winning_ship_count)

        _recursive_update_playing_ships_for_next_round(0, winning_ship_count)
        winning_ship_count_.write(0)
        return ()
    end

    func _recursive_update_playing_ships_for_next_round{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(index : felt, len : felt):
        if index == len:
            return ()
        end

        let (ship_address) = winning_ships_.read(index)
        playing_ships_.write(index, ship_address)

        _recursive_update_playing_ships_for_next_round(index + 1, len)
        return ()
    end
end
