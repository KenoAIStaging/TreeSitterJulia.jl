# C-compatible interface functions for tree-sitter

# Export C-compatible functions with @ccallable
Base.@ccallable function tree_sitter_julia_external_scanner_create()::Ptr{Scanner}
    create_scanner()
end

Base.@ccallable function tree_sitter_julia_external_scanner_destroy(scanner::Ptr{Scanner})::Cvoid
    destroy_scanner(scanner)
    nothing
end

Base.@ccallable function tree_sitter_julia_external_scanner_serialize(
    scanner::Ptr{Scanner},
    buffer::Ptr{UInt8}
)::UInt32
    serialize_scanner(scanner, buffer)
end

Base.@ccallable function tree_sitter_julia_external_scanner_deserialize(
    scanner::Ptr{Scanner},
    buffer::Ptr{UInt8},
    length::UInt32
)::Cvoid
    deserialize_scanner(scanner, buffer, length)
    nothing
end

Base.@ccallable function tree_sitter_julia_external_scanner_scan(
    scanner::Ptr{Scanner},
    ts_lexer::Ptr{TSLexer},
    valid_symbols::Ptr{Bool}
)::Bool
    scan(scanner, ts_lexer, valid_symbols)
end