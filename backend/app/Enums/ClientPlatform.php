<?php

namespace App\Enums;

enum ClientPlatform: string
{
    case IOS = 'ios';
    case ANDROID = 'android';
    case WEB = 'web';
    case MACOS = 'macos';
    case WINDOWS = 'windows';
    case LINUX = 'linux';
    case FUCHSIA = 'fuchsia';
    case UNKNOWN = 'unknown';

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(static fn (self $platform) => $platform->value, self::cases());
    }
}
