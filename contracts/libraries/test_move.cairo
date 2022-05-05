%lang starknet

from contracts.libraries.move import move_strategy
from contracts.models.common import Vector2
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Dust

func add_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
    let (cell) = cell_access.create()
    cell_access.add_dust{cell=cell}(dust)
    grid_access.set_next_cell_at(x, y, cell)
    return ()
end

func assert_dust_at{range_check_ptr, grid : Grid}(x : felt, y : felt, dust : Dust):
    let (cell) = grid_access.get_current_cell_at(x, y)
    assert cell.dust = dust
    return ()
end

@external
func test_move_dusts{range_check_ptr}():
    alloc_locals

    let dust1 = Dust(Vector2(1, 1))  # top left, going down right
    let dust2 = Dust(Vector2(1, -1))  # top right, going down left
    let dust3 = Dust(Vector2(-1, -1))  # bottom right, going up left
    let dust4 = Dust(Vector2(-1, 1))  # bottom left, going up right

    let (grid) = grid_access.create(4)
    with grid:
        add_dust_at(0, 0, dust1)
        add_dust_at(0, 3, dust2)
        add_dust_at(3, 3, dust3)
        add_dust_at(3, 0, dust4)
        grid_access.apply_modifications()

        move_strategy.move_all_dusts()
        grid_access.apply_modifications()

        with_attr error_message("bad dust move"):
            assert_dust_at(1, 1, dust1)
            assert_dust_at(1, 2, dust2)
            assert_dust_at(2, 2, dust3)
            assert_dust_at(2, 1, dust4)
        end
    end

    return ()
end

@external
func test_grid_move_dust_beyound_borders{range_check_ptr}():
    alloc_locals

    let dust1 = Dust(Vector2(-1, -1))  # top left, going up left
    let dust2 = Dust(Vector2(-1, 1))  # top right, going up right
    let dust3 = Dust(Vector2(1, 1))  # bottom right, going down right
    let dust4 = Dust(Vector2(1, -1))  # bottom left, going down left

    let new_dust1 = Dust(Vector2(1, 1))  # now going down right
    let new_dust2 = Dust(Vector2(1, -1))  # now going down left
    let new_dust3 = Dust(Vector2(-1, -1))  # now going up left
    let new_dust4 = Dust(Vector2(-1, 1))  # now going up right

    let (grid) = grid_access.create(4)
    with grid:
        add_dust_at(0, 0, dust1)
        add_dust_at(0, 3, dust2)
        add_dust_at(3, 3, dust3)
        add_dust_at(3, 0, dust4)
        grid_access.apply_modifications()

        move_strategy.move_all_dusts()
        grid_access.apply_modifications()

        with_attr error_message("bad dust move"):
            assert_dust_at(1, 1, new_dust1)
            assert_dust_at(1, 2, new_dust2)
            assert_dust_at(2, 2, new_dust3)
            assert_dust_at(2, 1, new_dust4)
        end
    end

    return ()
end
