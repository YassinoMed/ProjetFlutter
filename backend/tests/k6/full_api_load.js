/**
 * k6 Load Test: Full API Scenario
 * CDC: Performance requirements - 200 concurrent users
 *
 * Usage: k6 run tests/k6/full_api_load.js --env BASE_URL=http://localhost:8080/api
 */
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const loginDuration = new Trend('login_duration');
const appointmentDuration = new Trend('appointment_duration');
const chatDuration = new Trend('chat_duration');

// Test configuration matching CDC performance requirements
export const options = {
    stages: [
        { duration: '30s', target: 50 },    // Ramp up to 50 users
        { duration: '1m', target: 100 },    // Ramp to 100
        { duration: '2m', target: 200 },    // Peak at 200 concurrent (CDC requirement)
        { duration: '1m', target: 100 },    // Ramp down
        { duration: '30s', target: 0 },     // Cooldown
    ],
    thresholds: {
        http_req_duration: ['p(95)<500', 'p(99)<1000'],   // CDC: 95th < 500ms
        http_req_failed: ['rate<0.01'],                    // CDC: Error rate < 1%
        errors: ['rate<0.01'],
        login_duration: ['p(95)<300'],
        appointment_duration: ['p(95)<500'],
        chat_duration: ['p(95)<200'],
    },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080/api';

export default function () {
    let token = '';

    // ── Phase 1: Authentication ──────────────────────────
    group('Authentication', () => {
        // Register a unique user
        const email = `loadtest_${__VU}_${__ITER}@mediconnect.local`;
        const registerRes = http.post(`${BASE_URL}/auth/register`, JSON.stringify({
            email: email,
            password: 'Password123!',
            password_confirmation: 'Password123!',
            first_name: 'Load',
            last_name: `Test_${__VU}`,
        }), { headers: { 'Content-Type': 'application/json' } });

        check(registerRes, { 'register status 201': (r) => r.status === 201 });
        errorRate.add(registerRes.status !== 201);

        if (registerRes.status === 201) {
            const body = JSON.parse(registerRes.body);
            token = body.data?.token || '';
        }

        // Login
        const loginStart = Date.now();
        const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
            email: email,
            password: 'Password123!',
        }), { headers: { 'Content-Type': 'application/json' } });

        loginDuration.add(Date.now() - loginStart);
        check(loginRes, { 'login status 200': (r) => r.status === 200 });
        errorRate.add(loginRes.status !== 200);

        if (loginRes.status === 200) {
            const body = JSON.parse(loginRes.body);
            token = body.data?.token || token;
        }
    });

    if (!token) return;

    const authHeaders = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
    };

    sleep(1);

    // ── Phase 2: Doctor Search ───────────────────────────
    group('Doctor Search', () => {
        const doctorsRes = http.get(`${BASE_URL}/doctors?per_page=10`, { headers: authHeaders });
        check(doctorsRes, { 'doctors list 200': (r) => r.status === 200 });
        errorRate.add(doctorsRes.status !== 200);

        const specialtiesRes = http.get(`${BASE_URL}/doctors/specialties`, { headers: authHeaders });
        check(specialtiesRes, { 'specialties 200': (r) => r.status === 200 });
    });

    sleep(0.5);

    // ── Phase 3: Appointments ────────────────────────────
    group('Appointments', () => {
        const start = Date.now();
        const listRes = http.get(`${BASE_URL}/appointments?per_page=10`, { headers: authHeaders });
        appointmentDuration.add(Date.now() - start);
        check(listRes, { 'appointments list 200': (r) => r.status === 200 });
        errorRate.add(listRes.status !== 200);
    });

    sleep(0.5);

    // ── Phase 4: Profile ─────────────────────────────────
    group('Profile', () => {
        const profileRes = http.get(`${BASE_URL}/profile`, { headers: authHeaders });
        check(profileRes, { 'profile 200': (r) => r.status === 200 });
        errorRate.add(profileRes.status !== 200);
    });

    sleep(0.5);

    // ── Phase 5: Medical Records ─────────────────────────
    group('Medical Records', () => {
        const recordsRes = http.get(`${BASE_URL}/medical-records?per_page=10`, { headers: authHeaders });
        check(recordsRes, { 'medical records 200': (r) => r.status === 200 });
        errorRate.add(recordsRes.status !== 200);
    });

    sleep(0.5);

    // ── Phase 6: RGPD Export ─────────────────────────────
    group('RGPD', () => {
        const exportRes = http.get(`${BASE_URL}/rgpd/export`, { headers: authHeaders });
        check(exportRes, { 'rgpd export 200': (r) => r.status === 200 });
        errorRate.add(exportRes.status !== 200);
    });

    sleep(1);

    // ── Phase 7: Logout ──────────────────────────────────
    group('Logout', () => {
        const logoutRes = http.post(`${BASE_URL}/auth/logout`, null, { headers: authHeaders });
        check(logoutRes, { 'logout 200': (r) => r.status === 200 });
    });
}
