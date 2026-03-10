<?php

namespace App\Enums;

enum MessageReceiptStatus: string
{
    case SENT = 'SENT';
    case DELIVERED = 'DELIVERED';
    case READ = 'READ';
}
