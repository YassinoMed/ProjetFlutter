<?php

namespace App\Enums;

enum MessageType: string
{
    case TEXT = 'TEXT';
    case ATTACHMENT = 'ATTACHMENT';
    case SYSTEM = 'SYSTEM';
}
