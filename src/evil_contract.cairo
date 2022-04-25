%lang starknet

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from contracts.IERC20 import IERC20

const GOERLI_WETH_ADDRESS = 123

@external
func deposit_eth{syscall_pt}(amount : felt):
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    IERC20.transferFrom(sender=caller_address, recipient=contract_address, amount=amount)
    return ()
end
