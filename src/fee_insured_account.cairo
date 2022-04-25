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

from contracts.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256

struct InsuranceInfo:
    member num_tx_insured : felt
    member fixed_price_pr_tx : felt
    member agreed_premium : felt
end

@contract_interface
namespace IInsurer:
    func get_current_premium() -> (premium : felt):
    end

    func settle_with_insured_user(
        insured_address : felt, insurance_info: InsuranceInfo
    ):
    end

    func get_user_to_insurance_info(user : felt) -> (info : InsuranceInfo):
    end
end

@storage_var
func num_insured_transactions_left() -> (num : felt):
end

@storage_var
func insurer_address() -> (address : felt):
end

@storage_var
func hired_insurance_premium() -> (premium : felt):
end

#
# Getters
#

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
    let (address) = insurer_address.read()
    return (address)
end

@view
func get_hired_premium{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    premium : felt
):
    let (_premium) = hired_insurance_premium.read()
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
    let (caller_address) = get_caller_address()
    let (insurer_address) = get_insurer()
    let (local insurance_info) = IInsurer.get_user_to_insurance_info(
        insurer_address, caller_address
    )
    let (num_tx_left) = get_num_insured_transactions_left()

    let num_insured_transactions = insurance_info.num_tx_insured

    local new_num_insured_tx_left = num_insured_transactions - num_tx_left - 1

    num_insured_transactions_left.write(new_num_insured_tx_left)

    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr

    if new_num_insured_tx_left == 0:
        settle_with_insurer(insurance_info)
    end
    return ()
end

func settle_with_insurer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    insurance_info : InsuranceInfo
):
    let (insurer_address) = get_insurer()
    let (this_account_address) = get_contract_address()

    IInsurer.settle_with_insured_user(
        contract_address=insurer_address,
        insured_address=this_account_address,
        insurance_info=insurance_info,
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
