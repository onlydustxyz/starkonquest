%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.libraries.cell import Dust

@contract_interface
namespace IDustContract {
    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func mint(metadata: Dust) -> (token_id: Uint256) {
    }

    func mint_random_on_border(space_size: felt) -> (token_id: Uint256) {
    }

    func mint_batch(metadatas_len: felt, metadatas: Dust*) -> (
        token_id_len: felt, token_id: Uint256*
    ) {
    }

    func mint_batch_random_on_border(space_size: felt, nb_tokens: felt) -> (token_id: Uint256) {
    }

    func burn(token_id: Uint256) {
    }

    func balanceOf(owner: felt) -> (balance: Uint256) {
    }

    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }

    func safeTransferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }

    func setApprovalForAll(operator: felt, approved: felt) {
    }

    func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt) {
    }

    func metadata(token_id: Uint256) -> (metadata: Dust) {
    }

    func move(token_id: Uint256) -> (metadata: Dust) {
    }
}
