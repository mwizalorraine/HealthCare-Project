class AppStrings {
  AppStrings._();

  static const appName = 'RapidSave';
  static const tagline = 'Medicine, delivered fast';

  // static const baseUrl = 'https://rapidsave-2.onrender.com/api';
  // static const socketUrl = 'https://rapidsave-2.onrender.com';
  static const baseUrl = 'http://10.115.164.226:5000/api';
  static const socketUrl = 'http://10.115.164.226:5000';

  static const tokenKey = 'auth_token';
  static const userKey = 'auth_user';

  // Roles
  static const rolePatient = 'patient';
  static const rolePharmacyAdmin = 'pharmacy_admin';
  static const roleAdmin = 'admin';

  // Order status
  static const statusPending = 'pending';
  static const statusConfirmed = 'confirmed';
  static const statusReady = 'ready';
  static const statusCompleted = 'completed';
  static const statusCancelled = 'cancelled';

  // Payment status
  static const paymentUnpaid = 'unpaid';
  static const paymentPendingVerification = 'pending_verification';
  static const paymentVerified = 'verified';
  static const paymentRejected = 'rejected';

  // Delivery status
  static const deliveryAssigned = 'assigned';
  static const deliveryInTransit = 'in_transit';
  static const deliveryDelivered = 'delivered';
  static const deliveryFailed = 'failed';

  // Socket events — messaging
  static const eventJoinConversation = 'join_conversation';
  static const eventLeaveConversation = 'leave_conversation';
  static const eventSendMessage = 'send_message';
  static const eventNewMessage = 'new_message';
  static const eventTyping = 'typing';
  static const eventReadAck = 'read_ack';
  static const eventReceiptUpdate = 'receipt_update';
  static const eventAddReaction = 'add_reaction';
  static const eventReactionUpdate = 'reaction_update';
  static const eventConversationClosed = 'conversation_closed';

  // Socket events — delivery tracking
  static const eventJoinDelivery = 'join_delivery';
  static const eventLeaveDelivery = 'leave_delivery';
  static const eventDriverLocation = 'driver_location';
  static const eventDeliveryStatusUpdate = 'delivery_status_update';

  // Hive boxes
  static const boxUser = 'user_box';
  static const boxMedicines = 'medicines_box';
  static const boxPharmacies = 'pharmacies_box';
  static const boxOrders = 'orders_box';
  static const boxNotifications = 'notifications_box';
  static const boxSettings = 'settings_box';
}
