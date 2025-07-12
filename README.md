# TreeSitterJulia.jl

Tree-sitter external scanner for Julia, leveraging JuliaSyntax.jl's lexer through Julia's multiple dispatch system.

## Overview

This package provides a tree-sitter external scanner implementation for the Julia programming language. It demonstrates how to:

1. Adapt JuliaSyntax.jl's sophisticated lexer for tree-sitter's character-by-character API
2. Expand operators by precedence level as required by tree-sitter
3. Compile Julia code with `@ccallable` functions into a shared library
4. Integrate with tree-sitter's external scanner interface

## Features

- **Multiple Dispatch Integration**: Shares lexer code between JuliaSyntax and tree-sitter through Julia's multiple dispatch
- **Operator Precedence Expansion**: Maps JuliaSyntax's generic `Operator` kind to precedence-specific tokens
- **State Serialization**: Supports incremental parsing through scanner state save/restore
- **Full Token Coverage**: Handles all Julia token types including comments, strings, numbers, identifiers, and operators

## Architecture

```
JuliaSyntax.jl (external package)
       ↓
TreeSitterJulia.jl
       ├── TreeSitterLexer (Julia implementation)
       ├── Token Mapping (Kind → tree-sitter tokens)
       ├── C Interface (@ccallable functions)
       └── Scanner State Management
```

## Building

### Requirements

- Julia 1.6+ (Julia 1.12+ nightly for juliac.jl compilation)
- C compiler (gcc/clang)
- tree-sitter development files

### Basic Build

```bash
julia build.jl
```

This will:
1. Generate tree-sitter token definitions
2. Compile the scanner (using available method)
3. Create example grammar files

### Advanced Build with juliac.jl

If using Julia nightly with juliac.jl support:

```bash
julia build_with_juliac.jl
```

## Usage

### In Julia

```julia
using TreeSitterJulia

# Create a scanner
scanner = TreeSitterJulia.create_scanner()

# Use with tree-sitter (example)
# ... tree-sitter integration code ...
```

### With tree-sitter CLI

1. Copy generated files to your tree-sitter grammar directory
2. Reference the external scanner in your `grammar.js`
3. Run `tree-sitter generate` and link with the scanner library

## Examples

See the `examples/` directory for:
- Basic scanner usage
- Integration with tree-sitter
- Token mapping demonstrations
- Operator precedence examples

## Implementation Details

### Token Mapping

JuliaSyntax kinds are mapped to tree-sitter tokens with special handling for operators:

- `K"Operator"` + `PREC_PLUS` → `:OP_PREC_PLUS`
- `K"Operator"` + `PREC_TIMES` → `:OP_PREC_TIMES`
- `K"Operator"` + `PREC_POWER` → `:OP_PREC_POWER`
- ... and so on for all precedence levels

### Scanner State

The scanner maintains minimal state for incremental parsing:
- String delimiter tracking
- Comment depth
- Parenthesis/bracket nesting levels

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Built on top of [JuliaSyntax.jl](https://github.com/JuliaLang/JuliaSyntax.jl)
- Designed for [tree-sitter](https://tree-sitter.github.io/tree-sitter/)