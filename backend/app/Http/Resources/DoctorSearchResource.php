<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DoctorSearchResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'user_id' => $this->user_id,
            'first_name' => $this->user?->first_name,
            'last_name' => $this->user?->last_name,
            'email' => $this->user?->email,
            'phone' => $this->user?->phone,
            'rpps' => $this->rpps,
            'specialty' => $this->specialty,
            'bio' => $this->bio,
            'consultation_fee' => $this->consultation_fee,
            'city' => $this->city,
            'address' => $this->address,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'avatar_url' => $this->avatar_url,
            'rating' => (float) ($this->rating ?? 0),
            'total_reviews' => (int) ($this->total_reviews ?? 0),
            'is_available_for_video' => (bool) $this->is_available_for_video,
            'schedules' => ScheduleSlotResource::collection($this->whenLoaded('schedules')),
        ];
    }
}
