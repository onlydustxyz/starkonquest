%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.models.common import Player
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.alloc import alloc
from contracts.interfaces.itournament import ITournament
from contracts.tournament.library import (
    tournament,
    playing_ships_,
    playing_ship_count_,
    winning_ships_,
    winning_ship_count_,
)
from contracts.account.library import (
    account,
    Account
)
from contracts.interfaces.iaccount import IAccount

# ---------
# CONSTANTS
# ---------

const ONLY_DUST_TOKEN_ADDRESS = 0x3fe90a1958bb8468fb1b62970747d8a00c435ef96cda708ae8de3d07f1bb56b
const BOARDING_TOKEN_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a95
const RAND_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a91
const BATTLE_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04aaa
const ACCOUNT_TOKEN_ADDRESS = 0x4b8145115592590ecddac23732a454abfe682f02ab0a01b7682835eecd906f8a
const ADMIN = 300
const ANYONE = 301
const PLAYER_1 = 302
const PLAYER_2 = 303

# -------
# STRUCTS
# -------

struct Signers:
    member admin : felt
    member anyone : felt
    member player_1 : felt
    member player_2 : felt
end

struct Mocks:
    member only_dust_token_address : felt
    member boarding_pass_token_address : felt
    member rand_address : felt
    member battle_address : felt
    member account_token_address : felt
end

struct TestContext:
    member signers : Signers
    member mocks : Mocks

    member tournament_id : felt
    member tournament_name : felt
    member ships_per_battle : felt
    member max_ships_per_tournament : felt
    member grid_size : felt
    member turn_count : felt
    member max_dust : felt
end

struct DeployedContracts:
    member tournament_address : felt
    member other_address : Mocks
end

# -----
# TESTS
# -----

@external
func test_construct_tournament_with_invalid_ship_count{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    let ship_count_per_battle = 2
    let required_total_ship_count = 5  # Invalid. This should be a power of ship_count_per_battle.

    %{ expect_revert("TRANSACTION_FAILED", "Tournament: total ship count is expected to be a power of ship count per battle") %}
    tournament.constructor(
        owner=ADMIN,
        tournament_id=1,
        tournament_name=11,
        reward_token_address=ONLY_DUST_TOKEN_ADDRESS,
        boarding_pass_token_address=BOARDING_TOKEN_ADDRESS,
        rand_contract_address=RAND_ADDRESS,
        battle_contract_address=BATTLE_ADDRESS,
        account_contract_address=ACCOUNT_TOKEN_ADDRESS,
        ship_count_per_battle=ship_count_per_battle,
        required_total_ship_count=required_total_ship_count,
        grid_size=10,
        turn_count=10,
        max_dust=8,
    )
    return ()
end

@external
func test_automatic_close_registrations{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 2)

    # Start registrations
    %{ stop_prank_admin = start_prank(ids.context.signers.admin) %}
    %{ expect_events({"name": "stage_changed", "data": [1, 2]}) %}
    tournament.open_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
    %{ stop_prank_admin() %}

    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}
    %{ mock_call(ids.context.mocks.account_token_address, "balanceOf", [1, 0]) %}

    # Register ship 1
    %{ stop_prank_player_1 = start_prank(ids.context.signers.player_1) %}
    tournament.register(ship_address=1000)
    %{ stop_prank_player_1() %}

    # Register ship 2
    %{ stop_prank_player_2 = start_prank(ids.context.signers.player_2) %}
    %{ expect_events({"name": "stage_changed", "data": [2, 3]}) %}
    tournament.register(ship_address=1001)
    %{ stop_prank_player_2() %}

    # Registration should be closed automatically
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_CLOSED)

    return ()
end

@external
func test_register_without_account{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 4)

    # Start registration
    %{ stop_prank_admin = start_prank(ids.context.signers.admin) %}
    %{ expect_events({"name": "stage_changed", "data": [1, 2]}) %}
    tournament.open_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
    %{ stop_prank_admin() %}

    # Fail to register
    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}
    %{ mock_call(ids.context.mocks.account_token_address, "balanceOf", [0, 0]) %}
    %{ stop_prank_anyone = start_prank(ids.context.signers.anyone) %}
    %{ expect_revert("TRANSACTION_FAILED", "Tournament: player needs an account to register") %}
    tournament.register(1000)
    %{ stop_prank_anyone() %}

    return ()
end

@external
func test_register_without_access{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 4)

    # Start registration
    %{ stop_prank_admin = start_prank(ids.context.signers.admin) %}
    %{ expect_events({"name": "stage_changed", "data": [1, 2]}) %}
    tournament.open_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
    %{ stop_prank_admin() %}

    # Fail to register
    %{ mock_call(ids.context.mocks.account_token_address, "balanceOf", [1, 0]) %}
    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [0, 0]) %}
    %{ stop_prank_anyone = start_prank(ids.context.signers.anyone) %}
    %{ expect_revert("TRANSACTION_FAILED", "Tournament: player is not allowed to register") %}
    tournament.register(1000)
    %{ stop_prank_anyone() %}

    return ()
end

@external
func test_register_with_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 4)

    # Start registration
    %{ stop_prank_admin = start_prank(ids.context.signers.admin) %}
    %{ expect_events({"name": "stage_changed", "data": [1, 2]}) %}
    tournament.open_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
    %{ stop_prank_admin() %}

    # Register
    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}
    %{ mock_call(ids.context.mocks.account_token_address, "balanceOf", [1, 0]) %}
    %{ stop_prank_player_1 = start_prank(ids.context.signers.player_1) %}
    let ship_address = 1000
    tournament.register(ship_address)
    %{ expect_events({"name": "new_player_registered", "data": [ids.context.signers.player_1, 1, 5]}) %}
    %{ stop_prank_player_1() %}

    # Check registration
    let (player_address) = tournament.ship_player(ship_address)
    with_attr error_message("Expected ship {ship_address} to be registered"):
        assert player_address = context.signers.player_1
    end

    return ()
end

@external
func test_register_when_registrations_are_not_yet_open{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 4)

    assert_that.stage_is(tournament.STAGE_CREATED)

    # Register
    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}
    %{ mock_call(ids.context.mocks.account_token_address, "balanceOf", [1, 0]) %}
    %{ stop_prank_player_1 = start_prank(ids.context.signers.player_1) %}
    let ship_address = 1000

    %{ expect_revert("TRANSACTION_FAILED", "Tournament: current stage (1) is not 2") %}
    tournament.register(ship_address)
    %{ stop_prank_player_1() %}

    return ()
end

@external
func test_register_when_registrations_are_closed{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(1, 1)

    # Open and close registrations
    %{ stop_prank_admin = start_prank(ids.context.signers.admin) %}
    %{ expect_events({"name": "stage_changed", "data": [1, 2]}) %}
    tournament.open_registrations()
    %{ stop_prank_admin() %}

    # Register one ship to be able to close registrations
    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}
    %{ mock_call(ids.context.mocks.account_token_address, "balanceOf", [1, 0]) %}
    %{ stop_prank_player_1 = start_prank(ids.context.signers.player_1) %}
    let ship_address = 1001
    tournament.register(ship_address)
    %{ stop_prank_player_1() %}

    # Registration should be closed automatically
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_CLOSED)

    # Register
    %{ stop_prank_player_2 = start_prank(ids.context.signers.player_2) %}
    let ship_address = 1002

    %{ expect_revert("TRANSACTION_FAILED", "Tournament: current stage (3) is not 2") %}
    tournament.register(ship_address)
    %{ stop_prank_player_2() %}

    return ()
end

@external
func test_tournament_with_4_ships_and_2_ships_per_battle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 4)
    with context:
        %{ expect_events({"name": "stage_changed", "data": [3, 4]}) %}
        test_internal.setup_tournament(ships_len=4, ships=new (1, 2, 3, 4))
        assert_that.playing_ships_are(playing_ships_len=4, playing_ships=new (1, 2, 3, 4))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_STARTED)

        # Play the first battle
        %{ stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [2, 100, 60]) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=1, expected_round_before=1, expected_round_after=1
        )

        # After the first battle, we are still in the round 1 so the list of playing ships is still the same
        assert_that.playing_ships_are(playing_ships_len=4, playing_ships=new (1, 2, 3, 4))
        assert_that.winning_ships_are(winning_ships_len=1, winning_ships=new (1))

        # Play the second battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [2, 80, 50])
        %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=2, expected_round_before=1, expected_round_after=2
        )

        # After the second battle, we are in the round 2 so the list of playing ships has been updated
        assert_that.playing_ships_are(playing_ships_len=2, playing_ships=new (1, 3))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())

        # Play the final battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [2, 40, 70])
        %}
        %{ expect_events({"name": "stage_changed", "data": [4, 5]}) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=3, expected_round_before=2, expected_round_after=3
        )

        %{ stop_mock() %}

        # After the final battle, we have our winner
        assert_that.playing_ships_are(playing_ships_len=1, playing_ships=new (3))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_FINISHED)
    end
    return ()
end

@external
func test_tournament_with_9_ships_and_3_ships_per_battle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(3, 9)
    with context:
        %{ expect_events({"name": "stage_changed", "data": [3, 4]}) %}
        test_internal.setup_tournament(ships_len=9, ships=new (1, 2, 3, 4, 5, 6, 7, 8, 9))
        assert_that.playing_ships_are(
            playing_ships_len=9, playing_ships=new (1, 2, 3, 4, 5, 6, 7, 8, 9)
        )
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_STARTED)

        # Play the first battle
        %{ stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [3, 10, 60, 80]) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=1, expected_round_before=1, expected_round_after=1
        )

        # After the first battle, we are still in the round 1 so the list of playing ships is still the same
        assert_that.playing_ships_are(
            playing_ships_len=9, playing_ships=new (1, 2, 3, 4, 5, 6, 7, 8, 9)
        )
        assert_that.winning_ships_are(winning_ships_len=1, winning_ships=new (3))

        # Play the second battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [3, 100, 60, 80])
        %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=2, expected_round_before=1, expected_round_after=1
        )

        # After the second battle, we are still in the round 1 so the list of playing ships is still the same
        assert_that.playing_ships_are(
            playing_ships_len=9, playing_ships=new (1, 2, 3, 4, 5, 6, 7, 8, 9)
        )
        assert_that.winning_ships_are(winning_ships_len=2, winning_ships=new (3, 4))

        # Play the third battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [3, 10, 60, 8])
        %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=3, expected_round_before=1, expected_round_after=2
        )

        # After the third battle, we are in the round 2 so the list of playing ships has been updated
        assert_that.playing_ships_are(playing_ships_len=3, playing_ships=new (3, 4, 8))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())

        # Play the final battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [3, 0, 10, 1300])
        %}
        %{ expect_events({"name": "stage_changed", "data": [4, 5]}) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=4, expected_round_before=2, expected_round_after=3
        )

        # After the final battle, we have our winner
        assert_that.playing_ships_are(playing_ships_len=1, playing_ships=new (8))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_FINISHED)
    end
    return ()
end

@external
func test_deposit_rewards_with_less_allowance{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let (deployed_contracts : DeployedContracts) = test_integration.deploy_contracts()

    # Get initial token balances
    # ADMIN = 1000
    let (balance) = IERC20.balanceOf(
        contract_address=deployed_contracts.other_address.only_dust_token_address, account=ADMIN
    )
    assert balance.low = 1000
    assert balance.high = 0

    # Admin deposits 100 tokens to the tournament contract
    let deposit_amount = Uint256(100, 0)

    %{
        stop_prank = start_prank(
            ids.ADMIN,
            ids.deployed_contracts.other_address.only_dust_token_address
        )
    %}
    # Expect revert since there are no approvals yet
    %{ expect_revert("TRANSACTION_FAILED", "ERC20: transfer amount exceeds allowance") %}
    ITournament.deposit_rewards(
        contract_address=deployed_contracts.tournament_address, amount=deposit_amount
    )
    %{ stop_prank() %}
    return ()
end

@external
func test_deposit_rewards_with_enough_allowance{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let (deployed_contracts : DeployedContracts) = test_integration.deploy_contracts()

    # Get initial token balances
    # ADMIN = 1000, Contract = 0
    let (local addresses : felt*) = alloc()
    let (local token_balances_before : Uint256*) = alloc()
    let (local token_balances_after : Uint256*) = alloc()

    assert addresses[0] = ADMIN
    assert addresses[1] = deployed_contracts.tournament_address

    assert token_balances_before[0] = Uint256(1000, 0)
    assert token_balances_before[1] = Uint256(0, 0)

    with deployed_contracts:
        assert_that.token_balances_are(
            addresses_len=2,
            addresses=addresses,
            token_balances_len=2,
            token_balances=token_balances_before,
            idx=0,
        )

        # Admin deposits 100 tokens to the tournament contract
        local deposit_amount : Uint256 = Uint256(100, 0)

        %{
            stop_prank = start_prank(
                ids.ADMIN,
                ids.deployed_contracts.other_address.only_dust_token_address
            )
        %}
        # Approve the contract to spend 100 tokens
        IERC20.approve(
            contract_address=deployed_contracts.other_address.only_dust_token_address,
            spender=deployed_contracts.tournament_address,
            amount=deposit_amount,
        )
        %{ stop_prank() %}

        %{
            stop_prank = start_prank(
                ids.ADMIN,
                ids.deployed_contracts.tournament_address
            )
        %}
        %{ expect_events({"name": "rewards_deposited", "data": [ids.ADMIN, 100, 0]}) %}
        ITournament.deposit_rewards(
            contract_address=deployed_contracts.tournament_address, amount=deposit_amount
        )
        %{ stop_prank() %}

        assert token_balances_after[0] = Uint256(900, 0)
        assert token_balances_after[1] = Uint256(100, 0)

        assert_that.token_balances_are(
            addresses_len=2,
            addresses=addresses,
            token_balances_len=2,
            token_balances=token_balances_after,
            idx=0,
        )
    end
    return ()
end

@external
func test_withdraw_reward_tournament_not_finished{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 2)

    %{ stop_prank = start_prank(ids.context.signers.player_1) %}
    %{ expect_revert("TRANSACTION_FAILED", "Tournament: tournament not yet FINISHED") %}
    tournament.winner_withdraw()
    %{ stop_prank() %}

    return ()
end

@external
func test_withdraw_reward_by_zero_address{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 2)
    with context:
        # Tournament with 2 ships and 2 ships per battle
        %{ expect_events({"name": "stage_changed", "data": [3, 4]}) %}
        test_internal.setup_tournament(ships_len=2, ships=new (1, 2))
        assert_that.playing_ships_are(playing_ships_len=2, playing_ships=new (1, 2))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_STARTED)

        # Play the first and final battle, only 1 round
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [2, 100, 80]) %}
        %{ expect_events({"name": "stage_changed", "data": [4, 5]}) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=1, expected_round_before=1, expected_round_after=2
        )

        # We have our winner
        assert_that.playing_ships_are(playing_ships_len=1, playing_ships=new (1))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_FINISHED)
        assert_that.winner_is(1)

        # zero address withdraws reward
        %{ stop_prank = start_prank(caller_address=0) %}
        %{ expect_revert("TRANSACTION_FAILED", "caller cannot be zero address") %}
        tournament.winner_withdraw()
    end
    %{ stop_prank() %}
    return ()
end

@external
func test_withdraw_reward_not_by_winner{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 2)
    with context:
        # Tournament with 2 ships and 2 ships per battle
        %{ expect_events({"name": "stage_changed", "data": [3, 4]}) %}
        test_internal.setup_tournament(ships_len=2, ships=new (1, 2))
        assert_that.playing_ships_are(playing_ships_len=2, playing_ships=new (1, 2))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_STARTED)

        # Play the first and final battle, only 1 round
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [2, 100, 80]) %}
        %{ expect_events({"name": "stage_changed", "data": [4, 5]}) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=1, expected_round_before=1, expected_round_after=2
        )

        # We have our winner
        assert_that.playing_ships_are(playing_ships_len=1, playing_ships=new (1))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_FINISHED)
        assert_that.winner_is(1)

        # 2 withdraws reward
        %{ stop_prank = start_prank(caller_address=2) %}
        %{ expect_revert("TRANSACTION_FAILED", "Tournament: caller is not the final winner") %}
        tournament.winner_withdraw()
    end
    %{ stop_prank() %}
    return ()
end

@external
func test_winner_withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    # Deploy the contracts
    let (deployed_contracts : DeployedContracts) = test_integration.deploy_contracts()

    # Get initial token balances
    # ADMIN = 1000, Winner = 0
    tempvar addresses : felt* = new (ADMIN, PLAYER_1)
    let (local token_balances_before : Uint256*) = alloc()

    assert token_balances_before[0] = Uint256(1000, 0)
    assert token_balances_before[1] = Uint256(0, 0)

    with deployed_contracts:
        assert_that.token_balances_are(
            addresses_len=2,
            addresses=addresses,
            token_balances_len=2,
            token_balances=token_balances_before,
            idx=0,
        )

        # Admin deposits 100 tokens to the tournament contract
        let deposit_amount = Uint256(100, 0)

        %{
            stop_prank_admin = start_prank(
                ids.ADMIN,
                ids.deployed_contracts.other_address.only_dust_token_address
            )
        %}
        # ADMIN approves the contract to spend 100 tokens
        IERC20.approve(
            contract_address=deployed_contracts.other_address.only_dust_token_address,
            spender=deployed_contracts.tournament_address,
            amount=deposit_amount,
        )
        %{ stop_prank_admin() %}

        %{
            stop_prank_admin = start_prank(
                ids.ADMIN,
                ids.deployed_contracts.tournament_address
            )
        %}
        %{ expect_events({"name": "rewards_deposited", "data": [ids.ADMIN, 100, 0]}) %}
        # ADMIN deposits 100 tokens to the tournament contract
        ITournament.deposit_rewards(
            contract_address=deployed_contracts.tournament_address, amount=deposit_amount
        )

        # Start registration
        ITournament.open_registrations(deployed_contracts.tournament_address)
        %{ stop_prank_admin() %}

        # Register ships, tournament with 2 ships and 2 ships per battle
        # For simplicity, player_address = ship_address
        %{
            mock_call(
                ids.deployed_contracts.other_address.boarding_pass_token_address,
                "balanceOf",
                [1, 0]
                )
        %}
        %{
            mock_call(
                ids.deployed_contracts.other_address.account_token_address,
                "balanceOf",
                [1, 0]
                )
        %}

        # PLAYER 1 registers
        %{
            stop_prank_player_1 = start_prank(
                ids.PLAYER_1,
                ids.deployed_contracts.tournament_address
            )
        %}
        ITournament.register(
            contract_address=deployed_contracts.tournament_address, ship_address=PLAYER_1
        )
        %{ stop_prank_player_1() %}

        # PLAYER 2 registers
        %{
            stop_prank_player_2 = start_prank(
                ids.ADMIN,
                ids.deployed_contracts.tournament_address
            )
        %}
        ITournament.register(
            contract_address=deployed_contracts.tournament_address, ship_address=PLAYER_2
        )
        %{ stop_prank_player_2() %}

        %{
            stop_prank_admin = start_prank(
                ids.ADMIN,
                ids.deployed_contracts.tournament_address
            )
        %}

        # Start tournament
        ITournament.start(deployed_contracts.tournament_address)

        # Play first and final battle, tournament_finished event is emitted
        %{
            mock_call(
                ids.deployed_contracts.other_address.battle_address,
                "play_game",
                [2, 100, 80]
                )
        %}
        %{ expect_events({"name": "tournament_finished", "data": [ids.PLAYER_1, ids.PLAYER_1]}) %}
        %{ expect_events({"name": "stage_changed", "data": [4, 5]}) %}
        ITournament.play_next_battle(deployed_contracts.tournament_address)
        %{ stop_prank_admin() %}

        # We have our winner PLAYER_1
        let (stage) = ITournament.stage(deployed_contracts.tournament_address)
        let (winner) = ITournament.tournament_winner(deployed_contracts.tournament_address)
        assert stage = tournament.STAGE_FINISHED
        assert winner.player_address = PLAYER_1

        # Winner withdraws rewards, rewards_withdrawn event is emitted
        %{
            stop_prank_winner = start_prank(
                ids.PLAYER_1,
                ids.deployed_contracts.tournament_address
            )
        %}
        %{ expect_events({"name": "rewards_withdrawn", "data": [ids.PLAYER_1, 100, 0]}) %}
        ITournament.winner_withdraw(deployed_contracts.tournament_address)
        %{ stop_prank_winner() %}

        # Check token balances
        # ADMIN = 900, Winner = 100
        let (local token_balances_after : Uint256*) = alloc()

        assert token_balances_after[0] = Uint256(900, 0)
        assert token_balances_after[1] = Uint256(100, 0)
        assert_that.token_balances_are(
            addresses_len=2,
            addresses=addresses,
            token_balances_len=2,
            token_balances=token_balances_after,
            idx=0,
        )
    end
    return ()
end

@external
func test_event_sent_after_battle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 2)
    with context:
        # Tournament with 2 ships and 2 ships per battle
        test_internal.setup_tournament(ships_len=2, ships=new (1, 2))

        # Play the first and final battle, only 1 round and test if the event data is correct
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [2, 100, 80]) %}
        %{ expect_events({"name": "battle_completed", "data": [1, 1, 1]}) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=1, expected_round_before=1, expected_round_after=2
        )
    end
    return ()
end

@external
func test_auto_increment_accounts_information{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 4)
    with context:
        %{ expect_events({"name": "stage_changed", "data": [3, 4]}) %}
        test_internal.setup_tournament(ships_len=4, ships=new (1, 2, 3, 4))

        # Play the first battle
        %{ stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [2, 100, 60]) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=1, expected_round_before=1, expected_round_after=1
        )

        # After the first battle, we are still in the round 1 so the list of playing ships is still the same
        assert_that.playing_ships_are(playing_ships_len=4, playing_ships=new (1, 2, 3, 4))
        assert_that.winning_ships_are(winning_ships_len=1, winning_ships=new (1))
        assert_that.won_battle_count_is(1, 1, context.mocks.account_token_address)
        assert_that.won_battle_count_is(2, 0, context.mocks.account_token_address)
        assert_that.won_battle_count_is(3, 0, context.mocks.account_token_address)
        assert_that.won_battle_count_is(4, 0, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(1, 0, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(2, 1, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(3, 0, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(4, 0, context.mocks.account_token_address)

        # Play the second battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [2, 80, 50])
        %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=2, expected_round_before=1, expected_round_after=2
        )

        # After the second battle, we are in the round 2 so the list of playing ships has been updated
        assert_that.playing_ships_are(playing_ships_len=2, playing_ships=new (1, 3))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.won_battle_count_is(1, 1, context.mocks.account_token_address)
        assert_that.won_battle_count_is(2, 0, context.mocks.account_token_address)
        assert_that.won_battle_count_is(3, 1, context.mocks.account_token_address)
        assert_that.won_battle_count_is(4, 0, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(1, 0, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(2, 1, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(3, 0, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(4, 1, context.mocks.account_token_address)

        # Play the final battle
        %{
            stop_mock()
            stop_mock = mock_call(ids.context.mocks.battle_address, "play_game", [2, 40, 70])
        %}
        %{ expect_events({"name": "stage_changed", "data": [4, 5]}) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=3, expected_round_before=2, expected_round_after=3
        )

        %{ stop_mock() %}

        # After the final battle, we have our winner
        assert_that.won_battle_count_is(1, 1, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(1, 1, context.mocks.account_token_address)
        assert_that.won_battle_count_is(3, 2, context.mocks.account_token_address)
        assert_that.lost_battle_count_is(3, 0, context.mocks.account_token_address)



        assert_that.won_tournament_count_is(1, 0, context.mocks.account_token_address)
        assert_that.won_tournament_count_is(2, 0, context.mocks.account_token_address)
        assert_that.won_tournament_count_is(3, 1, context.mocks.account_token_address)
        assert_that.won_tournament_count_is(4, 0, context.mocks.account_token_address)
        assert_that.lost_tournament_count_is(1, 1, context.mocks.account_token_address)
        assert_that.lost_tournament_count_is(2, 1, context.mocks.account_token_address)
        assert_that.lost_tournament_count_is(3, 0, context.mocks.account_token_address)
        assert_that.lost_tournament_count_is(4, 1, context.mocks.account_token_address)

    end
    return ()
end

# -----------------------
# INTERNAL TEST FUNCTIONS
# -----------------------

namespace test_internal:
    func prepare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ships_per_battle : felt, max_ships_per_tournament : felt
    ) -> (test_context : TestContext):
        alloc_locals
        local signers : Signers = Signers(admin=ADMIN, anyone=ANYONE, player_1=PLAYER_1, player_2=PLAYER_2)

        local account_address : felt

        %{
            ids.account_address = deploy_contract(
            "./contracts/account/account.cairo",
            # name, symbol, owner
            [0, 0, ids.ADMIN]).contract_address
        %}

        local mocks : Mocks = Mocks(
            only_dust_token_address=ONLY_DUST_TOKEN_ADDRESS,
            boarding_pass_token_address=BOARDING_TOKEN_ADDRESS,
            rand_address=RAND_ADDRESS,
            battle_address=BATTLE_ADDRESS,
            account_token_address=account_address
            )

        local context : TestContext = TestContext(
            signers=signers,
            mocks=mocks,
            tournament_id=420,
            tournament_name=69,
            ships_per_battle=ships_per_battle,
            max_ships_per_tournament=max_ships_per_tournament,
            grid_size=5,
            turn_count=10,
            max_dust=2,
            )

        tournament.constructor(
            signers.admin,
            context.tournament_id,
            context.tournament_name,
            mocks.only_dust_token_address,
            mocks.boarding_pass_token_address,
            mocks.rand_address,
            mocks.battle_address,
            mocks.account_token_address,
            context.ships_per_battle,
            context.max_ships_per_tournament,
            context.grid_size,
            context.turn_count,
            context.max_dust,
        )

        assert_that.stage_is(tournament.STAGE_CREATED)
        return (test_context=context)
    end

    func setup_tournament{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : TestContext
    }(ships_len : felt, ships : felt*):
        alloc_locals

        %{ mock_call(ids.context.mocks.only_dust_token_address, "balanceOf", [100, 0]) %}
        let (reward_total_amount) = tournament.reward_total_amount()
        assert reward_total_amount.low = 100
        assert reward_total_amount.high = 0

        # Start registration
        %{ stop_prank_admin = start_prank(ids.context.signers.admin) %}
        assert_that.stage_is(tournament.STAGE_CREATED)
        %{ expect_events({"name": "stage_changed", "data": [1, 2]}) %}
        tournament.open_registrations()
        assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
        %{ stop_prank_admin() %}

        # Register ships
        %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}
        %{ mock_call(ids.context.mocks.account_token_address, "balanceOf", [1, 0]) %}
        _register_ships_loop(context.mocks.account_token_address, ships_len, ships)

        # Registration should now be closed
        %{ expect_events({"name": "stage_changed", "data": [2, 3]}) %}
        assert_that.stage_is(tournament.STAGE_REGISTRATIONS_CLOSED)

        # Start the tournament
        %{ stop_prank_admin= start_prank(ids.context.signers.admin) %}
        %{ expect_events({"name": "stage_changed", "data": [3, 4]}) %}
        tournament.start()
        assert_that.stage_is(tournament.STAGE_STARTED)
        %{ stop_prank_admin() %}

        let (played_battle_count) = tournament.played_battle_count()
        assert played_battle_count = 0
        let (round) = tournament.current_round()
        assert round = 1

        return ()
    end

    func _register_ships_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : TestContext
    }(account_address: felt, ships_len : felt, ships : felt*):
        alloc_locals
        if ships_len == 0:
            return ()
        end

        tempvar ship_address = [ships]
        local player_address = ship_address  # To keep it simple in tests, the player_address is equal to the ship_address

        IAccount.mint(account_address, player_address, player_address)

        # Register
        %{ stop_prank_player = start_prank(ids.player_address) %}
        tournament.register(ship_address)
        %{ stop_prank_player() %}

        # Check registration
        let (registered_player_address) = tournament.ship_player(ship_address)
        with_attr error_message("Expected ship {ship_address} to be registered"):
            assert registered_player_address = player_address
        end

        _register_ships_loop(account_address, ships_len - 1, &ships[1])
        return ()
    end

    func invoke_battle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : TestContext
    }(
        expected_played_battle_count_after : felt,
        expected_round_before : felt,
        expected_round_after : felt,
    ):
        alloc_locals
        local battle_address = BATTLE_ADDRESS
        local admin = ADMIN

        let (local round) = tournament.current_round()
        with_attr error_message(
                "Expected round number (before battle) to be {expected_round_before}, got {round}"):
            assert round = expected_round_before
        end

        %{ stop_prank_admin = start_prank(ids.context.signers.admin) %}
        tournament.play_next_battle()
        %{ stop_prank_admin() %}

        let (local played_battle_count) = tournament.played_battle_count()
        with_attr error_message(
                "Expected played battle count (after battle) to be {expected_played_battle_count_after}, got {played_battle_count}"):
            assert played_battle_count = expected_played_battle_count_after
        end

        let (local round) = tournament.current_round()
        with_attr error_message(
                "Expected round number (after battle) to be {expected_round_after}, got {round}"):
            assert round = expected_round_after
        end

        return ()
    end
end

# --------------------------
# INTEGRATION TEST FUNCTIONS
# --------------------------

namespace test_integration:
    func deploy_contracts{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        deployed_contracts : DeployedContracts
    ):
        alloc_locals

        local reward_token_address : felt
        local tournament_contract_address : felt
        local account_address : felt

        # Deploy the ERC20 contract and put its address into a local variable.
        # Second argument is calldata array, with 1000 initial tokens minted to ADMIN
        %{
            ids.reward_token_address = deploy_contract(
            "./contracts/tokens/only_dust/only_dust.cairo",
            # name, symbol, decimals, initial_supply, recipient
            [420, 69, 0, 1000, 0, ids.ADMIN]).contract_address
        %}

        %{
            ids.account_address = deploy_contract(
            "./contracts/account/account.cairo",
            # name, symbol, owner
            [0, 0, ids.ADMIN]).contract_address
        %}

        # TO-DO: Deploy other contracts here

        # Replace mocks with deployed contract addresses here and deploy the tournament contract
        %{
            ids.tournament_contract_address = deploy_contract(
            "./contracts/tournament/tournament.cairo",
            [   # owner, tournament_id, tournament_name
                ids.ADMIN, 1, 11, 
                ids.reward_token_address,
                ids.BOARDING_TOKEN_ADDRESS,
                ids.RAND_ADDRESS,
                ids.BATTLE_ADDRESS,
                ids.account_address,
                # ship_count_per_battle, required_total_ship_count, grid_size, turn_count, max_dust
                2, 2, 10, 10, 8
            ]).contract_address
        %}

        # Replace mocks with deployed contract addresses here
        let deployed_contracts = DeployedContracts(
            tournament_address=tournament_contract_address,
            other_address=Mocks(
            only_dust_token_address=reward_token_address,
            boarding_pass_token_address=BOARDING_TOKEN_ADDRESS,
            rand_address=RAND_ADDRESS,
            battle_address=BATTLE_ADDRESS,
            account_token_address=account_address
            ),
        )
        return (deployed_contracts)
    end
end

# -----------------
# CUSTOM ASSERTIONS
# -----------------

namespace assert_that:
    func stage_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected_stage : felt
    ):
        alloc_locals
        let (local stage) = tournament.stage()
        with_attr error_message("Expected stage to be {expected_stage}, got {stage}"):
            assert stage = expected_stage
        end
        return ()
    end

    func winner_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected_winner : felt
    ):
        let (winner : Player) = tournament.tournament_winner()
        with_attr error_message(
                "Expected winner to be {expected_winner}, got {winner.player_address}"):
            assert winner.player_address = expected_winner
        end
        return ()
    end

    func won_tournament_count_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt,
        expected_won_count : felt,
        account_address : felt
    ):
        let (_account : Account) = IAccount.account_information(account_address, address)
        assert _account.won_tournament_count = expected_won_count
        return ()
    end

    func lost_tournament_count_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt,
        expected_lost_count : felt,
        account_address : felt
    ):
        let (_account : Account) = IAccount.account_information(account_address, address)
        assert _account.lost_tournament_count = expected_lost_count
        return ()
    end

    func won_battle_count_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt,
        expected_won_count : felt,
        account_address : felt
    ):
        let (_account : Account) = IAccount.account_information(account_address, address)
        assert _account.won_battle_count = expected_won_count
        return ()
    end

    func lost_battle_count_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt,
        expected_lost_count : felt,
        account_address : felt
    ):
        let (_account : Account) = IAccount.account_information(account_address, address)
        assert _account.lost_battle_count = expected_lost_count
        return ()
    end

    func winning_ships_are{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        winning_ships_len : felt, winning_ships : felt*
    ):
        alloc_locals
        let (local winning_ship_count) = winning_ship_count_.read()
        with_attr error_message(
                "Expected winning_ship_count to be {winning_ships_len}, got {winning_ship_count}"):
            assert winning_ship_count = winning_ships_len
        end

        _assert_winning_ships_loop(0, winning_ships_len, winning_ships)
        return ()
    end

    func _assert_winning_ships_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(winning_index : felt, winning_ships_len : felt, winning_ships : felt*):
        alloc_locals
        if winning_ships_len == 0:
            return ()
        end

        local expected_winning_ship_address = [winning_ships]
        let (local winning_ship_address : felt) = winning_ships_.read(winning_index)

        with_attr error_message(
                "Expected winning_ship_address to be {expected_winning_ship_address} at index {winning_index}, got {winning_ship_address}"):
            assert winning_ship_address = expected_winning_ship_address
        end

        _assert_winning_ships_loop(winning_index + 1, winning_ships_len - 1, &winning_ships[1])
        return ()
    end

    func playing_ships_are{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        playing_ships_len : felt, playing_ships : felt*
    ):
        alloc_locals
        let (local playing_ship_count) = playing_ship_count_.read()
        with_attr error_message(
                "Expected playing_ship_count to be {playing_ships_len}, got {playing_ship_count}"):
            assert playing_ship_count = playing_ships_len
        end

        _assert_playing_ships_loop(0, playing_ships_len, playing_ships)
        return ()
    end

    func _assert_playing_ships_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(playing_index : felt, playing_ships_len : felt, playing_ships : felt*):
        alloc_locals
        if playing_ships_len == 0:
            return ()
        end

        local expected_playing_ship_address = [playing_ships]
        let (local playing_ship_address : felt) = playing_ships_.read(playing_index)

        with_attr error_message(
                "Expected playing_ship_address to be {expected_playing_ship_address} at index {playing_index}, got {playing_ship_address}"):
            assert playing_ship_address = expected_playing_ship_address
        end

        _assert_playing_ships_loop(playing_index + 1, playing_ships_len - 1, &playing_ships[1])
        return ()
    end

    func token_balances_are{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        deployed_contracts : DeployedContracts,
    }(
        addresses_len : felt,
        addresses : felt*,
        token_balances_len : felt,
        token_balances : Uint256*,
        idx : felt,
    ):
        alloc_locals
        if addresses_len == 0:
            return ()
        end

        if token_balances_len == 0:
            return ()
        end

        let address = addresses[idx]
        let expected_balance = token_balances[idx]
        let (balance) = IERC20.balanceOf(
            contract_address=deployed_contracts.other_address.only_dust_token_address,
            account=address,
        )
        let (is_equal) = uint256_eq(balance, expected_balance)
        with_attr error_message("Expected token balance to be {expected_balance}, got {balance}"):
            assert is_equal = TRUE
        end

        token_balances_are(
            addresses_len - 1, addresses, token_balances_len - 1, token_balances, idx + 1
        )
        return ()
    end
end
