%lang starknet

from contracts.account.account import account

@external
func test_mint_account{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    account.mint()
    
    return ()
end