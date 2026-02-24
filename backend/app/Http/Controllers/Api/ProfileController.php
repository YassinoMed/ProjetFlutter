<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Profiles\UpdateProfileRequest;
use App\Http\Resources\DoctorProfileResource;
use App\Http\Resources\PatientProfileResource;
use App\Http\Resources\UserResource;
use App\Models\Doctor;
use App\Models\Patient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        $patientProfile = null;
        $doctorProfile = null;

        if ($user->role === UserRole::PATIENT) {
            $patientProfile = $user->patientProfile;
        }

        if ($user->role === UserRole::DOCTOR) {
            $doctorProfile = $user->doctorProfile;
        }

        return response()->json([
            'user' => new UserResource($user),
            'patient_profile' => $patientProfile ? new PatientProfileResource($patientProfile) : null,
            'doctor_profile' => $doctorProfile ? new DoctorProfileResource($doctorProfile) : null,
        ]);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validated();

        $userFields = array_intersect_key($data, array_flip(['first_name', 'last_name', 'phone']));

        if ($userFields !== []) {
            $user->update($userFields);
        }

        $patientProfile = null;
        $doctorProfile = null;

        if ($user->role === UserRole::PATIENT) {
            $patientFields = array_intersect_key($data, array_flip(['date_of_birth', 'sex']));

            if ($patientFields !== []) {
                $patientProfile = Patient::query()->updateOrCreate(
                    ['user_id' => $user->id],
                    $patientFields,
                );
            } else {
                $patientProfile = $user->patientProfile;
            }
        }

        if ($user->role === UserRole::DOCTOR) {
            $doctorFields = array_intersect_key($data, array_flip(['rpps', 'specialty']));

            if ($doctorFields !== []) {
                $doctorProfile = Doctor::query()->updateOrCreate(
                    ['user_id' => $user->id],
                    $doctorFields,
                );
            } else {
                $doctorProfile = $user->doctorProfile;
            }
        }

        return response()->json([
            'user' => new UserResource($user->refresh()),
            'patient_profile' => $patientProfile ? new PatientProfileResource($patientProfile) : null,
            'doctor_profile' => $doctorProfile ? new DoctorProfileResource($doctorProfile) : null,
        ]);
    }
}
