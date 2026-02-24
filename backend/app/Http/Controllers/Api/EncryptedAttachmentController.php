<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Resources\EncryptedAttachmentResource;
use App\Models\EncryptedAttachment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

class EncryptedAttachmentController extends Controller
{
    /**
     * Upload an E2E-encrypted attachment.
     *
     * The client MUST encrypt the file locally before uploading.
     * The server receives only the encrypted blob + metadata.
     */
    public function upload(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|file|max:20480', // 20 MB max
            'encrypted_key' => 'required|string',
            'key_id' => 'nullable|string|max:255',
            'nonce' => 'required|string|max:64',
            'algorithm' => 'nullable|string|max:32',
            'original_filename' => 'required|string|max:500',
            'mime_type' => 'required|string|max:128',
            'checksum_sha256' => 'required|string|size:64',
            'attachable_type' => 'nullable|string|in:chat_message,medical_record',
            'attachable_id' => 'nullable|uuid',
            'ttl_days' => 'nullable|integer|min:1|max:3650',
        ]);

        $user = $request->user();
        $file = $request->file('file');
        $ttlDays = $request->integer('ttl_days', $this->defaultTtlDays($request->string('attachable_type', '')));

        // Store the encrypted blob
        $storagePath = $file->store('encrypted-attachments/' . $user->id, 'local');

        // Map attachable_type to model class
        $attachableType = match ($request->string('attachable_type', '')) {
            'chat_message' => \App\Models\ChatMessage::class,
            'medical_record' => \App\Models\MedicalRecordMetadata::class,
            default => null,
        };

        $attachment = EncryptedAttachment::query()->create([
            'owner_user_id' => $user->id,
            'attachable_type' => $attachableType,
            'attachable_id' => $request->input('attachable_id'),
            'original_filename' => $request->input('original_filename'),
            'mime_type' => $request->input('mime_type'),
            'file_size_bytes' => $file->getSize(),
            'storage_path' => $storagePath,
            'encrypted_key' => $request->input('encrypted_key'),
            'key_id' => $request->input('key_id'),
            'nonce' => $request->input('nonce'),
            'algorithm' => $request->input('algorithm', 'AES-256-GCM'),
            'checksum_sha256' => $request->input('checksum_sha256'),
            'expires_at' => $ttlDays > 0 ? now()->addDays($ttlDays) : null,
        ]);

        activity('attachment')
            ->performedOn($attachment)
            ->causedBy($user)
            ->withProperties(['action' => 'upload', 'file_size' => $file->getSize()])
            ->log('E2EE attachment uploaded');

        return response()->json([
            'attachment' => new EncryptedAttachmentResource($attachment),
        ], 201);
    }

    /**
     * Download the encrypted blob.
     * The client will decrypt it locally.
     */
    public function download(string $attachmentId, Request $request): StreamedResponse
    {
        $attachment = EncryptedAttachment::query()
            ->active()
            ->findOrFail($attachmentId);

        $this->assertCanAccess($request->user(), $attachment);

        if (! Storage::disk('local')->exists($attachment->storage_path)) {
            throw new NotFoundHttpException('Encrypted file not found on storage.');
        }

        activity('attachment')
            ->performedOn($attachment)
            ->causedBy($request->user())
            ->withProperties(['action' => 'download'])
            ->log('E2EE attachment downloaded');

        return Storage::disk('local')->download(
            $attachment->storage_path,
            $attachment->original_filename . '.enc',
            [
                'Content-Type' => 'application/octet-stream',
                'X-Encryption-Algorithm' => $attachment->algorithm,
                'X-Encryption-Nonce' => $attachment->nonce,
                'X-Encryption-Key-Id' => $attachment->key_id ?? '',
                'X-Checksum-SHA256' => $attachment->checksum_sha256,
            ]
        );
    }

    /**
     * Get attachment metadata (without the file).
     */
    public function show(string $attachmentId, Request $request): JsonResponse
    {
        $attachment = EncryptedAttachment::query()
            ->active()
            ->findOrFail($attachmentId);

        $this->assertCanAccess($request->user(), $attachment);

        return response()->json([
            'attachment' => new EncryptedAttachmentResource($attachment),
        ]);
    }

    /**
     * Delete an attachment (RGPD right to erasure).
     */
    public function destroy(string $attachmentId, Request $request): JsonResponse
    {
        $attachment = EncryptedAttachment::query()->findOrFail($attachmentId);

        $user = $request->user();
        if ($attachment->owner_user_id !== $user->id && $user->role !== UserRole::ADMIN) {
            throw new AccessDeniedHttpException;
        }

        // Delete the file from disk
        Storage::disk('local')->delete($attachment->storage_path);

        activity('attachment')
            ->performedOn($attachment)
            ->causedBy($user)
            ->withProperties(['action' => 'delete'])
            ->log('E2EE attachment deleted');

        $attachment->delete();

        return response()->json(['ok' => true]);
    }

    /**
     * Access control: owner, doctor in the consultation, or admin.
     */
    private function assertCanAccess($user, EncryptedAttachment $attachment): void
    {
        if ($user->role === UserRole::ADMIN) {
            return;
        }

        if ($attachment->owner_user_id === $user->id) {
            return;
        }

        // If attached to a chat message, check if the user is part of the consultation
        if ($attachment->attachable_type === \App\Models\ChatMessage::class && $attachment->attachable_id) {
            $message = \App\Models\ChatMessage::query()->find($attachment->attachable_id);
            if ($message && ($message->sender_user_id === $user->id || $message->recipient_user_id === $user->id)) {
                return;
            }
        }

        // If attached to a medical record, check patient/doctor
        if ($attachment->attachable_type === \App\Models\MedicalRecordMetadata::class && $attachment->attachable_id) {
            $record = \App\Models\MedicalRecordMetadata::query()->find($attachment->attachable_id);
            if ($record && ($record->patient_user_id === $user->id || $record->doctor_user_id === $user->id)) {
                return;
            }
        }

        throw new AccessDeniedHttpException;
    }

    private function defaultTtlDays(string $attachableType): int
    {
        return match ($attachableType) {
            'chat_message' => (int) env('CHAT_MESSAGE_TTL_DAYS', 730),
            'medical_record' => (int) env('MEDICAL_RECORD_TTL_DAYS', 3650),
            default => (int) env('CHAT_MESSAGE_TTL_DAYS', 730),
        };
    }
}
