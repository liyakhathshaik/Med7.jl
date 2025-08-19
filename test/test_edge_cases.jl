using MediSeven
using Test

@testset "Edge Cases and Error Handling" begin
    model = MediSeven.load_model(batch_size=2)
    
    @testset "Empty and Invalid Inputs" begin
        # Empty string
        doc_empty = model("")
        @test typeof(doc_empty) == MediSeven.Doc
        @test doc_empty.text == ""
        @test length(doc_empty.ents) == 0
        
        # Whitespace only
        doc_space = model("   \n\t   ")
        @test typeof(doc_space) == MediSeven.Doc
        @test length(doc_space.ents) == 0
        
        # Single character
        doc_char = model("a")
        @test typeof(doc_char) == MediSeven.Doc
        
        # Very long string
        long_text = repeat("Take aspirin daily. ", 1000)
        doc_long = model(long_text)
        @test typeof(doc_long) == MediSeven.Doc
        @test length(doc_long.ents) > 0
    end
    
    @testset "Special Characters and Unicode" begin
        # Text with special characters
        special_text = "Take 5mg α-blocker β-agonist daily!"
        doc_special = model(special_text)
        @test typeof(doc_special) == MediSeven.Doc
        
        # Text with numbers and symbols
        symbols_text = "Dose: 10mg @ 8AM & 6PM (2x daily) [PRN]"
        doc_symbols = model(symbols_text)
        @test typeof(doc_symbols) == MediSeven.Doc
        
        # Unicode characters
        unicode_text = "Prescribir 500mg paracetamol diariamente"
        doc_unicode = model(unicode_text)
        @test typeof(doc_unicode) == MediSeven.Doc
    end
    
    @testset "Batch Processing Edge Cases" begin
        # Empty batch
        empty_batch = String[]
        docs_empty = model(empty_batch)
        @test length(docs_empty) == 0
        
        # Single item batch
        single_batch = ["Take aspirin daily"]
        docs_single = model(single_batch)
        @test length(docs_single) == 1
        @test typeof(docs_single[1]) == MediSeven.Doc
        
        # Mixed content batch
        mixed_batch = [
            "",
            "Normal text without medical terms",
            "Take 10mg lisinopril daily",
            "   ",
            "Complex: 500mg acetaminophen q6h PRN pain"
        ]
        docs_mixed = model(mixed_batch)
        @test length(docs_mixed) == 5
        @test all(doc -> typeof(doc) == MediSeven.Doc, docs_mixed)
    end
    
    @testset "Boundary Conditions" begin
        # Text exactly at entity boundaries
        boundary_text = "aspirin"  # Just a drug name
        doc_boundary = model(boundary_text)
        @test typeof(doc_boundary) == MediSeven.Doc
        
        # Overlapping patterns
        overlap_text = "Take aspirin 500mg daily PRN"  # Multiple overlapping entities
        doc_overlap = model(overlap_text)
        @test typeof(doc_overlap) == MediSeven.Doc
        @test length(doc_overlap.ents) > 0
    end
    
    @testset "Case Sensitivity Tests" begin
        cases = [
            "ASPIRIN 10MG DAILY",
            "aspirin 10mg daily", 
            "Aspirin 10Mg Daily",
            "AsPiRiN 10mG dAiLy"
        ]
        
        for text in cases
            doc = model(text)
            @test typeof(doc) == MediSeven.Doc
            # Should find entities regardless of case
            @test length(doc.ents) > 0
        end
    end
    
    @testset "Numeric Edge Cases" begin
        # Very small doses
        doc_small = model("Take 0.001mg daily")
        @test typeof(doc_small) == MediSeven.Doc
        
        # Large doses
        doc_large = model("Administer 9999mg immediately")
        @test typeof(doc_large) == MediSeven.Doc
        
        # Doses with many decimal places
        doc_decimal = model("Use 2.56789mg per dose")
        @test typeof(doc_decimal) == MediSeven.Doc
    end
end