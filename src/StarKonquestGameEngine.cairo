# SPDX-License-Identifier: Apache-2.0
# StarKonquest Contracts for Cairo v0.0.1 (StarKonquestGameEngine.cairo)

%lang starknet
%builtins pedersen range_check

# Starkware dependencies
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

# Openzepppelin dependencies
from openzeppelin.introspection.ERC165 import ERC165_supports_interface

# ------------
# EVENT
# ------------
@event
func GameCreated(game_id: felt, player1_account: felt, player2_account: felt):
end

# ------------
# STRUCTS
# ------------

struct Game:
    member intialized: felt
    member turn_counter: felt
    # account address of player 1
    member player1_account: felt
    # account address of player 2
    member player2_account: felt
    # player 1 move intention
    # TODO: must be an array of intentions
    member player1_move_intention: felt
    # player 2 move intention
    # TODO: must be an array of intentions
    member player2_move_intention: felt
    # player 1 move
    # TODO: must be an array of moves
    member player1_move: felt
    # player 2 move
    # TODO: must be an array of moves
    member player2_move: felt
    # status of the current game
    member status: felt
end


# ------------
# STORAGE VARS
# ------------

@storage_var
func games_storage(game_id: felt) -> (game: Game):
end


# -----
# VIEWS
# -----

@view
func game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id: felt
) -> (game: Game):
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
func create_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    game_id: felt, player1_account: felt, player2_account: felt
) -> (success: felt):
    alloc_locals
    let (existing_game) = games_storage.read(game_id)
    # Check if game already exist
    with_attr error_message("StarKonquestGameEngine: game already exist"):
        assert existing_game.intialized = 1
    end
    with_attr error_message("StarKonquestGameEngine: cannot set player1 to zero address"):
        assert_not_zero(player1_account)
    end
    with_attr error_message("StarKonquestGameEngine: cannot set player2 to zero address"):
        assert_not_zero(player2_account)
    end

    # Initialize Game stuct
    local game: Game
    assert game.intialized = TRUE
    assert game.turn_counter = 0
    assert game.player1_account = player1_account
    assert game.player2_account = player2_account
    assert game.player1_move_intention = 0
    assert game.player2_move_intention = 0
    assert game.player1_move = 0
    assert game.player2_move = 0
    assert game.status = 0

    # Write Game struct in storage
    games_storage.write(game_id, game)

    # Emit event
    GameCreated.emit(game_id, player1_account, player1_account)
    
    return (TRUE)
end

@external
func submit_move_intention{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id: felt, player_id: felt,  move_intention: felt
):
    return ()
end

@external
func submit_move{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_id: felt, player_id: felt,  move: felt
):
    return ()
end
