<?php

namespace App\Enums;

enum CallSessionState: string
{
    case INITIATED = 'INITIATED';
    case RINGING = 'RINGING';
    case ACCEPTED = 'ACCEPTED';
    case REJECTED = 'REJECTED';
    case CANCELLED = 'CANCELLED';
    case ENDED = 'ENDED';
    case MISSED = 'MISSED';
    case TIMEOUT = 'TIMEOUT';
}
