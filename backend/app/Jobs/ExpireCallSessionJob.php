<?php

namespace App\Jobs;

use App\Services\Calls\CallSessionService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ExpireCallSessionJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public function __construct(public readonly string $callSessionId) {}

    public function handle(CallSessionService $callSessionService): void
    {
        $callSessionService->timeoutIfExpired($this->callSessionId);
    }
}
