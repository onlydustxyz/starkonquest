%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from contracts.account.account import (
    Account,
    mint,
    account_information,
)

@external
func test_mint_account{syscall_ptr : felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}():
    alloc_locals

    mint(0x123, 0x321)
    mint(0x124, 0x432)

    let (account1: Account) = account_information(Uint256(0, 0))
    let (account2: Account) = account_information(Uint256(1, 0))
    
    assert 0x321 = account1.nickname
    assert 0 = account1.won_tournament_count
    assert 0 = account1.lost_tournament_count
    assert 0 = account1.won_battle_count
    assert 0 = account1.lost_battle_count
    assert 0x432 = account2.nickname
    assert 0 = account2.won_tournament_count
    assert 0 = account2.lost_tournament_count
    assert 0 = account2.won_battle_count
    assert 0 = account2.lost_battle_count
    
    return ()
end