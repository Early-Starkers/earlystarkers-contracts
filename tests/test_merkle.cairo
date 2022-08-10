%lang starknet
from src.merkle import merkle_verify 
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc 

@external
func test_verify{
    syscall_ptr : felt*,
    range_check_ptr,
    pedersen_ptr : HashBuiltin*
}():
    alloc_locals
    let (local proof: felt*) = alloc()
    assert [proof] = 100
    assert [proof + 1] = 2183814239646397431695082851227829552607942615448013943574269069836880480326
    assert [proof + 2] = 1257769551700579117019971178823168494772710768113471413762010337972968695919

    let root = 483538810345755558079421941020521873215774254654424530538269918258156386391
    let leaf = 200
    let false_leaf = 500

    let (res: felt) = merkle_verify(leaf, root, 3, proof)
    assert res = 1

    let (res2: felt) = merkle_verify(false_leaf, root, 3, proof)
    assert res2 = 0

    return ()
end

# @external
# func test_cannot_increase_balance_with_negative_value{
#     syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*
# }():
#    let (result_before) = balance.read()
#    assert result_before = 0
#
#    %{ expect_revert("TRANSACTION_FAILED", "Amount must be positive") %}
#    increase_balance(-42)
#
#    return ()
# end
