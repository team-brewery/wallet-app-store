"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
account_file = os.path.join("src", "white_and_blacklist_account.cairo")

# The testing library uses python's asyncio. So the following
# decorator and the async keyword are needed.
@pytest.mark.asyncio
async def test_increase_balance():
    """Test increase_balance method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()


    acct = await starknet.deploy(account_file,
         constructor_calldata=[123, 0]
    )
    
    execution_info = await acct.set_whitelist_implementation(acct.contract_address).invoke()
    
    