using MediSeven
using Test

@testset "Fallback Functionality Tests" begin
    @testset "Pattern-Only Model" begin
        # Create model with no spaCy backend (simulates spaCy unavailable)
        fallback_model = MediSeven.MediSevenModel(nothing, 1)
        
        @testset "Drug Detection Fallback" begin
            # Test all drug patterns individually
            for pattern in MediSeven.DRUG_PATTERNS
                # Test some drugs that should match this pattern
                test_drugs = ["amoxicillin", "azithromycin", "lisinopril", "losartan", 
                             "simvastatin", "omeprazole", "rituximab", "aspirin", 
                             "ibuprofen", "acetaminophen", "warfarin", "metformin", "insulin"]
                
                for drug in test_drugs
                    if occursin(pattern, drug)
                        doc = fallback_model("Patient takes $drug daily")
                        drug_entities = filter(e -> e.label == "DRUG", doc.ents)
                        @test length(drug_entities) >= 1
                    end
                end
            end
        end
        
        @testset "Dosage Detection Fallback" begin
            dosage_tests = [
                "10mg", "2.5g", "100ml", "50mcg", "5units", "1000iu",
                "0.5mg", "999g", "1.234ml", "10 units", "500 mg"
            ]
            
            for dosage in dosage_tests
                doc = fallback_model("Take $dosage daily")
                dosage_entities = filter(e -> e.label == "DOSAGE", doc.ents)
                @test length(dosage_entities) >= 1
            end
        end
        
        @testset "Frequency Detection Fallback" begin
            freq_tests = [
                "daily", "BID", "TID", "QID", "q4h", "q12h", "once", "twice",
                "three times", "morning", "evening", "bedtime", "as needed", "PRN"
            ]
            
            for freq in freq_tests
                doc = fallback_model("Take medication $freq")
                freq_entities = filter(e -> e.label == "FREQUENCY", doc.ents)
                @test length(freq_entities) >= 1
            end
        end
    end
    
    @testset "Batch Processing Fallback" begin
        fallback_model = MediSeven.MediSevenModel(nothing, 3)
        
        texts = [
            "Take aspirin 81mg daily",
            "Administer insulin 10units BID", 
            "Use ibuprofen 200mg PRN pain",
            "Apply ointment twice daily",
            "Give warfarin 5mg at bedtime"
        ]
        
        docs = fallback_model(texts)
        @test length(docs) == 5
        @test all(doc -> typeof(doc) == MediSeven.Doc, docs)
        
        # Check that entities were found
        total_entities = sum(length(doc.ents) for doc in docs)
        @test total_entities > 0
    end
    
    @testset "Model Loading Fallback Behavior" begin
        # Test that load_model returns a valid model even if spaCy fails
        model = MediSeven.load_model(batch_size=5)
        @test typeof(model) == MediSeven.MediSevenModel
        @test model.batch_size == 5
        
        # Test with different batch sizes
        for batch_size in [1, 2, 10, 100]
            model = MediSeven.load_model(batch_size=batch_size)
            @test model.batch_size == batch_size
        end
    end
    
    @testset "Simple Tokenization Function" begin
        # Test the simple_tokenize function
        @test MediSeven.simple_tokenize("hello world") == ["hello", "world"]
        @test MediSeven.simple_tokenize("take, 10mg; daily!") == ["take", "10mg", "daily"]
        @test MediSeven.simple_tokenize("") == String[]
        @test MediSeven.simple_tokenize("   ") == String[]
        @test MediSeven.simple_tokenize("word") == ["word"]
        @test MediSeven.simple_tokenize("a,b.c!d?e") == ["a", "b", "c", "d", "e"]
        
        # Test with medical text
        medical_tokens = MediSeven.simple_tokenize("Take 500mg ibuprofen twice daily.")
        @test "Take" in medical_tokens
        @test "500mg" in medical_tokens
        @test "ibuprofen" in medical_tokens
        @test "twice" in medical_tokens
        @test "daily" in medical_tokens
    end
end