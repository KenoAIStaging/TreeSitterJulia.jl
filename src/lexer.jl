# Tree-sitter lexer implementation using JuliaSyntax

using JuliaSyntax: JuliaSyntax, Kind, @K_str, EOF_CHAR
using JuliaSyntax.Tokenize: is_identifier_char, is_identifier_start_char,
    is_operator_start_char, is_dottable_operator_start_char, isopsuffix,
    _unicode_ops, optakessuffix

# Tree-sitter lexer interface
mutable struct TSLexer
    # Tree-sitter callback functions
    advance::Ptr{Cvoid}
    mark_end::Ptr{Cvoid}
    get_column::Ptr{Cvoid}
    is_at_included_range_start::Ptr{Cvoid}
    eof::Ptr{Cvoid}
    lookahead::Ptr{Cvoid}
    result_symbol::Ptr{Cvoid}
end

# Interface functions for tree-sitter
function advance!(ts_lexer::Ptr{TSLexer}, skip::Bool=false)
    ts = unsafe_load(ts_lexer)
    ccall(ts.advance, Cvoid, (Ptr{TSLexer}, Bool), ts_lexer, skip)
end

function mark_end!(ts_lexer::Ptr{TSLexer})
    ts = unsafe_load(ts_lexer)
    ccall(ts.mark_end, Cvoid, (Ptr{TSLexer},), ts_lexer)
end

function get_column(ts_lexer::Ptr{TSLexer})::UInt32
    ts = unsafe_load(ts_lexer)
    return ccall(ts.get_column, UInt32, (Ptr{TSLexer},), ts_lexer)
end

function is_at_included_range_start(ts_lexer::Ptr{TSLexer})::Bool
    ts = unsafe_load(ts_lexer)
    return ccall(ts.is_at_included_range_start, Bool, (Ptr{TSLexer},), ts_lexer)
end

function is_eof(ts_lexer::Ptr{TSLexer})::Bool
    ts = unsafe_load(ts_lexer)
    return ccall(ts.eof, Bool, (Ptr{TSLexer},), ts_lexer)
end

function lookahead(ts_lexer::Ptr{TSLexer})::Int32
    ts = unsafe_load(ts_lexer)
    return ccall(ts.lookahead, Int32, (Ptr{TSLexer},), ts_lexer)
end

function set_result!(ts_lexer::Ptr{TSLexer}, token_type::Symbol)
    ts = unsafe_load(ts_lexer)
    token_id = get(TS_TOKEN_TO_ID, token_type, UInt16(0))
    unsafe_store!(Ptr{UInt16}(ts.result_symbol), token_id)
end

# Character reading functions adapted for tree-sitter
function peekchar_ts(ts_lexer::Ptr{TSLexer})::Char
    if is_eof(ts_lexer)
        return EOF_CHAR
    end
    c_int = lookahead(ts_lexer)
    return c_int < 0 ? EOF_CHAR : Char(c_int)
end

function readchar_ts!(ts_lexer::Ptr{TSLexer})::Char
    c = peekchar_ts(ts_lexer)
    if c != EOF_CHAR
        advance!(ts_lexer)
    end
    return c
end

# Skip whitespace
function skip_whitespace!(ts_lexer::Ptr{TSLexer})
    while !is_eof(ts_lexer)
        c = peekchar_ts(ts_lexer)
        if c == ' ' || c == '\t' || c == '\r'
            advance!(ts_lexer, true)  # skip = true
        else
            break
        end
    end
end