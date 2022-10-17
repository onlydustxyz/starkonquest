%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from contracts.account.account import (
    Account,
    mint,
    account_information,
    transferFrom,
    safeTransferFrom,
    incrementWonTournamentCount,
    incrementLostTournamentCount,
    incrementWonBattleCount,
    incrementLostBattleCount,
)
from contracts.interfaces.itournament import ITournament

const ONLY_DUST_TOKEN_ADDRESS = 0x3fe90a1958bb8468fb1b62970747d8a00c435ef96cda708ae8de3d07f1bb56b;
const BOARDING_TOKEN_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a95;
const RAND_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a91;
const BATTLE_ADDRESS = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04aaa;
const ADMIN = 300;
const ANYONE = 301;
const PLAYER_1 = 302;
const PLAYER_2 = 303;

struct Mocks {
    only_dust_token_address: felt,
    boarding_pass_token_address: felt,
    rand_address: felt,
    battle_address: felt,
}

struct DeployedContracts {
    tournament_address: felt,
    other_address: Mocks,
}

@external
func test_mint_account{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    alloc_locals;

    mint(0x123, 0x321);
    mint(0x124, 0x432);

    let (account1: Account) = account_information(0x123);
    let (account2: Account) = account_information(0x124);

    assert 0x321 = account1.nickname;
    assert 0 = account1.won_tournament_count;
    assert 0 = account1.lost_tournament_count;
    assert 0 = account1.won_battle_count;
    assert 0 = account1.lost_battle_count;
    assert 0x432 = account2.nickname;
    assert 0 = account2.won_tournament_count;
    assert 0 = account2.lost_tournament_count;
    assert 0 = account2.won_battle_count;
    assert 0 = account2.lost_battle_count;

    return ();
}

@external
func test_should_not_accept_two_mints_for_one_address{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    mint(0x121, 0x321);
    %{ expect_revert(error_message='Account: This address already has an associated account') %}
    mint(0x121, 0x432);

    return ();
}

@external
func test_should_not_accept_tranferring_accounts{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    mint(0x123, 0x321);
    %{ expect_revert(error_message='Account: transferring account is disabled') %}
    transferFrom(0x123, 0x124, Uint256(1, 0));

    return ();
}

@external
func test_should_increment_win_tournament_count{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    mint(0x123, 0x321);
    incrementWonTournamentCount(0x123);
    let (account1: Account) = account_information(0x123);
    assert account1.won_tournament_count = 1;
    incrementWonTournamentCount(0x123);
    let (account2: Account) = account_information(0x123);
    assert account2.won_tournament_count = 2;
    return ();
}

@external
func test_should_increment_lost_tournament_count{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    mint(0x123, 0x321);
    incrementLostTournamentCount(0x123);
    let (account1: Account) = account_information(0x123);
    assert account1.lost_tournament_count = 1;
    incrementLostTournamentCount(0x123);
    let (account2: Account) = account_information(0x123);
    assert account2.lost_tournament_count = 2;
    return ();
}

@external
func test_should_increment_won_battle_count{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    mint(0x123, 0x321);
    incrementWonBattleCount(0x123);
    let (account1: Account) = account_information(0x123);
    assert account1.won_battle_count = 1;
    incrementWonBattleCount(0x123);
    let (account2: Account) = account_information(0x123);
    assert account2.won_battle_count = 2;
    return ();
}

@external
func test_should_increment_lost_battle_count{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    mint(0x123, 0x321);
    incrementLostBattleCount(0x123);
    let (account1: Account) = account_information(0x123);
    assert account1.lost_battle_count = 1;
    incrementLostBattleCount(0x123);
    let (account2: Account) = account_information(0x123);
    assert account2.lost_battle_count = 2;
    return ();
}

namespace test_integration {
    func deploy_contracts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        deployed_contracts: DeployedContracts
    ) {
        alloc_locals;

        local reward_token_address: felt;
        local tournament_contract_address: felt;

        %{
            ids.tournament_contract_address = deploy_contract(
            "./contracts/tournament/tournament.cairo",
            [   # owner, tournament_id, tournament_name
                ids.ADMIN, 1, 11, 
                0x01, # we don't care about reward token address here
                ids.BOARDING_TOKEN_ADDRESS,
                ids.RAND_ADDRESS,
                ids.BATTLE_ADDRESS,
                # ship_count_per_battle, required_total_ship_count, grid_size, turn_count, max_dust
                2, 2, 10, 10, 8
            ]).contract_address
        %}

        let deployed_contracts = DeployedContracts(
            tournament_address=tournament_contract_address,
            other_address=Mocks(
            only_dust_token_address=0x01,
            boarding_pass_token_address=BOARDING_TOKEN_ADDRESS,
            rand_address=RAND_ADDRESS,
            battle_address=BATTLE_ADDRESS
            ),
        );
        return (deployed_contracts,);
    }
}
