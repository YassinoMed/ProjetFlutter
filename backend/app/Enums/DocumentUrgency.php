<?php

namespace App\Enums;

enum DocumentUrgency: string
{
    case LOW = 'LOW';
    case MEDIUM = 'MEDIUM';
    case HIGH = 'HIGH';
    case CRITICAL = 'CRITICAL';
    case UNKNOWN = 'UNKNOWN';
}
