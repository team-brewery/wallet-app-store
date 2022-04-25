# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.1.0 (account/Account.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from openzeppelin.account.library import (
    AccountCallArray,
    Account_execute,
    Account_get_nonce,
    Account_initializer,
    Account_get_public_key,
    Account_set_public_key,
    Account_is_valid_signature,
    Call,
    from_call_array_to_call,
)

from openzeppelin.introspection.ERC165 import ERC165_supports_interface

const TRUE = 1
const FALSE = 0

# Wallet modes
const SAFE = 2
const DEGEN = 1
const FULL_DEGEN = 0

@storage_var
func security_mode() -> (mode : felt):
end

@storage_var
func is_address_whitelisted(address : felt) -> (bool : felt):
end

@storage_var
func is_address_blacklisted(address : felt) -> (bool : felt):
end

#
# Getters
#

@view
func get_security_mode{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    mode : felt
):
    let (mode) = security_mode.read()
    return (mode)
end

@view
func get_is_address_whitelisted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (bool : felt):
    let (is_whitelisted) = is_address_whitelisted.read(address)
    return (is_whitelisted)
end

@view
func get_is_address_blacklisted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (bool : felt):
    let (is_blacklisted) = is_address_blacklisted.read(address)
    return (is_blacklisted)
end

@view
func get_public_key{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : felt
):
    let (res) = Account_get_public_key()
    return (res=res)
end

@view
func get_nonce{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res : felt):
    let (res) = Account_get_nonce()
    return (res=res)
end

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

#
# Setters
#

# TODO: make onlyOwnable
@external
func set_security_mode{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    mode : felt
):
    security_mode.write(mode)
    return ()
end

@external
func modify_whitelist_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_to_whitelist : felt, bool : felt
):
    is_address_whitelisted.write(address_to_whitelist, bool)
    return ()
end

@external
func modify_blacklist_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_to_blacklist : felt, bool : felt
):
    is_address_blacklisted.write(address_to_blacklist, 1)
    return ()
end

@external
func set_public_key{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_public_key : felt
):
    Account_set_public_key(new_public_key)
    return ()
end

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    public_key : felt
):
    Account_initializer(public_key)
    return ()
end

#
# Business logic
#

@view
func is_valid_signature{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, ecdsa_ptr : SignatureBuiltin*
}(hash : felt, signature_len : felt, signature : felt*) -> ():
    Account_is_valid_signature(hash, signature_len, signature)
    return ()
end

@external
func __execute__{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, ecdsa_ptr : SignatureBuiltin*
}(
    call_array_len : felt,
    call_array : AccountCallArray*,
    calldata_len : felt,
    calldata : felt*,
    nonce : felt,
) -> (response_len : felt, response : felt*):
    # TMP: Convert `AccountCallArray` to 'Call'.
    alloc_locals
    let (local calls : Call*) = alloc()
    from_call_array_to_call(call_array_len, call_array, calldata, calls)
    let calls_len = call_array_len

    let (security_mode) = get_security_mode()
    let (__fp__, _) = get_fp_and_pc()

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if security_mode == SAFE:
        check_if_call_array_is_all_whitelisted(calls_len, calls)
        check_if_call_array_has_some_blacklisted(calls_len, calls)
    end
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if security_mode == DEGEN:
        check_if_call_array_has_none_blacklisted(calls_len, calls)
    end

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if security_mode == FULL_DEGEN:
        check_if_call_array_has_some_blacklisted(calls_len, calls)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    let (response_len, response) = Account_execute(
        call_array_len, call_array, calldata_len, calldata, nonce
    )
    return (response_len=response_len, response=response)
end

func check_if_call_array_is_all_whitelisted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(calls_len : felt, calls : Call*) -> (bool : felt):
    if calls_len == 0:
        return (TRUE)
    end
    let contract_address = [calls].to
    let (is_whitelisted) = get_is_address_whitelisted(contract_address)
    assert is_whitelisted = TRUE
    return check_if_call_array_is_all_whitelisted(calls_len - 1, calls + 1)
end

func check_if_call_array_has_none_blacklisted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(calls_len : felt, calls : Call*) -> (bool : felt):
    if calls_len == 0:
        return (TRUE)
    end
    let contract_address = [calls].to
    let (is_blacklisted) = get_is_address_blacklisted(contract_address)
    assert is_blacklisted = FALSE
    return check_if_call_array_has_none_blacklisted(calls_len - 1, calls + 1)
end

func check_if_call_array_has_some_blacklisted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(calls_len : felt, calls : Call*) -> (bool : felt):
    if calls_len == 0:
        return (FALSE)
    end
    let contract_address = [calls].to
    let (is_blacklisted) = get_is_address_blacklisted(contract_address)
    if is_blacklisted == TRUE:
        return (TRUE)
    end
    return check_if_call_array_has_some_blacklisted(calls_len - 1, calls + 1)
end