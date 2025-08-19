using MediSeven
using Test
using Random

@testset "Performance and Stress Tests" begin
    @testset "Batch Size Performance" begin
        text_base = "Take aspirin 81mg daily with food"
        
        # Test different batch sizes
        batch_sizes = [1, 2, 5, 10, 20]
        texts = fill(text_base, 20)
        
        for batch_size in batch_sizes
            model = MediSeven.load_model(batch_size=batch_size)
            
            # Time the batch processing
            start_time = time()
            docs = model(texts)
            end_time = time()
            
            @test length(docs) == 20
            @test all(doc -> typeof(doc) == MediSeven.Doc, docs)
            @test (end_time - start_time) < 30.0  # Should complete within 30 seconds
        end
    end
    
    @testset "Large Text Processing" begin
        model = MediSeven.load_model()
        
        # Generate large medical text
        base_sentences = [
            "Patient takes aspirin 81mg daily.",
            "Prescribed metformin 500mg twice daily.", 
            "Apply topical cream BID to affected area.",
            "Administer insulin 10 units before meals.",
            "Continue warfarin 5mg daily with monitoring."
        ]
        
        # Test progressively larger texts
        for multiplier in [10, 50, 100, 200]
            large_text = join(repeat(base_sentences, multiplier), " ")
            
            start_time = time()
            doc = model(large_text)
            end_time = time()
            
            @test typeof(doc) == MediSeven.Doc
            @test doc.text == large_text
            @test length(doc.ents) > 0
            @test (end_time - start_time) < 60.0  # Should complete within 60 seconds
        end
    end
    
    @testset "Memory Usage Stress Test" begin
        model = MediSeven.load_model(batch_size=10)
        
        # Create many small batches to test memory management
        for batch_num in 1:50
            texts = [
                "Take medication $(rand(10:100))mg $(rand(["daily", "BID", "TID"]))",
                "Apply cream $(rand(["once", "twice", "three times"])) daily",
                "Use $(rand(["aspirin", "ibuprofen", "acetaminophen"])) PRN pain"
            ]
            
            docs = model(texts)
            @test length(docs) == 3
            @test all(doc -> typeof(doc) == MediSeven.Doc, docs)
        end
    end
    
    @testset "Concurrent Processing Simulation" begin
        model = MediSeven.load_model(batch_size=5)
        
        # Simulate multiple concurrent requests
        all_docs = []
        
        for i in 1:20
            texts = [
                "Patient $i takes aspirin 81mg daily",
                "Prescription $i: metformin 500mg BID", 
                "Treatment $i: apply cream twice daily"
            ]
            
            docs = model(texts)
            push!(all_docs, docs...)
        end
        
        @test length(all_docs) == 60
        @test all(doc -> typeof(doc) == MediSeven.Doc, all_docs)
    end
    
    @testset "Random Input Stress Test" begin
        model = MediSeven.load_model()
        Random.seed!(42)  # For reproducibility
        
        # Test with random medical combinations
        drugs = ["aspirin", "metformin", "lisinopril", "warfarin", "insulin", "ibuprofen"]
        doses = ["5mg", "10mg", "25mg", "50mg", "100mg", "500mg", "1000mg"]
        frequencies = ["daily", "BID", "TID", "QID", "PRN", "q6h", "q8h"]
        
        for _ in 1:100
            # Generate random medical text
            drug = rand(drugs)
            dose = rand(doses)
            freq = rand(frequencies)
            text = "Take $dose $drug $freq"
            
            doc = model(text)
            @test typeof(doc) == MediSeven.Doc
            @test doc.text == text
            @test typeof(doc.ents) == Vector{MediSeven.Entity}
        end
    end
    
    @testset "Edge Case Stress Test" begin
        model = MediSeven.load_model()
        
        # Test various edge cases that might cause issues
        edge_cases = [
            "",  # Empty
            " ",  # Single space
            "\n\t",  # Whitespace chars
            "a",  # Single char
            repeat("a", 10000),  # Very long single word
            repeat("aspirin 10mg daily. ", 1000),  # Repetitive medical text
            "🏥💊 Take medicine 💉",  # Unicode/emoji
            "Take 0.000001mg daily",  # Very small numbers
            "Administer 99999999mg immediately",  # Very large numbers
            "Drug: α-blocker β-agonist γ-rays",  # Greek letters
            string(rand(UInt8, 1000)...),  # Random bytes (might be invalid UTF-8, but should not crash)
        ]
        
        for edge_case in edge_cases
            try
                doc = model(edge_case)
                @test typeof(doc) == MediSeven.Doc
            catch e
                # If there's an exception, it should be a reasonable one, not a crash
                @test e isa Union{ArgumentError, BoundsError, StringIndexError}
            end
        end
    end
    
    @testset "Batch Edge Cases" begin
        model = MediSeven.load_model(batch_size=3)
        
        # Empty batch
        @test length(model(String[])) == 0
        
        # Single item
        @test length(model(["test"])) == 1
        
        # Batch larger than batch_size
        large_batch = fill("aspirin daily", 10)
        docs = model(large_batch)
        @test length(docs) == 10
        
        # Mixed content batch
        mixed = ["", "aspirin", "very long text " * repeat("word ", 100), "🔥"]
        mixed_docs = model(mixed)
        @test length(mixed_docs) == 4
    end
end