import ws from 'k6/ws';
import { check } from 'k6';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export const options = {
    stages: [
        { duration: '1m', target: 50 }, // Ramp up to 50 users over 1 minute
        { duration: '2m', target: 500 }, // Ramp up to 500 users
        { duration: '1m', target: 500 }, // Stay at 500 users for 1 minute
        { duration: '1m', target: 0 }, // Ramp down to 0 users
    ],
};

export default function () {
    const url = 'ws://localhost:3000/socket.io/?EIO=4&transport=websocket';
    // generate a fake token or use a predefined one
    const params = { tags: { my_tag: 'hello' } };

    const res = ws.connect(url, params, function (socket) {
        socket.on('open', () => {
            // Simulate client authenticating (in real scenario, pass token in query)
            check(socket, { 'connected successfully': (s) => true });

            const consultationId = `consultation_${randomString(5)}`;

            // Join consultation room
            const joinMsg = `42["join_consultation", {"consultationId": "${consultationId}"}]`;
            socket.send(joinMsg);

            // Send dummy SDP offer
            socket.setTimeout(function () {
                const offerMsg = `42["webrtc_offer", {"consultationId": "${consultationId}", "sdp": {"type": "offer", "sdp": "dummy"}}]`;
                socket.send(offerMsg);
            }, 1000);

            socket.setTimeout(function () {
                socket.close();
            }, 30000); // Close after 30 seconds
        });

        socket.on('message', (msg) => {
            check(msg, { 'received message': (m) => m && m.length > 0 });
        });

        socket.on('close', () => {
            check(socket, { 'closed': (s) => true });
        });
    });

    check(res, { 'status is 101': (r) => r && r.status === 101 });
}
