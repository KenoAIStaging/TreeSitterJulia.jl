# Scanner implementation for tree-sitter external scanner

include("lexer_adapter.jl")

# Scanner state that persists across parsing
mutable struct Scanner
    # State for context-sensitive lexing
    in_string::Bool
    string_triple::Bool
    string_delim_char::Char
    comment_depth::Int32
    paren_depth::Int32
    bracket_depth::Int32
    brace_depth::Int32
    # Last token info for context
    last_token_kind::Kind
    last_token_end_pos::Int
end

# Create a new scanner
function Scanner()
    Scanner(false, false, '"', 0, 0, 0, 0, K"None", 0)
end

# External token types handled by the scanner
const EXTERNAL_TOKENS = Dict{Symbol, Int}(
    :COMMENT => 0,
    :STRING_CONTENT => 1,
    :STRING_INTERPOLATION_START => 2,
    :STRING_INTERPOLATION_END => 3,
    :CMD_STRING_CONTENT => 4,
    :NEWLINE => 5,
    :ERROR_SENTINEL => 6,
)

# Scanner pool to prevent GC collection
const SCANNER_POOL = Dict{Ptr{Scanner}, Scanner}()

# Create scanner
function create_scanner()::Ptr{Scanner}
    scanner = Scanner()
    ptr = Ptr{Scanner}(Libc.malloc(sizeof(Scanner)))
    unsafe_store!(ptr, scanner)
    SCANNER_POOL[ptr] = scanner
    return ptr
end

# Destroy scanner
function destroy_scanner(ptr::Ptr{Scanner})
    delete!(SCANNER_POOL, ptr)
    Libc.free(ptr)
end

# Serialize scanner state
function serialize_scanner(ptr::Ptr{Scanner}, buffer::Ptr{UInt8})::UInt32
    scanner = unsafe_load(ptr)
    
    if buffer != C_NULL
        pos = 1
        # Write state (8 bytes total)
        unsafe_store!(buffer, scanner.in_string ? UInt8(1) : UInt8(0), pos); pos += 1
        unsafe_store!(buffer, scanner.string_triple ? UInt8(1) : UInt8(0), pos); pos += 1
        unsafe_store!(buffer, UInt8(scanner.string_delim_char), pos); pos += 1
        unsafe_store!(buffer, UInt8(scanner.comment_depth), pos); pos += 1
        unsafe_store!(buffer, UInt8(scanner.paren_depth), pos); pos += 1
        unsafe_store!(buffer, UInt8(scanner.bracket_depth), pos); pos += 1
        unsafe_store!(buffer, UInt8(scanner.brace_depth), pos); pos += 1
        unsafe_store!(buffer, UInt8(0), pos)  # padding
    end
    
    return 8
end

# Deserialize scanner state
function deserialize_scanner(ptr::Ptr{Scanner}, buffer::Ptr{UInt8}, length::UInt32)
    if length >= 8
        scanner = unsafe_load(ptr)
        
        pos = 1
        scanner.in_string = unsafe_load(buffer, pos) != 0; pos += 1
        scanner.string_triple = unsafe_load(buffer, pos) != 0; pos += 1
        scanner.string_delim_char = Char(unsafe_load(buffer, pos)); pos += 1
        scanner.comment_depth = Int32(unsafe_load(buffer, pos)); pos += 1
        scanner.paren_depth = Int32(unsafe_load(buffer, pos)); pos += 1
        scanner.bracket_depth = Int32(unsafe_load(buffer, pos)); pos += 1
        scanner.brace_depth = Int32(unsafe_load(buffer, pos)); pos += 1
        
        unsafe_store!(ptr, scanner)
    end
end

# Main scanning function using JuliaSyntax tokenizer
function scan(ptr::Ptr{Scanner}, ts_lexer::Ptr{TSLexer}, valid_symbols::Ptr{Bool})::Bool
    scanner = unsafe_load(ptr)
    
    # Use JuliaSyntax's tokenizer
    token = lex_julia_token(ts_lexer)
    
    if token === nothing
        return false
    end
    
    # Update scanner state based on token
    scanner.last_token_kind = token.kind
    scanner.last_token_end_pos = token.endbyte
    
    # Update nesting depths
    if token.kind == K"("
        scanner.paren_depth += 1
    elseif token.kind == K")"
        scanner.paren_depth -= 1
    elseif token.kind == K"["
        scanner.bracket_depth += 1
    elseif token.kind == K"]"
        scanner.bracket_depth -= 1
    elseif token.kind == K"{"
        scanner.brace_depth += 1
    elseif token.kind == K"}"
        scanner.brace_depth -= 1
    end
    
    # Handle string state
    if token.kind == K"\"" || token.kind == K"\"\"\""
        scanner.in_string = !scanner.in_string
        scanner.string_triple = (token.kind == K"\"\"\"")
        scanner.string_delim_char = '"'
    elseif token.kind == K"`" || token.kind == K"```"
        scanner.in_string = !scanner.in_string
        scanner.string_triple = (token.kind == K"```")
        scanner.string_delim_char = '`'
    end
    
    # Map to tree-sitter token, including operator precedence
    ts_token = if token.kind == K"Operator"
        kind_to_ts_token(token.kind, token.precedence)
    else
        kind_to_ts_token(token.kind)
    end
    
    # Check if this token type is valid
    token_id = get(TS_TOKEN_TO_ID, ts_token, nothing)
    if token_id !== nothing && token_id < 256  # Assuming max 256 external tokens
        if unsafe_load(valid_symbols, token_id + 1)
            set_result!(ts_lexer, ts_token)
            unsafe_store!(ptr, scanner)
            return true
        end
    end
    
    # If the exact token isn't in external tokens, try mapping to external token categories
    if token.kind == K"Comment" && unsafe_load(valid_symbols, EXTERNAL_TOKENS[:COMMENT] + 1)
        set_result!(ts_lexer, :COMMENT)
        unsafe_store!(ptr, scanner)
        return true
    elseif token.kind == K"NewlineWs" && unsafe_load(valid_symbols, EXTERNAL_TOKENS[:NEWLINE] + 1)
        set_result!(ts_lexer, :NEWLINE)
        unsafe_store!(ptr, scanner)
        return true
    elseif token.kind == K"String" && scanner.in_string && 
           unsafe_load(valid_symbols, EXTERNAL_TOKENS[:STRING_CONTENT] + 1)
        set_result!(ts_lexer, :STRING_CONTENT)
        unsafe_store!(ptr, scanner)
        return true
    end
    
    return false
end