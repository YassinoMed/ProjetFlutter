<?php

namespace App\Services\Documents;

use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

class DocumentStorageService
{
    public function store(UploadedFile $file, User $actor): array
    {
        $disk = (string) config('documents.disk', 'local');
        $directory = trim((string) config('documents.directory', 'medical-documents'), '/');
        $extension = strtolower($file->getClientOriginalExtension() ?: $file->extension() ?: 'bin');
        $storagePath = $file->storeAs(
            $directory.'/'.$actor->id,
            (string) Str::uuid().'.'.$extension,
            $disk,
        );

        return [
            'storage_disk' => $disk,
            'storage_path' => $storagePath,
            'sha256_checksum' => hash_file('sha256', $file->getRealPath()),
            'mime_type' => $file->getMimeType() ?: 'application/octet-stream',
            'file_extension' => $extension,
            'file_size_bytes' => $file->getSize(),
            'original_filename' => $file->getClientOriginalName(),
        ];
    }
}
