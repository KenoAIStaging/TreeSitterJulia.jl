#!/usr/bin/env julia

# Build script for TreeSitterJulia

using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using TreeSitterJulia

const BUILD_DIR = joinpath(@__DIR__, "build")
mkpath(BUILD_DIR)

println("TreeSitterJulia Build Script")
println("=" ^ 40)

# Step 1: Generate token header
println("\n1. Generating token header...")
header_content = TreeSitterJulia.generate_c_header()
header_path = joinpath(BUILD_DIR, "tree_sitter_julia_tokens.h")
open(header_path, "w") do f
    write(f, header_content)
end
println("   Generated: $header_path")

# Step 2: Create C wrapper
println("\n2. Creating C wrapper...")
c_wrapper = """
#include <julia.h>
#include <stdbool.h>
#include <stdint.h>
#include <tree_sitter/parser.h>

// Initialize Julia runtime
static int julia_initialized = 0;

static void ensure_julia_init() {
    if (!julia_initialized) {
        jl_init();
        
        // Add package to load path and load it
        jl_eval_string("using Pkg; Pkg.activate(\\\"$(escape_string(@__DIR__))\\\"); using TreeSitterJulia");
        
        if (jl_exception_occurred()) {
            jl_static_show(JL_STDERR, jl_exception_occurred());
            jl_exception_clear();
        }
        
        julia_initialized = 1;
    }
}

// Tree-sitter external scanner interface
void *tree_sitter_julia_external_scanner_create() {
    ensure_julia_init();
    
    jl_function_t *func = jl_get_function(jl_main_module, "tree_sitter_julia_external_scanner_create");
    if (!func) return NULL;
    
    jl_value_t *result = jl_call0(func);
    if (jl_exception_occurred()) {
        jl_static_show(JL_STDERR, jl_exception_occurred());
        return NULL;
    }
    
    return jl_unbox_voidpointer(result);
}

void tree_sitter_julia_external_scanner_destroy(void *payload) {
    jl_function_t *func = jl_get_function(jl_main_module, "tree_sitter_julia_external_scanner_destroy");
    if (!func) return;
    
    jl_value_t *arg = jl_box_voidpointer(payload);
    jl_call1(func, arg);
}

unsigned tree_sitter_julia_external_scanner_serialize(void *payload, char *buffer) {
    jl_function_t *func = jl_get_function(jl_main_module, "tree_sitter_julia_external_scanner_serialize");
    if (!func) return 0;
    
    jl_value_t *arg1 = jl_box_voidpointer(payload);
    jl_value_t *arg2 = jl_box_voidpointer(buffer);
    jl_value_t *result = jl_call2(func, arg1, arg2);
    
    if (jl_exception_occurred()) {
        return 0;
    }
    
    return jl_unbox_uint32(result);
}

void tree_sitter_julia_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
    jl_function_t *func = jl_get_function(jl_main_module, "tree_sitter_julia_external_scanner_deserialize");
    if (!func) return;
    
    jl_value_t *arg1 = jl_box_voidpointer(payload);
    jl_value_t *arg2 = jl_box_voidpointer((void*)buffer);
    jl_value_t *arg3 = jl_box_uint32(length);
    jl_call3(func, arg1, arg2, arg3);
}

bool tree_sitter_julia_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
    jl_function_t *func = jl_get_function(jl_main_module, "tree_sitter_julia_external_scanner_scan");
    if (!func) return false;
    
    jl_value_t *arg1 = jl_box_voidpointer(payload);
    jl_value_t *arg2 = jl_box_voidpointer(lexer);
    jl_value_t *arg3 = jl_box_voidpointer((void*)valid_symbols);
    jl_value_t *result = jl_call3(func, arg1, arg2, arg3);
    
    if (jl_exception_occurred()) {
        return false;
    }
    
    return jl_unbox_bool(result);
}
"""

wrapper_path = joinpath(BUILD_DIR, "scanner_wrapper.c")
open(wrapper_path, "w") do f
    write(f, c_wrapper)
end
println("   Generated: $wrapper_path")

# Step 3: Create example grammar.js
println("\n3. Creating example grammar...")
grammar_js = raw"""
module.exports = grammar({
  name: 'julia',

  externals: $ => [
    $.comment,
    $.string_content,
    $.string_interpolation_start,
    $.string_interpolation_end,
    $.cmd_string_content,
    $._newline,
    $.error_sentinel,
  ],

  extras: $ => [
    /[ \t\r]/,
    $.comment,
  ],

  conflicts: $ => [
    [$.binary_expression, $.unary_expression],
  ],

  rules: {
    source_file: $ => repeat($._statement),

    _statement: $ => choice(
      $.expression_statement,
      $.assignment,
      $.function_definition,
      $.if_statement,
      $.for_statement,
      $.while_statement,
    ),

    expression_statement: $ => seq(
      $._expression,
      optional(';')
    ),

    _expression: $ => choice(
      $.identifier,
      $.number,
      $.string,
      $.char,
      $.binary_expression,
      $.unary_expression,
      $.call_expression,
      $.array_expression,
      $.parenthesized_expression,
    ),

    identifier: $ => /[A-Za-z_][A-Za-z0-9_!]*/,

    number: $ => choice(
      /\d+/,                    // integers
      /\d+\.\d*/,              // floats
      /\.\d+/,                 // floats starting with dot
      /0x[0-9a-fA-F]+/,        // hex
      /0o[0-7]+/,              // octal
      /0b[01]+/,               // binary
    ),

    string: $ => choice(
      seq('"', repeat(choice($.string_content, $.escape_sequence)), '"'),
      seq('"""', repeat(choice($.string_content, $.escape_sequence)), '"""'),
    ),

    char: $ => seq("'", choice(/[^'\\]/, $.escape_sequence), "'"),

    escape_sequence: $ => /\\./,

    binary_expression: $ => choice(
      // Arithmetic
      prec.left(1, seq($._expression, '+', $._expression)),
      prec.left(1, seq($._expression, '-', $._expression)),
      prec.left(2, seq($._expression, '*', $._expression)),
      prec.left(2, seq($._expression, '/', $._expression)),
      prec.right(3, seq($._expression, '^', $._expression)),
      
      // Comparison
      prec.left(4, seq($._expression, '==', $._expression)),
      prec.left(4, seq($._expression, '!=', $._expression)),
      prec.left(4, seq($._expression, '<', $._expression)),
      prec.left(4, seq($._expression, '>', $._expression)),
      prec.left(4, seq($._expression, '<=', $._expression)),
      prec.left(4, seq($._expression, '>=', $._expression)),
      
      // Logical
      prec.left(5, seq($._expression, '&&', $._expression)),
      prec.left(6, seq($._expression, '||', $._expression)),
    ),

    unary_expression: $ => choice(
      prec(7, seq('-', $._expression)),
      prec(7, seq('+', $._expression)),
      prec(7, seq('!', $._expression)),
    ),

    call_expression: $ => seq(
      field('function', $._expression),
      '(',
      optional($.argument_list),
      ')'
    ),

    argument_list: $ => seq(
      $._expression,
      repeat(seq(',', $._expression)),
      optional(',')
    ),

    array_expression: $ => seq(
      '[',
      optional(seq(
        $._expression,
        repeat(seq(',', $._expression)),
        optional(',')
      )),
      ']'
    ),

    parenthesized_expression: $ => seq('(', $._expression, ')'),

    assignment: $ => seq(
      field('left', $._expression),
      '=',
      field('right', $._expression)
    ),

    function_definition: $ => seq(
      'function',
      field('name', $.identifier),
      '(',
      optional($.parameter_list),
      ')',
      optional($.block),
      'end'
    ),

    parameter_list: $ => seq(
      $.identifier,
      repeat(seq(',', $.identifier))
    ),

    block: $ => repeat1($._statement),

    if_statement: $ => seq(
      'if',
      field('condition', $._expression),
      optional($.block),
      repeat($.elseif_clause),
      optional($.else_clause),
      'end'
    ),

    elseif_clause: $ => seq(
      'elseif',
      field('condition', $._expression),
      optional($.block)
    ),

    else_clause: $ => seq(
      'else',
      optional($.block)
    ),

    for_statement: $ => seq(
      'for',
      field('iterator', $.identifier),
      'in',
      field('iterable', $._expression),
      optional($.block),
      'end'
    ),

    while_statement: $ => seq(
      'while',
      field('condition', $._expression),
      optional($.block),
      'end'
    ),
  }
});
"""

grammar_path = joinpath(BUILD_DIR, "grammar.js")
open(grammar_path, "w") do f
    write(f, grammar_js)
end
println("   Generated: $grammar_path")

# Step 4: Compile instructions
println("\n4. Compilation Instructions")
println("   To compile the scanner with gcc:")
println("   ```")
julia_include = joinpath(Sys.BINDIR, "..", "include", "julia")
julia_lib = joinpath(Sys.BINDIR, "..", "lib")
println("   gcc -shared -fPIC $wrapper_path -o scanner.so \\")
println("       -I$julia_include \\")
println("       -L$julia_lib -ljulia \\")
println("       -Wl,-rpath,$julia_lib")
println("   ```")

println("\n5. For use with tree-sitter:")
println("   a) Install tree-sitter: npm install -g tree-sitter-cli")
println("   b) Copy grammar.js to your tree-sitter-julia directory")
println("   c) Run: tree-sitter generate")
println("   d) Link with the scanner library when building")

println("\nBuild preparation complete!")
println("All files generated in: $BUILD_DIR")