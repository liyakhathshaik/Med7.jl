# Minimal test to check basic functionality
using Med7
using Test

println("Testing Med7 module loading...")

@testset "Minimal Tests" begin
    @testset "Module Constants" begin
        @test isdefined(Med7, :ENTITY_TYPES)
        @test isdefined(Med7, :FALLBACK_MODELS)
        @test typeof(Med7.ENTITY_TYPES) == Vector{String}
        @test typeof(Med7.FALLBACK_MODELS) == Vector{String}
    end
    
    @testset "Struct Definitions" begin
        # Test Entity struct
        entity = Med7.Entity(1, 5, "DRUG", "test")
        @test entity.start == 1
        @test entity.stop == 5
        @test entity.label == "DRUG"
        @test entity.text == "test"
        
        # Test Doc struct
        doc = Med7.Doc("test text", [entity])
        @test doc.text == "test text"
        @test length(doc.ents) == 1
    end
    
    @testset "Model Loading (Basic)" begin
        model = Med7.load_model(batch_size=1)
        @test typeof(model) == Med7.Med7Model
        @test model.batch_size == 1
    end
    
    @testset "Simple Processing" begin
        model = Med7.load_model()
        doc = model("test")
        @test typeof(doc) == Med7.Doc
        @test typeof(doc.ents) == Vector{Med7.Entity}
    end
end