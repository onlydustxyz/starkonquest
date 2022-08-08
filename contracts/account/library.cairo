# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.2.1 (token/erc721/presets/ERC721MintableBurnable.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721

struct Account:
    member nickname : felt
    member win_tournament_count : felt
    member lost_tournament_count : felt
    member won_battle_count : felt
    member lost_battle_count : felt
end

# ------------
# STORAGE VARS
# ------------

# Id of the tournament
@storage_var
func account_information_(token_id: Uint256) -> (res : felt):
end

namespace account:
    # -----
    # VIEWS
    # -----

    func supportsInterface{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(interfaceId: felt) -> (success: felt):
        let (success) = ERC165.supports_interface(interfaceId)
        return (success)
    end

    func name{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (name: felt):
        let (name) = ERC721.name()
        return (name)
    end

    func symbol{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (symbol: felt):
        let (symbol) = ERC721.symbol()
        return (symbol)
    end

    func balanceOf{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(owner: felt) -> (balance: Uint256):
        let (balance: Uint256) = ERC721.balance_of(owner)
        return (balance)
    end

    func ownerOf{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(tokenId: Uint256) -> (owner: felt):
        let (owner: felt) = ERC721.owner_of(tokenId)
        return (owner)
    end

    func getApproved{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(tokenId: Uint256) -> (approved: felt):
        let (approved: felt) = ERC721.get_approved(tokenId)
        return (approved)
    end

    func isApprovedForAll{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(owner: felt, operator: felt) -> (isApproved: felt):
        let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator)
        return (isApproved)
    end

    func tokenURI{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(tokenId: Uint256) -> (tokenURI: felt):
        let (tokenURI: felt) = ERC721.token_uri(tokenId)
        return (tokenURI)
    end

    func owner{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (owner: felt):
        let (owner: felt) = Ownable.owner()
        return (owner)
    end

    # -----------
    # CONSTRUCTOR
    # -----------

    func constructor{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(
            name: felt,
            symbol: felt,
            owner: felt
        ):
        ERC721.initializer(name, symbol)
        Ownable.initializer(owner)
        return ()
    end

    # ---------
    # EXTERNALS
    # ---------

    func approve{
            pedersen_ptr: HashBuiltin*,
            syscall_ptr: felt*,
            range_check_ptr
        }(to: felt, tokenId: Uint256):
        ERC721.approve(to, tokenId)
        return ()
    end

    func setApprovalForAll{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(operator: felt, approved: felt):
        ERC721.set_approval_for_all(operator, approved)
        return ()
    end

    func transferFrom{
            pedersen_ptr: HashBuiltin*,
            syscall_ptr: felt*,
            range_check_ptr
        }(
            from_: felt,
            to: felt,
            tokenId: Uint256
        ):
        ERC721.transfer_from(from_, to, tokenId)
        return ()
    end

    func safeTransferFrom{
            pedersen_ptr: HashBuiltin*,
            syscall_ptr: felt*,
            range_check_ptr
        }(
            from_: felt,
            to: felt,
            tokenId: Uint256,
            data_len: felt,
            data: felt*
        ):
        ERC721.safe_transfer_from(from_, to, tokenId, data_len, data)
        return ()
    end

    func mint{
            pedersen_ptr: HashBuiltin*,
            syscall_ptr: felt*,
            range_check_ptr
        }(to: felt, tokenId: Uint256):
        Ownable.assert_only_owner()
        ERC721._mint(to, tokenId)
        return ()
    end

    func burn{
            pedersen_ptr: HashBuiltin*,
            syscall_ptr: felt*,
            range_check_ptr
        }(tokenId: Uint256):
        ERC721.assert_only_token_owner(tokenId)
        ERC721._burn(tokenId)
        return ()
    end

    func setTokenURI{
            pedersen_ptr: HashBuiltin*,
            syscall_ptr: felt*,
            range_check_ptr
        }(tokenId: Uint256, tokenURI: felt):
        Ownable.assert_only_owner()
        ERC721._set_token_uri(tokenId, tokenURI)
        return ()
    end

    func transferOwnership{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(newOwner: felt):
        Ownable.transfer_ownership(newOwner)
        return ()
    end

    func renounceOwnership{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }():
        Ownable.renounce_ownership()
        return ()
    end
end