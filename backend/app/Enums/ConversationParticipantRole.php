<?php

namespace App\Enums;

enum ConversationParticipantRole: string
{
    case PATIENT = 'PATIENT';
    case DOCTOR = 'DOCTOR';
}
