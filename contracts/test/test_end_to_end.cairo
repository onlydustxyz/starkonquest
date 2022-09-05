%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256,  uint256_eq
from contracts.interfaces.itournament import ITournament
from contracts.interfaces.idust import IDustContract
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.tournament.library import (
    tournament,
)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721


# ---------
# CONSTANTS
# ---------

const ADMIN = 111
const SHIPS_PER_BATTLE = 2
const SHIPS_IN_TOTAL = 8
const GRID_SIZE = 10

@contract_interface
namespace IBoardingPassContract:

    func mint(to : felt, tokenId : Uint256):
    end
end


@external
func test_end_to_end_testing{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    local rand_contract_address : felt
    local reward_token_address : felt
    local boarding_pass_token_address : felt
    local battle_contract_address : felt
    local tournament_contract_address : felt
    local basic_ship_1 : felt
    local basic_ship_2 : felt
    local basic_ship_3 : felt
    local basic_ship_4 : felt
    local basic_ship_5 : felt
    local static_ship_1 : felt
    local static_ship_2 : felt
    local static_ship_3 : felt


    # We deploy all the contracts and put their address into local variables (declare above). Second argument is calldata array
    %{ ids.rand_contract_address = deploy_contract("./contracts/core/random/random.cairo", []).contract_address %}
    %{ ids.reward_token_address = deploy_contract("./contracts/tokens/only_dust/only_dust.cairo", [404, 405, 5, 100000, 0, ids.ADMIN]).contract_address%}
    %{ ids.boarding_pass_token_address = deploy_contract("./contracts/tokens/starkonquest_boarding_pass/starkonquest_boarding_pass.cairo", [406, 407, ids.ADMIN]).contract_address%}
    %{ ids.battle_contract_address = deploy_contract("./contracts/core/battle/battle.cairo", []).contract_address %}
    %{ ids.tournament_contract_address = deploy_contract("./contracts/tournament/tournament.cairo", [ids.ADMIN, 101, 102, ids.reward_token_address, ids.boarding_pass_token_address, ids.rand_contract_address, ids.battle_contract_address, ids.SHIPS_PER_BATTLE, ids.SHIPS_IN_TOTAL, ids.GRID_SIZE, 3,2]).contract_address %}

    #Deploy all the ships contracts (5 basic ships and 3 static ships)

    %{ ids.basic_ship_1 = deploy_contract("./contracts/ships/basic_ship/basic_ship.cairo", []).contract_address %}
    %{ ids.basic_ship_2 = deploy_contract("./contracts/ships/basic_ship/basic_ship.cairo", []).contract_address %}
    %{ ids.basic_ship_3 = deploy_contract("./contracts/ships/basic_ship/basic_ship.cairo", []).contract_address %}
    %{ ids.basic_ship_4 = deploy_contract("./contracts/ships/basic_ship/basic_ship.cairo", []).contract_address %}
    %{ ids.basic_ship_5 = deploy_contract("./contracts/ships/basic_ship/basic_ship.cairo", []).contract_address %}
    %{ ids.static_ship_1 = deploy_contract("./contracts/ships/static_ship/static_ship.cairo", []).contract_address %}
    %{ ids.static_ship_2 = deploy_contract("./contracts/ships/static_ship/static_ship.cairo", []).contract_address %}
    %{ ids.static_ship_3 = deploy_contract("./contracts/ships/static_ship/static_ship.cairo", []).contract_address %}

    # Transfer the equivalent of the reward total amount from the admin to the tournament_contract_address

    %{ stop_prank_admin = start_prank(ids.ADMIN, ids.reward_token_address) %}
    IERC20.transfer(reward_token_address, tournament_contract_address, Uint256(100,0))
    %{ stop_prank_admin() %}

    #Reward total amount of 100 tokens for the tournament winner

    let (reward_total_amount) = ITournament.reward_total_amount(tournament_contract_address)

    assert reward_total_amount.low = 100
    assert reward_total_amount.high = 0

    # Start registration

    %{ stop_prank_admin = start_prank(ids.ADMIN, ids.tournament_contract_address) %}
    assert_that.stage_is(tournament.STAGE_CREATED, tournament_contract_address)
    %{ expect_events({"name": "stage_changed", "data": [1, 2]}) %}
    ITournament.open_registrations(tournament_contract_address)
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN, tournament_contract_address)
    %{ stop_prank_admin() %}

    #The admin mint boarding pass NFTs

    %{ stop_prank_admin = start_prank(ids.ADMIN, ids.boarding_pass_token_address) %}
    IBoardingPassContract.mint(boarding_pass_token_address, ADMIN, Uint256(0,0))
    IBoardingPassContract.mint(boarding_pass_token_address, ADMIN, Uint256(1,0))
    IBoardingPassContract.mint(boarding_pass_token_address, ADMIN, Uint256(2,0))
    IBoardingPassContract.mint(boarding_pass_token_address, ADMIN, Uint256(3,0))
    IBoardingPassContract.mint(boarding_pass_token_address, ADMIN, Uint256(4,0))
    IBoardingPassContract.mint(boarding_pass_token_address, ADMIN, Uint256(5,0))
    IBoardingPassContract.mint(boarding_pass_token_address, ADMIN, Uint256(6,0))
    IBoardingPassContract.mint(boarding_pass_token_address, ADMIN, Uint256(7,0))
    %{ stop_prank_admin() %}

    #Check admin's balance

    let (admin_balance) = IERC721.balanceOf(boarding_pass_token_address, ADMIN)

    assert admin_balance.low = 8
    assert admin_balance.high = 0

    #Send a boarding pass token to each ships from admin
    %{ stop_prank_admin = start_prank(ids.ADMIN, ids.boarding_pass_token_address) %}
    IERC721.transferFrom(boarding_pass_token_address, ADMIN, basic_ship_1, Uint256(0,0))
    IERC721.transferFrom(boarding_pass_token_address, ADMIN, basic_ship_2, Uint256(1,0))
    IERC721.transferFrom(boarding_pass_token_address, ADMIN, basic_ship_3, Uint256(2,0))
    IERC721.transferFrom(boarding_pass_token_address, ADMIN, basic_ship_4, Uint256(3,0))
    IERC721.transferFrom(boarding_pass_token_address, ADMIN, basic_ship_5, Uint256(4,0))
    IERC721.transferFrom(boarding_pass_token_address, ADMIN, static_ship_1, Uint256(5,0))
    IERC721.transferFrom(boarding_pass_token_address, ADMIN, static_ship_2, Uint256(6,0))
    IERC721.transferFrom(boarding_pass_token_address, ADMIN, static_ship_3, Uint256(7,0))

    %{ stop_prank_admin() %}

    #Check balances of ships

    let (basic_ship_1_balance) = IERC721.balanceOf(boarding_pass_token_address, basic_ship_1)
    assert basic_ship_1_balance.low = 1
    assert basic_ship_1_balance.high = 0


    let (basic_ship_2_balance) = IERC721.balanceOf(boarding_pass_token_address, basic_ship_2)
    assert basic_ship_2_balance.low = 1
    assert basic_ship_2_balance.high = 0

    let (basic_ship_3_balance) = IERC721.balanceOf(boarding_pass_token_address, basic_ship_3)
    assert basic_ship_3_balance.low = 1
    assert basic_ship_3_balance.high = 0

    let (basic_ship_4_balance) = IERC721.balanceOf(boarding_pass_token_address, basic_ship_4)
    assert basic_ship_4_balance.low = 1
    assert basic_ship_4_balance.high = 0

    let (basic_ship_5_balance) = IERC721.balanceOf(boarding_pass_token_address, basic_ship_5)
    assert basic_ship_5_balance.low = 1
    assert basic_ship_5_balance.high = 0

    let (static_ship_1_balance) = IERC721.balanceOf(boarding_pass_token_address, static_ship_1)
    assert static_ship_1_balance.low = 1
    assert static_ship_1_balance.high = 0

    let (static_ship_2_balance) = IERC721.balanceOf(boarding_pass_token_address, static_ship_2)
    assert static_ship_2_balance.low = 1
    assert static_ship_2_balance.high = 0

    let (static_ship_3_balance) = IERC721.balanceOf(boarding_pass_token_address, static_ship_3)
    assert static_ship_3_balance.low = 1
    assert static_ship_3_balance.high = 0

    #Set the ships_len and ships value
    local ships_len = 8

    let (local ships : felt*) = alloc()
    assert [ships] = basic_ship_1
    assert [ships+1] = static_ship_1
    assert [ships+2] = basic_ship_3
    assert [ships+3] = basic_ship_4
    assert [ships+4] = basic_ship_5
    assert [ships+5] = static_ship_2
    assert [ships+6] = basic_ship_2
    assert [ships+7] = static_ship_3

    # Register ships
    _register_ships_loop(ships_len, ships, tournament_contract_address)

    # Registration should now be closed
    %{ expect_events({"name": "stage_changed", "data": [2, 3]}) %}
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_CLOSED, tournament_contract_address)

    # Start the tournament
    %{ stop_prank_admin= start_prank(ids.ADMIN, ids.tournament_contract_address) %}
    %{ expect_events({"name": "stage_changed", "data": [3, 4]}) %}
    ITournament.start(tournament_contract_address)
    assert_that.stage_is(tournament.STAGE_STARTED, tournament_contract_address)
    %{ stop_prank_admin() %}

    let (played_battle_count) = ITournament.played_battle_count(tournament_contract_address)
    assert played_battle_count = 0

    assert_that.stage_is(tournament.STAGE_STARTED, tournament_contract_address)

    # Play the first battle
    %{ stop_mock = mock_call(ids.rand_contract_address, "generate_random_numbers", [1, 2, 3, 4, 5]) %}

    invoke_battle(expected_played_battle_count_after=1, expected_round_before=1, expected_round_after=1, battle_contract_address=battle_contract_address, tournament_contract_address=tournament_contract_address, admin=ADMIN)

    # Play the second battle
    %{
        stop_mock()
        stop_mock = mock_call(ids.rand_contract_address, "generate_random_numbers", [2, 3, 4, 5, 6])
    %}

    invoke_battle(expected_played_battle_count_after=3, expected_round_before=1, expected_round_after=1, battle_contract_address=battle_contract_address, tournament_contract_address=tournament_contract_address, admin=ADMIN)

    # Play the third battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.rand_contract_address, "generate_random_numbers", [3, 4, 5, 6, 7])
        %}
    invoke_battle(expected_played_battle_count_after=3, expected_round_before=1, expected_round_after=1, battle_contract_address=battle_contract_address, tournament_contract_address=tournament_contract_address, admin=ADMIN)

    # Play the fourth battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.rand_contract_address, "generate_random_numbers", [1, 2, 3, 4, 5])
        %}
    invoke_battle(expected_played_battle_count_after=4, expected_round_before=1, expected_round_after=2, battle_contract_address=battle_contract_address, tournament_contract_address=tournament_contract_address, admin=ADMIN)

    # Play the fith battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.rand_contract_address, "generate_random_numbers", [5, 6, 7, 8, 9])
        %}

    invoke_battle(expected_played_battle_count_after=5, expected_round_before=2, expected_round_after=3, battle_contract_address=battle_contract_address, tournament_contract_address=tournament_contract_address, admin=ADMIN)

     # Play the sixth battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.rand_contract_address, "generate_random_numbers", [6, 7, 8, 9, 10])
        %}
    invoke_battle(expected_played_battle_count_after=6, expected_round_before=2, expected_round_after=3, battle_contract_address=battle_contract_address, tournament_contract_address=tournament_contract_address, admin=ADMIN)

     # Play the final battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.rand_contract_address, "generate_random_numbers", [7, 8, 9, 10, 11])
        %}
    invoke_battle(expected_played_battle_count_after=7, expected_round_before=3, expected_round_after=4, battle_contract_address=battle_contract_address, tournament_contract_address=tournament_contract_address, admin=ADMIN)

    # After the final battle, we have our winner
    let (tournament_winner) = ITournament.tournament_winner(tournament_contract_address)

    assert tournament_winner.ship_address = basic_ship_1

    assert_that.stage_is(tournament.STAGE_FINISHED, tournament_contract_address)

    return()
end


# -----------------
# CUSTOM ASSERTIONS
# -----------------

namespace assert_that:
    func stage_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected_stage : felt, tournament_contract_address : felt):

        alloc_locals
        let (local stage) = ITournament.stage(tournament_contract_address)
        with_attr error_message("Expected stage to be {expected_stage}, got {stage}"):
            assert stage = expected_stage
        end
        return ()
    end

end

# -----------------------
# INTERNAL TEST FUNCTIONS
# -----------------------

    func _register_ships_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(ships_len : felt, ships : felt*, tournament_contract_address : felt):
        alloc_locals
        if ships_len == 0:
            return ()
        end

        tempvar ship_address = [ships]
        local player_address = ship_address  # To keep it simple in tests, the player_address is equal to the ship_address

        # Register
        %{ stop_prank_player = start_prank(ids.player_address, ids.tournament_contract_address) %}
        ITournament.register(tournament_contract_address, ship_address)
        %{ stop_prank_player() %}

        # Check registration
        let (registered_player_address) = ITournament.ship_player(tournament_contract_address, ship_address)
        with_attr error_message("Expected ship {ship_address} to be registered"):
            assert registered_player_address = player_address
        end

        _register_ships_loop(ships_len - 1, &ships[1], tournament_contract_address)
        return ()
    end


    func invoke_battle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected_played_battle_count_after : felt,
        expected_round_before : felt,
        expected_round_after : felt,
        battle_contract_address : felt,
        tournament_contract_address : felt,
        admin : felt
    ):
        alloc_locals
        local battle_address = battle_contract_address
        local admin = admin

        %{ stop_prank_admin = start_prank(ids.admin, ids.tournament_contract_address) %}
        ITournament.play_next_battle(tournament_contract_address)
        %{ stop_prank_admin() %}

        return ()
    end
