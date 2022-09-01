# SPDX-License-Identifier: MIT
## @title Early Starkers
## @author zetsub0ii.eth
## @author hikmo

%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256, uint256_unsigned_div_rem, uint256_mul, uint256_le, uint256_check) 
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import (
    assert_nn_le, assert_not_zero, unsigned_div_rem)
from starkware.starknet.common.syscalls import (
    get_caller_address, get_contract_address)

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20 

from src.merkle import merkle_verify

const ERC2981_ID = 0x2a55205a
const MAX_SUPPLY  = 1234
const TEAM_SUPPLY = 34
const MAX_WL_MINT = 1
const MAX_PUBLIC_MINT = 1
const TOTAL_WL_AMOUNT = 200
const START_ID = 1

################################ TESTNET CONFIG ################################

const ETH_ADDRESS = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7 

################################ TESTNET CONFIG ################################

@storage_var
func _base_uri() -> (base_uri : felt):
end


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

@storage_var
func _strings(tag: felt, id: felt, offset: felt) -> (short_str: felt):
end

@storage_var
func _string_lens(tag: felt, id: felt) -> (length: felt):
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

## @notice Total whitelisted mints
@storage_var
func _total_wl_mints() -> (mints: felt):
end

## @notice Stores whitelist root
@storage_var
func _wl_root() -> (root: felt):
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

## @notice Owner royalty
@storage_var
func _owner_royalty() -> (royalty):
end

## @notice Is burning active
@storage_var
func _is_burn_active() -> (res : felt):
end

## @notice Is burning active
@storage_var
func _is_naming_active() -> (res : felt):
end

## Constructor
################################################################################

## @param owner: Contract owner
## @param team_receiver: The address that'll receive the team tokens
@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(owner: felt, team_receiver: felt, base_uri: felt):
    ERC721.initializer('Early Starkers', 'ESTARK')
    ERC165.register_interface(ERC2981_ID)
    Ownable.initializer(owner)

    _base_uri.write(base_uri)

    # Mint team supply
    tempvar end_id: felt = TEAM_SUPPLY + START_ID
    _mint{
        receiver=team_receiver, 
        end_id=end_id
    }(START_ID)
    _last_id.write(TEAM_SUPPLY + START_ID)
    return ()
end

## Events
################################################################################

@event
func minted(
    tokenId: Uint256, address: felt):
end

@event
func named(
    tokenId: Uint256, name: felt):
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
func baseURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (baseURI: felt):
    let (base_uri: felt) = _base_uri.read()
    return (baseURI=base_uri)
end

@view
func tokenURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(tokenId: Uint256) -> (tokenURI: felt):
    let (caller) = get_caller_address()
    let (name) = _names.read(tokenId)

    if name == 0:
        let (tokenURI_no_name) = _tokenURI(tokenId.low)
        return (tokenURI_no_name)
    else:
        let (tokenURI_name) = _tokenURI(1234 + tokenId.low)
        return (tokenURI_name)
    end
end

func _tokenURI{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(token_id: felt) -> (uri: felt):
    let (base_uri: felt) = _base_uri.read()
    # Offset base_uri like 'my_base_uri.com/00000000'
    let base_uri_ext: felt = base_uri * 2**32

    # if ID is 1234
    let (t_div_1000, t_rem_1000) = unsigned_div_rem(token_id, 1000)
    # 1 234
    let (t_div_100, t_rem_100) = unsigned_div_rem(token_id, 100)
    # 12 34
    let (t_div_10, t_rem_10) = unsigned_div_rem(token_id, 10)
    # 123 4

    const ZERO_ASCII = 48
    let d1 = ZERO_ASCII + t_div_1000
    let d2 = ZERO_ASCII + (t_div_100 - t_div_1000 * 10) 
    let d3 = ZERO_ASCII + (t_div_10 - t_div_100 * 10) 
    let d4 = ZERO_ASCII + t_rem_10

    # It should look like 'my_base_uri.com/d1d2d3d4' at the end
    let uri = base_uri_ext + d4 + d3*2**8 + d2*2**16 + d1*2**24
    return(uri=uri)
end

# Early Starkers View Functions

@view
func get_wl_root{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (wl_root: felt):
    let (wl_root: felt) = _wl_root.read()
    return (wl_root=wl_root)
end

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
func star_wall_links_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(id: Uint256) -> (links_len: felt, links: felt*):
    let (links_len: felt, links: felt*) = _read_string('star_wall', id)
    return (links_len, links)
end

@view
func galactic_talks_links_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(id: Uint256) -> (links_len: felt, links: felt*):
    let (links_len: felt, links: felt*) = _read_string('galactic_talks', id)    
    return (links_len, links)
end

@view
func get_last_id{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (last_id: felt):
    let (last_id: felt) = _last_id.read()
    return(last_id)
end

# ERC2981: NFT Royalties

## @notice Returns royalty info
## @dev Royalty is owner_royalty% of the salePrice to the owner
@view
func royaltyInfo{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(
    _tokenId: Uint256,
    salePrice: Uint256
) -> (
    receiver: felt,
    royaltyAmount: Uint256
):
    alloc_locals
    let (owner: felt) = Ownable.owner()
    let (owner_royalty: felt) = _owner_royalty.read()

    # Royalty = Sale Price * Owner Royalty / 100
    let (
        local sale_price_ext: Uint256,
        local sale_price_of: Uint256
    ) = uint256_mul(salePrice, Uint256(owner_royalty, 0))

    let (
        local royalty_amount: Uint256, 
        _rem: Uint256
    ) = uint256_unsigned_div_rem(sale_price_ext, Uint256(100, 0))

    # Multiplication mustn't overflow
    assert sale_price_of = Uint256(0,0)

    return (receiver=owner, royaltyAmount=royalty_amount)
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

    with_attr error_message("Not the right caller"):
        assert caller = leaf
    end

    # Check for whitelist period
    with_attr error_message("Whitelist period not active"):
        let (wl_active: felt) = _wl_mint_active.read()
        assert wl_active = TRUE
    end

    # Check for merkle proof
    with_attr error_message("Invalid proof"):
        let (wl_root: felt) = _wl_root.read()
        let (proof_valid: felt) = merkle_verify(
            leaf, wl_root, proof_len, proof)
        assert proof_valid = TRUE
    end

    # We're going with the safest route which is wrapping amount in Uint256
    # and using OZ SafeMath for Uint256
    let (local amount_uint256) = Uint256(amount, 0)
    uint256_check(amount_uint256)

    # Check for maximum whitelist mint per user
    let (prev_mints: felt) = _wl_mints.read(caller)
    with_attr error_message("Amount exceeds max whitelist mint amount"):
        let (user_mint_count: Uint256) = SafeUint256.add(
            Uint256(prev_mints,0), amount_uint256)

        let (le_peruser_wl) = uint256_le(
            user_mint_count, Uint256(MAX_WL_MINT, 0))
        assert le_max_wl = 1
    end
    _wl_mints.write(caller, prev_mints+amount)

    # Check for total wl amount
    let (total_wl_mints: felt) = _total_wl_mints.read()
    with_attr error_message("All NFTs that were allocated for wl period has been minted"):
        let (total_mint_count: Uint256) = SafeUint256.add(
            Uint256(total_wl_mints, 0), amount_uint256)

        let (le_total_wl) = uint256_le(
            total_mint_count, Uint256(TOTAL_WL_AMOUNT, 0))
        assert le_total_wl = 1
    end
    _total_wl_mints.write(total_wl_mints + amount)

    # Check for max supply
    let (last_id: felt) = _last_id.read()
    with_attr error_message("Amount exceeds max supply"):
        let (total_mints: Uint256) = SafeUint256.add(
            Uint256(last_id, 0), amount_uint256)
        
        let (le_total_mint) = uint256_le(
            total_mints, Uint256(MAX_SUPPLY), 0)
        assert le_total_mint = 1
    end
    
    # Take mint fee
    let (mint_fee: felt) = _wl_mint_fee.read()
    let (success: felt) = IERC20.transferFrom(
        contract_address=ETH_ADDRESS,
        sender=caller,
        recipient=this_address,
        amount=Uint256(amount * mint_fee, 0)
    )
    with_attr error_message("ERC20 transfer failed"):
        assert success = 1
    end
    
    local end_id: felt = last_id + amount

    # Update supply
    _last_id.write(end_id)

    _mint{
        receiver=caller,
        end_id=end_id
    }(last_id)

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
        let (public_active: felt) = _public_mint_active.read()
        assert public_active = TRUE
    end

    let (local amount_uint256: Uint256) = Uint256(amount, 0)
    uint256_check(amount_uint256)

    # Check for maximum public mint per user
    let (prev_mints: felt) = _public_mints.read(caller)
    with_attr error_message("Amount exceeds max public mint amount"):
        let (user_mint_count: Uint256) = SafeUint256.add(
            Uint256(prev_mints,0), amount_uint256)

        let (le_peruser_pub) = uint256_le(
            user_mint_count, Uint256(MAX_PUBLIC_MINT, 0))
        assert le_max_pub = 1
    end
    _public_mints.write(caller, prev_mints+amount)

    # Check for max supply
    let (last_id: felt) = _last_id.read()
    with_attr error_message("Amount exceeds max supply"):
        let (total_mints: Uint256) = SafeUint256.add(
            Uint256(last_id, 0), amount_uint256)
        
        let (le_total_mint) = uint256_le(
            total_mints, Uint256(MAX_SUPPLY), 0)
        assert le_total_mint = 1
    end
    
    # Take mint fee
    let (mint_fee: felt) = _public_mint_fee.read()
    let (success: felt) = IERC20.transferFrom(
        contract_address=ETH_ADDRESS,
        sender=caller,
        recipient=this_address,
        amount=Uint256(mint_fee*amount, 0)
    )
    with_attr error_message("ERC20 transfer failed"):
        assert success = 1
    end
    
    local end_id: felt = last_id + amount

    # Update supply
    _last_id.write(end_id)

    # Mint tokens
    _mint{
        receiver=caller,
        end_id=end_id
    }(last_id)
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

    with_attr error_message("Naming is not activated"):
        let (naming_active: felt) = _is_naming_active.read()
        assert naming_active = TRUE
    end

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
    let (success: felt) = IERC20.transferFrom(
        contract_address=ETH_ADDRESS,
        sender=caller,
        recipient=this_address,
        amount=Uint256(name_price, 0)
    )
    with_attr error_message("ERC20 transfer failed"):
        assert success = 1
    end

    _names.write(id, new_name)
    named.emit(tokenId=id,name=new_name)
    return ()
end

## @notice Changes links associated with the token
## @param id: ID of the token
## @param new_links[]: List of short strings that includes links
## @dev new_links must be split on the frontend, best way would be to use
##      the website
@external
func change_star_wall_links{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(id: Uint256, new_links_len: felt, new_links: felt*):
    let (caller: felt) = get_caller_address()

    let (owner_of_id: felt) = ERC721.owner_of(id)
    with_attr error_message("Not the owner of token"):
        assert owner_of_id = caller
    end

    _write_string(tag='star_wall', id=id, str_len=new_links_len, str=new_links)
    return ()
end

@external
func change_galactic_talks_links{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(id: Uint256, new_links_len: felt, new_links: felt*):
    let (caller: felt) = get_caller_address()

    let (owner_of_id: felt) = ERC721.owner_of(id)
    with_attr error_message("Not the owner of token"):
        assert owner_of_id = caller
    end

    let (prev_name: felt) = _names.read(id)
    with_attr error_message("Naming is required for galactic talks"):
        assert_not_zero(prev_name)
    end

    _write_string(tag='galactic_talks', id=id, str_len=new_links_len, str=new_links)
    return ()
end

@external
func burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
):
    with_attr error_message("Burning is not activated"):
        let (burn_active: felt) = _is_burn_active.read()
        assert burn_active = TRUE
    end
    ERC721.assert_only_token_owner(tokenId)
    ERC721._burn(tokenId)
    return ()  
end

## Owner Functions
################################################################################

@external
func set_base_uri{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_base_uri: felt):
    Ownable.assert_only_owner()
    _base_uri.write(new_base_uri)
    return ()
end

## @notice Enable burning
## @dev onlyOwner
@external
func enable_burn{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    Ownable.assert_only_owner()
    _is_burn_active.write(TRUE)
    return ()
end

@external
func enable_naming{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    Ownable.assert_only_owner()
    _is_naming_active.write(TRUE)
    return ()
end

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

## @notice Changes whitelist root
## @dev onlyOwner
@external
func change_wl_root{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_root: felt):
    Ownable.assert_only_owner()

    _wl_root.write(new_root)
    return()
end

## @notice Sets owner royalty
## @dev onlyOwner
@external
func set_owner_royalty{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(new_royalty: felt):
    Ownable.assert_only_owner()
    with_attr error_message("Royalties are in range of [0,100](%)"):
        assert_nn_le(new_royalty, 99)
    end

    _owner_royalty.write(new_royalty)
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
            recipient=team_receiver,
            amount=balance)
        assert success = 1
    end

    return ()
end


## Helpers
################################################################################

## @dev Mints tokens between [start_id, end_id) to receiver
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
    ERC721._mint(receiver, next_id) 
    minted.emit(tokenId=next_id, address=receiver)
    return _mint(start_id + 1)
end

## @dev Helper function to read a string from storage
## @dev Starting from 0, reads each offset from _strings[tag][id_low] and concats them
## @param tag:  Tag of the string (star_wall_link / galactic_talks_link / ...)
## @param id:   Token ID
func _read_string{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(tag: felt, id: Uint256) -> (str_len: felt, str: felt*):
    alloc_locals
    let (local str: felt*) = alloc()
    let (local str_len: felt) = _string_lens.read(tag, id.low)

    tempvar id_low: felt = id.low
    __read_string{
        tag=tag,
        id_low=id_low,
        str_len=str_len,
        str=str
    }(0)

    return (str_len, str)
end

## @implicit_param tag:     Tag of the string (star_wall_link / galactic_talks_link / ...)
## @implicit_param id_low:  Low part of the Uint256 id
## @implicit_param str_len: Length of the string
## @implicit_param str:     String
## @param offset:           Where to start reading (must be 0)
func __read_string{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    tag: felt,
    id_low: felt,
    str_len: felt,
    str: felt*
}(offset: felt):
    if offset == str_len:
        return ()
    end

    let (next_short_str: felt) = _strings.read(tag, id_low, offset)
    assert [str + offset] = next_short_str

    return __read_string(offset+1)
end

## @dev Helper function to write a string to the storage
## @param tag:      Tag of the string (star_wall_link / galactic_talks_link / ...)
## @param id:       Token ID 
## @param str_len:  Length of the string
## @param str:      String
func _write_string{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(tag: felt, id: Uint256, str_len: felt, str: felt*):
    tempvar id_low: felt = id.low
    __write_string{
        tag = tag,
        id_low = id_low,
        str_len = str_len,
        str = str
    }(0)

    _string_lens.write(tag, id.low, str_len)
    return()
end

## @implicit_param tag:     Tag of the string (star_wall / galactic_talks / ...)
## @implicit_param id_low:  Low part of the Uint256 id
## @implicit_param str_len: Length of the string
## @implicit_param str:     String
## @param offset:           Where to start reading (must be 0)
func __write_string{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    tag: felt,
    id_low: felt,
    str_len: felt,
    str: felt*
}(offset: felt):
    if offset == str_len:
        return ()
    end

    _strings.write(tag, id_low, offset, [str+offset])
    return __write_string(offset=offset+1)
end

## After Reset
################################################################################

@external
func airdrop_tokens{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(new_addresses_len: felt, new_addresses: felt*, start_id: felt):
    Ownable.assert_only_owner() # [start_id, start_id + new_adresses-len)
    let (last_id: felt) = _last_id.read()
    if start_id - last_id == new_addresses_len:
        _last_id.write(last_id + new_addresses_len)
        return()
    end
    let next_id: Uint256 = Uint256(start_id, 0)
    ERC721._mint([new_addresses + start_id - last_id], next_id) 
    minted.emit(tokenId=next_id, address=[new_addresses + start_id - last_id])
    return airdrop_tokens(new_addresses_len, new_addresses, start_id + 1)
end

@external
func restore_names{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(names_len: felt, names: felt*, start_id: felt):
    Ownable.assert_only_owner()
    if start_id - START_ID == names_len:
        return()
    end
    let next_id: Uint256 = Uint256(start_id, 0)
    _names.write(next_id, [names + start_id - START_ID])
    named.emit(tokenId=next_id, name=[names + start_id - START_ID])
    return restore_names(names_len, names, start_id + 1)
end
