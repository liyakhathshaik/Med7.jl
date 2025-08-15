# Med7.jl

[![Build Status](https://github.com/liyakhathshaik/Med7.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/liyakhathshaik/Med7.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/liyakhathshaik/Med7.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/liyakhathshaik/Med7.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

A robust Julia package for medical named entity recognition (NER) using transformer models. Med7.jl provides state-of-the-art extraction of medical entities like drugs, dosages, frequencies, and routes from clinical text.

## Features

- 🏥 **Medical NER**: Extract DRUG, DOSAGE, FREQUENCY, DURATION, ROUTE, FORM, and STRENGTH entities
- 🔄 **Automatic Fallbacks**: Robust model loading with multiple fallback options
- ⚡ **Batch Processing**: Efficient processing of multiple texts
- 🤖 **Transformer-Powered**: Built on HuggingFace transformers
- 📊 **Production Ready**: Comprehensive error handling and logging

## Installation

```julia
using Pkg
Pkg.add("Med7")
```

Or from the Julia REPL:
```julia
] add Med7
```

## Quick Start

```julia
using Med7

# Load model (automatic fallback if primary model fails)
model = load_model()

# Process single text
doc = model("Take 500mg paracetamol every 6 hours for pain")
println("Entities found: $(length(doc.ents))")

# Process batch
texts = [
    "Administer 40mg lisinopril daily", 
    "Apply 0.1% tacrolimus ointment BID"
]
docs = model(texts)
```

## API Reference

### Model Loading

```julia
# Default loading with fallbacks
model = load_model()

# Specify model and batch size
model = load_model(model_name="kormilitzin/en_core_med7_lg", batch_size=16)

# Disable fallbacks (strict mode)
model = load_model(model_name="my_model", use_fallback=false)
```

### Text Processing

```julia
# Single text
doc = process!(text, model)
# or
doc = model(text)

# Batch processing
docs = process!(texts, model)
# or 
docs = model(texts)
```

### Entities

```julia
for entity in doc.ents
    println("$(entity.label): '$(entity.text)' at $(entity.start):$(entity.stop)")
end
```

## Supported Entity Types

- **DRUG**: Medication names (aspirin, metformin)
- **DOSAGE**: Amounts (500mg, 2 tablets) 
- **FREQUENCY**: How often (daily, BID, every 6 hours)
- **DURATION**: How long (for 7 days, until symptoms resolve)
- **ROUTE**: Administration route (oral, IV, topical)
- **FORM**: Drug form (tablet, ointment, injection)
- **STRENGTH**: Concentration (0.1%, 20mg/ml)

## Fallback Models

Med7.jl automatically tries multiple models in order of preference:

1. `kormilitzin/en_core_med7_lg` (primary)
2. `Clinical-AI-Apollo/Medical-NER`
3. `d4data/biomedical-ner-all` 
4. `alvaroalon2/biobert_diseases_ner`
5. `microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract-fulltext`

## Development

```bash
git clone https://github.com/liyakhathshaik/Med7.jl.git
cd Med7.jl
julia --project=. -e "using Pkg; Pkg.instantiate()"
julia --project=. -e "using Pkg; Pkg.test()"
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

```bibtex
@software{med7_jl,
  title = {Med7.jl: Medical Named Entity Recognition for Julia},
  author = {Liyakhath Shaik},
  year = {2025},
  url = {https://github.com/liyakhathshaik/Med7.jl}
}
```

## Acknowledgments

- Built with [PyCall.jl](https://github.com/JuliaPy/PyCall.jl) for Python integration
- Uses [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl) for web requests
- JSON handling via [JSON3.jl](https://github.com/quinnj/JSON3.jl)
- Inspired by the original [Med7](https://github.com/kormilitzin/med7) Python package