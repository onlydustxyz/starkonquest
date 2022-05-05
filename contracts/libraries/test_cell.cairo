%lang starknet

from contracts.libraries.cell import Cell, Dust, cell_access
from contracts.models.common import Vector2

func assert_dust_count{cell : Cell}(dust_count : felt):
    let (value) = cell_access.get_dust_count()
    assert value = dust_count
    return ()
end

func assert_dust{cell : Cell}(dust : Dust):
    let (value) = cell_access.get_dust()
    assert value = dust
    return ()
end

func assert_has_dust{cell : Cell}(has_dust : felt):
    let (value) = cell_access.has_dust()
    assert value = has_dust
    return ()
end

func assert_ship{cell : Cell}(ship_id : felt):
    let (value) = cell_access.get_ship()
    assert value = ship_id
    return ()
end

func assert_has_ship{cell : Cell}(has_ship : felt):
    let (value) = cell_access.has_ship()
    assert value = has_ship
    return ()
end

func assert_occupied{cell : Cell}(occupied : felt):
    let (value) = cell_access.is_occupied()
    assert value = occupied
    return ()
end

func assert_free{cell : Cell}(free : felt):
    let (value) = cell_access.is_free()
    assert value = free
    return ()
end

@external
func test_cell_empty():
    let (cell) = cell_access.create()
    let dust = Dust(Vector2(0, 0))

    with cell:
        assert_dust_count(0)
        assert_dust(dust)
        assert_ship(0)
        assert_has_dust(0)
        assert_has_ship(0)
        assert_occupied(0)
        assert_free(1)
    end

    return ()
end

@external
func test_cell_add_dust():
    let (cell) = cell_access.create()
    let dust1 = Dust(Vector2(0, 1))
    let dust2 = Dust(Vector2(1, 1))

    with cell:
        # Add one dust
        cell_access.add_dust(dust1)

        assert_dust_count(1)
        assert_dust(dust1)
        assert_has_dust(1)
        assert_occupied(1)
        assert_free(0)

        # Add another dust
        cell_access.add_dust(dust2)

        assert_dust_count(2)
        assert_dust(dust2)
        assert_has_dust(1)
        assert_occupied(1)
        assert_free(0)
    end

    return ()
end

@external
func test_cell_remove_dust():
    let (cell) = cell_access.create()
    let dust = Dust(Vector2(0, 1))

    with cell:
        # Add 2 dusts and remove one
        cell_access.add_dust(dust)
        cell_access.add_dust(dust)
        cell_access.remove_dust()

        assert_dust_count(1)
        assert_dust(dust)
        assert_has_dust(1)
        assert_occupied(1)
        assert_free(0)

        # Remove the last dust
        cell_access.remove_dust()

        assert_dust_count(0)
        assert_has_dust(0)
        assert_occupied(0)
        assert_free(1)
    end

    return ()
end

@external
func test_cell_remove_dust_should_revert_if_no_dust():
    let (cell) = cell_access.create()

    with cell:
        %{ expect_revert(error_message="Cell: No dust here") %}
        cell_access.remove_dust()
    end

    return ()
end

@external
func test_cell_add_ship():
    let (cell) = cell_access.create()

    with cell:
        # Add one ship
        cell_access.add_ship(23)

        assert_ship(23)
        assert_has_ship(1)
        assert_occupied(1)
        assert_free(0)
    end

    return ()
end

@external
func test_cell_remove_ship():
    let (cell) = cell_access.create()

    with cell:
        # Add one ship and remove it
        cell_access.add_ship(23)
        cell_access.remove_ship()

        assert_ship(0)
        assert_has_ship(0)
        assert_occupied(0)
        assert_free(1)
    end

    return ()
end

@external
func test_cell_add_ship_should_revert_if_already_a_ship():
    let (cell) = cell_access.create()

    with cell:
        # Add one ship
        cell_access.add_ship(23)

        # Add another ship
        %{ expect_revert(error_message="Cell: There is already a ship") %}
        cell_access.add_ship(32)
    end

    return ()
end

@external
func test_cell_remove_ship_should_revert_if_no_ship():
    let (cell) = cell_access.create()

    with cell:
        %{ expect_revert(error_message="Cell: No ship here") %}
        cell_access.remove_ship()
    end

    return ()
end

@external
func test_cell_play_with_both_dust_and_ship():
    let (cell) = cell_access.create()
    let dust = Dust(Vector2(0, 1))

    with cell:
        # Add 2 dusts and 1 ship
        cell_access.add_dust(dust)
        cell_access.add_ship(23)
        cell_access.add_dust(dust)

        assert_dust_count(2)
        assert_dust(dust)
        assert_has_dust(1)
        assert_ship(23)
        assert_has_ship(1)
        assert_occupied(1)
        assert_free(0)

        # Remove one dust => ship still here
        cell_access.remove_dust()

        assert_dust_count(1)
        assert_dust(dust)
        assert_has_dust(1)
        assert_ship(23)
        assert_has_ship(1)
        assert_occupied(1)
        assert_free(0)

        # Remove the ship => dust still here
        cell_access.remove_ship()

        assert_dust_count(1)
        assert_dust(dust)
        assert_has_dust(1)
        assert_ship(0)
        assert_has_ship(0)
        assert_occupied(1)
        assert_free(0)
    end

    return ()
end
