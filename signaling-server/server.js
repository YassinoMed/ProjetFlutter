const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const cors = require('cors');

require('dotenv').config();

const app = express();
app.use(cors());

const server = http.createServer(app);

const io = new Server(server, {
    cors: {
        origin: process.env.ALLOWED_ORIGINS || "*",
        credentials: true,
    },
});

// Middleware JWT
io.use((socket, next) => {
    const token = socket.handshake.auth.token || socket.handshake.headers['x-auth-token'];

    if (!token) {
        return next(new Error('Authentication error: No token provided'));
    }

    try {
        // Dans un projet réel, utilisez une vraie clé secrète partagée avec le backend Laravel
        // Ex: jwt.verify(token, process.env.JWT_SECRET)
        const SECRET = process.env.JWT_SECRET || 'secret';
        const payload = jwt.verify(token, SECRET);

        socket.userId = payload.sub || payload.id;
        socket.role = payload.role; // 'doctor' ou 'patient'
        next();
    } catch (err) {
        next(new Error('Authentication error: Invalid token'));
    }
});

io.on('connection', (socket) => {
    console.log(`[+] User connected: ${socket.userId} (Role: ${socket.role}, SocketID: ${socket.id})`);

    // Rejoindre la room spécifique à une consultation
    socket.on('join_consultation', ({ consultationId }) => {
        if (!consultationId) return;
        const room = `consultation:${consultationId}`;
        socket.join(room);
        console.log(`[ROOM] User ${socket.userId} joined ${room}`);

        // Notifier les autres participants dans la room
        socket.to(room).emit('user_joined', { userId: socket.userId, role: socket.role });
    });

    // Initier l'appel (Médecin) -> envoie notification INCOMING_CALL
    socket.on('start_call', ({ consultationId, to }) => {
        // Si to est le patient, on lui envoie un événement d'appel entrant
        console.log(`[CALL] User ${socket.userId} is calling ${to} in consultation ${consultationId}`);
        socket.to(`consultation:${consultationId}`).emit('incoming_call', {
            from: socket.userId,
            consultationId: consultationId
        });
    });

    // Patient accepte l'appel
    socket.on('accept_call', ({ consultationId, to }) => {
        console.log(`[CALL] User ${socket.userId} accepted call from ${to}`);
        socket.to(`consultation:${consultationId}`).emit('call_accepted', {
            from: socket.userId,
            consultationId: consultationId
        });
    });

    // Signalisation WebRTC - Offre SDP
    socket.on('webrtc_offer', ({ consultationId, sdp }) => {
        console.log(`[SDP] Offer from ${socket.userId} for consultation ${consultationId}`);
        socket.to(`consultation:${consultationId}`).emit('webrtc_offer', {
            from: socket.userId,
            sdp
        });
    });

    // Signalisation WebRTC - Réponse SDP
    socket.on('webrtc_answer', ({ consultationId, sdp }) => {
        console.log(`[SDP] Answer from ${socket.userId} for consultation ${consultationId}`);
        socket.to(`consultation:${consultationId}`).emit('webrtc_answer', {
            from: socket.userId,
            sdp
        });
    });

    // Signalisation WebRTC - ICE Candidates
    socket.on('webrtc_ice_candidate', ({ consultationId, candidate }) => {
        console.log(`[ICE] Candidate from ${socket.userId} for consultation ${consultationId}`);
        socket.to(`consultation:${consultationId}`).emit('webrtc_ice_candidate', {
            from: socket.userId,
            candidate
        });
    });

    // Fin de l'appel
    socket.on('end_call', ({ consultationId }) => {
        console.log(`[CALL] Ended by ${socket.userId} for consultation ${consultationId}`);
        socket.to(`consultation:${consultationId}`).emit('call_ended', {
            from: socket.userId,
            consultationId
        });
    });

    socket.on('disconnect', () => {
        console.log(`[-] User disconnected: ${socket.userId} (SocketID: ${socket.id})`);
    });
});

const PORT = process.env.PORT || 3000;

if (require.main === module) {
    server.listen(PORT, () => {
        console.log(`Signaling server running on port ${PORT}`);
    });
}

module.exports = { app, server, io }; // Pour les tests
