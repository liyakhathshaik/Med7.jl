using MediSeven
using Test

@testset "Basic Structure Tests" begin
    @testset "Module Loading" begin
        @test isdefined(MediSeven, :MediSevenModel)
        @test isdefined(MediSeven, :Entity)
        @test isdefined(MediSeven, :Doc)
        @test isdefined(MediSeven, :ENTITY_TYPES)
        @test isdefined(MediSeven, :FALLBACK_MODELS)
    end
    
    @testset "Entity Types" begin
        @test "DRUG" in MediSeven.ENTITY_TYPES
        @test "DOSAGE" in MediSeven.ENTITY_TYPES
        @test "FREQUENCY" in MediSeven.ENTITY_TYPES
        @test length(MediSeven.ENTITY_TYPES) == 7
    end
    
    @testset "Fallback Models" begin
        @test length(MediSeven.FALLBACK_MODELS) >= 3
        @test "kormilitzin/en_core_med7_lg" in MediSeven.FALLBACK_MODELS
    end
    
    @testset "Entity Creation" begin
        entity = MediSeven.Entity(1, 5, "DRUG", "test")
        @test entity.start == 1
        @test entity.stop == 5
        @test entity.label == "DRUG"
        @test entity.text == "test"
    end
    
    @testset "Doc Creation" begin
        entities = [MediSeven.Entity(1, 4, "DRUG", "test")]
        doc = MediSeven.Doc("test text", entities)
        @test doc.text == "test text"
        @test length(doc.ents) == 1
        @test doc.ents[1].label == "DRUG"
    end
end