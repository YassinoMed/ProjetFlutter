<?php

namespace App\Enums;

enum SecretaryInvitationStatus: string
{
    case PENDING = 'PENDING';
    case ACCEPTED = 'ACCEPTED';
    case EXPIRED = 'EXPIRED';
    case REVOKED = 'REVOKED';
}
