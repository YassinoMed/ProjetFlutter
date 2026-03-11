<?php

namespace App\Enums;

enum DocumentSummaryAudience: string
{
    case PATIENT = 'PATIENT';
    case PROFESSIONAL = 'PROFESSIONAL';
    case ADMINISTRATIVE = 'ADMINISTRATIVE';
}
