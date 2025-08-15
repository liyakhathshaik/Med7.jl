module Med7

using Transformers
using Transformers.HuggingFace
using Tokenizers

export Med7Model, Entity, Doc, load_model, process!, process_batch!

"""
    Entity

Represents a medical entity extracted from text.

# Fields
- `start::Int`: starting character index (1-based)
- `stop::Int`: ending character index
- `label::String`: entity type (DRUG, DOSAGE, etc.)
- `text::String`: extracted entity text
"""
struct Entity
    start::Int
    stop::Int
    label::String
    text::String
end

"""
    Doc

Document analysis result container.

# Fields
- `text::String`: original input text
- `ents::Vector{Entity}`: extracted entities
"""
struct Doc
    text::String
    ents::Vector{Entity}
end

"""
    Med7Model

Main model container with batch processing support.

# Fields
- `tokenizer`: Tokenizer instance
- `model`: Transformer model
- `id2label::Dict`: Label ID to string mapping
- `batch_size::Int`: Default batch size for processing
"""
struct Med7Model
    tokenizer
    model
    id2label::Dict{Int, String}
    batch_size::Int
end

const ENTITY_TYPES = Set(["DRUG", "DOSAGE", "DURATION", "FREQUENCY", "ROUTE", "FORM", "STRENGTH"])

# Fallback models in order of preference
const FALLBACK_MODELS = [
    "kormilitzin/en_core_med7_lg",
    "Clinical-AI-Apollo/Medical-NER", 
    "d4data/biomedical-ner-all",
    "alvaroalon2/biobert_diseases_ner",
    "microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract-fulltext"
]

"""
    load_model(; model_name=nothing, batch_size=8, use_fallback=true)

Load Med7 model from Hugging Face Hub with automatic fallback support.

# Arguments
- `model_name`: Specific model to load. If `nothing`, tries fallback models
- `batch_size`: Default batch size for processing (default: 8)  
- `use_fallback`: Whether to try fallback models on failure (default: true)

# Returns
- Initialized Med7Model ready for inference

# Examples
```julia
# Load with automatic fallback
model = load_model()

# Load specific model with fallback
model = load_model(model_name="kormilitzin/en_core_med7_lg")

# Load without fallback (strict mode)
model = load_model(model_name="my_model", use_fallback=false)
```
"""
function load_model(; model_name=nothing, batch_size=8, use_fallback=true)
    models_to_try = if model_name !== nothing
        use_fallback ? [model_name, FALLBACK_MODELS...] : [model_name]
    else
        FALLBACK_MODELS
    end
    
    # Remove duplicates while preserving order
    models_to_try = unique(models_to_try)
    
    last_error = nothing
    for (i, model_candidate) in enumerate(models_to_try)
        try
            @info "Attempting to load model: $model_candidate"
            tokenizer = Tokenizer(Tokenizers.from_pretrained(model_candidate))
            model = Transformers.HuggingFace.load_model(model_candidate; token_classification=true)
            
            @info "Successfully loaded model: $model_candidate"
            return _create_med7_model(tokenizer, model, model_candidate, batch_size)
            
        catch e
            last_error = e
            @warn "Failed to load model $model_candidate: $e"
            
            if i == length(models_to_try)
                @error "All fallback models failed. Last error: $e"
                if !use_fallback && model_name !== nothing
                    throw(ArgumentError("Failed to load specified model '$model_name' and fallback is disabled. Error: $e"))
                else
                    throw(ArgumentError("Failed to load any available medical NER model. Please check your internet connection and HuggingFace access. Last error: $e"))
                end
            end
        end
    end
end

function _create_med7_model(tokenizer, model, model_name, batch_size)</to_replace>
</Editor.edit_file_by_replace>

<Editor.edit_file_by_replace>
<file_name>/workspace/uploads/Med7.jl/src/Med7.jl</file_name>
<to_replace>    id2label = Dict(
        0 => "B-DOSAGE",
        1 => "B-DRUG",
        2 => "B-DURATION",
        3 => "B-FORM",
        4 => "B-FREQUENCY",
        5 => "B-ROUTE",
        6 => "B-STRENGTH",
        7 => "I-DOSAGE",
        8 => "I-DRUG",
        9 => "I-DURATION",
        10 => "I-FORM",
        11 => "I-FREQUENCY",
        12 => "I-ROUTE",
        13 => "I-STRENGTH",
        14 => "O"
    )
    
    return Med7Model(tokenizer, model, id2label, batch_size)</to_replace>
<new_content>    # Try to get labels from model config, fallback to default
    id2label = _get_model_labels(model, model_name)
    
    return Med7Model(tokenizer, model, id2label, batch_size)
end

function _get_model_labels(model, model_name)
    # Default Med7 labels
    default_labels = Dict(
        0 => "B-DOSAGE", 1 => "B-DRUG", 2 => "B-DURATION", 3 => "B-FORM",
        4 => "B-FREQUENCY", 5 => "B-ROUTE", 6 => "B-STRENGTH",
        7 => "I-DOSAGE", 8 => "I-DRUG", 9 => "I-DURATION", 10 => "I-FORM", 
        11 => "I-FREQUENCY", 12 => "I-ROUTE", 13 => "I-STRENGTH", 14 => "O"
    )
    
    try
        # Try to extract labels from model config
        if hasfield(typeof(model), :config) && hasfield(typeof(model.config), :id2label)
            model_labels = model.config.id2label
            @info "Using model-specific labels from $model_name"
            return model_labels
        end
    catch e
        @warn "Could not extract labels from model config: $e"
    end
    
    @info "Using default Med7 labels for $model_name"
    return default_labels</to_replace>
</Editor.edit_file_by_replace>

<Editor.write>
<path>/workspace/uploads/Med7.jl/.github/workflows/CI.yml</path>
<content>name: CI

on:
  push:
    branches:
      - main
      - master
      - develop
    tags: '*'
  pull_request:

concurrency:
  # Skip intermediate builds: always.
  # Cancel intermediate builds: only if it is a pull request build.
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ startsWith(github.ref, 'refs/pull/') }}

jobs:
  test:
    name: Julia ${{ matrix.version }} - ${{ matrix.os }} - ${{ matrix.arch }} - ${{ github.event_name }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        version:
          - '1.6'
          - '1.9' 
          - '1.10'
          - 'nightly'
        os:
          - ubuntu-latest
        arch:
          - x64
        include:
          # Test on macOS and Windows with latest Julia only
          - os: macOS-latest
            arch: x64
            version: '1.10'
          - os: windows-latest
            arch: x64
            version: '1.10'
    steps:
      - uses: actions/checkout@v4
      - uses: julia-actions/setup-julia@v1
        with:
          version: ${{ matrix.version }}
          arch: ${{ matrix.arch }}
      - uses: julia-actions/cache@v1
      - uses: julia-actions/julia-buildpkg@v1
      - uses: julia-actions/julia-runtest@v1
        env:
          JULIA_NUM_THREADS: 2
      - uses: julia-actions/julia-processcoverage@v1
      - uses: codecov/codecov-action@v3
        with:
          files: lcov.info
          
  docs:
    name: Documentation
    runs-on: ubuntu-latest
    permissions:
      contents: write
      statuses: write
    steps:
      - uses: actions/checkout@v4
      - uses: julia-actions/setup-julia@v1
        with:
          version: '1.10'
      - uses: julia-actions/cache@v1
      - name: Configure doc environment
        shell: julia --project=docs --color=yes {0}
        run: |
          using Pkg
          Pkg.develop(PackageSpec(path=pwd()))
          Pkg.instantiate()
      - uses: julia-actions/julia-buildpkg@v1
      - uses: julia-actions/julia-docdeploy@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
</content>
</Editor.write>

<Editor.write>
<path>/workspace/uploads/Med7.jl/.github/workflows/CompatHelper.yml</path>
<content>name: CompatHelper
on:
  schedule:
    - cron: 0 0 * * *
  workflow_dispatch:
permissions:
  contents: write
  pull-requests: write
jobs:
  CompatHelper:
    runs-on: ubuntu-latest
    steps:
      - name: Check if Julia is already available in the PATH
        id: julia_in_path
        run: which julia
        continue-on-error: true
      - name: Install Julia, but only if it is not already available in the PATH
        uses: julia-actions/setup-julia@v1
        with:
          version: '1'
          arch: x64
        if: steps.julia_in_path.outcome != 'success'
      - name: "Add the General registry via Git"
        run: |
          import Pkg
          ENV["JULIA_PKG_SERVER"] = ""
          Pkg.Registry.add("General")
        shell: julia --color=yes {0}
      - name: "Install CompatHelper"
        run: |
          import Pkg
          name = "CompatHelper"
          uuid = "aa819f21-2bde-4658-8897-bab36330d9b5"
          version = "3"
          Pkg.add(; name, uuid, version)
        shell: julia --color=yes {0}
      - name: "Run CompatHelper"
        run: |
          import CompatHelper
          CompatHelper.main()
        shell: julia --color=yes {0}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          COMPATHELPER_PRIV: ${{ secrets.DOCUMENTER_KEY }}
</content>
</Editor.write>

<Editor.write>
<path>/workspace/uploads/Med7.jl/.github/workflows/TagBot.yml</path>
<content>name: TagBot
on:
  issue_comment:
    types:
      - created
  workflow_dispatch:
    inputs:
      lookback:
        default: "3"
permissions:
  actions: read
  checks: read
  contents: write
  deployments: read
  issues: read
  discussions: read
  packages: read
  pages: read
  pull-requests: read
  repository-projects: read
  security-events: read
  statuses: read
jobs:
  TagBot:
    if: github.event_name == 'workflow_dispatch' || github.actor == 'JuliaTagBot'
    runs-on: ubuntu-latest
    steps:
      - uses: JuliaRegistries/TagBot@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          ssh: ${{ secrets.DOCUMENTER_KEY }}
</content>
</Editor.write>

<Editor.edit_file_by_replace>
<file_name>/workspace/uploads/Med7.jl/Project.toml</file_name>
<to_replace>[compat]
julia = "1.6"
Tokenizers = "0.15"
Transformers = "0.4"</to_replace>
<new_content>[compat]
julia = "1.6"
Tokenizers = "0.15"
Transformers = "0.4"

[extras]
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[targets]
test = ["Test"]
    
    id2label = Dict(
        0 => "B-DOSAGE",
        1 => "B-DRUG",
        2 => "B-DURATION",
        3 => "B-FORM",
        4 => "B-FREQUENCY",
        5 => "B-ROUTE",
        6 => "B-STRENGTH",
        7 => "I-DOSAGE",
        8 => "I-DRUG",
        9 => "I-DURATION",
        10 => "I-FORM",
        11 => "I-FREQUENCY",
        12 => "I-ROUTE",
        13 => "I-STRENGTH",
        14 => "O"
    )
    
    return Med7Model(tokenizer, model, id2label, batch_size)
end

function _process_single(text, model)
    encoding = Tokenizers.encode(model.tokenizer, text)
    input_ids = reshape(encoding.ids, 1, :)
    attention_mask = reshape(ones(Int, length(encoding.ids)), 1, :)
    outputs = model.model(input_ids; attention_mask=attention_mask)
    logits = outputs.logits[1, :, :]
    return reconstruct_doc(text, logits, encoding, model)
end

function _process_batch(texts, model)
    encodings = Tokenizers.encode_batch(model.tokenizer, texts)
    max_len = maximum(length(e.ids) for e in encodings)
    
    # Prepare padded batch
    input_ids = []
    attention_masks = []
    for encoding in encodings
        ids = encoding.ids
        mask = ones(Int, length(ids))
        
        # Pad sequences
        if length(ids) < max_len
           pad_token_id = get(model.tokenizer.vocab, "[PAD]", 0)
           pad_length = max_len - length(ids)
           append!(ids, fill(pad_token_id, pad_length))
           append!(mask, zeros(Int, pad_length))
        end
        
        push!(input_ids, ids)
        push!(attention_masks, mask)
    end
    
    # Convert to matrix
    input_ids = permutedims(hcat(input_ids...))
    attention_masks = permutedims(hcat(attention_masks...)))
    
    # Batch inference
    outputs = model.model(input_ids; attention_mask=attention_masks)
    
    # Process results
    docs = Vector{Doc}(undef, length(texts))
    for i in 1:length(texts)
        seq_len = length(encodings[i].ids)
        seq_logits = outputs.logits[i, 1:seq_len, :]
        docs[i] = reconstruct_doc(texts[i], seq_logits, encodings[i], model)
    end
    
    return docs
end

function reconstruct_doc(text, logits, encoding, model)
    predictions = [argmax(logits[i, :]) - 1 for i in 1:size(logits, 1)]
    tokens = encoding.tokens
    offsets = encoding.offsets
    
    entities = []
    current_entity = nothing
    
    for i in 1:length(tokens)
        token = tokens[i]
        off = offsets[i]
        label_idx = predictions[i]
        label_str = get(model.id2label, label_idx, "O")
        
        token in ("[CLS]", "[SEP]") && continue
        label_str == "O" && continue
        
        # Extract clean label
        if occursin('-', label_str)
            parts = split(label_str, '-', limit=2)
            prefix = parts[1]
            clean_label = length(parts) > 1 ? parts[2] : ""
        else
            prefix = ""
            clean_label = label_str
        end
        (clean_label ∉ ENTITY_TYPES) && continue
        
        if prefix == "B"
            # Finalize previous entity
            current_entity !== nothing && push!(entities, current_entity)
            current_entity = (
                start = off[1] + 1,  # Convert to 1-based
                stop = off[2],
                label = clean_label,
                tokens = [i]
            )
        elseif prefix == "I" && current_entity !== nothing && current_entity.label == clean_label
            # Extend entity
            current_entity = (
                start = current_entity.start,
                stop = off[2],
                label = clean_label,
                tokens = [current_entity.tokens..., i]
            )
        else
            # Start new entity
            current_entity !== nothing && push!(entities, current_entity)
            current_entity = (
                start = off[1] + 1,
                stop = off[2],
                label = clean_label,
                tokens = [i]
            )
        end
    end
    
    # Add final entity
    current_entity !== nothing && push!(entities, current_entity)
    
    # Convert to Entity objects
    ents = map(entities) do e
        Entity(e.start, e.stop, e.label, text[e.start:e.stop])
    end
    
    return Doc(text, ents)
end

"""
    process!(text::Union{String, Vector{String}}, model::Med7Model)

Process text or batch of texts to extract medical entities.

# Arguments
- `text`: Input text or array of texts
- `model`: Initialized Med7Model

# Returns
- For single text: Doc object
- For batch: Vector{Doc}
"""
function process!(text::Union{String, Vector{String}}, model::Med7Model)
    if text isa String
        return _process_single(text, model)
    else
        return _process_batch(text, model)
    end
end

# Convenience methods
process_batch!(texts::Vector{String}, model::Med7Model) = _process_batch(texts, model)
(model::Med7Model)(text::Union{String, Vector{String}}) = process!(text, model)

end # module