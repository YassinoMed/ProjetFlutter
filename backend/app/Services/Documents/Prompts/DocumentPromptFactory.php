<?php

namespace App\Services\Documents\Prompts;

class DocumentPromptFactory
{
    public function classificationPrompt(): string
    {
        return <<<'PROMPT'
You classify a single medical document.
Rules:
- Use only the provided document content.
- Never invent metadata or diagnoses.
- If confidence is low, still choose the closest class but explain the uncertainty.
- Output strict JSON only.

Allowed classes:
- PRESCRIPTION
- MEDICAL_REPORT
- LAB_RESULT
- RADIOLOGY_REPORT
- REFERRAL_LETTER
- MEDICAL_CERTIFICATE
- CONSULTATION_HISTORY
- OTHER

Expected JSON:
{
  "document_type": "",
  "confidence": 0.0,
  "reason": "",
  "uncertainty_notes": []
}
PROMPT;
    }

    public function extractionPrompt(): string
    {
        return <<<'PROMPT'
You analyze one medical document only.
Rules:
- Never invent information.
- If a field is absent, return null.
- If uncertain, keep the best factual extraction and explain the uncertainty in "uncertainty_notes".
- Distinguish explicit facts from hypotheses.
- Keep arrays empty instead of guessing missing values.
- Output strict JSON only.

Expected JSON:
{
  "document_type": "",
  "document_date": null,
  "patient_name": null,
  "doctor_name": null,
  "establishment": null,
  "specialty": null,
  "diagnosis": null,
  "suspected_diagnosis": null,
  "symptoms": [],
  "medical_history": [],
  "treatments": [{"name":"","dosage":"","frequency":"","duration":"","certainty":""}],
  "requested_exams": [],
  "important_lab_results": [{"label":"","value":"","unit":"","certainty":"","note":""}],
  "recommendations": [],
  "follow_up_date": null,
  "keywords": [],
  "urgency_level": "LOW|MEDIUM|HIGH|CRITICAL|UNKNOWN",
  "missing_fields": [],
  "uncertainty_notes": [],
  "facts_only": [],
  "interpretation_candidates": []
}
PROMPT;
    }

    public function shortSummaryPrompt(): string
    {
        return <<<'PROMPT'
Produce a short medical summary in French in 3 to 5 lines maximum.
Rules:
- Use only facts explicitly present in the document.
- Never infer missing diagnoses, medications, or dates.
- Mention uncertainty if the text is ambiguous or incomplete.
- End with: "Ce résumé ne remplace pas l’avis médical."
- Output plain text only.
PROMPT;
    }

    public function structuredSummaryPrompt(): string
    {
        return <<<'PROMPT'
Produce a structured summary of the document in French.
Rules:
- Use only information explicitly present in the document.
- Separate extracted facts from uncertain or missing elements.
- Never infer absent content.
- Output strict JSON only.

Expected JSON:
{
  "document_type": "",
  "key_facts": [],
  "diagnosis_or_hypothesis": [],
  "treatments": [],
  "requested_exams": [],
  "important_results": [],
  "recommendations": [],
  "follow_up": [],
  "critical_elements": [],
  "missing_information": [],
  "uncertainty_notes": []
}
PROMPT;
    }

    public function patientSummaryPrompt(): string
    {
        return <<<'PROMPT'
Write a patient-friendly summary in simple French.
Rules:
- Keep medical accuracy.
- Use simple language and explain jargon briefly if necessary.
- Never invent details not found in the document.
- Explicitly say when something is unclear or missing.
- Do not provide medical advice beyond the document.
- End with a reminder that only a clinician can interpret the document medically.
PROMPT;
    }

    public function professionalSummaryPrompt(): string
    {
        return <<<'PROMPT'
Write a concise professional medical summary in French.
Rules:
- Keep professional terminology.
- Separate explicit facts from uncertain elements.
- Never infer a diagnosis if it is not written.
- Output strict JSON only.

Expected JSON:
{
  "facts": [],
  "clinical_points": [],
  "follow_up": [],
  "uncertainties": [],
  "missing_information": []
}
PROMPT;
    }

    public function criticalElementsPrompt(): string
    {
        return <<<'PROMPT'
List only critical or time-sensitive elements from the document.
Rules:
- No invention.
- If no critical element is explicitly present, return an empty list.
- Mention uncertainty if the wording is ambiguous.
- Output strict JSON only.

Expected JSON:
{
  "critical_alerts": [
    {"label":"","reason":"","certainty":"","source_excerpt":""}
  ]
}
PROMPT;
    }

    public function administrativeSummaryPrompt(): string
    {
        return <<<'PROMPT'
Create an administrative summary in French.
Rules:
- Include only administrative/documentary facts explicitly present.
- Focus on patient identity, issuer, document date, document type, follow-up date, and administrative next actions.
- Never invent clinical interpretation.
- Output strict JSON only.

Expected JSON:
{
  "patient_name": null,
  "issuer": null,
  "document_date": null,
  "document_type": null,
  "follow_up_date": null,
  "administrative_actions": [],
  "uncertainty_notes": []
}
PROMPT;
    }

    public function documentQuestionPrompt(): string
    {
        return <<<'PROMPT'
Answer a user question using only the provided medical document.
Rules:
- Use only the document content.
- Never invent facts or interpret beyond the document.
- If the answer is missing or uncertain, say so clearly.
- Distinguish direct evidence from uncertainty.
- Output strict JSON only.

Expected JSON:
{
  "answer": "",
  "insufficient_evidence": false,
  "evidence": [{"excerpt":"","field":null,"certainty":""}],
  "uncertainty_notes": []
}
PROMPT;
    }
}
