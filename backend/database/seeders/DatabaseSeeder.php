<?php

namespace Database\Seeders;

use App\Enums\AppointmentStatus;
use App\Enums\UserRole;
use App\Models\Appointment;
use App\Models\AppointmentEvent;
use App\Models\Doctor;
use App\Models\DoctorSchedule;
use App\Models\Patient;
use App\Models\User;
use App\Models\UserConsent;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    private static ?string $hashedPassword = null;

    public function run(): void
    {
        self::$hashedPassword ??= Hash::make('password');

        // ── Admin ───────────────────────────────────────────
        $admin = $this->createUser('admin@mediconnect.local', 'Admin', 'MediConnect', UserRole::ADMIN);

        // ── Doctors ─────────────────────────────────────────
        $doctors = $this->seedDoctors();

        // ── Patients ────────────────────────────────────────
        $patients = $this->seedPatients();

        // ── Appointments ────────────────────────────────────
        $this->seedAppointments($doctors, $patients);

        // ── RGPD Consents ───────────────────────────────────
        foreach ($patients as $patient) {
            $this->seedConsents($patient);
        }
    }

    private function seedDoctors(): array
    {
        $specialties = [
            ['Cardiologie', 'Paris', '45 Rue de la Santé', 48.8340, 2.3408, '60€'],
            ['Dermatologie', 'Lyon', '12 Avenue de la médecine', 45.7578, 4.8320, '50€'],
            ['Ophtalmologie', 'Marseille', '9 Boulevard des yeux', 43.2965, 5.3698, '55€'],
            ['Pédiatrie', 'Toulouse', '33 Rue des enfants', 43.6047, 1.4442, '45€'],
            ['Psychiatrie', 'Bordeaux', '7 Place de la sérénité', 44.8378, -0.5792, '70€'],
            ['Médecine Générale', 'Paris', '120 Rue principale', 48.8566, 2.3522, '25€'],
            ['Neurologie', 'Nice', '5 Promenade du cerveau', 43.7102, 7.2620, '65€'],
            ['Gynécologie', 'Nantes', '15 Rue de la maternité', 47.2184, -1.5536, '55€'],
            ['Orthopédie', 'Strasbourg', '22 Avenue des os', 48.5734, 7.7521, '60€'],
            ['ORL', 'Lille', '8 Rue de l\'audition', 50.6292, 3.0573, '50€'],
        ];

        $doctors = [];

        foreach ($specialties as $i => [$specialty, $city, $address, $lat, $lng, $fee]) {
            $firstName = fake()->firstName();
            $lastName = fake()->lastName();

            $user = $this->createUser(
                "dr.{$i}@mediconnect.local",
                $firstName,
                $lastName,
                UserRole::DOCTOR,
                fake()->phoneNumber(),
            );

            Doctor::query()->create([
                'user_id' => $user->id,
                'rpps' => sprintf('RPPS%09d', $i + 1),
                'specialty' => $specialty,
                'bio' => "Dr. {$firstName} {$lastName}, spécialiste en {$specialty} avec plus de " . rand(5, 25) . " ans d'expérience.",
                'consultation_fee' => $fee,
                'city' => $city,
                'address' => $address,
                'latitude' => $lat,
                'longitude' => $lng,
                'rating' => round(rand(35, 50) / 10, 2),
                'total_reviews' => rand(10, 250),
                'is_available_for_video' => true,
            ]);

            // Create weekly schedule (Mon-Fri, 09:00-17:00)
            for ($day = 1; $day <= 5; $day++) {
                DoctorSchedule::query()->create([
                    'doctor_user_id' => $user->id,
                    'day_of_week' => $day,
                    'start_time' => '09:00',
                    'end_time' => '12:30',
                    'slot_duration_minutes' => 30,
                    'is_active' => true,
                ]);

                DoctorSchedule::query()->create([
                    'doctor_user_id' => $user->id,
                    'day_of_week' => $day,
                    'start_time' => '14:00',
                    'end_time' => '17:30',
                    'slot_duration_minutes' => 30,
                    'is_active' => true,
                ]);
            }

            $doctors[] = $user;
        }

        return $doctors;
    }

    private function seedPatients(): array
    {
        $patients = [];

        // Default test patient
        $testPatient = $this->createUser('patient@mediconnect.local', 'Jean', 'Dupont', UserRole::PATIENT, '+33612345678');
        Patient::query()->create([
            'user_id' => $testPatient->id,
            'date_of_birth' => '1990-05-15',
            'sex' => 'M',
        ]);
        $patients[] = $testPatient;

        // Additional patients
        for ($i = 0; $i < 5; $i++) {
            $user = $this->createUser(
                "patient.{$i}@mediconnect.local",
                fake()->firstName(),
                fake()->lastName(),
                UserRole::PATIENT,
                fake()->phoneNumber(),
            );

            Patient::query()->create([
                'user_id' => $user->id,
                'date_of_birth' => fake()->dateTimeBetween('-70 years', '-18 years')->format('Y-m-d'),
                'sex' => fake()->randomElement(['M', 'F']),
            ]);

            $patients[] = $user;
        }

        return $patients;
    }

    private function seedAppointments(array $doctors, array $patients): void
    {
        // Past completed appointment
        $pastStart = Carbon::now('UTC')->subDays(3)->setTime(10, 0);
        $appt1 = Appointment::query()->create([
            'patient_user_id' => $patients[0]->id,
            'doctor_user_id' => $doctors[0]->id,
            'starts_at_utc' => $pastStart,
            'ends_at_utc' => $pastStart->copy()->addMinutes(30),
            'status' => AppointmentStatus::COMPLETED,
        ]);
        AppointmentEvent::query()->create([
            'appointment_id' => $appt1->id,
            'actor_user_id' => $patients[0]->id,
            'from_status' => null,
            'to_status' => 'COMPLETED',
            'occurred_at_utc' => $pastStart->copy()->addMinutes(30),
        ]);

        // Upcoming confirmed appointment
        $futureStart = Carbon::now('UTC')->addDays(2)->setTime(14, 0);
        $appt2 = Appointment::query()->create([
            'patient_user_id' => $patients[0]->id,
            'doctor_user_id' => $doctors[1]->id,
            'starts_at_utc' => $futureStart,
            'ends_at_utc' => $futureStart->copy()->addMinutes(30),
            'status' => AppointmentStatus::CONFIRMED,
        ]);
        AppointmentEvent::query()->create([
            'appointment_id' => $appt2->id,
            'actor_user_id' => $patients[0]->id,
            'from_status' => null,
            'to_status' => 'REQUESTED',
            'occurred_at_utc' => now('UTC')->subDay(),
        ]);
        AppointmentEvent::query()->create([
            'appointment_id' => $appt2->id,
            'actor_user_id' => $doctors[1]->id,
            'from_status' => 'REQUESTED',
            'to_status' => 'CONFIRMED',
            'occurred_at_utc' => now('UTC'),
        ]);

        // Requested appointment (pending confirmation)
        $futureStart2 = Carbon::now('UTC')->addDays(5)->setTime(9, 30);
        $appt3 = Appointment::query()->create([
            'patient_user_id' => $patients[1]->id,
            'doctor_user_id' => $doctors[2]->id,
            'starts_at_utc' => $futureStart2,
            'ends_at_utc' => $futureStart2->copy()->addMinutes(30),
            'status' => AppointmentStatus::REQUESTED,
        ]);
        AppointmentEvent::query()->create([
            'appointment_id' => $appt3->id,
            'actor_user_id' => $patients[1]->id,
            'from_status' => null,
            'to_status' => 'REQUESTED',
            'occurred_at_utc' => now('UTC'),
        ]);

        // Cancelled appointment
        $pastStart2 = Carbon::now('UTC')->subDays(1)->setTime(11, 0);
        $appt4 = Appointment::query()->create([
            'patient_user_id' => $patients[0]->id,
            'doctor_user_id' => $doctors[3]->id,
            'starts_at_utc' => $pastStart2,
            'ends_at_utc' => $pastStart2->copy()->addMinutes(30),
            'status' => AppointmentStatus::CANCELLED,
            'cancel_reason' => 'Patient indisponible',
        ]);
        AppointmentEvent::query()->create([
            'appointment_id' => $appt4->id,
            'actor_user_id' => $patients[0]->id,
            'from_status' => 'REQUESTED',
            'to_status' => 'CANCELLED',
            'occurred_at_utc' => $pastStart2->copy()->subHours(2),
        ]);
    }

    private function seedConsents(User $user): void
    {
        $consentTypes = ['data_processing', 'medical_data', 'notifications', 'analytics'];

        foreach ($consentTypes as $type) {
            UserConsent::query()->create([
                'user_id' => $user->id,
                'consent_type' => $type,
                'consented' => true,
                'consented_at_utc' => now('UTC'),
            ]);
        }
    }

    private function createUser(string $email, string $firstName, string $lastName, UserRole $role, ?string $phone = null): User
    {
        return User::query()->create([
            'email' => $email,
            'password' => self::$hashedPassword,
            'first_name' => $firstName,
            'last_name' => $lastName,
            'phone' => $phone,
            'role' => $role,
        ]);
    }
}
