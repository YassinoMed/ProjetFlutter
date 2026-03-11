<?php

namespace App\Services\Documents\Prompts;

class DocumentPromptFactory
{
    public function extractionPrompt(): string
    {
        return <<<'PROMPT'
You analyze one medical document only.
Rules:
- Never invent data.
- If a field is absent, return "not_present".
- If uncertain, return "uncertain" and explain why in "uncertainty_notes".
- Distinguish extracted facts from interpretation.
- Output strict JSON only.

Expected JSON keys:
{
  "document_type": "...",
  "document_date": "...",
  "patient_name": "...",
  "doctor_name": "...",
  "establishment": "...",
  "specialty": "...",
  "diagnosis": "...",
  "suspected_diagnosis": "...",
  "symptoms": [],
  "medical_history": [],
  "treatments": [{"name":"","dosage":"","frequency":"","duration":"","certainty":""}],
  "requested_exams": [],
  "important_lab_results": [{"label":"","value":"","unit":"","interpretation":"","certainty":""}],
  "recommendations": [],
  "follow_up_date": "...",
  "keywords": [],
  "urgency_level": "LOW|MEDIUM|HIGH|CRITICAL|UNKNOWN",
  "missing_fields": [],
  "uncertainty_notes": []
}
PROMPT;
    }

    public function shortSummaryPrompt(): string
    {
        return <<<'PROMPT'
Summarize this medical document in 3 to 5 lines maximum.
Rules:
- Use only facts present in the document.
- Do not infer missing diagnoses or treatments.
- Mention if a critical fact is missing.
- End with: "Ce résumé ne remplace pas l’avis du médecin."
PROMPT;
    }

    public function patientSummaryPrompt(): string
    {
        return <<<'PROMPT'
Write a patient-friendly summary in simple French.
Rules:
- Keep medical accuracy.
- Avoid jargon when possible; explain briefly if jargon is necessary.
- Never invent details not found in the document.
- Explicitly say when something is unclear or missing.
- Mention that only a physician can interpret the document clinically.
PROMPT;
    }

    public function professionalSummaryPrompt(): string
    {
        return <<<'PROMPT'
Write a concise professional medical summary.
Rules:
- Keep medical terminology.
- Separate explicit facts from uncertain elements.
- Never infer a diagnosis if not written.
- Structure output as JSON:
{
  "facts": [],
  "clinical_points": [],
  "follow_up": [],
  "uncertainties": []
}
PROMPT;
    }

    public function criticalElementsPrompt(): string
    {
        return <<<'PROMPT'
List only critical or time-sensitive elements from the document.
Rules:
- No invention.
- If no critical element is present, return an empty list.
- Output strict JSON: {"critical_alerts":[{"label":"","reason":"","certainty":""}]}
PROMPT;
    }

    public function classificationPrompt(): string
    {
        return <<<'PROMPT'
Classify the medical document.
Allowed classes:
- PRESCRIPTION
- MEDICAL_REPORT
- LAB_RESULT
- RADIOLOGY_REPORT
- REFERRAL_LETTER
- MEDICAL_CERTIFICATE
- CONSULTATION_HISTORY
- OTHER

Rules:
- Choose only one class.
- Never invent metadata.
- Output strict JSON:
{"document_type":"","confidence":0,"reason":""}
PROMPT;
    }
}
