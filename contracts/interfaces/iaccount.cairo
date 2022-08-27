%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.account.library import Account

@contract_interface
namespace IAccount:
    
    func supportsInterface(interfaceId: felt) -> (success: felt):
    end

    func name() -> (name: felt):
    end

    func symbol() -> (symbol: felt):
    end

    func balanceOf(owner: felt) -> (balance: Uint256):
    end

    func ownerOf(tokenId: Uint256) -> (owner: felt):
    end

    func getApproved(tokenId: Uint256) -> (approved: felt):
    end

    func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt):
    end

    func tokenURI(tokenId: Uint256) -> (tokenURI: felt):
    end

    func account_information(address: felt) -> (account: Account):
    end

    func approve(to: felt, tokenId: Uint256):
    end

    func setApprovalForAll(operator: felt, approved: felt):
    end

    func transferFrom(
            from_: felt,
            to: felt,
            tokenId: Uint256
        ):
    end

    func safeTransferFrom(
            from_: felt,
            to: felt,
            tokenId: Uint256,
            data_len: felt,
            data: felt*
        ):
    end

    func mint(to: felt, nickname: felt):
    end

    func burn(tokenId: Uint256):
    end

    func setTokenURI(tokenId: Uint256, tokenURI: felt):
    end

    func incrementWonTournamentCount(address: felt):
    end

    func incrementLostTournamentCount(address: felt):
    end

    func incrementWonBattleCount(address: felt):
    end

    func incrementLostBattleCount(address: felt):
    end
end