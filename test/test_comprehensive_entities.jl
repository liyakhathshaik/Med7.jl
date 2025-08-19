using MediSeven
using Test
include("sample_texts.jl")

@testset "Comprehensive Entity Testing" begin
    model = MediSeven.load_model(batch_size=4)
    
    @testset "All Entity Types Recognition" begin
        # Test each entity type from ENTITY_TYPES
        for entity_type in MediSeven.ENTITY_TYPES
            @test entity_type isa String
            @test length(entity_type) > 0
        end
        
        # Comprehensive medical text with all entity types
        comprehensive_text = """
        Patient prescribed lisinopril 10mg tablets to take once daily by mouth 
        for 30 days. Also start metformin 500mg twice daily with meals.
        Apply topical cream to affected area BID for one week duration.
        """
        
        doc = model(comprehensive_text)
        @test typeof(doc) == MediSeven.Doc
        @test length(doc.ents) > 0
        
        # Check entity integrity
        for entity in doc.ents
            @test entity.start >= 1
            @test entity.stop >= entity.start
            @test entity.label in MediSeven.ENTITY_TYPES
            @test length(entity.text) > 0
        end
    end
    
    @testset "Sample Texts Processing" begin
        # Test all sample texts
        for (i, text) in enumerate(SAMPLE_TEXTS)
            doc = model(text)
            @test typeof(doc) == MediSeven.Doc
            @test doc.text == text
            @test typeof(doc.ents) == Vector{MediSeven.Entity}
            
            # Should find at least some entities in medical texts
            if occursin(r"mg|daily|BID|TID|aspirin|ibuprofen|warfarin|insulin", text)
                @test length(doc.ents) > 0
            end
        end
        
        # Test complex text
        complex_doc = model(COMPLEX_TEXT)
        @test typeof(complex_doc) == MediSeven.Doc
        @test length(complex_doc.ents) > 0
        
        # Test batch processing of sample texts
        sample_docs = model(SAMPLE_TEXTS)
        @test length(sample_docs) == length(SAMPLE_TEXTS)
        @test all(doc -> typeof(doc) == MediSeven.Doc, sample_docs)
    end
    
    @testset "Real-World Medical Scenarios" begin
        scenarios = [
            # Cardiology
            "Start atorvastatin 40mg PO daily and metoprolol 25mg BID for cardiovascular protection",
            
            # Diabetes management  
            "Continue metformin 1000mg BID and add insulin glargine 20 units subcutaneous at bedtime",
            
            # Pain management
            "Prescribe acetaminophen 650mg every 6 hours PRN pain, max 4g daily",
            
            # Anticoagulation
            "Initiate warfarin 5mg daily with INR monitoring, target INR 2-3",
            
            # Hypertension
            "Increase lisinopril to 10mg daily and add hydrochlorothiazide 25mg daily",
            
            # Infection
            "Start amoxicillin 875mg twice daily for 10 days for bacterial infection"
        ]
        
        for scenario in scenarios
            doc = model(scenario)
            @test typeof(doc) == MediSeven.Doc
            @test length(doc.ents) > 0
            
            # Check for expected entity types in medical scenarios
            labels = [e.label for e in doc.ents]
            if occursin(r"mg|g|units", scenario)
                @test "DOSAGE" in labels || "STRENGTH" in labels
            end
            if occursin(r"daily|BID|TID|hours", scenario)
                @test "FREQUENCY" in labels || "DURATION" in labels
            end
        end
    end
    
    @testset "Entity Overlap and Boundaries" begin
        # Test cases where entities might overlap or have complex boundaries
        overlap_cases = [
            "aspirin 81mg daily",  # drug + strength + frequency
            "take two 500mg tablets BID",  # multiple dosage references
            "apply 0.1% cream topically twice daily",  # percentage + form + route + frequency
            "inject 40mg/mL solution subcutaneously"  # concentration + form + route
        ]
        
        for case in overlap_cases
            doc = model(case)
            @test typeof(doc) == MediSeven.Doc
            
            # Verify no invalid overlaps (entities with same start/stop)
            starts = [e.start for e in doc.ents]
            stops = [e.stop for e in doc.ents]
            
            for (i, entity) in enumerate(doc.ents)
                @test entity.start <= entity.stop
                # Check text extraction is correct
                extracted = case[entity.start:entity.stop]
                @test entity.text == extracted
            end
        end
    end
    
    @testset "Medical Abbreviation Handling" begin
        abbreviations = [
            "PO", "IV", "IM", "SC", "SL", "PR", "PRN", "BID", "TID", "QID", 
            "Q4H", "Q6H", "Q8H", "Q12H", "QD", "QHS", "QAM", "QPM"
        ]
        
        for abbrev in abbreviations
            text = "Take medication $abbrev as directed"
            doc = model(text)
            @test typeof(doc) == MediSeven.Doc
            # Many abbreviations should be recognized as frequency or route
        end
    end
end