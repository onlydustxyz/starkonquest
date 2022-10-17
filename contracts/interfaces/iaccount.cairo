%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.account.library import Account

@contract_interface
namespace IAccount {
    func supportsInterface(interfaceId: felt) -> (success: felt) {
    }

    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func balanceOf(owner: felt) -> (balance: Uint256) {
    }

    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }

    func getApproved(tokenId: Uint256) -> (approved: felt) {
    }

    func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt) {
    }

    func tokenURI(tokenId: Uint256) -> (tokenURI: felt) {
    }

    func account_information(address: felt) -> (account: Account) {
    }

    func approve(to: felt, tokenId: Uint256) {
    }

    func setApprovalForAll(operator: felt, approved: felt) {
    }

    func transferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }

    func safeTransferFrom(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*) {
    }

    func mint(to: felt, nickname: felt) {
    }

    func burn(tokenId: Uint256) {
    }

    func setTokenURI(tokenId: Uint256, tokenURI: felt) {
    }

    func incrementWonTournamentCount(address: felt) {
    }

    func incrementLostTournamentCount(address: felt) {
    }

    func incrementWonBattleCount(address: felt) {
    }

    func incrementLostBattleCount(address: felt) {
    }
}
