# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.1.0 (account/Account.cairo)

%lang starknet

from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
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
const SAFE = 0
const DEGEN = 1
const FULL_DEGEN = 2

@storage_var
func security_mode(caller_adress: felt) -> (mode : felt):
end

@storage_var
func is_address_whitelisted(caller_adress: felt, address : felt) -> (bool : felt):
end

@storage_var
func is_address_blacklisted(caller_adress: felt, address : felt) -> (bool : felt):
end

@storage_var
func is_implementation_whitelisted() -> (bool :felt):
end

#
# Getters
#

@view
func get_security_mode{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    mode : felt
):
    let (_caller_address) = get_caller_address()
    let (mode) = security_mode.read(_caller_address)
    return (mode)
end

@view
func get_is_address_whitelisted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (bool : felt):
    let (_caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    if contract_address == address:
        return (TRUE)
    else:
        let (is_whitelisted) = is_address_whitelisted.read(_caller_address, address)
        return (is_whitelisted)
    end
end

@view
func get_is_address_blacklisted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (bool : felt):
    let (_caller_address) = get_caller_address()
    let (is_blacklisted) = is_address_blacklisted.read(_caller_address, address)
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

@external
func set_security_mode{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    mode : felt
):
    let (_caller_address) = get_caller_address()
    security_mode.write(_caller_address, mode)
    return ()
end

@external
func modify_whitelist_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_to_whitelist : felt, bool : felt
):
    let (_caller_address) = get_caller_address()
    is_address_whitelisted.write(_caller_address, address_to_whitelist, bool)
    return ()
end

@external
func modify_blacklist_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_to_blacklist : felt, bool : felt
):
    let (_caller_address) = get_caller_address()
    is_address_blacklisted.write(_caller_address, address_to_blacklist, TRUE)
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
    public_key : felt, mode : felt
):
    Account_initializer(public_key)

    # We need to whitelist this contract so it can be called by account contracts
    let (contract_address) = get_contract_address()
    modify_whitelist_status(contract_address, TRUE)
    _set_security_mode(mode) # SAFE MODE default
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
func set_whitelist_implementation{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, ecdsa_ptr : SignatureBuiltin*
    }(address: felt):
    let(has_been_initialized) = is_implementation_whitelisted.read()
    with_attr error_message("IMPLEMENTATION HAS BEEN WHITELISTED"):
        assert has_been_initialized = FALSE
    end
    modify_whitelist_status(address, TRUE)
    is_implementation_whitelisted.write(1)
    return()
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

    let selector = [calls].selector

    # emergency_override
    if selector == 1205090328239986150179692412881459612163409910210950210957524523286026684471:
        let (response_len, response) = Account_execute(
                call_array_len, call_array,
                calldata_len,
                calldata,
                nonce
            )
        return (response_len=response_len, response=response)
    end

    let (security_mode) = get_security_mode()
    let (__fp__, _) = get_fp_and_pc()

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if security_mode == SAFE:
        check_if_call_array_is_all_whitelisted(calls_len, calls)
        check_if_call_array_has_some_blacklisted(calls_len, calls)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
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
    end

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

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
    with_attr error_message("NOT WHITELISTED"):
        assert is_whitelisted = TRUE
    end
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
    with_attr error_message("BLACKLISTED"):
        assert is_blacklisted = FALSE
    end
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

func _set_security_mode{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    mode : felt
):
    let (_caller_address) = get_caller_address()
    security_mode.write(_caller_address, mode)
    return ()
end