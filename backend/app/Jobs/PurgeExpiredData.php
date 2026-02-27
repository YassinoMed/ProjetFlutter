<?php

namespace App\Jobs;

use App\Models\ChatMessage;
use App\Models\EncryptedAttachment;
use App\Models\MedicalRecordMetadata;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class PurgeExpiredData implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public function handle(): void
    {
        $now = now('UTC');

        // Purge expired chat messages
        $expiredMessages = ChatMessage::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', $now)
            ->count();

        ChatMessage::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', $now)
            ->delete();

        // Purge expired medical records metadata
        $expiredRecords = MedicalRecordMetadata::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', $now)
            ->count();

        MedicalRecordMetadata::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', $now)
            ->delete();

        // Purge expired encrypted attachments (also delete files)
        $expiredAttachments = EncryptedAttachment::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', $now)
            ->get();

        foreach ($expiredAttachments as $attachment) {
            Storage::disk('local')->delete($attachment->storage_path);
            $attachment->delete();
        }

        Log::channel('security')->info('data_minimization_purge', [
            'expired_messages' => $expiredMessages,
            'expired_records' => $expiredRecords,
            'expired_attachments' => $expiredAttachments->count(),
            'purged_at_utc' => $now->toISOString(),
        ]);
    }
}
