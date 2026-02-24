import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 5,
  duration: '30s',
};

const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';
const token = __ENV.ACCESS_TOKEN || '';
const appointmentId = __ENV.APPOINTMENT_ID || '';

const headers = token ? { Authorization: `Bearer ${token}` } : {};

export default function () {
  if (!token || !appointmentId) {
    sleep(1);
    return;
  }

  const join = http.post(`${baseUrl}/api/consultations/${appointmentId}/webrtc/join`, null, { headers });
  check(join, { 'join ok': (r) => r.status === 200 });

  const offer = http.post(
    `${baseUrl}/api/consultations/${appointmentId}/webrtc/offer`,
    JSON.stringify({ sdp: 'v=0', sdp_type: 'offer' }),
    { headers: { ...headers, 'Content-Type': 'application/json' } }
  );
  check(offer, { 'offer ok': (r) => r.status === 200 });

  const message = http.post(
    `${baseUrl}/api/consultations/${appointmentId}/messages`,
    JSON.stringify({ ciphertext: 'ciphertext', nonce: 'nonce', algorithm: 'xchacha20poly1305' }),
    { headers: { ...headers, 'Content-Type': 'application/json' } }
  );
  check(message, { 'message ok': (r) => r.status === 201 });

  sleep(1);
}
