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

    mint(0x123, 0x78122109201)
    let (account: Account) = account_information(Uint256(0, 0))
    assert 0x78122109201 = account.nickname
    
    return ()
end