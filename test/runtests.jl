using Med7
using Test
using Random

# Include sample medical texts
include("sample_texts.jl")

@testset "Core Functionality" begin
    model = Med7.load_model(; batch_size=4)
    
    @testset "Model Loading" begin
        @test typeof(model) == Med7.Med7Model
        @test model.batch_size == 4
        @test haskey(model.id2label, 0)
    end
    
    @testset "Single Text Processing" begin
        doc = model("Administer 500mg paracetamol every 6 hours PRN")
        @test length(doc.ents) >= 3
        @test any(e -> e.label == "DRUG" && contains(e.text, "paracetamol"), doc.ents)
    end
    
    @testset "Batch Processing" begin
        texts = [
            "Take 1 tablet aspirin daily",
            "Apply 0.1% tacrolimus ointment BID",
            "Inject 40mg enoxaparin SC daily"
        ]
        docs = model(texts)
        
        @test length(docs) == 3
        # Check that entities are found, but don't assume specific order
        @test any(e -> e.label in ["DOSAGE", "DRUG", "FREQUENCY"], docs[1].ents)
        @test any(e -> e.label in ["DOSAGE", "DRUG", "FREQUENCY"], docs[2].ents)
        @test any(e -> e.label in ["DOSAGE", "DRUG", "FREQUENCY"], docs[3].ents)
    end
    
    @testset "Edge Cases" begin
        @test isempty(model("").ents)
        @test isempty(model("Normal progress note").ents)
        
        # Test mixed case and punctuation
        mixed = model("Patient on ATORVASTATIN 20mg QD, lisinopril 10mg OD")
        @test length(mixed.ents) >= 4
    end
end

@testset "Performance Sanity Checks" begin
    model = Med7.load_model()
    text = "Prescribe " * join(["100mg ibuprofen TID", "50mg atenolol daily", "200mg celecoxib BID"], ". ") 
    
    @time doc = model(text)
    @test length(doc.ents) >= 6
    
    texts = fill(text, 10)
    @time docs = model(texts)
    @test length(docs) == 10
end

@testset "Randomized Stress Testing" begin
    model = Med7.load_model()
    drugs = ["aspirin", "metformin", "warfarin", "simvastatin"]
    doses = ["10mg", "25mg", "50mg", "100mg"]
    freqs = ["daily", "BID", "TID", "QID"]
    
    for _ in 1:10
        text = "Take $(rand(doses)) $(rand(drugs)) $(rand(freqs))"
        doc = model(text)
        @test length(doc.ents) >= 2
    end
end