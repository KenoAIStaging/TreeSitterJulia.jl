# Token definitions and mapping between JuliaSyntax kinds and tree-sitter tokens

using JuliaSyntax: Kind, @K_str, PrecedenceLevel, PREC_NONE, PREC_ASSIGNMENT,
    PREC_PAIRARROW, PREC_CONDITIONAL, PREC_ARROW, PREC_LAZYOR, PREC_LAZYAND,
    PREC_COMPARISON, PREC_PIPE_LT, PREC_PIPE_GT, PREC_COLON, PREC_PLUS,
    PREC_BITSHIFT, PREC_TIMES, PREC_RATIONAL, PREC_POWER, PREC_DECL,
    PREC_WHERE, PREC_DOT, PREC_QUOTE, PREC_UNICODE_OPS, PREC_COMPOUND_ASSIGN

# Tree-sitter token types
const TS_TOKENS = [
    # Whitespace and trivia
    :WHITESPACE,
    :NEWLINE,
    :COMMENT,
    
    # Identifiers
    :IDENTIFIER,
    :PLACEHOLDER,
    
    # Keywords
    :BAREMODULE, :BEGIN, :BREAK, :CONST, :CONTINUE, :DO, :EXPORT,
    :FOR, :FUNCTION, :GLOBAL, :IF, :IMPORT, :LET, :LOCAL, :MACRO,
    :MODULE, :QUOTE, :RETURN, :STRUCT, :TRY, :USING, :WHILE,
    :CATCH, :FINALLY, :ELSE, :ELSEIF, :END,
    :ABSTRACT, :AS, :DOC, :MUTABLE, :OUTER, :PRIMITIVE, :PUBLIC,
    :TYPE, :VAR,
    
    # Literals
    :BOOL_LITERAL,
    :INTEGER_LITERAL,
    :BIN_INT_LITERAL,
    :HEX_INT_LITERAL,
    :OCT_INT_LITERAL,
    :FLOAT_LITERAL,
    :FLOAT32_LITERAL,
    :STRING_LITERAL,
    :CHAR_LITERAL,
    :CMD_STRING_LITERAL,
    
    # Delimiters
    :AT,         # @
    :COMMA,      # ,
    :SEMICOLON,  # ;
    :LBRACKET,   # [
    :RBRACKET,   # ]
    :LBRACE,     # {
    :RBRACE,     # }
    :LPAREN,     # (
    :RPAREN,     # )
    :QUOTE_DELIM,      # "
    :TRIPLE_QUOTE,     # """
    :BACKTICK,         # `
    :TRIPLE_BACKTICK,  # ```
    
    # Special operators (non-precedence based)
    :EQ,           # =
    :DOT_EQ,       # .=
    :COLON_EQ,     # :=
    :TILDE,        # ~
    :QUESTION,     # ?
    :OR,           # ||
    :AND,          # &&
    :SUBTYPE,      # <:
    :SUPERTYPE,    # >:
    :DOUBLE_COLON, # ::
    :DOT,          # .
    :DOT_DOT,      # ..
    :DOT_DOT_DOT,  # ...
    :IN,           # in
    :ISA,          # isa
    :WHERE,        # where
    :BANG,         # !
    :PRIME,        # '
    :DOT_PRIME,    # .'
    :ARROW,        # ->
    :LONG_ARROW,   # -->
    :COLON,        # :
    :DOLLAR,       # $
    
    # Operators by precedence level
    :OP_PREC_ASSIGNMENT,
    :OP_PREC_PAIRARROW,
    :OP_PREC_CONDITIONAL,
    :OP_PREC_ARROW,
    :OP_PREC_LAZYOR,
    :OP_PREC_LAZYAND,
    :OP_PREC_COMPARISON,
    :OP_PREC_PIPE_LT,
    :OP_PREC_PIPE_GT,
    :OP_PREC_COLON,
    :OP_PREC_PLUS,
    :OP_PREC_BITSHIFT,
    :OP_PREC_TIMES,
    :OP_PREC_RATIONAL,
    :OP_PREC_POWER,
    :OP_PREC_DECL,
    :OP_PREC_WHERE,
    :OP_PREC_DOT,
    :OP_PREC_QUOTE,
    :OP_PREC_UNICODE_OPS,
    :OP_PREC_COMPOUND_ASSIGN,
    
    # Error tokens
    :ERROR,
    :ERROR_INVALID_OPERATOR,
    :ERROR_EOF_MULTICOMMENT,
    :ERROR_INVALID_NUMERIC,
    :ERROR_HEX_FLOAT_P,
    :ERROR_AMBIGUOUS_NUMERIC,
    :ERROR_AMBIGUOUS_DOT_MULTIPLY,
    :ERROR_INVALID_INTERPOLATION,
    :ERROR_NUMERIC_OVERFLOW,
    :ERROR_INVALID_ESCAPE,
    :ERROR_OVERLONG_CHAR,
    :ERROR_INVALID_UTF8,
    :ERROR_INVISIBLE_CHAR,
    :ERROR_IDENTIFIER_START,
    :ERROR_UNKNOWN_CHAR,
    :ERROR_BIDI_FORMAT,
    :ERROR_STAR_STAR,
    
    # Special markers
    :END_MARKER,
    :NONE,
]

# Create bidirectional mappings
const TS_TOKEN_TO_ID = Dict{Symbol, UInt16}()
const TS_ID_TO_TOKEN = Dict{UInt16, Symbol}()
const KIND_TO_TS_TOKEN = Dict{Kind, Symbol}()

# Initialize token mappings
function init_token_map!()
    # Create ID mappings
    for (i, token) in enumerate(TS_TOKENS)
        id = UInt16(i - 1)  # 0-based IDs for tree-sitter
        TS_TOKEN_TO_ID[token] = id
        TS_ID_TO_TOKEN[id] = token
    end
    
    # Map JuliaSyntax kinds to tree-sitter tokens
    
    # Whitespace and trivia
    KIND_TO_TS_TOKEN[K"Whitespace"] = :WHITESPACE
    KIND_TO_TS_TOKEN[K"NewlineWs"] = :NEWLINE
    KIND_TO_TS_TOKEN[K"Comment"] = :COMMENT
    
    # Identifiers
    KIND_TO_TS_TOKEN[K"Identifier"] = :IDENTIFIER
    KIND_TO_TS_TOKEN[K"Placeholder"] = :PLACEHOLDER
    
    # Keywords
    for kw in ["baremodule", "begin", "break", "const", "continue", "do", "export",
               "for", "function", "global", "if", "import", "let", "local", "macro",
               "module", "quote", "return", "struct", "try", "using", "while",
               "catch", "finally", "else", "elseif", "end",
               "abstract", "as", "doc", "mutable", "outer", "primitive", "public",
               "type", "var"]
        KIND_TO_TS_TOKEN[Kind(kw)] = Symbol(uppercase(kw))
    end
    
    # Literals
    KIND_TO_TS_TOKEN[K"Bool"] = :BOOL_LITERAL
    KIND_TO_TS_TOKEN[K"Integer"] = :INTEGER_LITERAL
    KIND_TO_TS_TOKEN[K"BinInt"] = :BIN_INT_LITERAL
    KIND_TO_TS_TOKEN[K"HexInt"] = :HEX_INT_LITERAL
    KIND_TO_TS_TOKEN[K"OctInt"] = :OCT_INT_LITERAL
    KIND_TO_TS_TOKEN[K"Float"] = :FLOAT_LITERAL
    KIND_TO_TS_TOKEN[K"Float32"] = :FLOAT32_LITERAL
    KIND_TO_TS_TOKEN[K"String"] = :STRING_LITERAL
    KIND_TO_TS_TOKEN[K"Char"] = :CHAR_LITERAL
    KIND_TO_TS_TOKEN[K"CmdString"] = :CMD_STRING_LITERAL
    
    # Delimiters
    KIND_TO_TS_TOKEN[K"@"] = :AT
    KIND_TO_TS_TOKEN[K","] = :COMMA
    KIND_TO_TS_TOKEN[K";"] = :SEMICOLON
    KIND_TO_TS_TOKEN[K"["] = :LBRACKET
    KIND_TO_TS_TOKEN[K"]"] = :RBRACKET
    KIND_TO_TS_TOKEN[K"{"] = :LBRACE
    KIND_TO_TS_TOKEN[K"}"] = :RBRACE
    KIND_TO_TS_TOKEN[K"("] = :LPAREN
    KIND_TO_TS_TOKEN[K")"] = :RPAREN
    KIND_TO_TS_TOKEN[K"\""] = :QUOTE_DELIM
    KIND_TO_TS_TOKEN[K"\"\"\""] = :TRIPLE_QUOTE
    KIND_TO_TS_TOKEN[K"`"] = :BACKTICK
    KIND_TO_TS_TOKEN[K"```"] = :TRIPLE_BACKTICK
    
    # Special operators
    KIND_TO_TS_TOKEN[K"="] = :EQ
    KIND_TO_TS_TOKEN[K".="] = :DOT_EQ
    KIND_TO_TS_TOKEN[K":="] = :COLON_EQ
    KIND_TO_TS_TOKEN[K"~"] = :TILDE
    KIND_TO_TS_TOKEN[K"?"] = :QUESTION
    KIND_TO_TS_TOKEN[K"||"] = :OR
    KIND_TO_TS_TOKEN[K"&&"] = :AND
    KIND_TO_TS_TOKEN[K"<:"] = :SUBTYPE
    KIND_TO_TS_TOKEN[K">:"] = :SUPERTYPE
    KIND_TO_TS_TOKEN[K"::"] = :DOUBLE_COLON
    KIND_TO_TS_TOKEN[K"."] = :DOT
    KIND_TO_TS_TOKEN[K".."] = :DOT_DOT
    KIND_TO_TS_TOKEN[K"..."] = :DOT_DOT_DOT
    KIND_TO_TS_TOKEN[K"in"] = :IN
    KIND_TO_TS_TOKEN[K"isa"] = :ISA
    KIND_TO_TS_TOKEN[K"where"] = :WHERE
    KIND_TO_TS_TOKEN[K"!"] = :BANG
    KIND_TO_TS_TOKEN[K"'"] = :PRIME
    KIND_TO_TS_TOKEN[K".'"] = :DOT_PRIME
    KIND_TO_TS_TOKEN[K"->"] = :ARROW
    KIND_TO_TS_TOKEN[K"-->"] = :LONG_ARROW
    KIND_TO_TS_TOKEN[K":"] = :COLON
    KIND_TO_TS_TOKEN[K"\$"] = :DOLLAR
    
    # Error tokens
    KIND_TO_TS_TOKEN[K"error"] = :ERROR
    KIND_TO_TS_TOKEN[K"ErrorInvalidOperator"] = :ERROR_INVALID_OPERATOR
    KIND_TO_TS_TOKEN[K"ErrorEofMultiComment"] = :ERROR_EOF_MULTICOMMENT
    KIND_TO_TS_TOKEN[K"ErrorInvalidNumericConstant"] = :ERROR_INVALID_NUMERIC
    KIND_TO_TS_TOKEN[K"ErrorHexFloatMustContainP"] = :ERROR_HEX_FLOAT_P
    KIND_TO_TS_TOKEN[K"ErrorAmbiguousNumericConstant"] = :ERROR_AMBIGUOUS_NUMERIC
    KIND_TO_TS_TOKEN[K"ErrorAmbiguousNumericDotMultiply"] = :ERROR_AMBIGUOUS_DOT_MULTIPLY
    KIND_TO_TS_TOKEN[K"ErrorInvalidInterpolationTerminator"] = :ERROR_INVALID_INTERPOLATION
    KIND_TO_TS_TOKEN[K"ErrorNumericOverflow"] = :ERROR_NUMERIC_OVERFLOW
    KIND_TO_TS_TOKEN[K"ErrorInvalidEscapeSequence"] = :ERROR_INVALID_ESCAPE
    KIND_TO_TS_TOKEN[K"ErrorOverLongCharacter"] = :ERROR_OVERLONG_CHAR
    KIND_TO_TS_TOKEN[K"ErrorInvalidUTF8"] = :ERROR_INVALID_UTF8
    KIND_TO_TS_TOKEN[K"ErrorInvisibleChar"] = :ERROR_INVISIBLE_CHAR
    KIND_TO_TS_TOKEN[K"ErrorIdentifierStart"] = :ERROR_IDENTIFIER_START
    KIND_TO_TS_TOKEN[K"ErrorUnknownCharacter"] = :ERROR_UNKNOWN_CHAR
    KIND_TO_TS_TOKEN[K"ErrorBidiFormatting"] = :ERROR_BIDI_FORMAT
    KIND_TO_TS_TOKEN[K"Error**"] = :ERROR_STAR_STAR
    
    # Special markers
    KIND_TO_TS_TOKEN[K"EndMarker"] = :END_MARKER
    KIND_TO_TS_TOKEN[K"None"] = :NONE
end

# Convert a Kind to a tree-sitter token type, handling operator precedence
function kind_to_ts_token(k::Kind, precedence::PrecedenceLevel=PREC_NONE)
    if k == K"Operator"
        # Map to precedence-specific operator token
        return precedence_to_token(precedence)
    else
        return get(KIND_TO_TS_TOKEN, k, :ERROR)
    end
end

# Map precedence level to token symbol
function precedence_to_token(prec::PrecedenceLevel)
    if prec == PREC_ASSIGNMENT
        return :OP_PREC_ASSIGNMENT
    elseif prec == PREC_PAIRARROW
        return :OP_PREC_PAIRARROW
    elseif prec == PREC_CONDITIONAL
        return :OP_PREC_CONDITIONAL
    elseif prec == PREC_ARROW
        return :OP_PREC_ARROW
    elseif prec == PREC_LAZYOR
        return :OP_PREC_LAZYOR
    elseif prec == PREC_LAZYAND
        return :OP_PREC_LAZYAND
    elseif prec == PREC_COMPARISON
        return :OP_PREC_COMPARISON
    elseif prec == PREC_PIPE_LT
        return :OP_PREC_PIPE_LT
    elseif prec == PREC_PIPE_GT
        return :OP_PREC_PIPE_GT
    elseif prec == PREC_COLON
        return :OP_PREC_COLON
    elseif prec == PREC_PLUS
        return :OP_PREC_PLUS
    elseif prec == PREC_BITSHIFT
        return :OP_PREC_BITSHIFT
    elseif prec == PREC_TIMES
        return :OP_PREC_TIMES
    elseif prec == PREC_RATIONAL
        return :OP_PREC_RATIONAL
    elseif prec == PREC_POWER
        return :OP_PREC_POWER
    elseif prec == PREC_DECL
        return :OP_PREC_DECL
    elseif prec == PREC_WHERE
        return :OP_PREC_WHERE
    elseif prec == PREC_DOT
        return :OP_PREC_DOT
    elseif prec == PREC_QUOTE
        return :OP_PREC_QUOTE
    elseif prec == PREC_UNICODE_OPS
        return :OP_PREC_UNICODE_OPS
    elseif prec == PREC_COMPOUND_ASSIGN
        return :OP_PREC_COMPOUND_ASSIGN
    else
        return :OP_PREC_UNICODE_OPS  # Default for unknown precedence
    end
end

# Export token count for tree-sitter
const TS_TOKEN_COUNT = length(TS_TOKENS)

# Generate C header content
function generate_c_header()::String
    header = """
    // Generated by TreeSitterJulia.jl
    #ifndef TREE_SITTER_JULIA_TOKENS_H
    #define TREE_SITTER_JULIA_TOKENS_H
    
    enum TokenType {
    """
    
    for (i, token) in enumerate(TS_TOKENS)
        header *= "    $(token) = $(i-1),\n"
    end
    
    header *= """
    };
    
    #define TOKEN_COUNT $(TS_TOKEN_COUNT)
    
    #endif // TREE_SITTER_JULIA_TOKENS_H
    """
    
    return header
end