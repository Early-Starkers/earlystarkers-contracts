%lang starknet
from src.merkle import merkle_verify 

from src.experiment import set_name, name_of
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.alloc import alloc 

@external
func test_cant_mint_before{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}():
    with_attr error_message("unimplemented"):
        assert 1 = 0
    end

    return ()
end