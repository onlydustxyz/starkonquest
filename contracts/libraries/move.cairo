%lang starknet

from contracts.models.common import Vector2
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Cell, Dust
from contracts.interfaces.iship import IShip

from starkware.cairo.common.math_cmp import is_not_zero
from starkware.starknet.common.syscalls import get_contract_address

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
        with grid_iterator:
            internal.move_dust_loop()
        end
        return ()
    end

    # Move all ships on the grid, checking for ship collisions as we go
    func move_all_ships{syscall_ptr : felt*, range_check_ptr, grid : Grid}(ship_addresses : felt*):
        let (grid_iterator) = grid_access.start()
        with grid_iterator:
            internal.move_ship_loop(ship_addresses)
        end
        return ()
    end

    # ------------------
    # PUBLIC NAMESPACE
    # ------------------
    namespace internal:
        func move_dust_loop{
            syscall_ptr : felt*, range_check_ptr, grid : Grid, grid_iterator : Vector2
        }():
            alloc_locals
            local grid_iterator : Vector2 = grid_iterator

            let (done) = grid_access.done()
            if done == 1:
                return ()
            end

            try_move_single_dust()

            grid_access.next()
            return move_dust_loop()
        end

        func try_move_single_dust{
            syscall_ptr : felt*, range_check_ptr, grid : Grid, grid_iterator : Vector2
        }():
            alloc_locals

            let (cell) = grid_access.get_current_cell_at(grid_iterator.x, grid_iterator.y)

            local range_check_ptr = range_check_ptr  # Revoked reference

            let (has_dust) = cell_access.has_dust{cell=cell}()
            if has_dust == 0:
                return ()
            end

            let (dust) = cell_access.get_dust{cell=cell}()
            move_single_dust(dust)

            return ()
        end

        func move_single_dust{
            syscall_ptr : felt*, range_check_ptr, grid : Grid, grid_iterator : Vector2
        }(dust : Dust):
            alloc_locals

            # Bounce if needed
            let (local new_direction) = bounce(grid_iterator, dust.direction)

            # Get the next cell
            local new_dust_position : Vector2 = Vector2(
                grid_iterator.x + new_direction.x, grid_iterator.y + new_direction.y
                )
            let (new_cell) = grid_access.get_next_cell_at(new_dust_position.x, new_dust_position.y)

            # Modify the dust direction in it
            cell_access.add_dust{cell=new_cell}(Dust(new_direction))

            # Store the new cell
            grid_access.set_next_cell_at(new_dust_position.x, new_dust_position.y, new_cell)

            let (space_contract_address) = get_contract_address()
            dust_moved.emit(space_contract_address, grid_iterator, new_dust_position)

            return ()
        end

        func move_ship_loop{
            syscall_ptr : felt*, range_check_ptr, grid : Grid, grid_iterator : Vector2
        }(ship_addresses : felt*):
            alloc_locals
            local grid_iterator : Vector2 = grid_iterator

            let (done) = grid_access.done()
            if done == 1:
                return ()
            end

            try_move_single_ship(ship_addresses)

            grid_access.next()
            return move_ship_loop(ship_addresses)
        end

        func try_move_single_ship{
            syscall_ptr : felt*, range_check_ptr, grid : Grid, grid_iterator : Vector2
        }(ship_addresses : felt*):
            alloc_locals

            let (cell) = grid_access.get_current_cell_at(grid_iterator.x, grid_iterator.y)

            local range_check_ptr = range_check_ptr  # Revoked reference

            let (has_ship) = cell_access.has_ship{cell=cell}()
            if has_ship == 0:
                return ()
            end

            let (ship_id) = cell_access.get_ship{cell=cell}()
            move_single_ship(ship_id, ship_addresses[ship_id - 1])

            return ()
        end

        func move_single_ship{
            syscall_ptr : felt*, range_check_ptr, grid : Grid, grid_iterator : Vector2
        }(ship_id : felt, ship_contract : felt):
            alloc_locals

            # Call ship interface
            let (ship_direction) = IShip.move(
                ship_contract, grid.cell_count, grid.current_cells, ship_id
            )
            let new_position_candidate = Vector2(
                grid_iterator.x + ship_direction.x, grid_iterator.y + ship_direction.y
            )

            let (new_position) = validate_new_position_candidate(new_position_candidate)
            let (cell) = grid_access.get_next_cell_at(new_position.x, new_position.y)
            cell_access.add_ship{cell=cell}(ship_id)
            grid_access.set_next_cell_at(new_position.x, new_position.y, cell)

            let (space_contract_address) = get_contract_address()
            ship_moved.emit(space_contract_address, ship_id, grid_iterator, new_position)
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
            let (destination) = grid_access.get_current_cell_at(new_position.x, new_position.y)
            let (local has_ship_in_current_grid) = cell_access.has_ship{cell=destination}()

            let (destination) = grid_access.get_next_cell_at(new_position.x, new_position.y)
            let (has_ship_in_next_grid) = cell_access.has_ship{cell=destination}()

            let (collision) = is_not_zero(has_ship_in_current_grid + has_ship_in_next_grid)
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
