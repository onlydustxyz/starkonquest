%lang starknet

from contracts.models.common import Vector2
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Cell, Dust
from contracts.interfaces.iship import IShip
from contracts.test.grid_helper import grid_helper

from starkware.cairo.common.math_cmp import is_not_zero
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.alloc import alloc

# ------------------
# EVENTS
# ------------------

@event
func dust_moved(space_contract_address : felt, previous_position : Vector2, position : Vector2):
end

@event
func ship_moved(
    space_contract_address : felt, ship_id : felt, previous_position : Vector2, position : Vector2
):
end

# ------------------
# PUBLIC NAMESPACE
# ------------------
namespace move_strategy:
    # Move all dusts on the grid according to their direction, bouncing if needed
    func move_all_dusts{syscall_ptr : felt*, range_check_ptr, grid : Grid}():
        let (grid_iterator) = grid_access.start()
        let (dust_positions_array : Vector2*) = alloc()
        let dust_positions_array_len = 0
        with grid_iterator, dust_positions_array, dust_positions_array_len:
            internal.find_dust_to_move_loop()
        end
        with dust_positions_array, dust_positions_array_len:
            internal.move_relevant_dust_loop(0)
        end

        return ()
    end

    # Move all ships on the grid, checking for ship collisions as we go
    func move_all_ships{syscall_ptr : felt*, range_check_ptr, grid : Grid}(ship_addresses : felt*):
        alloc_locals
        internal.move_relevant_ship_loop(0, ship_addresses)
        return ()
    end

    # ------------------
    # PUBLIC NAMESPACE
    # ------------------
    namespace internal:
        func find_dust_to_move_loop{
            syscall_ptr : felt*,
            range_check_ptr,
            grid : Grid,
            grid_iterator : Vector2,
            dust_positions_array : Vector2*,
            dust_positions_array_len : felt,
        }():
            alloc_locals
            local grid_iterator : Vector2 = grid_iterator
            let (done) = grid_access.done()
            if done == 1:
                return ()
            end

            try_add_single_dust_position()
            grid_access.next()
            return find_dust_to_move_loop()
        end

        func try_add_single_dust_position{
            syscall_ptr : felt*,
            range_check_ptr,
            grid : Grid,
            grid_iterator : Vector2,
            dust_positions_array : Vector2*,
            dust_positions_array_len : felt,
        }():
            alloc_locals

            let (cell) = grid_access.get_cell_at(grid_iterator.x, grid_iterator.y)

            local range_check_ptr = range_check_ptr  # Revoked reference

            let (has_dust) = cell_access.has_dust{cell=cell}()
            if has_dust == 0:
                return ()
            end
            # Add the dust psition to the end of vector_array
            assert dust_positions_array[dust_positions_array_len] = grid_iterator  # [vector_array + vector_array_len * Vector2.SIZE] = grid_iterator
            let dust_positions_array_len = dust_positions_array_len + 1

            return ()
        end
        func move_relevant_dust_loop{
            syscall_ptr : felt*,
            range_check_ptr,
            grid : Grid,
            dust_positions_array : Vector2*,
            dust_positions_array_len : felt,
        }(index : felt):
            alloc_locals
            if index == dust_positions_array_len:
                return ()
            end
            let position : Vector2 = dust_positions_array[index]  # [vector_array + index * Vector2.SIZE]
            let (cell) = grid_access.get_cell_at(position.x, position.y)
            let (dust) = cell_access.get_dust{cell=cell}()
            move_single_dust(position, dust)

            # Remove dust from current cell
            with cell:
                cell_access.remove_dust()
            end
            grid_access.set_cell_at(position.x, position.y, cell)

            return move_relevant_dust_loop(index + 1)
        end
        func move_single_dust{syscall_ptr : felt*, range_check_ptr, grid : Grid}(
            position : Vector2, dust : Dust
        ):
            alloc_locals

            # Bounce if needed
            let (local new_direction) = bounce(position, dust.direction)

            # Get the next cell
            local new_dust_position : Vector2 = Vector2(
                position.x + new_direction.x, position.y + new_direction.y
                )
            let (new_cell) = grid_access.get_cell_at(new_dust_position.x, new_dust_position.y)

            # Modify the dust direction in it
            cell_access.add_dust{cell=new_cell}(Dust(new_direction))

            # Store the new cell
            grid_access.set_cell_at(new_dust_position.x, new_dust_position.y, new_cell)

            let (space_contract_address) = get_contract_address()
            dust_moved.emit(space_contract_address, position, new_dust_position)

            return ()
        end

        func move_relevant_ship_loop{syscall_ptr : felt*, range_check_ptr, grid : Grid}(
            index : felt, ship_addresses : felt*
        ):
            alloc_locals
            if index == grid.ships_positions_len:
                return ()
            end
            let position : Vector2 = grid.ships_positions[index]
            let (cell) = grid_access.get_cell_at(position.x, position.y)
            let (ship_id) = cell_access.get_ship{cell=cell}()
            move_single_ship(ship_id, ship_addresses[ship_id - 1], position, cell)
            # grid_helper.debug_grid()

            return move_relevant_ship_loop(index + 1, ship_addresses)
        end
        func move_single_ship{syscall_ptr : felt*, range_check_ptr, grid : Grid}(
            ship_id : felt, ship_contract : felt, position : Vector2, original_cell : Cell
        ):
            alloc_locals

            # Call ship interface

            let (cell_array : Cell*) = alloc()
            dict_to_array(cell_array, 0)

            let (ship_direction) = IShip.move(ship_contract, grid.cell_count, cell_array, ship_id)

            let new_position_candidate = Vector2(
                position.x + ship_direction.x, position.y + ship_direction.y
            )

            let (new_position) = validate_new_position_candidate{grid_iterator=position}(
                new_position_candidate
            )
            let (space_contract_address) = get_contract_address()

            if new_position.x == position.x:
                if new_position.y == position.y:
                    ship_moved.emit(space_contract_address, ship_id, position, new_position)
                    return ()
                end
            end
            let (cell_new) = grid_access.get_cell_at(new_position.x, new_position.y)

            cell_access.add_ship{cell=cell_new}(ship_id)
            grid_access.set_cell_at(new_position.x, new_position.y, cell_new)

            # remove ship from cell after it has moved, only if it has moved
            let cell = original_cell
            with cell:
                cell_access.remove_ship()
            end
            grid_access.set_cell_at(position.x, position.y, cell)
            # Update ships_positions in Grid
            grid_access.update_ship_position_at_index(ship_id - 1, new_position)

            ship_moved.emit(space_contract_address, ship_id, position, new_position)
            return ()
        end

        func dict_to_array{syscall_ptr : felt*, range_check_ptr, grid : Grid}(
            array : Cell*, index : felt
        ):
            if index == grid.cell_count:
                return ()
            end
            let cell : Cell = grid_access.get_cell_at_index(index)
            assert [array] = cell
            dict_to_array(array + Cell.SIZE, index + 1)
            return ()
        end

        func validate_new_position_candidate{
            syscall_ptr : felt*, range_check_ptr, grid : Grid, grid_iterator : Vector2
        }(new_position_candidate : Vector2) -> (new_position : Vector2):
            let (ship_collision) = ship_can_collide(new_position_candidate)
            if ship_collision == 1:
                # Ship collision => do not move
                return (new_position=grid_iterator)
            end
            return (new_position=new_position_candidate)
        end

        func ship_can_collide{range_check_ptr, grid : Grid}(new_position : Vector2) -> (
            collision : felt
        ):
            alloc_locals
            # ! We check ship collision on both current and next cells
            # ! as if there is a collition, the ship will not move
            # ! we need to ensure there will be no ship taking its place
            let (destination) = grid_access.get_cell_at(new_position.x, new_position.y)
            let (local has_ship_in_current_grid) = cell_access.has_ship{cell=destination}()

            let (collision) = is_not_zero(has_ship_in_current_grid)  # + has_ship_in_next_grid)
            return (collision=collision)
        end

        func bounce{grid : Grid}(position : Vector2, direction : Vector2) -> (
            new_direction : Vector2
        ):
            alloc_locals

            local new_direction : Vector2

            let (crossing) = grid_access.is_crossing_border(position, direction)

            if crossing.x == 1:
                assert new_direction.x = -direction.x
            else:
                assert new_direction.x = direction.x
            end

            if crossing.y == 1:
                assert new_direction.y = -direction.y
            else:
                assert new_direction.y = direction.y
            end

            return (new_direction=new_direction)
        end
    end
end
