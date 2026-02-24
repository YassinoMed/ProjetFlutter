<?php

namespace App\Enums;

enum ChatMessageStatus: string
{
    case SENT = 'SENT';
    case DELIVERED = 'DELIVERED';
    case READ = 'READ';
}
