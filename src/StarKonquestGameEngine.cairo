# SPDX-License-Identifier: Apache-2.0
# StarKonquest Contracts for Cairo v0.0.1 (StarKonquestGameEngine.cairo)

%lang starknet
%builtins pedersen range_check

# Starkware dependencies
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_caller_address

# Openzepppelin dependencies
from openzeppelin.introspection.ERC165 import ERC165_supports_interface

# ------------
# EVENT
# ------------
@event
func GameCreated(game_id : felt):
end

@event
func PlayerAdded(game_id : felt, player_account : felt, player_id : felt):
end

@event
func MoveSubmitted(game_id : felt, player_id : felt):
end

# ------------
# STRUCTS
# ------------

struct Game:
    member intialized : felt
    member turn_counter : felt
    # status of the current game
    member status : felt
end

# ------------
# STORAGE VARS
# ------------

@storage_var
func games_storage(game_id : felt) -> (game : Game):
end

@storage_var
func players_counter(game_id : felt) -> (count : felt):
end

@storage_var
func players_account(game_id : felt, player_id : felt) -> (account : felt):
end

@storage_var
func players_index(game_id : felt, account : felt) -> (player_id : felt):
end

@storage_var
func players_intention(game_id : felt, player_id : felt) -> (intention : felt):
end

@storage_var
func players_moves(game_id : felt, player_id : felt, move_idx : felt) -> (move : felt):
end

# -----
# VIEWS
# -----

@view
func game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(game_id : felt) -> (
    game : Game
):
    let (game) = games_storage.read(game_id)
    return (game=game)
end

# -----------
# CONSTRUCTOR
# -----------

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    return ()
end

# ------------------
# EXTERNAL FUNCTIONS
# ------------------

@external
func create_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id : felt
) -> (success : felt):
    alloc_locals
    let (existing_game) = games_storage.read(game_id)
    # Check if game already exist
    with_attr error_message("StarKonquestGameEngine: game already exist"):
        assert existing_game.intialized = FALSE
    end

    # Initialize Game stuct
    local game : Game
    assert game.intialized = TRUE
    assert game.turn_counter = 0
    assert game.status = 0

    # Write Game struct in storage
    games_storage.write(game_id, game)

    # Emit event
    GameCreated.emit(game_id)

    return (TRUE)
end

@external
func add_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id : felt, player_account : felt
) -> (player_id : felt):
    with_attr error_message("StarKonquestGameEngine: cannot add player with zero address"):
        assert_not_zero(player_account)
    end
    _assert_game_exists(game_id)

    let (existing_player_id) = players_index.read(game_id, player_account)
    with_attr error_message("StarKonquestGameEngine: player already added"):
        assert existing_player_id = 0
    end

    let (count) = players_counter.read(game_id)
    let player_id = count + 1
    players_account.write(game_id, player_id, player_account)
    players_index.write(game_id, player_account, player_id)
    players_counter.write(game_id, count + 1)

    # Emit event
    PlayerAdded.emit(game_id, player_account, player_id)

    return (player_id)
end

@external
func submit_move_intention{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id : felt, player_id : felt, move_intention : felt
):
    _assert_game_exists(game_id)
    _only_player(game_id, player_id)

    players_intention.write(game_id, player_id, move_intention)
    return ()
end

@external
func submit_moves{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id : felt, player_id : felt, moves_len : felt, moves : felt*
):
    alloc_locals
    _assert_game_exists(game_id)
    _only_player(game_id, player_id)

    # Compute move integrity hash
    assert_not_zero(moves_len)
    let (moves_integrity_hash) = _compute_integrity_hash(0, moves_len, moves)

    let (intention) = players_intention.read(game_id, player_id)

    with_attr error_message("StarKonquestGameEngine: move intention mismatch"):
        assert moves_integrity_hash = intention
    end

    _store_moves(game_id, player_id, 0, moves_len, moves)

    # Emit event
    MoveSubmitted.emit(game_id, player_id)

    return ()
end

# ------------------
# INTERNAL FUNCTIONS
# ------------------

func _store_moves{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id : felt, player_id : felt, index : felt, moves_len : felt, moves : felt*
):
    if moves_len == 0:
        return ()
    end

    players_moves.write(game_id, player_id, index, moves[0])
    _store_moves(game_id, player_id, index + 1, moves_len - 1, &moves[1])
    return ()
end

func _compute_integrity_hash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    hash : felt, moves_len : felt, moves : felt*
) -> (integrity_hash : felt):
    if moves_len == 0:
        return (hash)
    end
    let (new_hash) = hash2{hash_ptr=pedersen_ptr}(hash, moves[0])
    let (rest) = _compute_integrity_hash(new_hash, moves_len - 1, &moves[1])
    return (rest)
end

func _assert_game_exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id : felt
):
    let (game) = games_storage.read(game_id)
    with_attr error_message("StarKonquestGameEngine: game does not exist"):
        assert game.intialized = TRUE
    end
    return ()
end

func _only_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id : felt, player_id : felt
):
    let (player_account) = players_account.read(game_id, player_id)
    with_attr error_message("StarKonquestGameEngine: invalid player id"):
        assert_not_zero(player_account)
    end
    return ()
end
