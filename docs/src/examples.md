# Clinical NLP Examples
# Examples

## Basic Usage
```julia
using Med7

model = Med7.load_model()
doc = model("Take 2 aspirin tablets after meals")

for ent in doc.ents
    println(ent.text, " → ", ent.label)
end
```

## Batch Processing
```julia
texts = [
    "Administer 100mg ibuprofen every 8 hours",
    "Apply 1% hydrocortisone cream twice daily"
]

docs = model(texts)

for doc in docs
    println("\nText: ", doc.text)
    for ent in doc.ents
        println(" - ", ent.label, ": ", ent.text)
    end
end
```

## Entity Types
| Label      | Description          | Example        |
|------------|----------------------|----------------|
| DRUG       | Medication names     | "Lisinopril"   |
| DOSAGE     | Dose amount          | "40 mg"        |
| STRENGTH   | Drug strength        | "0.1%"         |
| FREQUENCY  | Administration freq  | "twice daily"  |
| ROUTE      | Administration method| "subcutaneous" |
| FORM       | Drug form            | "tablets"      |
| DURATION   | Treatment duration   | "for 2 weeks"  |










