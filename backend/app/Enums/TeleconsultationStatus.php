<?php

namespace App\Enums;

enum TeleconsultationStatus: string
{
    case SCHEDULED = 'scheduled';
    case RINGING = 'ringing';
    case ACTIVE = 'active';
    case COMPLETED = 'completed';
    case CANCELLED = 'cancelled';
    case MISSED = 'missed';
    case FAILED = 'failed';
    case EXPIRED = 'expired';
}
