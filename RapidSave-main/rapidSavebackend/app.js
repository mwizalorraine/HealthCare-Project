const express            = require('express');
const cors               = require('cors');
const helmet             = require('helmet');
const morgan             = require('morgan');
const mongoSanitize      = require('express-mongo-sanitize');
const { defaultLimiter } = require('./middleware/rateLimiter.middleware');
const errorHandler       = require('./middleware/error.middleware');

const authRoutes         = require('./routes/auth.routes');
const userRoutes         = require('./routes/user.routes');
const pharmacyRoutes     = require('./routes/pharmacy.routes');
const medicineRoutes     = require('./routes/medicine.routes');
const inventoryRoutes    = require('./routes/inventory.routes');
const orderRoutes        = require('./routes/order.routes');
const deliveryRoutes     = require('./routes/delivery.routes');
const conversationRoutes = require('./routes/conversation.routes');
const notificationRoutes = require('./routes/notification.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(mongoSanitize());
app.use(defaultLimiter);

if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

app.get('/health', (req, res) => {
  res.status(200).json({
    success:     true,
    message:     'RapidSave API is running',
    environment: process.env.NODE_ENV,
    timestamp:   new Date().toISOString(),
  });
});

app.use('/api/auth',          authRoutes);
app.use('/api/users',         userRoutes);
app.use('/api/pharmacies',    pharmacyRoutes);
app.use('/api/medicines',     medicineRoutes);
app.use('/api/inventory',     inventoryRoutes);
app.use('/api/orders',        orderRoutes);
app.use('/api/deliveries',    deliveryRoutes);
app.use('/api/conversations', conversationRoutes);
app.use('/api/notifications', notificationRoutes);

app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found` });
});

app.use(errorHandler);

module.exports = app;