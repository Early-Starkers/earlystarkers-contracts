%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

const owner = 0x6f776e6572
const team = 0x7465616d
const user_1 = 0x5553455231
const user_2 = 0x5553455232

const base_start_fee = 100000000 # 10**8

# @external
# func __setup__{
#     syscall_ptr: felt*,
#     pedersen_ptr: HashBuiltin*,
#     range_check_ptr: felt
# }():
#     %{ 
#         context.owner = 0x6f776e6572
#         context.team = 0x7465616d
#         context.user_1 = 0x5553455231
#         context.user_2 = 0x5553455232

#         context.es_addr = deploy_contract(
#             "./src/early_starkers.cairo",
#             {
#                 "owner": context.owner,
#                 "team_receiver": context.team 
#             }
#         ).contract_address 

#         context.eth = deploy_contract(
#             "./lib/cairo-contracts/src/openzeppelin/token/erc20/presets/ERC20Mintable.cairo",
#             {
#                 "name": "T",
#                 "symbol": "T",
#                 "decimals": 18,
#                 "initial_supply": 100000 * 10**18,
#                 "recipient": context.user_1,
#                 "owner": context.owner,
#             }
#         ).contract_address

#         print(context.es_addr, context.eth)
#     %}
#     return ()
# end

@external
func test_cant_mint_before{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr: felt
}():
    alloc_locals
    local early_starkers: felt
    local eth: felt

    %{ 
        context.owner = 0x6f776e6572
        context.team = 0x7465616d
        context.user_1 = 0x5553455231
        context.user_2 = 0x5553455232

        context.early_starkers = deploy_contract(
            "./src/early_starkers.cairo",
            {
                "owner": context.owner,
                "team_receiver": context.team 
            }
        ).contract_address 

        context.eth = deploy_contract(
            "./lib/cairo-contracts/src/openzeppelin/token/erc20/presets/ERC20Mintable.cairo",
            {
                "name": "T",
                "symbol": "T",
                "decimals": 18,
                "initial_supply": 100000 * 10**18,
                "recipient": context.user_1,
                "owner": context.owner,
            }
        ).contract_address

        ids.eth = context.eth
        ids.early_starkers = context.early_starkers
    %}

    %{ stop_prank = start_prank(context.owner, context.early_starkers) %}
    EarlyStarkers.__t_set_eth_addr(
        contract_address=early_starkers,
        addr=eth 
    ) 
    %{ stop_prank() %}

    %{
        stop_prank = start_prank(context.user_1, context.early_starkers)
        expect_revert("TRANSACTION_FAILED", "Public mint period not active")
    %}
    EarlyStarkers.public_mint(
        contract_address=early_starkers,
        amount=1
    )
    %{ stop_prank() %}

    %{ stop_prank = start_prank(context.owner, context.early_starkers) %}
    EarlyStarkers.start_public_mint(
        contract_address=early_starkers,
        start_fee=base_start_fee
    ) 
    %{ stop_prank() %}

    %{
        stop_prank = start_prank(context.user_1, context.early_starkers)
    %}
    EarlyStarkers.public_mint(
        contract_address=early_starkers,
        amount=1
    )
    %{ stop_prank() %}


    return ()
end

@contract_interface
namespace EarlyStarkers:
    func public_mint(amount: felt):
    end

    func start_public_mint(start_fee: felt): 
    end

    func __t_set_eth_addr(addr: felt):
    end

    func __t_owner() -> (o: felt):
    end
end
