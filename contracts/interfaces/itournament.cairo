%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.models.common import Player

@contract_interface
namespace ITournament {
    func start() -> (res: felt) {
    }

    func play_next_battle() {
    }

    func open_registrations() -> (res: felt) {
    }

    func register(ship_address) -> (res: felt) {
    }

    func tournament_id() -> (res: felt) {
    }

    func tournament_name() -> (res: felt) {
    }

    func tournament_winner() -> (res: Player) {
    }

    func reward_token_address() -> (res: felt) {
    }

    func boarding_pass_token_address() -> (res: felt) {
    }

    func rand_contract_address() -> (res: felt) {
    }

    func reward_total_amount() -> (res: Uint256) {
    }

    func stage() -> (res: felt) {
    }

    func ship_count_per_battle() -> (res: felt) {
    }

    func required_total_ship_count() -> (res: felt) {
    }

    func grid_size() -> (res: felt) {
    }

    func turn_count() -> (res: felt) {
    }

    func max_dust() -> (res: felt) {
    }

    func ship_count() -> (res: felt) {
    }

    func player_ship(player_address: felt) -> (res: felt) {
    }

    func ship_player(ship_address: felt) -> (res: felt) {
    }

    func played_battle_count() -> (res: felt) {
    }

    func deposit_rewards(amount: Uint256) -> (res: felt) {
    }

    func winner_withdraw() -> (res: felt) {
    }
}
