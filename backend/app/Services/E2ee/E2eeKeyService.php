<?php

namespace App\Services\E2ee;

use App\Models\User;
use App\Models\UserE2eeDevice;
use App\Models\UserE2eePreKey;
use App\Services\Conversations\ConversationService;
use Illuminate\Support\Facades\DB;

class E2eeKeyService
{
    public function __construct(private readonly ConversationService $conversationService) {}

    public function upsertOwnDevice(User $user, array $payload): UserE2eeDevice
    {
        return DB::transaction(function () use ($user, $payload): UserE2eeDevice {
            $device = UserE2eeDevice::query()->updateOrCreate(
                [
                    'user_id' => $user->id,
                    'device_id' => $payload['device_id'],
                ],
                [
                    'device_label' => $payload['device_label'] ?? null,
                    'bundle_version' => $payload['bundle_version'],
                    'identity_key_algorithm' => $payload['identity_key_algorithm'],
                    'identity_key_public' => $payload['identity_key_public'],
                    'signed_pre_key_id' => $payload['signed_pre_key_id'],
                    'signed_pre_key_public' => $payload['signed_pre_key_public'],
                    'signed_pre_key_signature' => $payload['signed_pre_key_signature'],
                    'last_seen_at_utc' => now('UTC'),
                    'revoked_at' => null,
                ],
            );

            foreach ($payload['one_time_pre_keys'] ?? [] as $preKey) {
                UserE2eePreKey::query()->updateOrCreate(
                    [
                        'user_e2ee_device_id' => $device->id,
                        'key_id' => $preKey['key_id'],
                    ],
                    [
                        'public_key' => $preKey['public_key'],
                        'consumed_at_utc' => null,
                    ],
                );
            }

            return $device->load('preKeys');
        });
    }

    public function getPeerBundle(User $requester, User $peer, ?string $consultationId = null): array
    {
        $consultation = $this->conversationService->findAuthorizedConsultationBetween($requester, $peer, $consultationId);

        $devices = DB::transaction(function () use ($peer): array {
            return UserE2eeDevice::query()
                ->where('user_id', $peer->id)
                ->whereNull('revoked_at')
                ->with(['preKeys' => function ($query): void {
                    $query->whereNull('consumed_at_utc')->orderBy('id');
                }])
                ->lockForUpdate()
                ->get()
                ->map(function (UserE2eeDevice $device): array {
                    $preKey = $device->preKeys->first();

                    if ($preKey !== null) {
                        $preKey->forceFill(['consumed_at_utc' => now('UTC')])->save();
                    }

                    return [
                        'device_id' => $device->device_id,
                        'device_label' => $device->device_label,
                        'bundle_version' => $device->bundle_version,
                        'identity_key_algorithm' => $device->identity_key_algorithm,
                        'identity_key_public' => $device->identity_key_public,
                        'signed_pre_key' => [
                            'key_id' => $device->signed_pre_key_id,
                            'public_key' => $device->signed_pre_key_public,
                            'signature' => $device->signed_pre_key_signature,
                        ],
                        'one_time_pre_key' => $preKey === null ? null : [
                            'key_id' => $preKey->key_id,
                            'public_key' => $preKey->public_key,
                        ],
                    ];
                })
                ->all();
        });

        return [
            'user_id' => $peer->id,
            'consultation_id' => $consultation->id,
            'devices' => $devices,
        ];
    }
}
