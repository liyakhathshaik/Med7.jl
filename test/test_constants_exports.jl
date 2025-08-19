using MediSeven
using Test

@testset "Constants and Exports Tests" begin
    @testset "Module Exports" begin
        # Test that all expected symbols are exported
        exported_symbols = names(MediSeven)
        
        @test :MediSevenModel in exported_symbols
        @test :load_model in exported_symbols
        @test :Entity in exported_symbols
        @test :Doc in exported_symbols
        @test :ENTITY_TYPES in exported_symbols
        @test :FALLBACK_MODELS in exported_symbols
    end
    
    @testset "ENTITY_TYPES Constant" begin
        @test typeof(MediSeven.ENTITY_TYPES) == Vector{String}
        @test length(MediSeven.ENTITY_TYPES) == 7
        
        # Test all expected entity types
        expected_types = ["DRUG", "STRENGTH", "DOSAGE", "DURATION", "FREQUENCY", "FORM", "ROUTE"]
        for expected_type in expected_types
            @test expected_type in MediSeven.ENTITY_TYPES
        end
        
        # Test no duplicates
        @test length(MediSeven.ENTITY_TYPES) == length(unique(MediSeven.ENTITY_TYPES))
        
        # Test all are uppercase strings
        for entity_type in MediSeven.ENTITY_TYPES
            @test entity_type == uppercase(entity_type)
            @test length(entity_type) > 0
        end
    end
    
    @testset "FALLBACK_MODELS Constant" begin
        @test typeof(MediSeven.FALLBACK_MODELS) == Vector{String}
        @test length(MediSeven.FALLBACK_MODELS) >= 5
        
        # Test expected models are present
        expected_models = [
            "kormilitzin/en_core_med7_lg",
            "en_core_med7_lg", 
            "en_core_web_sm",
            "en_core_web_md",
            "en_core_web_lg"
        ]
        
        for expected_model in expected_models
            @test expected_model in MediSeven.FALLBACK_MODELS
        end
        
        # Test no duplicates
        @test length(MediSeven.FALLBACK_MODELS) == length(unique(MediSeven.FALLBACK_MODELS))
        
        # Test all are non-empty strings
        for model in MediSeven.FALLBACK_MODELS
            @test typeof(model) == String
            @test length(model) > 0
        end
    end
    
    @testset "Pattern Constants" begin
        # Test DRUG_PATTERNS
        @test isdefined(MediSeven, :DRUG_PATTERNS)
        @test typeof(MediSeven.DRUG_PATTERNS) == Vector{Regex}
        @test length(MediSeven.DRUG_PATTERNS) >= 2
        
        # Test patterns work
        for pattern in MediSeven.DRUG_PATTERNS
            @test typeof(pattern) == Regex
        end
        
        # Test DOSAGE_PATTERNS  
        @test isdefined(MediSeven, :DOSAGE_PATTERNS)
        @test typeof(MediSeven.DOSAGE_PATTERNS) == Vector{Regex}
        @test length(MediSeven.DOSAGE_PATTERNS) >= 1
        
        # Test FREQUENCY_PATTERNS
        @test isdefined(MediSeven, :FREQUENCY_PATTERNS)
        @test typeof(MediSeven.FREQUENCY_PATTERNS) == Vector{Regex}
        @test length(MediSeven.FREQUENCY_PATTERNS) >= 2
    end
    
    @testset "Pattern Functionality" begin
        # Test drug patterns catch expected drugs
        drug_tests = [
            ("amoxicillin", true),
            ("azithromycin", true), 
            ("lisinopril", true),
            ("losartan", true),
            ("simvastatin", true),
            ("omeprazole", true),
            ("rituximab", true),
            ("aspirin", true),
            ("ibuprofen", true),
            ("acetaminophen", true),
            ("warfarin", true),
            ("metformin", true),
            ("insulin", true),
            ("randomword", false),
            ("notadrug", false)
        ]
        
        for (word, should_match) in drug_tests
            matches = any(pattern -> occursin(pattern, word), MediSeven.DRUG_PATTERNS)
            if should_match
                @test matches
            end
        end
        
        # Test dosage patterns
        dosage_tests = [
            ("10mg", true),
            ("2.5g", true),
            ("100ml", true),
            ("50mcg", true),
            ("5units", true),
            ("1000iu", true),
            ("notadose", false),
            ("randomtext", false)
        ]
        
        for (text, should_match) in dosage_tests
            matches = any(pattern -> occursin(pattern, text), MediSeven.DOSAGE_PATTERNS)
            if should_match
                @test matches
            end
        end
        
        # Test frequency patterns
        freq_tests = [
            ("daily", true),
            ("BID", true),
            ("TID", true),
            ("QID", true),
            ("q8h", true),
            ("once", true),
            ("twice", true),
            ("three times", true),
            ("morning", true),
            ("evening", true),
            ("bedtime", true),
            ("as needed", true),
            ("PRN", true),
            ("randomtext", false)
        ]
        
        for (text, should_match) in freq_tests
            matches = any(pattern -> occursin(pattern, text), MediSeven.FREQUENCY_PATTERNS)
            if should_match
                @test matches
            end
        end
    end
    
    @testset "Struct Constructors" begin
        # Test Entity constructor
        entity = MediSeven.Entity(1, 10, "DRUG", "aspirin")
        @test entity.start == 1
        @test entity.stop == 10
        @test entity.label == "DRUG"
        @test entity.text == "aspirin"
        @test typeof(entity.start) == Int
        @test typeof(entity.stop) == Int
        @test typeof(entity.label) == String
        @test typeof(entity.text) == String
        
        # Test Doc constructor
        entities = [MediSeven.Entity(1, 7, "DRUG", "aspirin")]
        doc = MediSeven.Doc("aspirin daily", entities)
        @test doc.text == "aspirin daily"
        @test length(doc.ents) == 1
        @test doc.ents[1].label == "DRUG"
        @test typeof(doc.text) == String
        @test typeof(doc.ents) == Vector{MediSeven.Entity}
        
        # Test MediSevenModel constructor
        model = MediSeven.MediSevenModel(nothing, 5)
        @test model.nlp === nothing
        @test model.batch_size == 5
        @test typeof(model.batch_size) == Int
    end
end