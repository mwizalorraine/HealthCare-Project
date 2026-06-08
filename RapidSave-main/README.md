# RapidSave

Here is a clean, copy-paste ready `README.md` (no extra formatting, just pure markdown):

```markdown
# RapidSave Backend API

A Node.js + Express + MongoDB REST API with Socket.IO real-time chat and Firebase Cloud Messaging push notifications for the RapidSave medicine access platform.

---

## 📁 Project Location

The documentation goes in a `README.md` file at the root of the project — same level as `package.json` and `server.js`.
```

rapidsave-backend/
├── README.md
├── package.json
├── server.js
├── app.js
└── ...

```

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js |
| Framework | Express.js |
| Database | MongoDB + Mongoose |
| Real-time | Socket.IO |
| Push notifications | Firebase Admin SDK (FCM) |
| File uploads | Multer + Cloudinary |
| Authentication | JWT + bcryptjs |
| Geolocation | Geolib |

---

## 📦 Project Structure

```

rapidsave-backend/
├── config/
│ ├── db.js
│ ├── firebase.js
│ ├── cloudinary.js
│ └── socket.js
├── constants/
│ ├── roles.js
│ ├── orderStatus.js
│ └── events.js
├── controllers/
│ ├── auth.controller.js
│ ├── user.controller.js
│ ├── pharmacy.controller.js
│ ├── medicine.controller.js
│ ├── inventory.controller.js
│ ├── order.controller.js
│ ├── delivery.controller.js
│ ├── conversation.controller.js
│ └── notification.controller.js
├── middleware/
│ ├── auth.middleware.js
│ ├── validate.middleware.js
│ ├── error.middleware.js
│ ├── upload.middleware.js
│ └── rateLimiter.middleware.js
├── models/
│ ├── User.js
│ ├── DeviceToken.js
│ ├── Pharmacy.js
│ ├── Medicine.js
│ ├── Inventory.js
│ ├── Order.js
│ ├── OrderItem.js
│ ├── Delivery.js
│ ├── Conversation.js
│ ├── Message.js
│ ├── ReadReceipt.js
│ └── Notification.js
├── routes/
│ ├── auth.routes.js
│ ├── user.routes.js
│ ├── pharmacy.routes.js
│ ├── medicine.routes.js
│ ├── inventory.routes.js
│ ├── order.routes.js
│ ├── delivery.routes.js
│ ├── conversation.routes.js
│ └── notification.routes.js
├── services/
│ ├── fcm.service.js
│ ├── socket.service.js
│ ├── geo.service.js
│ └── notification.service.js
├── utils/
│ ├── apiResponse.js
│ ├── apiError.js
│ └── generateToken.js
├── .env
├── .env.example
├── app.js
├── server.js
└── package.json

````

---

## 🚀 Getting Started

### Prerequisites

- Node.js v18+
- MongoDB (local or Atlas)
- Firebase project with a service account key
- Cloudinary account

### Installation

```bash
git clone https://github.com/your-org/rapidsave-backend.git
cd rapidsave-backend
npm install
````

### Environment Setup

```bash
cp .env.example .env
```

Fill in:

```env
PORT=5000
NODE_ENV=development
MONGO_URI=mongodb://localhost:27017/rapidsave
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100
```

> ⚠️ Wrap `FIREBASE_PRIVATE_KEY` in double quotes to preserve newlines.

### Run Server

```bash
# Development
npm run dev

# Production
npm start
```

---

## 🌐 API Reference

### Base URL

```
http://localhost:5000/api
```

### Authentication

```
Authorization: Bearer <token>
```

---

## 🔐 Auth

| Method | Endpoint         | Access | Description   |
| ------ | ---------------- | ------ | ------------- |
| POST   | `/auth/register` | Public | Register      |
| POST   | `/auth/login`    | Public | Login         |
| POST   | `/auth/refresh`  | Public | Refresh token |

---

## 👤 Users

| Method | Endpoint                     | Access    | Description    |
| ------ | ---------------------------- | --------- | -------------- |
| GET    | `/users/me`                  | Protected | Get profile    |
| PATCH  | `/users/me`                  | Protected | Update profile |
| POST   | `/users/device-token`        | Protected | Register FCM   |
| DELETE | `/users/device-token/:token` | Protected | Remove FCM     |

---

## 🏥 Pharmacies

| Method | Endpoint                     | Access         | Description  |
| ------ | ---------------------------- | -------------- | ------------ |
| POST   | `/pharmacies`                | pharmacy_admin | Create       |
| GET    | `/pharmacies/me`             | pharmacy_admin | Own pharmacy |
| PATCH  | `/pharmacies/me`             | pharmacy_admin | Update       |
| PATCH  | `/pharmacies/me/toggle-open` | pharmacy_admin | Toggle       |
| GET    | `/pharmacies/nearby`         | Protected      | Nearby       |
| GET    | `/pharmacies/:id`            | Protected      | By ID        |
| GET    | `/pharmacies`                | admin          | List         |
| PATCH  | `/pharmacies/:id/verify`     | admin          | Verify       |

---

## 💊 Medicines

| Method | Endpoint               | Access    |
| ------ | ---------------------- | --------- |
| POST   | `/medicines`           | admin     |
| GET    | `/medicines`           | Protected |
| GET    | `/medicines/search?q=` | Protected |
| GET    | `/medicines/:id`       | Protected |
| PATCH  | `/medicines/:id`       | admin     |

---

## 📦 Inventory

| Method | Endpoint                          | Access         |
| ------ | --------------------------------- | -------------- |
| POST   | `/inventory`                      | pharmacy_admin |
| GET    | `/inventory/pharmacy/:pharmacyId` | Protected      |
| GET    | `/inventory/medicine/:medicineId` | Protected      |
| DELETE | `/inventory/:id`                  | pharmacy_admin |

---

## 🛒 Orders

| Method | Endpoint             | Access         |
| ------ | -------------------- | -------------- |
| POST   | `/orders`            | patient        |
| GET    | `/orders/my`         | patient        |
| GET    | `/orders/pharmacy`   | pharmacy_admin |
| GET    | `/orders/:id`        | Protected      |
| PATCH  | `/orders/:id/status` | pharmacy_admin |

---

## 🚚 Deliveries

| Method | Endpoint                     | Access         |
| ------ | ---------------------------- | -------------- |
| POST   | `/deliveries`                | pharmacy_admin |
| GET    | `/deliveries/my`             | patient        |
| GET    | `/deliveries/order/:orderId` | Protected      |
| PATCH  | `/deliveries/:id/status`     | pharmacy_admin |

---

## 💬 Conversations (Chat)

| Method | Endpoint                                           | Access    |
| ------ | -------------------------------------------------- | --------- |
| GET    | `/conversations/:id`                               | Protected |
| GET    | `/conversations/:id/messages`                      | Protected |
| POST   | `/conversations/:id/messages`                      | Protected |
| POST   | `/conversations/:id/messages/:messageId/reactions` | Protected |
| PATCH  | `/conversations/:id/messages/read`                 | Protected |

---

## 🔔 Notifications

| Method | Endpoint                      | Access    |
| ------ | ----------------------------- | --------- |
| GET    | `/notifications`              | Protected |
| GET    | `/notifications/unread-count` | Protected |
| PATCH  | `/notifications/:id/read`     | Protected |
| PATCH  | `/notifications/read-all`     | Protected |

---

## ⚡ Socket.IO

### Connect

```js
import { io } from "socket.io-client";

const socket = io("http://localhost:5000", {
  auth: { token: "" },
});
```

### Events

**Client → Server**

- `join_conversation`
- `leave_conversation`
- `typing`

**Server → Client**

- `new_message`
- `reaction_update`
- `receipt_update`
- `typing`
- `conversation_closed`

---

## 📄 Standard Response

### Success

```json
{
  "success": true,
  "message": "",
  "data": {}
}
```

### Error

```json
{
  "success": false,
  "message": "",
  "errors": []
}
```

---

## ⚠️ Error Codes

| Code | Meaning          |
| ---- | ---------------- |
| 400  | Bad request      |
| 401  | Unauthorized     |
| 403  | Forbidden        |
| 404  | Not found        |
| 409  | Conflict         |
| 422  | Validation error |
| 429  | Rate limit       |
| 500  | Server error     |

---

## 📜 Scripts

```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  }
}
```

---

## Notes

- MongoDB transactions ensure safe order creation
- FCM tokens are soft-deleted when invalid
- Max 5 prescription files (10MB each)
- One reaction per user per message enforced at DB level
- Conversations auto-created and auto-closed with delivery lifecycle

```

```

Author
: Lorraine Mwiza || CoE
