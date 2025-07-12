# Scanner implementation for tree-sitter external scanner

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
end

# Create a new scanner
function Scanner()
    Scanner(false, false, '"', 0, 0, 0, 0)
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

# Main scanning function
function scan(ptr::Ptr{Scanner}, ts_lexer::Ptr{TSLexer}, valid_symbols::Ptr{Bool})::Bool
    scanner = unsafe_load(ptr)
    
    # Skip whitespace except newlines
    skip_whitespace!(ts_lexer)
    
    if is_eof(ts_lexer)
        return false
    end
    
    c = peekchar_ts(ts_lexer)
    
    # Handle newlines
    if c == '\n' && unsafe_load(valid_symbols, EXTERNAL_TOKENS[:NEWLINE] + 1)
        advance!(ts_lexer)
        mark_end!(ts_lexer)
        set_result!(ts_lexer, :NEWLINE)
        return true
    end
    
    # Handle comments
    if c == '#' && unsafe_load(valid_symbols, EXTERNAL_TOKENS[:COMMENT] + 1)
        advance!(ts_lexer)
        
        # Check for multiline comment #= ... =#
        if peekchar_ts(ts_lexer) == '='
            advance!(ts_lexer)
            scanner.comment_depth = 1
            
            while scanner.comment_depth > 0 && !is_eof(ts_lexer)
                c1 = readchar_ts!(ts_lexer)
                
                if c1 == '#' && peekchar_ts(ts_lexer) == '='
                    advance!(ts_lexer)
                    scanner.comment_depth += 1
                elseif c1 == '=' && peekchar_ts(ts_lexer) == '#'
                    advance!(ts_lexer)
                    scanner.comment_depth -= 1
                end
            end
            
            if scanner.comment_depth > 0
                # Unterminated multiline comment
                return false
            end
        else
            # Single-line comment
            while !is_eof(ts_lexer) && peekchar_ts(ts_lexer) != '\n'
                advance!(ts_lexer)
            end
        end
        
        mark_end!(ts_lexer)
        set_result!(ts_lexer, :COMMENT)
        unsafe_store!(ptr, scanner)
        return true
    end
    
    # Handle string content (simplified for now)
    if scanner.in_string && unsafe_load(valid_symbols, EXTERNAL_TOKENS[:STRING_CONTENT] + 1)
        has_content = false
        
        while !is_eof(ts_lexer)
            c = peekchar_ts(ts_lexer)
            
            if c == scanner.string_delim_char
                if scanner.string_triple
                    # Check for triple quotes (simplified)
                    break
                else
                    break
                end
            elseif c == '\\'
                advance!(ts_lexer)
                has_content = true
                if !is_eof(ts_lexer)
                    advance!(ts_lexer)
                end
            elseif c == '\$'
                # String interpolation
                break
            else
                advance!(ts_lexer)
                has_content = true
            end
        end
        
        if has_content
            mark_end!(ts_lexer)
            set_result!(ts_lexer, :STRING_CONTENT)
            return true
        end
    end
    
    return false
end