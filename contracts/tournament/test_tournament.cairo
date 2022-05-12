%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from contracts.tournament.library import (
    tournament,
    playing_ships_,
    playing_ship_count_,
    winning_ships_,
    winning_ship_count_,
)

# ---------
# CONSTANTS
# ---------

const ONLY_DUST_TOKEN_ADDRESS = 0x3fe90a1958bb8468fb1b62970747d8a00c435ef96cda708ae8de3d07f1bb56b
const BOARDING_TOKEN_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a95
const RAND_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a91
const BATTLE_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04aaa
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
        ship_count_per_battle=ship_count_per_battle,
        required_total_ship_count=required_total_ship_count,
        grid_size=10,
        turn_count=10,
        max_dust=8,
    )
    return ()
end

@external
func test_close_registrations_with_good_ship_count{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 2)

    # Start registrations
    %{ start_prank(ids.context.signers.admin) %}
    tournament.open_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
    %{ stop_prank() %}

    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}

    # Register ship 1
    %{ start_prank(ids.context.signers.player_1) %}
    tournament.register(ship_address=1000)
    %{ stop_prank() %}

    # Register ship 2
    %{ start_prank(ids.context.signers.player_2) %}
    tournament.register(ship_address=1001)
    %{ stop_prank() %}

    # Close registrations
    %{ start_prank(ids.context.signers.admin) %}
    tournament.close_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_CLOSED)
    %{ stop_prank() %}

    return ()
end

@external
func test_close_registrations_with_bad_ship_count{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 2)

    # Start registrations
    %{ start_prank(ids.context.signers.admin) %}
    tournament.open_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
    %{ stop_prank() %}

    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}

    # Register ship 1
    %{ start_prank(ids.context.signers.player_1) %}
    tournament.register(ship_address=1000)
    %{ stop_prank() %}

    # Do NOT register ship 2

    # Close registrations
    %{ start_prank(ids.context.signers.admin) %}
    %{ expect_revert("TRANSACTION_FAILED", "Tournament: ship count not reached") %}
    tournament.close_registrations()
    %{ stop_prank() %}

    return ()
end

@external
func test_register_without_access{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 4)

    # Start registration
    %{ start_prank(ids.context.signers.admin) %}
    tournament.open_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
    %{ stop_prank() %}

    # Fail to register
    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [0, 0]) %}
    %{ start_prank(ids.context.signers.anyone) %}
    %{ expect_revert("TRANSACTION_FAILED", "Tournament: player is not allowed to register") %}
    tournament.register(1000)
    %{ stop_prank() %}

    return ()
end

@external
func test_register_with_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 4)

    # Start registration
    %{ start_prank(ids.context.signers.admin) %}
    tournament.open_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
    %{ stop_prank() %}

    # Register
    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}
    %{ start_prank(ids.context.signers.player_1) %}
    let ship_address = 1000
    tournament.register(ship_address)
    %{ stop_prank() %}

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
    %{ start_prank(ids.context.signers.player_1) %}
    let ship_address = 1000

    %{ expect_revert("TRANSACTION_FAILED", "Tournament: current stage (1) is not 2") %}
    tournament.register(ship_address)
    %{ stop_prank() %}

    return ()
end

@external
func test_register_when_registrations_are_closed{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(1, 1)

    # Open and close registrations
    %{ start_prank(ids.context.signers.admin) %}
    tournament.open_registrations()
    %{ stop_prank() %}

    # Register one ship to be able to close registrations
    %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}
    %{ start_prank(ids.context.signers.player_1) %}
    let ship_address = 1001
    tournament.register(ship_address)
    %{ stop_prank() %}

    %{ start_prank(ids.context.signers.admin) %}
    tournament.close_registrations()
    assert_that.stage_is(tournament.STAGE_REGISTRATIONS_CLOSED)
    %{ stop_prank() %}

    # Register
    %{ start_prank(ids.context.signers.player_2) %}
    let ship_address = 1002

    %{ expect_revert("TRANSACTION_FAILED", "Tournament: current stage (3) is not 2") %}
    tournament.register(ship_address)
    %{ stop_prank() %}

    return ()
end

@external
func test_tournament_with_4_ships_and_2_ships_per_battle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (local context : TestContext) = test_internal.prepare(2, 4)
    with context:
        test_internal.setup_tournament(ships_len=4, ships=new (1, 2, 3, 4))
        assert_that.playing_ships_are(playing_ships_len=4, playing_ships=new (1, 2, 3, 4))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_STARTED)

        # Play the first battle
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [2, 100, 60]) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=1, expected_round_before=1, expected_round_after=1
        )

        # After the first battle, we are still in the round 1 so the list of playing ships is still the same
        assert_that.playing_ships_are(playing_ships_len=4, playing_ships=new (1, 2, 3, 4))
        assert_that.winning_ships_are(winning_ships_len=1, winning_ships=new (1))

        # Play the second battle
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [2, 80, 50]) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=2, expected_round_before=1, expected_round_after=2
        )

        # After the second battle, we are in the round 2 so the list of playing ships has been updated
        assert_that.playing_ships_are(playing_ships_len=2, playing_ships=new (1, 3))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())

        # Play the final battle
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [2, 40, 70]) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=3, expected_round_before=2, expected_round_after=3
        )

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
        test_internal.setup_tournament(ships_len=9, ships=new (1, 2, 3, 4, 5, 6, 7, 8, 9))
        assert_that.playing_ships_are(
            playing_ships_len=9, playing_ships=new (1, 2, 3, 4, 5, 6, 7, 8, 9)
        )
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())
        assert_that.stage_is(tournament.STAGE_STARTED)

        # Play the first battle
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [3, 10, 60, 80]) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=1, expected_round_before=1, expected_round_after=1
        )

        # After the first battle, we are still in the round 1 so the list of playing ships is still the same
        assert_that.playing_ships_are(
            playing_ships_len=9, playing_ships=new (1, 2, 3, 4, 5, 6, 7, 8, 9)
        )
        assert_that.winning_ships_are(winning_ships_len=1, winning_ships=new (3))

        # Play the second battle
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [3, 100, 60, 80]) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=2, expected_round_before=1, expected_round_after=1
        )

        # After the second battle, we are still in the round 1 so the list of playing ships is still the same
        assert_that.playing_ships_are(
            playing_ships_len=9, playing_ships=new (1, 2, 3, 4, 5, 6, 7, 8, 9)
        )
        assert_that.winning_ships_are(winning_ships_len=2, winning_ships=new (3, 4))

        # Play the third battle
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [3, 10, 60, 8]) %}
        test_internal.invoke_battle(
            expected_played_battle_count_after=3, expected_round_before=1, expected_round_after=2
        )

        # After the third battle, we are in the round 2 so the list of playing ships has been updated
        assert_that.playing_ships_are(playing_ships_len=3, playing_ships=new (3, 4, 8))
        assert_that.winning_ships_are(winning_ships_len=0, winning_ships=new ())

        # Play the final battle
        %{ mock_call(ids.context.mocks.battle_address, "play_game", [3, 0, 10, 1300]) %}
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

# -----------------------
# INTERNAL TEST FUNCTIONS
# -----------------------

namespace test_internal:
    func prepare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ships_per_battle : felt, max_ships_per_tournament : felt
    ) -> (test_context : TestContext):
        alloc_locals
        local signers : Signers = Signers(admin=ADMIN, anyone=ANYONE, player_1=PLAYER_1, player_2=PLAYER_2)

        local mocks : Mocks = Mocks(
            only_dust_token_address=ONLY_DUST_TOKEN_ADDRESS,
            boarding_pass_token_address=BOARDING_TOKEN_ADDRESS,
            rand_address=RAND_ADDRESS,
            battle_address=BATTLE_ADDRESS,
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
        %{ start_prank(ids.context.signers.admin) %}
        assert_that.stage_is(tournament.STAGE_CREATED)
        tournament.open_registrations()
        assert_that.stage_is(tournament.STAGE_REGISTRATIONS_OPEN)
        %{ stop_prank() %}

        # Register ships
        %{ mock_call(ids.context.mocks.boarding_pass_token_address, "balanceOf", [1, 0]) %}
        _register_ships_loop(ships_len, ships)

        # Close registration
        %{ start_prank(ids.context.signers.admin) %}
        tournament.close_registrations()
        assert_that.stage_is(tournament.STAGE_REGISTRATIONS_CLOSED)
        %{ stop_prank() %}

        # Start the tournament
        %{ start_prank(ids.context.signers.admin) %}
        tournament.start()
        assert_that.stage_is(tournament.STAGE_STARTED)
        %{ stop_prank() %}

        let (played_battle_count) = tournament.played_battle_count()
        assert played_battle_count = 0
        let (round) = tournament.current_round()
        assert round = 1

        return ()
    end

    func _register_ships_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, context : TestContext
    }(ships_len : felt, ships : felt*):
        alloc_locals
        if ships_len == 0:
            return ()
        end

        tempvar ship_address = [ships]
        local player_address = ship_address  # To keep it simple in tests, the player_address is equal to the ship_address

        # Register
        %{ start_prank(ids.player_address) %}
        tournament.register(ship_address)
        %{ stop_prank() %}

        # Check registration
        let (registered_player_address) = tournament.ship_player(ship_address)
        with_attr error_message("Expected ship {ship_address} to be registered"):
            assert registered_player_address = player_address
        end

        _register_ships_loop(ships_len - 1, &ships[1])
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

        %{ start_prank(ids.context.signers.admin) %}
        tournament.play_next_battle()
        %{ stop_prank() %}

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
end
