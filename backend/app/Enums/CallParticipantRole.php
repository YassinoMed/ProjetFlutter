<?php

namespace App\Enums;

enum CallParticipantRole: string
{
    case CALLER = 'CALLER';
    case CALLEE = 'CALLEE';
}
