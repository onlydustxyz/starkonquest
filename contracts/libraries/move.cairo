%lang starknet

from contracts.models.common import Vector2
from contracts.libraries.square_grid import grid_access, Grid
from contracts.libraries.cell import cell_access, Cell, Dust

# ------------------
# PUBLIC NAMESPACE
# ------------------
namespace move_strategy:
    # Move all dusts on the grid according to their direction, bouncing if needed
    func move_all_dusts{range_check_ptr, grid : Grid}():
        let (grid_iterator) = grid_access.start()
        with grid_iterator:
            internal.move_dust_loop()
        end
        return ()
    end

    # ------------------
    # PUBLIC NAMESPACE
    # ------------------
    namespace internal:
        func move_dust_loop{range_check_ptr, grid : Grid, grid_iterator : Vector2}():
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

        func try_move_single_dust{range_check_ptr, grid : Grid, grid_iterator : Vector2}():
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

        func move_single_dust{range_check_ptr, grid : Grid, grid_iterator : Vector2}(dust : Dust):
            alloc_locals

            # Bounce if needed
            let (local new_direction) = bounce(grid_iterator, dust.direction)

            # Get the next cell
            let (new_cell) = grid_access.get_next_cell_at(grid_iterator.x, grid_iterator.y)

            # Modify the dust direction in it
            cell_access.add_dust{cell=new_cell}(Dust(new_direction))

            # Store the new cell
            grid_access.set_next_cell_at(
                grid_iterator.x + new_direction.x, grid_iterator.y + new_direction.y, new_cell
            )

            return ()
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
