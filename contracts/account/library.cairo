// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.1.0 (token/erc721/ERC721.Mintable_Burnable.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math import assert_le

from openzeppelin.token.erc721.library import ERC721

from openzeppelin.introspection.erc165.library import ERC165

from openzeppelin.access.ownable.library import Ownable

struct Account {
    nickname: felt,
    won_tournament_count: felt,
    lost_tournament_count: felt,
    won_battle_count: felt,
    lost_battle_count: felt,
}

// ------------
// STORAGE VARS
// ------------

@storage_var
func account_information_(token_id: Uint256) -> (res: Account) {
}

// get the token associated with a given account
@storage_var
func account_id_(address: felt) -> (token_id: Uint256) {
}

@storage_var
func next_token_id_() -> (res: Uint256) {
}

namespace account {
    // -----
    // VIEWS
    // -----

    func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        interfaceId: felt
    ) -> (success: felt) {
        let (success) = ERC165.supports_interface(interfaceId);
        return (success,);
    }

    func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
        let (name) = ERC721.name();
        return (name,);
    }

    func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        symbol: felt
    ) {
        let (symbol) = ERC721.symbol();
        return (symbol,);
    }

    func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt
    ) -> (balance: Uint256) {
        let (balance: Uint256) = ERC721.balance_of(owner);
        return (balance,);
    }

    func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
    ) -> (owner: felt) {
        let (owner: felt) = ERC721.owner_of(tokenId);
        return (owner,);
    }

    func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
    ) -> (approved: felt) {
        let (approved: felt) = ERC721.get_approved(tokenId);
        return (approved,);
    }

    func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, operator: felt
    ) -> (isApproved: felt) {
        let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
        return (isApproved,);
    }

    func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tokenId: Uint256
    ) -> (tokenURI: felt) {
        let (tokenURI: felt) = ERC721.token_uri(tokenId);
        return (tokenURI,);
    }

    func account_information{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) -> (account: Account) {
        let (token_id: Uint256) = account_id_.read(address);
        let (account: Account) = account_information_.read(token_id);
        return (account,);
    }

    //
    // Constructor
    //

    func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        name: felt, symbol: felt, owner: felt
    ) {
        ERC721.initializer(name, symbol);
        Ownable.initializer(owner);
        return ();
    }

    //
    // Externals
    //

    func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        to: felt, tokenId: Uint256
    ) {
        ERC721.approve(to, tokenId);
        return ();
    }

    func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        operator: felt, approved: felt
    ) {
        ERC721.set_approval_for_all(operator, approved);
        return ();
    }

    func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        from_: felt, to: felt, tokenId: Uint256
    ) {
        with_attr error_message("Account: transferring account is disabled") {
            assert 1 = 0;
        }
        return ();
    }

    func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
    ) {
        ERC721.safe_transfer_from(from_, to, tokenId, data_len, data);
        return ();
    }

    func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        tokenId: Uint256, tokenURI: felt
    ) {
        Ownable.assert_only_owner();
        ERC721._set_token_uri(tokenId, tokenURI);
        return ();
    }

    func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        to: felt, nickname: felt
    ) {
        alloc_locals;

        // we check if the address already has an account
        let (balance) = balanceOf(to);

        with_attr error_message("Account: This address already has an associated account") {
            assert_le(balance.low, 0);
            assert_le(balance.high, 0);
        }

        let (next_token_id) = next_token_id_.read();
        ERC721._mint(to, next_token_id);

        let account: Account = Account(nickname, 0, 0, 0, 0);
        account_information_.write(next_token_id, account);
        account_id_.write(to, next_token_id);

        let (incremented_token_id, _) = uint256_add(next_token_id, Uint256(1, 0));
        next_token_id_.write(incremented_token_id);

        return ();
    }

    func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
        ERC721.assert_only_token_owner(tokenId);
        ERC721._burn(tokenId);
        return ();
    }

    func incrementWonTournamentCount{
        pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
    }(address: felt) {
        let (token_id: Uint256) = account_id_.read(address);
        let (a: Account) = account_information_.read(token_id);
        let new_account: Account = Account(
            a.nickname,
            a.won_tournament_count + 1,
            a.lost_tournament_count,
            a.won_battle_count,
            a.lost_battle_count,
        );
        account_information_.write(token_id, new_account);
        return ();
    }

    func incrementLostTournamentCount{
        pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
    }(address: felt) {
        let (token_id: Uint256) = account_id_.read(address);
        let (a: Account) = account_information_.read(token_id);
        let new_account: Account = Account(
            a.nickname,
            a.won_tournament_count,
            a.lost_tournament_count + 1,
            a.won_battle_count,
            a.lost_battle_count,
        );
        account_information_.write(token_id, new_account);
        return ();
    }

    func incrementWonBattleCount{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        address: felt
    ) {
        let (token_id: Uint256) = account_id_.read(address);
        let (a: Account) = account_information_.read(token_id);
        let new_account: Account = Account(
            a.nickname,
            a.won_tournament_count,
            a.lost_tournament_count,
            a.won_battle_count + 1,
            a.lost_battle_count,
        );
        account_information_.write(token_id, new_account);
        return ();
    }

    func incrementLostBattleCount{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        address: felt
    ) {
        let (token_id: Uint256) = account_id_.read(address);
        let (a: Account) = account_information_.read(token_id);
        let new_account: Account = Account(
            a.nickname,
            a.won_tournament_count,
            a.lost_tournament_count,
            a.won_battle_count,
            a.lost_battle_count + 1,
        );
        account_information_.write(token_id, new_account);
        return ();
    }
}
