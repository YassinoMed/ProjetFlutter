<?php

namespace App\Enums;

enum DeviceTokenProvider: string
{
    case FCM = 'FCM';
    case APNS = 'APNS';
}
