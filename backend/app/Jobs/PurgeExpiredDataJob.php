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

/**
 * RGPD Data Minimization: Purge expired data.
 *
 * This job should be scheduled daily via the Laravel scheduler:
 *   $schedule->job(new PurgeExpiredDataJob)->daily()->at('03:00');
 *
 * Behaviour:
 * 1. Deletes chat messages whose expires_at < now()
 * 2. Deletes medical records whose expires_at < now()
 * 3. Deletes encrypted attachments whose expires_at < now() (including blob on disk)
 * 4. Logs everything in the activity log for audit trail
 */
class PurgeExpiredDataJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public function handle(): void
    {
        Log::channel('security')->info('[RGPD] PurgeExpiredDataJob started.');

        $this->purgeExpiredChatMessages();
        $this->purgeExpiredMedicalRecords();
        $this->purgeExpiredAttachments();

        Log::channel('security')->info('[RGPD] PurgeExpiredDataJob completed.');
    }

    private function purgeExpiredChatMessages(): void
    {
        $count = ChatMessage::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now())
            ->count();

        if ($count === 0) {
            return;
        }

        // Delete in chunks to avoid memory issues
        ChatMessage::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now())
            ->chunkById(500, function ($messages) {
                $ids = $messages->pluck('id')->toArray();
                ChatMessage::query()->whereIn('id', $ids)->delete();
            });

        Log::channel('security')->info("[RGPD] Purged {$count} expired chat messages.");

        activity('rgpd_purge')
            ->withProperties(['type' => 'chat_messages', 'count' => $count])
            ->log("Purged {$count} expired chat messages (data minimization).");
    }

    private function purgeExpiredMedicalRecords(): void
    {
        $count = MedicalRecordMetadata::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now())
            ->count();

        if ($count === 0) {
            return;
        }

        MedicalRecordMetadata::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now())
            ->chunkById(200, function ($records) {
                $ids = $records->pluck('id')->toArray();
                MedicalRecordMetadata::query()->whereIn('id', $ids)->delete();
            });

        Log::channel('security')->info("[RGPD] Purged {$count} expired medical records.");

        activity('rgpd_purge')
            ->withProperties(['type' => 'medical_records', 'count' => $count])
            ->log("Purged {$count} expired medical records (data minimization).");
    }

    private function purgeExpiredAttachments(): void
    {
        $count = 0;

        EncryptedAttachment::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now())
            ->chunkById(100, function ($attachments) use (&$count) {
                foreach ($attachments as $attachment) {
                    // Delete the encrypted blob from disk
                    if (Storage::disk('local')->exists($attachment->storage_path)) {
                        Storage::disk('local')->delete($attachment->storage_path);
                    }
                    $attachment->delete();
                    $count++;
                }
            });

        if ($count > 0) {
            Log::channel('security')->info("[RGPD] Purged {$count} expired encrypted attachments.");

            activity('rgpd_purge')
                ->withProperties(['type' => 'encrypted_attachments', 'count' => $count])
                ->log("Purged {$count} expired encrypted attachments (data minimization).");
        }
    }
}
