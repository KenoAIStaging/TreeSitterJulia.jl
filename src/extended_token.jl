# Extended token type that includes operator precedence

using JuliaSyntax: Kind, PrecedenceLevel, PREC_NONE

struct ExtendedToken
    kind::Kind
    startbyte::Int
    endbyte::Int
    precedence::PrecedenceLevel
    text::String  # Store the actual text for operators
end

# Convert RawToken to ExtendedToken
function ExtendedToken(raw::RawToken, text::String="", precedence::PrecedenceLevel=PREC_NONE)
    ExtendedToken(raw.kind, raw.startbyte, raw.endbyte, precedence, text)
end