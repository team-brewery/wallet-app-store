# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.1.0 (account/Account.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from openzeppelin.account.library import (
    AccountCallArray,
    Account_execute,
    Account_get_nonce,
    Account_initializer,
    # Account_get_public_key,
    # Account_set_public_key,
    Account_is_valid_signature
)

from starkware.cairo.common.alloc import alloc
from openzeppelin.introspection.ERC165 import ERC165_supports_interface 

#########################
##### STORAGE VARS ######
#########################

@storage_var
func MultiSignatureAccount_public_keys(index : felt) -> (public_key : felt):
end

@storage_var
func MultiSignatureAccount_public_keys_index() -> (index : felt):
end

@storage_var
func MultiSignatureAccount_threshold() -> (threshold : felt):
end


#########################
######## GETTERS ########
#########################

@view
func get_public_keys{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt, res: felt*):
    let (res_len, res) = MultiSignatureAccount_public_keys()
    return (res_len, res)
end

@view
func get_nonce{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res) = Account_get_nonce()
    return (res=res)
end

@view
func supportsInterface{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (interfaceId: felt) -> (success: felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func MultiSignatureAccount_get_public_keys_length{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (public_keys_len: felt):
    let (index) = MultiSignatureAccount_public_keys_index.read()
    return (public_keys_len=index)
end

@view
func MultiSignatureAccount_get_public_keys{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (public_keys_len: felt, public_keys_len : felt*):
    alloc_locals

    let public_keys : felt* = alloc()

    # Get the length of public keys
    let (index) = MultiSignatureAccount_get_public_keys_length()

    # Get public key by index
    let (public_key) = MultiSignatureAccount_public_keys.read(index)
    assert [public_keys] = public_key

    # if no more keys
    if index == 0:
        return (public_keys_len=0, public_keys_len=0)
    end

    # parse the remaining public keys recursively
    MultiSignatureAccount_get_public_keys()
    return (public_keys_len=index, public_keys)
end

#########################
######## SETTERS ########
#########################

@external
func add_public_key{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(public_key: felt, _threshold : felt):
    Account_set_public_key(public_key)

    return ()
end

@external
func set_public_key{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(new_public_key: felt):
    Account_set_public_key(new_public_key)
    return ()
end

#########################
###### CONSTRUCTOR ######
#########################

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(public_key: felt):
    Account_initializer(public_key)
    return ()
end

#########################
#### BUSINESS LOGIC #####
#########################

@view
func is_valid_signature{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
        ecdsa_ptr: SignatureBuiltin*
    }(
        hash: felt,
        signature_len: felt,
        signature: felt*
    ) -> ():
    Account_is_valid_signature(hash, signature_len, signature)
    return ()
end

@external
func __execute__{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
        ecdsa_ptr: SignatureBuiltin*
    }(
        call_array_len: felt,
        call_array: AccountCallArray*,
        calldata_len: felt,
        calldata: felt*,
        nonce: felt
    ) -> (response_len: felt, response: felt*):
    let (response_len, response) = Account_execute(
        call_array_len,
        call_array,
        calldata_len,
        calldata,
        nonce
    )
    return (response_len=response_len, response=response)
end


# Adds the public key to MultiSignatureAccount_public_keys and increases the threshold
func MultiSignatureAccount_add_public_key{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        public_key: felt,
        threshold: felt
    ):
    let (public_keys_len : felt, public_keys : felt*) = MultiSignatureAccount_public_keys.read()
    # Add public key to array
    assert [public_keys] = public_key 
    # Increase public key length
    MultiSignatureAccount_public_keys.write(public_key, public_keys_len + 1)
    # Update threshold
    MultiSignatureAccount_threshold.write(threshold)
    return ()
end

# Adds the public key to MultiSignatureAccount_public_keys and increases the threshold
func MultiSignatureAccount_add_public_keys{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        public_keys_len: felt,
        public_keys: felt*,
        threshold: felt
    ):
    let (public_keys_len : felt, public_keys : felt*) = MultiSignatureAccount_public_keys.read()
    # Add public keys to array
    assert [public_keys] = 
    # Increase public key length
    MultiSignatureAccount_public_keys.write(public_key, public_keys_len + 1)
    # Update threshold
    MultiSignatureAccount_threshold.write(threshold)
    return ()
end