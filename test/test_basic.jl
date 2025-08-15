using Med7
using Test

@testset "Basic Structure Tests" begin
    @testset "Module Loading" begin
        @test isdefined(Med7, :Med7Model)
        @test isdefined(Med7, :Entity)
        @test isdefined(Med7, :Doc)
        @test isdefined(Med7, :ENTITY_TYPES)
        @test isdefined(Med7, :FALLBACK_MODELS)
    end
    
    @testset "Entity Types" begin
        @test "DRUG" in Med7.ENTITY_TYPES
        @test "DOSAGE" in Med7.ENTITY_TYPES
        @test "FREQUENCY" in Med7.ENTITY_TYPES
        @test length(Med7.ENTITY_TYPES) == 7
    end
    
    @testset "Fallback Models" begin
        @test length(Med7.FALLBACK_MODELS) >= 3
        @test "kormilitzin/en_core_med7_lg" in Med7.FALLBACK_MODELS
    end
    
    @testset "Entity Creation" begin
        entity = Med7.Entity(1, 5, "DRUG", "test")
        @test entity.start == 1
        @test entity.stop == 5
        @test entity.label == "DRUG"
        @test entity.text == "test"
    end
    
    @testset "Doc Creation" begin
        entities = [Med7.Entity(1, 4, "DRUG", "test")]
        doc = Med7.Doc("test text", entities)
        @test doc.text == "test text"
        @test length(doc.ents) == 1
        @test doc.ents[1].label == "DRUG"
    end
end