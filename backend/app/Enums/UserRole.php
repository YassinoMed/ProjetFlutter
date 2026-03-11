<?php

namespace App\Enums;

enum UserRole: string
{
    case PATIENT = 'PATIENT';
    case DOCTOR = 'DOCTOR';
    case SECRETARY = 'SECRETARY';
    case ADMIN = 'ADMIN';
}
