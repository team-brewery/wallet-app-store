%lang starknet

@contract_interface
namespace WhiteBlackListContract:

    func get_public_key_by_index(index: felt) -> (public_key : felt):
    end

    func get_public_keys() -> (res_len: felt, res: felt*):
    end

    func get_admin_limit() -> (limit : felt):
    end
    
    func add_public_key(public_key: felt, threshold: felt) -> ():
    end

    func add_public_keys(
        public_keys_len: felt,
        public_keys: felt*,
        threshold: felt
    ) -> ():
    end

    func get_admin_limit_() -> (limit : felt):
    end
end

@external
func test_multisig_contract{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local multisig_contract_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ 
        ids.multisig_contract_address = deploy_contract("./src/MultiSignatureAccount.cairo", [3, 10, 20, 30, 5]).contract_address 
    %}

    # Assert admin limit is set
    let (limit) = MultiSigContract.get_admin_limit_(contract_address=multisig_contract_address)
    assert limit = 5

    # Assert 
    let (public_key) = MultiSigContract.get_public_key_by_index(contract_address=multisig_contract_address, index=1)
    assert public_key = 30

    # let (res_len, res) = MultiSigContract.get_public_keys(contract_address=multisig_contract_address)
    # assert res_len = 3
    # assert [res] = 10
    # assert [res] = 20
    # assert [res] = 30
    return ()

end