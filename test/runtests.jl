using Test
using TreeSitterJulia
using JuliaSyntax

@testset "TreeSitterJulia.jl" begin
    @testset "Token Mapping" begin
        # Test basic token mapping
        @test TreeSitterJulia.kind_to_ts_token(K"Identifier") == :IDENTIFIER
        @test TreeSitterJulia.kind_to_ts_token(K"function") == :FUNCTION
        @test TreeSitterJulia.kind_to_ts_token(K"Integer") == :INTEGER_LITERAL
        @test TreeSitterJulia.kind_to_ts_token(K"String") == :STRING_LITERAL
        
        # Test operator precedence mapping
        @test TreeSitterJulia.kind_to_ts_token(K"Operator", PREC_PLUS) == :OP_PREC_PLUS
        @test TreeSitterJulia.kind_to_ts_token(K"Operator", PREC_TIMES) == :OP_PREC_TIMES
        @test TreeSitterJulia.kind_to_ts_token(K"Operator", PREC_POWER) == :OP_PREC_POWER
    end
    
    @testset "Scanner Lifecycle" begin
        # Test scanner creation/destruction
        scanner = TreeSitterJulia.create_scanner()
        @test scanner != C_NULL
        
        # Test serialization
        buffer = zeros(UInt8, 100)
        size = TreeSitterJulia.serialize_scanner(scanner, pointer(buffer))
        @test size > 0
        
        # Test deserialization
        TreeSitterJulia.deserialize_scanner(scanner, pointer(buffer), size)
        
        # Clean up
        TreeSitterJulia.destroy_scanner(scanner)
    end
    
    @testset "Token Generation" begin
        # Test C header generation
        header = TreeSitterJulia.generate_c_header()
        @test occursin("enum TokenType", header)
        @test occursin("IDENTIFIER", header)
        @test occursin("OP_PREC_PLUS", header)
    end
end