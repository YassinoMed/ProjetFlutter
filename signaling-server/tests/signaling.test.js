const { createServer } = require("http");
const { Server } = require("socket.io");
const Client = require("socket.io-client");
const jwt = require("jsonwebtoken");

describe("Signaling Server unit tests", () => {
    let io, serverSocket, clientSocket1, clientSocket2;
    const SECRET = process.env.JWT_SECRET || 'secret';

    const token1 = jwt.sign({ sub: 'user_1', role: 'doctor' }, SECRET);
    const token2 = jwt.sign({ sub: 'user_2', role: 'patient' }, SECRET);

    beforeAll((done) => {
        const httpServer = createServer();
        io = new Server(httpServer);

        // Simulate JWT validation logic from server.js
        io.use((socket, next) => {
            const token = socket.handshake.auth.token;
            if (!token) return next(new Error('Authentication error'));
            try {
                const payload = jwt.verify(token, SECRET);
                socket.userId = payload.sub || payload.id;
                socket.role = payload.role;
                next();
            } catch (err) {
                next(new Error('Authentication error'));
            }
        });

        httpServer.listen(() => {
            const port = httpServer.address().port;
            clientSocket1 = new Client(`http://localhost:${port}`, { auth: { token: token1 } });
            clientSocket2 = new Client(`http://localhost:${port}`, { auth: { token: token2 } });

            io.on("connection", (socket) => {
                socket.on('join_consultation', ({ consultationId }) => {
                    socket.join(`consultation:${consultationId}`);
                });

                socket.on('webrtc_offer', ({ consultationId, sdp }) => {
                    socket.to(`consultation:${consultationId}`).emit('webrtc_offer', { from: socket.userId, sdp });
                });

                socket.on('webrtc_answer', ({ consultationId, sdp }) => {
                    socket.to(`consultation:${consultationId}`).emit('webrtc_answer', { from: socket.userId, sdp });
                });

                socket.on('webrtc_ice_candidate', ({ consultationId, candidate }) => {
                    socket.to(`consultation:${consultationId}`).emit('webrtc_ice_candidate', { from: socket.userId, candidate });
                });
            });

            let readyCount = 0;
            const onReady = () => { readyCount++; if (readyCount === 2) done(); };
            clientSocket1.on("connect", onReady);
            clientSocket2.on("connect", onReady);
        });
    });

    afterAll(() => {
        io.close();
        clientSocket1.close();
        clientSocket2.close();
    });

    test("should join consultation room and exchange SDP offers/answers", (done) => {
        const consultationId = "12345";

        clientSocket1.emit("join_consultation", { consultationId });
        clientSocket2.emit("join_consultation", { consultationId });

        clientSocket2.on("webrtc_offer", (data) => {
            expect(data.from).toBe("user_1");
            expect(data.sdp.type).toBe("offer");

            // Send answer back
            clientSocket2.emit("webrtc_answer", { consultationId, sdp: { type: "answer", sdp: "sdp_answer_string" } });
        });

        clientSocket1.on("webrtc_answer", (data) => {
            expect(data.from).toBe("user_2");
            expect(data.sdp.type).toBe("answer");
            done();
        });

        // Let clients join before emitting offer
        setTimeout(() => {
            clientSocket1.emit("webrtc_offer", { consultationId, sdp: { type: "offer", sdp: "sdp_offer_string" } });
        }, 100);
    });

    test("should exchange ICE candidates", (done) => {
        const consultationId = "12345";

        clientSocket2.on("webrtc_ice_candidate", (data) => {
            expect(data.from).toBe("user_1");
            expect(data.candidate.candidate).toBe("candidate1");
            done();
        });

        // Let clients join
        setTimeout(() => {
            clientSocket1.emit("webrtc_ice_candidate", { consultationId, candidate: { candidate: "candidate1" } });
        }, 100);
    });
});
