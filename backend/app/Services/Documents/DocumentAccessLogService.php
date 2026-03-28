<?php

namespace App\Services\Documents;

use App\Models\Document;
use App\Models\DocumentAccessLog;
use App\Models\User;
use Illuminate\Http\Request;

class DocumentAccessLogService
{
    public function log(
        Document $document,
        ?User $actor,
        string $action,
        ?Request $request = null,
        ?string $audience = null,
        array $context = [],
    ): void {
        DocumentAccessLog::query()->create([
            'document_id' => $document->id,
            'actor_user_id' => $actor?->id,
            'action' => $action,
            'audience' => $audience,
            'ip_address' => $request?->ip(),
            'user_agent' => $request?->userAgent(),
            'context' => $context,
            'accessed_at_utc' => now('UTC'),
        ]);
    }
}
