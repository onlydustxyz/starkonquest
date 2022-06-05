%lang starknet

struct Vector2:
    member x : felt
    member y : felt
end

struct Context:
    member max_turn_count : felt
    member max_dust : felt
    member rand_contract : felt
    member ship_count : felt
    member ship_contracts : felt*
end

struct ShipInit:
    member address : felt
    member position : Vector2
end

struct Player:
    member player_address : felt
    member ship_address : felt
end
