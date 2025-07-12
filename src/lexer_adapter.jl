# Adapter that connects JuliaSyntax's tokenizer to tree-sitter's character-by-character API

using JuliaSyntax
using JuliaSyntax: Kind, @K_str, EOF_CHAR, RawToken
import JuliaSyntax.Tokenize

include("extended_token.jl")

# Import PREC_NONE for default precedence
using JuliaSyntax: PREC_NONE

# Buffer that accumulates characters from tree-sitter
mutable struct CharBuffer
    chars::Vector{Char}
    pos::Int
end

CharBuffer() = CharBuffer(Char[], 1)

function Base.String(buf::CharBuffer)
    return String(buf.chars)
end

function append_char!(buf::CharBuffer, c::Char)
    push!(buf.chars, c)
end

function reset!(buf::CharBuffer)
    empty!(buf.chars)
    buf.pos = 1
end

# Use JuliaSyntax tokenizer on accumulated text
function tokenize_buffer(buf::CharBuffer)
    if isempty(buf.chars)
        return nothing
    end
    
    text = String(buf)
    tokens = JuliaSyntax.tokenize(text)
    
    # Return the first complete token
    for token in tokens
        if JuliaSyntax.kind(token) != K"None"
            return token
        end
    end
    
    return nothing
end

# Main lexing function that accumulates characters until a token is formed
function lex_julia_token(ts_lexer::Ptr{TSLexer})::Union{ExtendedToken, Nothing}
    buf = CharBuffer()
    start_pos = 0
    
    # Skip leading whitespace (except newlines)
    while !is_eof(ts_lexer)
        c_int = lookahead(ts_lexer)
        if c_int < 0
            break
        end
        c = Char(c_int)
        if c == ' ' || c == '\t' || c == '\r'
            advance!(ts_lexer)
            start_pos += 1
        else
            break
        end
    end
    
    if is_eof(ts_lexer)
        return nothing
    end
    
    # Special handling for single-character tokens
    c_int = lookahead(ts_lexer)
    if c_int < 0
        return nothing
    end
    c = Char(c_int)
    
    # Quick check for single-char tokens
    if c in "()[]{},;@\$"
        advance!(ts_lexer)
        mark_end!(ts_lexer)
        append_char!(buf, c)
        token = tokenize_buffer(buf)
        if token !== nothing
            text = String(buf)
            k = JuliaSyntax.kind(token)
            prec = k == K"Operator" ? get_operator_precedence(text) : PREC_NONE
            return ExtendedToken(k, start_pos, start_pos + 1, prec, text)
        end
    end
    
    # For other tokens, accumulate characters until we have a complete token
    prev_token = nothing
    
    while !is_eof(ts_lexer)
        c_int = lookahead(ts_lexer)
        if c_int < 0
            break
        end
        c = Char(c_int)
        
        # Try adding this character
        append_char!(buf, c)
        token = tokenize_buffer(buf)
        
        if token !== nothing
            # Check if adding the next character would create a different token
            advance!(ts_lexer)
            
            if !is_eof(ts_lexer)
                next_c_int = lookahead(ts_lexer)
                if next_c_int >= 0
                    next_c = Char(next_c_int)
                    append_char!(buf, next_c)
                    next_token = tokenize_buffer(buf)
                    
                    # If the token changes, we've gone too far
                    if next_token === nothing || 
                       JuliaSyntax.kind(next_token) != JuliaSyntax.kind(token) ||
                       (JuliaSyntax.kind(token) != K"Whitespace" && 
                        JuliaSyntax.kind(token) != K"Comment" &&
                        JuliaSyntax.kind(token) != K"String")
                        # Don't include the next character
                        pop!(buf.chars)
                        mark_end!(ts_lexer)
                        text = String(buf)
                        k = JuliaSyntax.kind(token)
                        prec = k == K"Operator" ? get_operator_precedence(text) : PREC_NONE
                        return ExtendedToken(k, start_pos, start_pos + length(buf.chars), prec, text)
                    end
                end
            else
                # At EOF, return what we have
                mark_end!(ts_lexer)
                text = String(buf)
                k = JuliaSyntax.kind(token)
                prec = k == K"Operator" ? get_operator_precedence(text) : PREC_NONE
                return ExtendedToken(k, start_pos, start_pos + length(buf.chars), prec, text)
            end
        else
            advance!(ts_lexer)
        end
        
        # Safety check to prevent infinite loops
        if length(buf.chars) > 1000
            break
        end
    end
    
    # Try to return whatever we accumulated
    if !isempty(buf.chars)
        token = tokenize_buffer(buf)
        if token !== nothing
            mark_end!(ts_lexer)
            text = String(buf)
            k = JuliaSyntax.kind(token)
            prec = k == K"Operator" ? get_operator_precedence(text) : PREC_NONE
            return ExtendedToken(k, start_pos, start_pos + length(buf.chars), prec, text)
        end
    end
    
    return nothing
end

# Helper to determine operator precedence from the operator text
function get_operator_precedence(op_text::AbstractString)::JuliaSyntax.PrecedenceLevel
    if length(op_text) == 1
        c = first(op_text)
        if haskey(JuliaSyntax.Tokenize._unicode_ops, c)
            return JuliaSyntax.Tokenize._unicode_ops[c]
        end
    end
    
    # Check specific operators
    op_str = String(op_text)
    if op_str in ["=", ".=", ":=", "~", "≔", "⩴", "≕"]
        return JuliaSyntax.PREC_ASSIGNMENT
    elseif op_str == "=>"
        return JuliaSyntax.PREC_PAIRARROW
    elseif op_str == "?"
        return JuliaSyntax.PREC_CONDITIONAL
    elseif op_str in ["->", "-->", "←", "→", "↔"]
        return JuliaSyntax.PREC_ARROW
    elseif op_str == "||"
        return JuliaSyntax.PREC_LAZYOR
    elseif op_str == "&&"
        return JuliaSyntax.PREC_LAZYAND
    elseif op_str in ["<", ">", "==", "!=", "<=", ">=", "≤", "≥", "≡", "≠", "≢"]
        return JuliaSyntax.PREC_COMPARISON
    elseif op_str == "<|"
        return JuliaSyntax.PREC_PIPE_LT
    elseif op_str == "|>"
        return JuliaSyntax.PREC_PIPE_GT
    elseif op_str in [":", "..", "…"]
        return JuliaSyntax.PREC_COLON
    elseif op_str in ["+", "-", "⊕", "⊖", "|", "∪", "∨"]
        return JuliaSyntax.PREC_PLUS
    elseif op_str in ["<<", ">>", ">>>"]
        return JuliaSyntax.PREC_BITSHIFT
    elseif op_str in ["*", "/", "÷", "%", "&", "∩", "∧"]
        return JuliaSyntax.PREC_TIMES
    elseif op_str == "//"
        return JuliaSyntax.PREC_RATIONAL
    elseif op_str in ["^", "↑", "↓"]
        return JuliaSyntax.PREC_POWER
    elseif op_str == "::"
        return JuliaSyntax.PREC_DECL
    elseif op_str == "where"
        return JuliaSyntax.PREC_WHERE
    elseif op_str == "."
        return JuliaSyntax.PREC_DOT
    elseif op_str in ["'", ".'"]
        return JuliaSyntax.PREC_QUOTE
    else
        return JuliaSyntax.PREC_UNICODE_OPS
    end
end