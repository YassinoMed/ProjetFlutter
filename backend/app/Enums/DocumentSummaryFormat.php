<?php

namespace App\Enums;

enum DocumentSummaryFormat: string
{
    case SHORT = 'SHORT';
    case STRUCTURED = 'STRUCTURED';
    case PATIENT_FRIENDLY = 'PATIENT_FRIENDLY';
    case PROFESSIONAL_DETAILED = 'PROFESSIONAL_DETAILED';
    case BULLETS = 'BULLETS';
    case CRITICAL = 'CRITICAL';
    case ADMINISTRATIVE = 'ADMINISTRATIVE';
}
