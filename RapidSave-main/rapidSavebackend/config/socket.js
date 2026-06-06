const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const EVENTS = require('../constants/events');

let io;

const initSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('Unauthorized: no token'));

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded;
      next();
    } catch (err) {
      next(new Error('Unauthorized: invalid token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.id} | user: ${socket.user.id}`);

   
    socket.on(EVENTS.JOIN_CONVERSATION, (data) => {
      // Client sends { conversation_id: '...' }
      const conversationId = typeof data === 'string' ? data : data?.conversation_id;
      if (!conversationId) return;
      socket.join(`conversation:${conversationId}`);
      console.log(`User ${socket.user.id} joined conversation:${conversationId}`);
    });

    socket.on(EVENTS.LEAVE_CONVERSATION, (data) => {
      const conversationId = typeof data === 'string' ? data : data?.conversation_id;
      if (conversationId) socket.leave(`conversation:${conversationId}`);
    });

    socket.on(EVENTS.TYPING, (data) => {
      const conversationId = data?.conversation_id || data?.conversationId;
      if (conversationId) {
        socket.to(`conversation:${conversationId}`).emit(EVENTS.TYPING, {
          userId: socket.user.id,
        });
      }
    });

    // Delivery tracking rooms
    socket.on(EVENTS.JOIN_DELIVERY, ({ delivery_id }) => {
      if (delivery_id) {
        socket.join(`delivery:${delivery_id}`);
      }
    });

    socket.on(EVENTS.LEAVE_DELIVERY, ({ delivery_id }) => {
      if (delivery_id) {
        socket.leave(`delivery:${delivery_id}`);
      }
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });

  return io;
};

const getIO = () => {
  if (!io) throw new Error('Socket.IO not initialized');
  return io;
};

module.exports = { initSocket, getIO };