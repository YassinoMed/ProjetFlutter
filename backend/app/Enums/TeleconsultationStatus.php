<?php

namespace App\Enums;

enum TeleconsultationStatus: string
{
    case SCHEDULED = 'scheduled';
    case WAITING = 'waiting';
    case ACTIVE = 'active';
    case ENDED = 'ended';
    case CANCELLED = 'cancelled';
    case EXPIRED = 'expired';

    public function canTransitionTo(self $next): bool
    {
        return match ($this) {
            self::SCHEDULED => in_array($next, [self::WAITING, self::CANCELLED, self::EXPIRED], true),
            self::WAITING => in_array($next, [self::ACTIVE, self::CANCELLED, self::EXPIRED], true),
            self::ACTIVE => $next === self::ENDED,
            self::ENDED, self::CANCELLED, self::EXPIRED => false,
        };
    }

    public function isTerminal(): bool
    {
        return in_array($this, [self::ENDED, self::CANCELLED, self::EXPIRED], true);
    }
}
