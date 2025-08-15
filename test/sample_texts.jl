module SampleTexts

const PRESCRIPTION_TEXTS = [
    "The patient was prescribed 40 mg of Lisinopril daily for hypertension.",
    "Administer 500 mg Paracetamol every 6 hours as needed for pain.",
    "Take 2 tablets of Metformin twice a day with meals.",
    "Injection: 100 units insulin glargine subcutaneous once daily at bedtime.",
    "Apply 0.1% tacrolimus ointment topically twice daily for eczema."
]

const CLINICAL_NOTES = [
    "Patient advised to continue current regimen of atorvastatin 20mg at bedtime.",
    "Discontinue metoprolol and start carvedilol 3.125mg BID.",
    "Hold lisinopril if systolic BP < 100 mmHg.",
    "Allergies: Penicillin (rash), Sulfa (nausea).",
    "Plan: Increase insulin glargine to 15 units nightly."
]

const EXPECTED_ENTITIES = Dict(
    PRESCRIPTION_TEXTS[1] => ["40 mg" => "DOSAGE", "Lisinopril" => "DRUG", "daily" => "FREQUENCY"],
    PRESCRIPTION_TEXTS[2] => ["500 mg" => "DOSAGE", "Paracetamol" => "DRUG", "every 6 hours" => "FREQUENCY"],
    CLINICAL_NOTES[1] => ["atorvastatin" => "DRUG", "20mg" => "DOSAGE", "at bedtime" => "FREQUENCY"]
)

end