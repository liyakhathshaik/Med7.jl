module Med7

using HTTP
using JSON3
using PyCall
using Random

export Med7Model, load_model, Entity, Doc, ENTITY_TYPES, FALLBACK_MODELS

# Define medical entity types
const ENTITY_TYPES = ["DRUG", "STRENGTH", "DOSAGE", "DURATION", "FREQUENCY", "FORM", "ROUTE"]

# Fallback model names for spaCy
const FALLBACK_MODELS = [
    "kormilitzin/en_core_med7_lg",
    "en_core_med7_lg", 
    "en_core_web_sm",
    "en_core_web_md",
    "en_core_web_lg"
]

# Basic medical entity detection patterns (fallback when spaCy models unavailable)
const DRUG_PATTERNS = [
    r"\b\w*(cillin|mycin|pril|sartan|statin|zole|mab)\b"i,
    r"\b(aspirin|ibuprofen|acetaminophen|warfarin|metformin|insulin)\b"i
]

const DOSAGE_PATTERNS = [
    r"\b\d+\.?\d*\s*(mg|g|ml|mcg|units?|iu)\b"i
]

const FREQUENCY_PATTERNS = [
    r"\b(daily|bid|tid|qid|q\d+h|once|twice|three times)\b"i,
    r"\b(morning|evening|bedtime|as needed|prn)\b"i
]

# Entity structure
struct Entity
    start::Int
    stop::Int
    label::String
    text::String
end

# Document structure with entities
struct Doc
    text::String
    ents::Vector{Entity}
end

# Med7 model wrapper
struct Med7Model
    nlp::Union{PyObject, Nothing}
    batch_size::Int
end

# Simple word tokenization as fallback
function simple_tokenize(text::String)
    # Remove punctuation and split on whitespace
    words = split(replace(text, r"[^\w\s]" => " "), r"\s+")
    return filter(!isempty, words)
end

"""
    load_model(; batch_size=1)

Load the Med7 spaCy model with fallback options.
Returns a Med7Model instance that can process medical texts.

# Arguments
- `batch_size::Int=1`: Number of texts to process in parallel

# Returns
- `Med7Model`: Model instance for medical NER

# Example
```julia
model = Med7.load_model()
doc = model("Patient takes 10mg aspirin daily")
```
"""
function load_model(; batch_size::Int=1)
    # Try to load spaCy model with fallbacks
    for model_name in FALLBACK_MODELS
        try
            @info "Attempting to load model: $model_name"
            spacy = pyimport("spacy")
            nlp = spacy.load(model_name)
            @info "Successfully loaded model: $model_name"
            return Med7Model(nlp, batch_size)
        catch e
            @warn "Failed to load model $model_name: $e"
            continue
        end
    end
    
    # If all models fail, create a basic fallback processor
    @warn "All spaCy models failed to load. Using basic pattern-based processor."
    return Med7Model(nothing, batch_size)
end

"""
    (model::Med7Model)(text::String)

Process a medical text and extract entities.

# Arguments  
- `text::String`: Medical text to analyze

# Returns
- `Doc`: Document with extracted medical entities

# Example
```julia
model = Med7.load_model()
doc = model("Patient prescribed 20mg lisinopril twice daily")
for ent in doc.ents
    println("\$(ent.text) -> \$(ent.label)")
end
```
"""
function (model::Med7Model)(text::String)
    if model.nlp === nothing
        # Fallback: basic pattern matching
        entities = Entity[]
        
        # Drug detection
        for pattern in DRUG_PATTERNS
            for match in eachmatch(pattern, text)
                start_pos = match.offset
                end_pos = match.offset + length(match.match) - 1
                push!(entities, Entity(start_pos, end_pos, "DRUG", match.match))
            end
        end
        
        # Dosage detection  
        for match in eachmatch(DOSAGE_PATTERNS[1], text)
            start_pos = match.offset
            end_pos = match.offset + length(match.match) - 1
            push!(entities, Entity(start_pos, end_pos, "DOSAGE", match.match))
        end
        
        # Frequency detection
        for pattern in FREQUENCY_PATTERNS
            for match in eachmatch(pattern, text)
                start_pos = match.offset
                end_pos = match.offset + length(match.match) - 1
                push!(entities, Entity(start_pos, end_pos, "FREQUENCY", match.match))
            end
        end
        
        return Doc(text, entities)
    end
    
    # Use spaCy model if available
    try
        doc = model.nlp(text)
        entities = Entity[]
        
        for ent in doc.ents
            push!(entities, Entity(
                Int(ent.start_char) + 1,  # Julia uses 1-based indexing
                Int(ent.end_char),
                String(ent.label_),
                String(ent.text)
            ))
        end
        
        return Doc(text, entities)
    catch e
        @warn "spaCy processing failed: $e. Using pattern-based fallback."
        # Use pattern matching fallback
        return Med7Model(nothing, model.batch_size)(text)
    end
end

"""
    (model::Med7Model)(texts::Vector{String})

Process multiple medical texts in batch.

# Arguments
- `texts::Vector{String}`: Vector of medical texts to analyze

# Returns  
- `Vector{Doc}`: Vector of documents with extracted entities

# Example
```julia
model = Med7.load_model(batch_size=4)
texts = ["Take aspirin 10mg daily", "Metformin 500mg twice daily"]
docs = model(texts)
```
"""
function (model::Med7Model)(texts::Vector{String})
    if model.nlp === nothing
        # Process each text individually with pattern matching
        return [model(text) for text in texts]
    end
    
    # Use spaCy batch processing if available
    try
        spacy_docs = model.nlp.pipe(texts, batch_size=model.batch_size)
        docs = Doc[]
        
        for (i, doc) in enumerate(spacy_docs)
            entities = Entity[]
            for ent in doc.ents
                push!(entities, Entity(
                    Int(ent.start_char) + 1,
                    Int(ent.end_char), 
                    String(ent.label_),
                    String(ent.text)
                ))
            end
            push!(docs, Doc(texts[i], entities))
        end
        
        return docs
    catch e
        @warn "Batch processing failed: $e. Processing individually."
        return [model(text) for text in texts]
    end
end

end # module Med7