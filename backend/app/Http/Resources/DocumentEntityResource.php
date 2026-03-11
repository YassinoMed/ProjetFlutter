<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DocumentEntityResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'version' => $this->version,
            'entity_type' => $this->entity_type,
            'label' => $this->label,
            'value' => $this->value_encrypted,
            'is_sensitive' => $this->is_sensitive,
            'confidence_score' => $this->confidence_score,
            'qualifiers' => $this->qualifiers,
        ];
    }
}
