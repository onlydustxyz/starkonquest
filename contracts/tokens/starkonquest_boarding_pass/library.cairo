// SPDX-License-Identifier: Apache-2.0

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.access.ownable.library import Ownable

namespace StarkonquestBoardingPass {
    // -----------
    // CONSTRUCTOR
    // -----------

    func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        name: felt, symbol: felt, owner: felt
    ) {
        ERC721.initializer(name, symbol);
        Ownable.initializer(owner);
        return ();
    }

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

    // ---------
    // EXTERNALS
    // ---------

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
        ERC721.transfer_from(from_, to, tokenId);
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
        to: felt, tokenId: Uint256
    ) {
        Ownable.assert_only_owner();
        ERC721._mint(to, tokenId);
        return ();
    }

    func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
        ERC721.assert_only_token_owner(tokenId);
        ERC721._burn(tokenId);
        return ();
    }
}
