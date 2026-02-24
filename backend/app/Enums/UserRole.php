<?php

namespace App\Enums;

enum UserRole: string
{
    case PATIENT = 'PATIENT';
    case DOCTOR = 'DOCTOR';
    case ADMIN = 'ADMIN';
}
