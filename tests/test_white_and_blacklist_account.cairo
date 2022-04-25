%lang starknet

from openzeppelin.account.library import AccountCallArray
from starkware.cairo.common.uint256 import Uint256

const TRUE = 1
const FALSE = 0

# Wallet modes
const SAFE = 0
const DEGEN = 1
const FULL_DEGEN = 2
const account_address = 123

@contract_interface
namespace WhiteBlackListContract:

    func get_security_mode() -> (mode: felt):
    end

    func set_security_mode(mode: felt) -> ():
    end

    func modify_whitelist_status(address_to_whitelist: felt, bool: felt) -> ():
    end

    func modify_blacklist_status(address_to_whitelist: felt, bool: felt) -> ():
    end

    func get_is_address_blacklisted(address : felt) -> (bool : felt):
    end

    func __execute__(
        call_array_len : felt,
        call_array : AccountCallArray*,
        calldata_len : felt,
        calldata : felt*,
        nonce : felt,
    ) -> ():
    end

end

@contract_interface
namespace EvilContract:

    func deposit_eth(amount :Uint256):
    end

end
@external
func test_white_blacklist_contract{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local whiteblacklist_contract_address : felt
    local evil_contract_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ 
        SAFE = 0
        DEGEN = 1
        FULL_DEGEN = 2
        ids.whiteblacklist_contract_address = deploy_contract("./src/white_and_blacklist_account.cairo", [1, SAFE]).contract_address 
        ids.evil_contract_address = deploy_contract("./src/evil_contract.cairo", []).contract_address
    %}

    ### SAFE MODE ###
    # Get the security mode of the contract
    let (security_mode) = WhiteBlackListContract.get_security_mode(whiteblacklist_contract_address)
    assert security_mode = SAFE

    # Set caller address
    %{
        account_address = 123
        start_prank(caller_address=account_address)
    %}

    # Set evil contract as blacklisted
    WhiteBlackListContract.modify_blacklist_status(
        contract_address=whiteblacklist_contract_address,
        address_to_whitelist=evil_contract_address,
        bool=TRUE)

    # Assert indeed it is blacklisted
    let (is_blacklisted) = WhiteBlackListContract.get_is_address_blacklisted(
        contract_address=whiteblacklist_contract_address,
        address=evil_contract_address
    )

    # Transaction should fail because
    # tempvar deposit_selector : felt
    # %{
    #     from starkware.starknet.compiler.compile import get_selector_from_name
    #     ids.deposit_selector = get_selector_from_name("deposit_eth")
    # %}
    # let call_array = AccountCallArray(
    #                     to=whiteblacklist_contract_address,
    #                     selector=deposit_selector,
    #                     data_offset=2,
    #                     data_len=
    #                 )
    # %{ stop_expecting_revert = expect_revert("StarknetErrorCode.TRANSACTION_FAILED") %}
    #     whiteblacklist_contract_address.__execute__(
    #         contract_address=whiteblacklist_contract_address,
    #         call_array_len=1,
    #         call_array_=
    #     )

    # %{ stop_expecting_revert() %}  
    %{
        stop_prank()
    %}
    assert is_blacklisted = TRUE

    ###

    return ()

end