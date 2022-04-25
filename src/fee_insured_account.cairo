%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from openzeppelin.account.library import (
    AccountCallArray,
    Account_execute,
    Account_get_nonce,
    Account_initializer,
    Account_get_public_key,
    Account_set_public_key,
    Account_is_valid_signature,
)

from openzeppelin.introspection.ERC165 import ERC165_supports_interface

@storage_var
func tx_fee_price_insured() -> (amount : felt):
end

@storage_var
func num_insured_transactions_left() -> (num : felt):
end

@storage_var
func total_num_insured_transactions() -> (amount : felt):
end

@storage_var
func insurer_address() -> (address : felt):
end

@storage_var
func insurance_premium() -> (premium : felt):
end

#
# Getters
#

@view
func get_tx_fee_price_insured{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (amount : felt):
    let (tx_fee) = tx_fee_price_insured.read()
    return (tx_fee)
end

@view
func get_total_num_insured_transactions{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (amount : felt):
    let (amount) = total_num_insured_transactions.read()
    return (amount)
end

@view
func get_num_insured_transactions_left{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (num : felt):
    let (num) = num_insured_transactions_left.read()
    return (num)
end

@view
func get_insurer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (address) = insurer.read()
    return (address)
end

@view
func get_premium{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    premium : felt
):
    let (_premium) = insurance_premium.read()
    return (_premium)
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
    public_key : felt, insurer : felt
):
    Account_initializer(public_key)
    insurer_address.write(insurer)
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
    alloc_locals
    let (local response_len, local response) = Account_execute(
        call_array_len, call_array, calldata_len, calldata, nonce
    )

    update_transaction_insurance_status()

    return (response_len=response_len, response=response)
end

#
# Internal functions
#

func update_transaction_insurance_status{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    let (num_tx_left) = get_num_insured_transactions_left()
    let (num_insured_transactions) = get_total_num_insured_transactions()

    local new_num_insured_tx_left = num_insured_transactions - num_tx_left - 1
    num_insured_transactions_left.write(new_num_insured_tx_left)

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if new_num_insured_tx_left == 0:
        settle_with_insurer()
    end
    return ()
end

@contract_interface
namespace IInsurer:
    func settle_with_insured(
        insured_address : felt, tx_fee_price_insured : felt, num_tx_insured : felt
    ):
    end
end

func settle_with_insurer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (tx_fee_price_insured) = get_tx_fee_price_insured()
    let (num_tx_insured) = get_total_num_insured_transactions()
    let (insurer_address) = get_insurer()
    let (this_account_address) = get_contract_address()
    IInsurer.settle_with_insured(
        contract_address=insurer_address,
        insured_address=this_account_address,
        tx_fee_price_insured=tx_fee_price_insured,
        num_tx_insured=num_tx_insured,
    )
    # TODO: check balances add up
    reset_num_insured_transactions_left()
    return ()
end

func reset_num_insured_transactions_left{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    num_insured_transactions_left.write(0)
    return ()
end
