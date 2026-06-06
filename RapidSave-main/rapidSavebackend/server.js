require('dotenv').config();
const http            = require('http');
const app             = require('./app');
const connectDB       = require('./config/db');
const initFirebase    = require('./config/firebase');
const connectCloudinary = require('./config/cloudinary');
const { initSocket }  = require('./config/socket');

const PORT = process.env.PORT || 5000;

const start = async () => {
  await connectDB();

  initFirebase();
  connectCloudinary();

  const httpServer = http.createServer(app);
  initSocket(httpServer);

  httpServer.listen(PORT, () => {
    console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
  });
};

start();