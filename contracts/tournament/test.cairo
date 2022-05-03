%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from contracts.tournament.library import Tournament

const ONLY_DUST_TOKEN_ADDRESS = 0x3fe90a1958bb8468fb1b62970747d8a00c435ef96cda708ae8de3d07f1bb56b
const BOARDING_TOKEN_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a95
const RAND_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a91
const SPACE_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04aaa
const ADMIN = 42

@external
func test_tournament{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    local only_dust_token_address = ONLY_DUST_TOKEN_ADDRESS
    local boarding_pass_token_address = BOARDING_TOKEN_ADDRESS
    local rand_address = RAND_ADDRESS
    local space_address = SPACE_ADDRESS
    local admin = ADMIN

    Tournament.constructor(
        ADMIN, # Owner
        2, # Tournament Id
        3, # Tournament Name
        ONLY_DUST_TOKEN_ADDRESS, # ERC20 token address of the reward
        BOARDING_TOKEN_ADDRESS, # ERC721 token address for access control
        RAND_ADDRESS, # Random generator contract address
        SPACE_ADDRESS, # Space contract address
        2, # Ships per battle
        8, # Maximum Ships per tournament
        5, # grid_size
        3, # turn_count
        2, # max_dust
    )

    %{ mock_call(ids.only_dust_token_address, "balanceOf", [100, 0]) %}
    let (reward_total_amount) = Tournament.reward_total_amount()
    assert reward_total_amount.low = 100
    assert reward_total_amount.high = 0

    # Start registration
    %{ start_prank(ids.admin) %}
    let (are_tournament_registrations_open) = Tournament.are_tournament_registrations_open()
    assert are_tournament_registrations_open = FALSE

    Tournament.open_registrations()

    let (are_tournament_registrations_open) = Tournament.are_tournament_registrations_open()
    assert are_tournament_registrations_open = TRUE
    %{ stop_prank() %}

    # Player 1 registers ship 1
    %{ mock_call(ids.boarding_pass_token_address, "balanceOf", [1, 0]) %}
    %{ start_prank(1) %}
    Tournament.register(1)
    %{ stop_prank() %}

    # Player 2 registers ship 2
    %{ start_prank(2) %}
    Tournament.register(2)
    %{ stop_prank() %}

    # Player 3 registers ship 3
    %{ start_prank(3) %}
    Tournament.register(3)
    %{ stop_prank() %}

    # Player 4 registers ship 4
    %{ start_prank(4) %}
    Tournament.register(4)
    %{ stop_prank() %}

    # Close registration
    %{ start_prank(ids.admin) %}
    Tournament.close_registrations()
    let (are_tournament_registrations_open) = Tournament.are_tournament_registrations_open()
    assert are_tournament_registrations_open = FALSE
    %{ stop_prank() %}

    # Start the tournament
    %{ start_prank(ids.admin) %}
    Tournament.start()
    %{ stop_prank() %}

    let (played_battle_count) = Tournament.played_battle_count()
    assert played_battle_count = 0
    let (round) = Tournament.current_round()
    assert round = 1

    # Play the first battle
    _test_battle(1, 1, 1)

    # Play the second battle
    _test_battle(2, 1, 2)

    # Play the final battle
    _test_battle(3, 2, 3)

    return ()
end

func _test_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(expected_played_battle_count : felt, expected_round_before : felt, expected_round_after : felt):
    alloc_locals
    local space_address = SPACE_ADDRESS
    local admin = ADMIN

    let (round) = Tournament.current_round()
    with_attr error_message("Bad round before"):
        assert round = expected_round_before
    end

    %{ mock_call(ids.space_address, "play_game", []) %}
    %{ start_prank(ids.admin) %}
    Tournament.play_next_battle()
    %{ stop_prank() %}

    let (played_battle_count) = Tournament.played_battle_count()
    with_attr error_message("Bad played_battle_count"):
        assert played_battle_count = expected_played_battle_count
    end
    let (round) = Tournament.current_round()
    with_attr error_message("Bad round after"):
        assert round = expected_round_after
    end

    return ()
end
