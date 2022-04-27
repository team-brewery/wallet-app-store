%lang starknet

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256

const GOERLI_WETH_ADDRESS = 0x28179321c34e2ca38beafa45d0526673fbb5f044b4f46a9bcbe78841edfbc41


@external
func deposit_eth{syscall_ptr: felt*, range_check_ptr: felt}(amount : Uint256):
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    IERC20.transferFrom(contract_address=GOERLI_WETH_ADDRESS, sender=caller_address, recipient=contract_address, amount=amount)
    return ()
end
