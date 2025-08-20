# MediSeven.jl Package Description

## Overview

MediSeven.jl is a Julia package for Medical Named Entity Recognition (NER) that extracts structured medical information from clinical text. It's designed to identify and classify medical entities such as drugs, dosages, frequencies, routes, and other medication-related information from unstructured medical text.

## What Problems Does It Solve?

### Primary Use Cases:
1. **Clinical Text Processing**: Extract medication information from electronic health records (EHRs)
2. **Medical Document Analysis**: Parse prescription texts, clinical notes, and medical reports
3. **Healthcare NLP**: Support downstream tasks like medication reconciliation, adverse event detection
4. **Research Applications**: Enable large-scale analysis of medical text data

### Specific Problems Addressed:
- **Information Extraction**: Converting unstructured medical text into structured data
- **Standardization**: Normalizing medication names, dosages, and frequencies
- **Clinical Decision Support**: Providing structured data for clinical applications
- **Compliance**: Supporting medication safety and regulatory requirements

## Architecture & Design

### Core Components

#### 1. **MediSevenModel Struct**
```julia
struct MediSevenModel
    nlp::Union{PyObject, Nothing}
    batch_size::Int
end
```

**Purpose**: Wraps the underlying spaCy model and provides a unified interface for text processing.

**Design Rationale**: 
- Uses `Union{PyObject, Nothing}` to handle cases where spaCy models fail to load
- Includes `batch_size` for performance optimization during batch processing
- Provides a callable interface for intuitive usage

#### 2. **Entity Struct**
```julia
struct Entity
    start::Int
    stop::Int
    label::String
    text::String
end
```

**Purpose**: Represents a single medical entity found in text.

**Design Decisions**:
- `start`/`stop`: 1-based indexing (Julia convention) for character positions
- `label`: String type for entity classification (DRUG, DOSAGE, etc.)
- `text`: The actual text span that was identified as an entity

#### 3. **Doc Struct**
```julia
struct Doc
    text::String
    ents::Vector{Entity}
end
```

**Purpose**: Container for processed text and its extracted entities.

**Design Rationale**:
- Keeps original text for reference and debugging
- Stores entities as a vector for easy iteration and manipulation

### Entity Types

The package recognizes 7 core medical entity types:

```julia
const ENTITY_TYPES = ["DRUG", "STRENGTH", "DOSAGE", "DURATION", "FREQUENCY", "FORM", "ROUTE"]
```

**Why These Specific Types?**
- **DRUG**: Core medication identification (aspirin, metformin)
- **STRENGTH**: Concentration information (0.1%, 20mg/ml)
- **DOSAGE**: Amount to administer (500mg, 2 tablets)
- **DURATION**: How long to take (for 7 days, until symptoms resolve)
- **FREQUENCY**: How often to take (daily, BID, every 6 hours)
- **FORM**: Physical form (tablet, ointment, injection)
- **ROUTE**: Administration method (oral, IV, topical)

These types cover the essential components of medication instructions and are based on the original Med7 Python package.

## Implementation Details

### Model Loading Strategy

```julia
function load_model(; batch_size::Int=1)
    for model_name in FALLBACK_MODELS
        try
            spacy = pyimport("spacy")
            nlp = spacy.load(model_name)
            return MediSevenModel(nlp, batch_size)
        catch e
            @warn "Failed to load model $model_name: $e"
            continue
        end
    end
    return MediSevenModel(nothing, batch_size)
end
```

**Fallback Hierarchy**:
1. `kormilitzin/en_core_med7_lg` (primary medical model)
2. `en_core_med7_lg` (alternative medical model)
3. `en_core_web_sm/md/lg` (general English models)

**Why This Approach?**
- **Robustness**: Ensures the package works even if specific models aren't available
- **Specialization**: Prioritizes medical-specific models over general ones
- **Graceful Degradation**: Falls back to pattern matching if all spaCy models fail

### Text Processing Pipeline

#### Single Text Processing
```julia
function (model::MediSevenModel)(text::String)
    if model.nlp === nothing
        # Pattern-based fallback
        return pattern_based_extraction(text)
    else
        # spaCy-based processing
        return spacy_based_extraction(text, model.nlp)
    end
end
```

**Dual Processing Strategy**:
1. **Primary**: Uses spaCy models for high-quality entity recognition
2. **Fallback**: Uses regex patterns when spaCy is unavailable

#### Batch Processing
```julia
function (model::MediSevenModel)(texts::Vector{String})
    if model.nlp === nothing
        return [model(text) for text in texts]
    else
        spacy_docs = model.nlp.pipe(texts, batch_size=model.batch_size)
        return process_spacy_batch(spacy_docs, texts)
    end
end
```

**Performance Optimizations**:
- Uses spaCy's `pipe()` method for efficient batch processing
- Configurable `batch_size` for memory/performance tuning
- Falls back to individual processing if batch fails

### Pattern-Based Fallback System

When spaCy models are unavailable, the package uses regex patterns:

```julia
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
```

**Pattern Design Rationale**:
- **Drug Patterns**: Common medication suffixes and well-known drugs
- **Dosage Patterns**: Standard medical units with numeric values
- **Frequency Patterns**: Common medical abbreviations and time expressions

## Technology Stack & Dependencies

### Core Dependencies

#### 1. **PyCall.jl**
```julia
using PyCall
```

**Purpose**: Enables Julia to call Python functions and use Python packages.

**Why PyCall?**
- **spaCy Integration**: spaCy is a mature, well-maintained NLP library
- **Model Availability**: Access to pre-trained medical NER models
- **Performance**: spaCy's optimized Cython implementation
- **Community**: Large ecosystem of medical NLP models

**Alternatives Considered**:
- **Pure Julia NLP**: Limited medical-specific models available
- **REST APIs**: Network dependency, potential latency issues
- **Other Python bridges**: PyCall is the most mature and stable

#### 2. **HTTP.jl**
```julia
using HTTP
```

**Purpose**: Handles web requests (though not directly used in current implementation).

**Potential Uses**:
- Model downloading from Hugging Face
- API integration for external services
- Web-based model loading

#### 3. **JSON3.jl**
```julia
using JSON3
```

**Purpose**: JSON parsing and serialization.

**Use Cases**:
- Configuration file handling
- API response parsing
- Model metadata processing

### Python Dependencies (via PyCall)

#### spaCy
- **Version**: Compatible with spaCy 3.x
- **Models**: Medical-specific models (Med7, en_core_med7_lg)
- **Features**: Named entity recognition, tokenization, dependency parsing

## Design Decisions & Trade-offs

### 1. **Julia-Python Bridge vs Pure Julia**

**Chosen**: Julia-Python bridge via PyCall

**Pros**:
- Access to mature medical NLP models
- Leverages spaCy's optimized performance
- Reduces development time significantly

**Cons**:
- Python dependency requirement
- Potential performance overhead
- More complex deployment

**Alternatives**:
- **Pure Julia**: Would require training new models from scratch
- **REST API**: Network dependency, potential reliability issues
- **C++ bindings**: More complex, less mature ecosystem

### 2. **Fallback Strategy**

**Chosen**: Multi-level fallback with pattern matching

**Rationale**:
- **Reliability**: Package works even without Python/spaCy
- **Graceful Degradation**: Maintains functionality with reduced accuracy
- **User Experience**: No hard failures, always returns results

**Implementation**:
1. Try spaCy models in order of preference
2. Fall back to regex patterns if all models fail
3. Provide clear logging of fallback usage

### 3. **Entity Structure Design**

**Chosen**: Simple struct with start/stop positions

**Pros**:
- **Simplicity**: Easy to understand and use
- **Flexibility**: Can represent any text span
- **Compatibility**: Matches spaCy's entity format

**Alternatives**:
- **Rich metadata**: Would add complexity without clear benefit
- **Nested entities**: Could handle overlapping entities but adds complexity

### 4. **Batch Processing Strategy**

**Chosen**: spaCy pipe() with individual fallback

**Benefits**:
- **Performance**: Efficient batch processing when available
- **Reliability**: Individual processing as fallback
- **Flexibility**: Configurable batch sizes

## Performance Characteristics

### Time Complexity
- **Single Text**: O(n) where n is text length
- **Batch Processing**: O(n × m) where n is texts count, m is average text length
- **Pattern Matching**: O(p × n) where p is pattern count

### Memory Usage
- **Model Loading**: ~500MB-2GB depending on spaCy model size
- **Text Processing**: Linear with text size
- **Batch Processing**: Proportional to batch_size

### Optimization Strategies
1. **Batch Processing**: Reduces overhead per text
2. **Model Caching**: spaCy models loaded once and reused
3. **Efficient Patterns**: Optimized regex patterns for fallback

## Error Handling & Robustness

### Error Categories

#### 1. **Model Loading Errors**
```julia
try
    nlp = spacy.load(model_name)
catch e
    @warn "Failed to load model $model_name: $e"
    continue
end
```

**Handling**: Log warning and try next model in fallback chain

#### 2. **Processing Errors**
```julia
try
    doc = model.nlp(text)
catch e
    @warn "spaCy processing failed: $e. Using pattern-based fallback."
    return pattern_based_fallback(text)
end
```

**Handling**: Fall back to pattern matching with warning

#### 3. **Batch Processing Errors**
```julia
try
    spacy_docs = model.nlp.pipe(texts, batch_size=model.batch_size)
catch e
    @warn "Batch processing failed: $e. Processing individually."
    return [model(text) for text in texts]
end
```

**Handling**: Process texts individually with warning

### Robustness Features
- **No Hard Failures**: Package always returns results
- **Comprehensive Logging**: Clear indication of fallback usage
- **Input Validation**: Handles edge cases gracefully
- **Memory Management**: Efficient resource usage

## Limitations & Known Issues

### Current Limitations

#### 1. **Accuracy Trade-offs**
- **Pattern Fallback**: Less accurate than spaCy models
- **Limited Context**: Basic patterns don't understand context
- **Entity Overlap**: May miss complex nested entities

#### 2. **Performance Considerations**
- **Python Overhead**: PyCall introduces some performance cost
- **Model Size**: Large spaCy models require significant memory
- **Startup Time**: Model loading can be slow

#### 3. **Dependency Requirements**
- **Python Installation**: Requires Python and spaCy
- **Model Downloads**: May need to download large model files
- **Version Compatibility**: Dependent on spaCy version compatibility

### Potential Issues

#### 1. **Model Availability**
- **Internet Dependency**: Models may not be available offline
- **Version Conflicts**: spaCy model version mismatches
- **Platform Issues**: Different behavior across operating systems

#### 2. **Text Processing Edge Cases**
- **Unicode Handling**: Complex medical terminology
- **Format Variations**: Different text formats and encodings
- **Language Support**: Primarily English-focused

#### 3. **Memory Management**
- **Large Texts**: Memory usage with very long documents
- **Batch Size**: Optimal batch size depends on available memory
- **Model Caching**: Memory usage with multiple model instances

## Future Improvements

### Planned Enhancements

#### 1. **Enhanced Pattern Matching**
- **Context-Aware Patterns**: Consider surrounding text
- **Medical Dictionary Integration**: Use medical terminology databases
- **Machine Learning Patterns**: Learn patterns from training data

#### 2. **Performance Optimizations**
- **Native Julia Models**: Pure Julia implementation for better performance
- **Parallel Processing**: Multi-threaded batch processing
- **Memory Optimization**: More efficient data structures

#### 3. **Additional Features**
- **Entity Linking**: Connect entities to medical databases
- **Confidence Scores**: Provide confidence levels for entity recognition
- **Custom Training**: Support for domain-specific model training

#### 4. **Better Error Handling**
- **Detailed Error Messages**: More informative error reporting
- **Recovery Strategies**: Automatic recovery from common errors
- **Validation Tools**: Input validation and sanitization

## Usage Patterns & Best Practices

### Recommended Usage

#### 1. **Model Initialization**
```julia
# Initialize once, reuse for multiple texts
model = MediSeven.load_model(batch_size=16)
```

#### 2. **Batch Processing**
```julia
# Use batch processing for multiple texts
texts = ["text1", "text2", "text3"]
docs = model(texts)
```

#### 3. **Error Handling**
```julia
# Check for fallback usage
if model.nlp === nothing
    @warn "Using pattern-based fallback - reduced accuracy"
end
```

### Performance Tips
1. **Reuse Models**: Don't reload models for each text
2. **Batch Processing**: Use batch processing for multiple texts
3. **Memory Management**: Choose appropriate batch sizes
4. **Model Selection**: Use smaller models if memory is limited

## Conclusion

MediSeven.jl provides a robust, production-ready solution for medical named entity recognition in Julia. Its dual processing strategy (spaCy + pattern fallback) ensures reliability while maintaining high accuracy when possible. The package's design prioritizes ease of use, robustness, and performance, making it suitable for both research and production applications in healthcare NLP.

The choice of PyCall for spaCy integration, comprehensive fallback strategies, and thoughtful error handling make this package a practical solution for medical text processing in the Julia ecosystem. While there are some limitations and areas for improvement, the current implementation provides a solid foundation for medical NLP tasks.
