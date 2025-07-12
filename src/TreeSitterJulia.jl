module TreeSitterJulia

using JuliaSyntax

# Export main functionality
export create_scanner, destroy_scanner, serialize_scanner, deserialize_scanner, scan

# Include submodules
include("tokens.jl")
include("lexer.jl")
include("scanner.jl")
include("interface.jl")

# Module initialization
function __init__()
    # Initialize token mappings
    init_token_map!()
end

end # module TreeSitterJulia