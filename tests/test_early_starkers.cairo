%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

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