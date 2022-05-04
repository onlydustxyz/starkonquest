%lang starknet

struct Vector2:
    member x : felt
    member y : felt
end

struct Dust:
    member direction : Vector2
end

struct Cell:
    member dust_count : felt
    member dust : Dust
    member ship_id : felt
end

struct Grid:
    member cells : Cell*
    member size : felt
    member nb_cells : felt
end

struct Context:
    member max_turn_count : felt
    member max_dust : felt
    member rand_contract : felt
    member nb_ships : felt
    member ship_contracts : felt*
end

struct ShipInit:
    member address : felt
    member position : Vector2
end
