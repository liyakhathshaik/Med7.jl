# Minimal test to check basic functionality
using MediSeven
using Test

println("Testing Med7 module loading...")

@testset "Minimal Tests" begin
    @testset "Module Constants" begin
        @test isdefined(Med7, :ENTITY_TYPES)
        @test isdefined(Med7, :FALLBACK_MODELS)
        @test typeof(MediSeven.ENTITY_TYPES) == Vector{String}
        @test typeof(MediSeven.FALLBACK_MODELS) == Vector{String}
    end
    
    @testset "Struct Definitions" begin
        # Test Entity struct
        entity = MediSeven.Entity(1, 5, "DRUG", "test")
        @test entity.start == 1
        @test entity.stop == 5
        @test entity.label == "DRUG"
        @test entity.text == "test"
        
        # Test Doc struct
        doc = MediSeven.Doc("test text", [entity])
        @test doc.text == "test text"
        @test length(doc.ents) == 1
    end
    
    @testset "Model Loading (Basic)" begin
        model = MediSeven.load_model(batch_size=1)
        @test typeof(model) == MediSeven.Med7Model
        @test model.batch_size == 1
    end
    
    @testset "Simple Processing" begin
        model = MediSeven.load_model()
        doc = model("test")
        @test typeof(doc) == MediSeven.Doc
        @test typeof(doc.ents) == Vector{MediSeven.Entity}
    end
end