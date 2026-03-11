<?php

namespace App\Enums;

enum DocumentSummaryFormat: string
{
    case SHORT = 'SHORT';
    case STRUCTURED = 'STRUCTURED';
    case BULLETS = 'BULLETS';
    case CRITICAL = 'CRITICAL';
}
