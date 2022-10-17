%lang starknet

@contract_interface
namespace IRandom {
    func generate_random_numbers(seed: felt) -> (r1: felt, r2: felt, r3: felt, r4: felt, r5: felt) {
    }
}
