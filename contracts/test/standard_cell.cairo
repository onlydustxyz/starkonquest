namespace StandardCell {
    func declare{syscall_ptr: felt*, range_check_ptr}() {
        %{ context.standard_cell_class_hash = declare('contracts/cells/standard_cell.cairo').class_hash %}
        return ();
    }

    func class_hash() -> felt {
        tempvar standard_cell_class_hash;
        %{ ids.standard_cell_class_hash = context.standard_cell_class_hash %}
        return standard_cell_class_hash;
    }
}
