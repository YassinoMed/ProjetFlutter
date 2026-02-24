<?php

namespace App\Enums;

enum AppointmentStatus: string
{
    case DRAFT = 'DRAFT';
    case REQUESTED = 'REQUESTED';
    case CONFIRMED = 'CONFIRMED';
    case CANCELLED = 'CANCELLED';
    case COMPLETED = 'COMPLETED';

    public function canTransitionTo(self $next): bool
    {
        return match ($this) {
            self::DRAFT => in_array($next, [self::REQUESTED, self::CANCELLED], true),
            self::REQUESTED => in_array($next, [self::CONFIRMED, self::CANCELLED], true),
            self::CONFIRMED => in_array($next, [self::COMPLETED, self::CANCELLED], true),
            self::CANCELLED => false,
            self::COMPLETED => false,
        };
    }
}
