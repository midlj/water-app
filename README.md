# Water Bill Management System

A full-stack water bill management application with a **Flutter** mobile frontend and **Node.js/Express** backend backed by **MongoDB**.

---

## Project Structure

```
App/
├── backend/          Node.js + Express + MongoDB API
└── frontend/         Flutter mobile app
```

---

## Backend Setup

### Prerequisites
- Node.js >= 18
- MongoDB (local or Atlas)

### Installation

```bash
cd backend
npm install
```

### Configuration

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Key environment variables:
| Variable | Description | Default |
|---|---|---|
| `PORT` | Server port | `5000` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://localhost:27017/water_bill_db` |
| `JWT_SECRET` | JWT signing secret | *(change this!)* |
| `JWT_EXPIRES_IN` | Token expiry | `7d` |

### Seed Admin User

```bash
npm run seed
```

Default admin: `admin@waterbill.com` / `Admin@123`

### Run

```bash
# Development (auto-reload)
npm run dev

# Production
npm start
```

---

## API Reference

### Authentication
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/login` | None | Login (admin or client) |
| POST | `/api/auth/register` | Admin | Create account |
| GET | `/api/auth/me` | Any | Get current user |

### Users
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/api/users` | Admin | List all clients |
| POST | `/api/users` | Admin | Create client |
| GET | `/api/users/:id` | Any | Get user |
| PUT | `/api/users/:id` | Any | Update user |
| GET | `/api/users/dashboard/stats` | Admin | Dashboard statistics |

### Meter Readings
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/meter` | Admin | Add meter reading |
| GET | `/api/meter` | Admin | All readings |
| GET | `/api/meter/:userId` | Any | Readings for user |

### Bills
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/bills/generate` | Admin | Generate bill from reading |
| GET | `/api/bills` | Admin | All bills |
| GET | `/api/bills/user/:userId` | Any | Bills for user |
| GET | `/api/bills/:id` | Any | Single bill |
| PATCH | `/api/bills/:id/status` | Admin | Update bill status |

### Payments
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/payments` | Any | Make payment |
| GET | `/api/payments` | Admin | All payments |
| GET | `/api/payments/user/:userId` | Any | Payments for user |

---

## Billing Tariff

| Tier | Units | Rate |
|---|---|---|
| Tier 1 | 0 – 10 | $2.00/unit |
| Tier 2 | 11 – 20 | $3.00/unit |
| Tier 3 | 21+ | $4.50/unit |
| Service charge | Flat | $5.00 |
| Tax | 5% | on water charges |

---

## Frontend Setup

### Prerequisites
- Flutter SDK >= 3.0
- Android Studio / Xcode

### Installation

```bash
cd frontend
flutter pub get
```

### Configuration

Update the API base URL in [lib/core/constants/app_constants.dart](frontend/lib/core/constants/app_constants.dart):

```dart
// Android emulator → localhost
static const String baseUrl = 'http://10.0.2.2:5000/api';

// Physical device → your machine's LAN IP
// static const String baseUrl = 'http://192.168.1.x:5000/api';
```

### Run

```bash
flutter run
```

---

## App Screens

### Admin
- **Dashboard** — client count, revenue, unpaid bills overview
- **Manage Users** — create/search/edit clients
- **Add Meter Reading** — record monthly readings per client
- **Generate Bills** — auto-calculate bills from readings with tariff breakdown

### Client
- **Dashboard** — pending bills, quick pay action
- **Usage History** — bar chart + monthly reading list
- **Bills** — expandable cards with full breakdown, pay button
- **Payment History** — transaction log with total summary

---

## Architecture

### Backend (MVC)
```
src/
├── config/        DB connection
├── models/        Mongoose schemas
├── controllers/   Request handlers
├── routes/        Express routers
├── middlewares/   JWT auth, error handling
├── services/      Billing tariff calculation
├── utils/         Logger, seed script
└── validations/   Joi request validation
```

### Frontend (Feature-first)
```
lib/
├── core/          Theme, colors, API client, storage
├── models/        Data models (fromJson)
├── services/      API service calls
├── providers/     ChangeNotifier state
├── screens/       UI pages (admin/ + client/)
└── widgets/       Reusable components
```

---

## Security Features

- JWT Bearer token authentication
- bcryptjs password hashing (salt rounds: 12)
- Role-based middleware (`restrictTo`)
- Helmet.js HTTP security headers
- CORS configuration
- Rate limiting (100 req / 15 min)
- Input validation with Joi
- Secure token storage with flutter_secure_storage (AES encrypted on Android)
