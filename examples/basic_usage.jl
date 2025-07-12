# Basic usage example of TreeSitterJulia

using TreeSitterJulia
using JuliaSyntax

println("TreeSitterJulia Basic Usage Example")
println("=" ^ 40)

# Example 1: Token mapping demonstration
println("\n1. Token Mapping")
println("-" ^ 20)

code = "function f(x) x^2 + 1 end"
tokens = JuliaSyntax.tokenize(code)

println("Code: $code\n")
println("JuliaSyntax Kind -> TreeSitter Token:")
for tok in tokens
    k = JuliaSyntax.kind(tok)
    ts_token = TreeSitterJulia.kind_to_ts_token(k)
    text = code[tok.range]
    println("  $k -> :$ts_token ('$text')")
end

# Example 2: Operator precedence  
println("\n2. Operator Precedence Mapping")
println("-" ^ 20)

using JuliaSyntax: PREC_PLUS, PREC_TIMES, PREC_POWER

# Show how operators get mapped based on their precedence
operator_examples = ["+", "*", "^", "==", "->", "&&", "::", "."]

for op in operator_examples
    tokens = JuliaSyntax.tokenize(op)
    if !isempty(tokens)
        tok = first(tokens)
        k = JuliaSyntax.kind(tok)
        
        # Determine precedence
        prec = TreeSitterJulia.get_operator_precedence(op)
        ts_token = TreeSitterJulia.kind_to_ts_token(k, prec)
        
        println("  '$op': $k + $prec -> :$ts_token")
    end
end

# Example 3: Scanner lifecycle
println("\n3. Scanner Lifecycle")
println("-" ^ 20)

# Create scanner
scanner = TreeSitterJulia.create_scanner()
println("Scanner created: $scanner")

# Serialize state
buffer = zeros(UInt8, 100)
size = TreeSitterJulia.serialize_scanner(scanner, pointer(buffer))
println("State serialized: $size bytes")

# Deserialize state
TreeSitterJulia.deserialize_scanner(scanner, pointer(buffer), size)
println("State restored")

# Destroy scanner
TreeSitterJulia.destroy_scanner(scanner)
println("Scanner destroyed")

# Example 4: Token examples
println("\n4. Token Examples")
println("-" ^ 20)

examples = [
    "# Comment",
    "\"string\"",
    "'a'",
    "123",
    "3.14",
    "0x1F",
    "true",
    "function",
    "->",
    "::",
]

for ex in examples
    tokens = JuliaSyntax.tokenize(ex)
    if !isempty(tokens)
        tok = first(tokens)
        k = JuliaSyntax.kind(tok)
        ts_token = TreeSitterJulia.kind_to_ts_token(k)
        println("  '$ex' -> $k -> :$ts_token")
    end
end

println("\n✓ Examples completed!")