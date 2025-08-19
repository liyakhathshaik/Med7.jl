using MediSeven
using Test

@testset "Pattern Matching Tests" begin
    # Test with pattern-only model (no spaCy)
    model = MediSeven.MediSevenModel(nothing, 1)
    
    @testset "Drug Pattern Detection" begin
        # Test drug suffix patterns
        doc1 = model("Patient takes amoxicillin for infection")
        drug_ents = filter(e -> e.label == "DRUG", doc1.ents)
        @test length(drug_ents) >= 1
        @test any(e -> occursin("amoxicillin", e.text), drug_ents)
        
        # Test multiple drug patterns
        doc2 = model("Prescribed azithromycin and lisinopril together")
        drug_ents2 = filter(e -> e.label == "DRUG", doc2.ents)
        @test length(drug_ents2) >= 2
        
        # Test common drug names
        doc3 = model("Take aspirin and ibuprofen as needed")
        drug_ents3 = filter(e -> e.label == "DRUG", doc3.ents)
        @test length(drug_ents3) >= 2
        
        # Test case insensitivity
        doc4 = model("WARFARIN and Metformin prescribed")
        drug_ents4 = filter(e -> e.label == "DRUG", doc4.ents)
        @test length(drug_ents4) >= 2
        
        # Test drug patterns with various suffixes
        suffixes = ["penicillin", "erythromycin", "enalapril", "losartan", "simvastatin", "omeprazole", "rituximab"]
        for suffix in suffixes
            doc = model("Patient on $suffix treatment")
            drug_ents = filter(e -> e.label == "DRUG", doc.ents)
            @test length(drug_ents) >= 1
        end
    end
    
    @testset "Dosage Pattern Detection" begin
        # Test various dosage formats
        dosage_texts = [
            "Take 500mg twice daily",
            "Administer 2.5g every morning", 
            "Apply 10ml topically",
            "Inject 100mcg subcutaneously",
            "Give 20 units before meals",
            "Use 1000iu daily"
        ]
        
        for text in dosage_texts
            doc = model(text)
            dosage_ents = filter(e -> e.label == "DOSAGE", doc.ents)
            @test length(dosage_ents) >= 1
        end
        
        # Test decimal dosages
        doc_decimal = model("Prescribe 0.25mg daily")
        dosage_ents = filter(e -> e.label == "DOSAGE", doc_decimal.ents)
        @test length(dosage_ents) >= 1
        
        # Test multiple dosages in one text
        doc_multiple = model("Take 10mg in morning and 5mg at night")
        dosage_ents = filter(e -> e.label == "DOSAGE", doc_multiple.ents)
        @test length(dosage_ents) >= 2
    end
    
    @testset "Frequency Pattern Detection" begin
        # Test standard frequencies
        freq_texts = [
            "Take medication daily",
            "Administer BID",
            "Give TID as needed",
            "Use QID for severe symptoms",
            "Apply q8h",
            "Take once in morning",
            "Use twice daily",
            "Give three times per day"
        ]
        
        for text in freq_texts
            doc = model(text)
            freq_ents = filter(e -> e.label == "FREQUENCY", doc.ents)
            @test length(freq_ents) >= 1
        end
        
        # Test time-specific frequencies
        time_texts = [
            "Take in the morning",
            "Use at bedtime", 
            "Give in evening",
            "Take as needed",
            "Use PRN for pain"
        ]
        
        for text in time_texts
            doc = model(text)
            freq_ents = filter(e -> e.label == "FREQUENCY", doc.ents)
            @test length(freq_ents) >= 1
        end
    end
    
    @testset "Multiple Entity Types" begin
        # Test text with multiple entity types
        complex_text = "Take 500mg ibuprofen twice daily as needed"
        doc = model(complex_text)
        
        @test length(doc.ents) >= 3  # Should find drug, dosage, and frequency
        
        labels = [e.label for e in doc.ents]
        @test "DRUG" in labels
        @test "DOSAGE" in labels  
        @test "FREQUENCY" in labels
    end
    
    @testset "Entity Position Accuracy" begin
        text = "Patient takes 10mg aspirin daily"
        doc = model(text)
        
        for entity in doc.ents
            # Check that entity positions are valid
            @test entity.start >= 1
            @test entity.stop >= entity.start
            @test entity.stop <= length(text)
            
            # Check that extracted text matches position
            extracted = text[entity.start:entity.stop]
            @test entity.text == extracted
        end
    end
end