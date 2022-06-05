%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.models.common import Player

@contract_interface
namespace ITournament:
    func start() -> (res : felt):
    end

    func play_next_battle():
    end

    func open_registrations() -> (res : felt):
    end

    func close_registrations() -> (res : felt):
    end

    func register(ship_address) -> (res : felt):
    end

    func tournament_id() -> (res : felt):
    end

    func tournament_name() -> (res : felt):
    end

    func tournament_winner() -> (res : Player):
    end

    func reward_token_address() -> (res : felt):
    end

    func boarding_pass_token_address() -> (res : felt):
    end

    func rand_contract_address() -> (res : felt):
    end

    func reward_total_amount() -> (res : Uint256):
    end

    func stage() -> (res : felt):
    end

    func ship_count_per_battle() -> (res : felt):
    end

    func required_total_ship_count() -> (res : felt):
    end

    func grid_size() -> (res : felt):
    end

    func turn_count() -> (res : felt):
    end

    func max_dust() -> (res : felt):
    end

    func ship_count() -> (res : felt):
    end

    func player_ship(player_address : felt) -> (res : felt):
    end

    func ship_player(ship_address : felt) -> (res : felt):
    end

    func played_battle_count() -> (res : felt):
    end

    func deposit_rewards(amount : Uint256) -> (res : felt):
    end

    func winner_withdraw() -> (res : felt):
    end
end
