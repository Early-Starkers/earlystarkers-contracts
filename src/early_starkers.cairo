# SPDX-License-Identifier: MIT
## @title Early Starkers
## @author zetsub0ii.eth

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import (
    get_caller_address, get_contract_address)

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20 

from src.merkle import merkle_verify

const MAX_SUPPLY  = 1234
const TEAM_SUPPLY = 34
const MAX_WL_MINT = 1
const MAX_PUBLIC_MINT = 5
const MERKLE_ROOT = 0xdeafbeef # TODO: Update
const ETH_ADDRESS = 0xdeadbeef # TODO: Update

## @notice Stores last minted ID
@storage_var
func _last_id() -> (id: felt):
end

## @notice Holds names for each token, has to be <32 characters
@storage_var
func _names(id: Uint256) -> (name: felt):
end

## @dev As there's no direct way to store strings longer than 32 chars,
##      we store them in a (offset -> str) mapping and have an another mapping
##      for the lengths

## @notice Storage for links
@storage_var
func _links(id: Uint256, offset: felt) -> (short_str: felt):
end

## @notice Stores links lengths
@storage_var
func _link_lens(id: Uint256) -> (short_str: felt):
end

## @notice Price to change name
@storage_var
func _name_price() -> (price: felt):
end

## @notice Stores if whitelist sales are active
@storage_var
func _wl_mint_active() -> (active: felt):
end

## @notice Whitelist mint fee
@storage_var
func _wl_mint_fee() -> (fee: felt):
end

## @notice Whitelist mint amount per user
@storage_var
func _wl_mints(account: felt) -> (mints: felt):
end

## @notice Stores if public mints are active
@storage_var
func _public_mint_active() -> (active: felt):
end

## @notice Public mint fee
@storage_var
func _public_mint_fee() -> (fee: felt):
end

## @notice Public mint amount per user
@storage_var
func _public_mints(account: felt) -> (mints: felt):
end

## @param owner: Contract owner
## @param team_receiver: The address that'll receive the team tokens
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt, team_receiver: felt):
    ERC721.initializer('Early Starkers', 'ESTARK')
    Ownable.initializer(owner)

    # Mint team supply
    tempvar end_id: felt = TEAM_SUPPLY
    _mint{
        receiver=team_receiver, 
        end_id=end_id
    }(0)
    _last_id.write(TEAM_SUPPLY)
    return ()
end

## Getters
################################################################################

# ERC721 View Functions

@view
func supportsInterface{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(interfaceId: felt) -> (success: felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (name: felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (symbol: felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt) -> (balance: Uint256):
    let (balance) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: Uint256) -> (owner: felt):
    let (owner) = ERC721.owner_of(token_id)
    return (owner)
end

@view
func getApproved{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: Uint256) -> (approved: felt):
    let (approved) = ERC721.get_approved(token_id)
    return (approved)
end

@view
func isApprovedForAll{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved) = ERC721.is_approved_for_all(owner, operator)
    return (isApproved)
end

@view
func tokenURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256) -> (tokenURI: felt):
    let (tokenURI) = ERC721.token_uri(tokenId)
    return (tokenURI)
end

# Early Starkers View Functions

@view
func get_name_price{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (name_price: felt):
    let (name_price: felt) = _name_price.read()
    return (name_price=name_price)
end

@view
func get_wl_mint_active{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (wl_mint_active: felt):
    let (wl_mint_active: felt) = _wl_mint_active.read()
    return (wl_mint_active=wl_mint_active)
end

@view
func get_wl_mint_fee{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (wl_mint_fee: felt):
    let (wl_mint_fee: felt) = _wl_mint_fee.read()
    return (wl_mint_fee=wl_mint_fee)
end

@view
func get_wl_mints{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(account: felt) -> (mints: felt):
    let (mints: felt) = _wl_mints.read(account)
    return (mints=mints)
end

@view
func get_public_mint_active{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (public_mint_active: felt):
    let (public_mint_active: felt) = _public_mint_active.read()
    return (public_mint_active=public_mint_active)
end

@view
func get_public_mint_fee{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (public_mint_fee):
    let (public_mint_fee: felt) = _public_mint_fee.read()
    return (public_mint_fee=public_mint_fee)
end

@view
func get_public_mints{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(account: felt) -> (mints: felt):
    let (mints: felt) = _public_mints.read(account)
    return (mints=mints)
end

@view
func name_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(id: Uint256) -> (name: felt):
    let (token_name: felt) = _names.read(id=id)
    return (name=token_name)
end

@view
func links_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(id: Uint256) -> (links_len: felt, links: felt*):
    alloc_locals
    let (links: felt*) = alloc()
    let (local max_len: felt) = _link_lens.read(id)

    # Start from idx 0 and fill the links
    _read_links{id=id, links_len=max_len, links=links}(0)
    
    return (links_len=max_len, links=links)
end

func _read_links{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    id: Uint256,
    links_len: felt,
    links: felt*,
}(idx: felt):
    if idx == links_len:
        return ()
    end
    
    let (next_short_str: felt) = _links.read(id, idx)
    assert [links + idx] = next_short_str

    _read_links(idx+1)

    return ()
end

## External
################################################################################

# ERC721 functions

@external
func approve{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(to: felt, tokenId: Uint256):
    ERC721.approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(operator: felt, approved: felt):
    ERC721.set_approval_for_all(operator, approved)
    return ()
end

@external
func transferFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(from_: felt, to: felt, tokenId: Uint256):
    ERC721.transfer_from(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*):
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data)
    return ()
end

## Minting
################################################################################

## @notice Mints a token in whitelist period
## @param amount:   Amount of tokens to mint, must be <= MAX_WL_MINT
## @param leaf:     Leaf of the user in merkle tree
## @param proof[]:  Merkle proof
@external
func wl_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    amount: felt,
    leaf: felt,
    proof_len: felt,
    proof: felt*
):
    alloc_locals
    let (local caller: felt) = get_caller_address()
    let (local this_address: felt) = get_contract_address()

    # Check for whitelist period
    with_attr error_message("Whitelist period not active"):
        let (wl_active: felt) = _wl_mint_active.read()
        assert wl_active = TRUE
    end

    # Check for merkle proof
    with_attr error_message("Invalid proof"):
        let (proof_valid: felt) = merkle_verify(
            leaf, MERKLE_ROOT, proof_len, proof)
        assert proof_valid = TRUE
    end

    # Check for maximum whitelist mint per user
    let (prev_mints: felt) = _wl_mints.read(caller)
    with_attr error_message("Amount exceeds max whitelist mint amount"):
        assert_le(prev_mints+amount, MAX_WL_MINT)
    end
    _wl_mints.write(caller, prev_mints+amount)

    # Check for max supply
    let (last_id: felt) = _last_id.read()
    with_attr error_message("Amount exceeds max supply"):
        assert_le(last_id + amount, MAX_SUPPLY)
    end
    
    # Take mint fee
    let (mint_fee: felt) = _wl_mint_fee.read()
    IERC20.transferFrom(
        contract_address=ETH_ADDRESS,
        sender=caller,
        recipient=this_address,
        amount=Uint256(mint_fee*amount, 0)
    )
    
    tempvar end_id: felt = last_id + amount
    _mint{
        receiver=caller,
        end_id=end_id
    }(last_id)

    # Update supply
    _last_id.write(end_id)
    return()
end

## @notice Mints token in public mint period
## @param amount: Amount of tokens, must be <= MAX_PUBLIC_MINT
@external
func public_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    amount: felt
):
    alloc_locals
    let (local caller: felt) = get_caller_address()
    let (local this_address: felt) = get_contract_address()

    # Check for whitelist period
    with_attr error_message("Public mint period not active"):
        let (wl_active: felt) = _public_mint_active.read()
        assert wl_active = TRUE
    end

    # Check for maximum public mint per user
    let (prev_mints: felt) = _public_mints.read(caller)
    with_attr error_message("Amount exceeds max public mint amount"):
        assert_le(prev_mints+amount, MAX_PUBLIC_MINT)
    end
    _public_mints.write(caller, prev_mints+amount)

    # Check for max supply
    let (last_id: felt) = _last_id.read()
    with_attr error_message("Amount exceeds max supply"):
        assert_le(last_id + amount, MAX_SUPPLY)
    end
    
    # Take mint fee
    let (mint_fee: felt) = _public_mint_fee.read()
    IERC20.transferFrom(
        contract_address=ETH_ADDRESS,
        sender=caller,
        recipient=this_address,
        amount=Uint256(mint_fee*amount, 0)
    )
    
    tempvar end_id: felt = last_id + amount
    _mint{
        receiver=caller,
        end_id=end_id
    }(last_id)

    # Update supply
    _last_id.write(end_id)
    return()
end

## @notice Changes name of the token
## @param id: ID of the token
## @param new_name: New name, must be shorter than 32 characters
@external
func change_name{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(id: Uint256, new_name: felt):
    alloc_locals
    let (local caller: felt) = get_caller_address()
    let (local this_address: felt) = get_contract_address()

    let (owner_of_id: felt) = ERC721.owner_of(id)
    with_attr error_message("Not the owner of token"):
        assert owner_of_id = caller
    end

    let (prev_name: felt) = _names.read(id)
    with_attr error_message("Names can only be changed once"):
        assert prev_name = 0
    end

    # Get changing name price
    let (name_price: felt) = _name_price.read()
    IERC20.transferFrom(
        contract_address=ETH_ADDRESS,
        sender=caller,
        recipient=this_address,
        amount=Uint256(name_price, 0)
    )

    _names.write(id, new_name)
    return ()
end

## @notice Changes links associated with the token
## @param id: ID of the token
## @param new_links[]: List of short strings that includes links
## @dev new_links must be split on the frontend, best way would be to use
##      the website
@external
func change_links{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(id: Uint256, new_links_len: felt, new_links: felt*):
    let (caller: felt) = get_caller_address()

    let (owner_of_id: felt) = ERC721.owner_of(id)
    with_attr error_message("Not the owner of token"):
        assert owner_of_id = caller
    end

    _write_links{id=id, links_len=new_links_len, links=new_links}(0)
    _link_lens.write(id, new_links_len)

    return ()
end

func _write_links{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    id: Uint256,
    links_len: felt,
    links: felt*
}(idx: felt):
    if idx == links_len:
        return ()
    end

    _links.write(id, idx, links[idx]) 

    return _write_links(idx+1)
end

## Owner Functions
################################################################################

## @notice Start whitelist minting 
## @dev onlyOwner
@external
func start_wl_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(start_fee: felt): 
    Ownable.assert_only_owner()

    _wl_mint_fee.write(start_fee)
    _wl_mint_active.write(TRUE)
    return()
end

## @notice Changes whitelist mint price
## @dev onlyOwner
@external
func change_wl_mint_price{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_fee: felt): 
    Ownable.assert_only_owner()

    _wl_mint_fee.write(new_fee)
    return()
end

## @notice Stops whitelist minting 
## @dev onlyOwner
@external
func stop_wl_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    Ownable.assert_only_owner()

    _wl_mint_active.write(FALSE)
    return()
end

## @notice Starts public minting 
## @dev onlyOwner
@external
func start_public_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(start_fee: felt): 
    Ownable.assert_only_owner()

    _public_mint_fee.write(start_fee)
    _public_mint_active.write(TRUE)
    return()
end

## @notice Changes public minting price 
## @dev onlyOwner
@external
func change_public_mint_price{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_fee: felt): 
    Ownable.assert_only_owner()

    _public_mint_fee.write(new_fee)
    return()
end

## @notice Stops public minting 
## @dev onlyOwner
@external
func stop_public_mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    Ownable.assert_only_owner()

    _public_mint_active.write(FALSE)
    return()
end

## @notice Changes price to change name 
## @dev onlyOwner
@external
func change_name_price{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(price: felt):
    Ownable.assert_only_owner()

    _name_price.write(price) 
    return()
end

## @notice Function for team to withdraw funds
## @dev onlyOwner
@external
func withdraw{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    alloc_locals
    Ownable.assert_only_owner()

    let (local this_address: felt) = get_contract_address()
    let (local caller_address: felt) = get_caller_address()
    let (balance: Uint256) = IERC20.balanceOf(
        contract_address=ETH_ADDRESS,
        account=this_address)

    with_attr error_message("Transfer failed"):
        let (success: felt) = IERC20.transfer(
            contract_address=ETH_ADDRESS,
            recipient=caller_address,
            amount=balance)
        assert success = 1
    end

    return ()
end


## Helpers
################################################################################

## @dev Mints tokens between [start_id, end_id) 
func _mint{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    receiver,
    end_id
}(start_id):
    if start_id == end_id:
        return ()
    end

    let next_id: Uint256 = Uint256(start_id, 0)
    let empty_data: felt* = alloc()
    ERC721._safe_mint(receiver, next_id, 0, empty_data) 

    return _mint(start_id + 1)
end

