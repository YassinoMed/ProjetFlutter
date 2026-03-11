<?php

namespace App\Enums;

enum SecretaryPermission: string
{
    case MANAGE_APPOINTMENTS = 'MANAGE_APPOINTMENTS';
    case MANAGE_SCHEDULE = 'MANAGE_SCHEDULE';
    case VIEW_PATIENT_LIST = 'VIEW_PATIENT_LIST';
    case SEND_ADMIN_MESSAGES = 'SEND_ADMIN_MESSAGES';
    case VIEW_ADMIN_INFO = 'VIEW_ADMIN_INFO';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(static fn (self $permission) => $permission->value, self::cases());
    }
}
