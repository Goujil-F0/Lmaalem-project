<div align="center">

# Lmaalem

### A mobile marketplace that connects clients with trusted local artisans.

<p>
  <a href="#features"><img alt="Features" src="https://img.shields.io/badge/features-client%20%7C%20artisan-2F80ED?style=for-the-badge"></a>
  <a href="#tech-stack"><img alt="Flutter" src="https://img.shields.io/badge/mobile-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"></a>
  <a href="#tech-stack"><img alt="Node.js" src="https://img.shields.io/badge/backend-Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white"></a>
  <a href="#tech-stack"><img alt="PostgreSQL" src="https://img.shields.io/badge/database-PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white"></a>
</p>

<p>
  <strong>Lmaalem</strong> helps clients discover nearby artisans, book services, track requests, chat in real time, and manage trusted profiles from a clean mobile experience.
</p>

</div>

---

## Overview

Lmaalem is a full-stack mobile application designed to make local artisan services easier to find, compare, book, and manage. The platform supports two main user experiences:

- Clients can create an account, search for artisans, view profiles, save favorites, request services, track bookings, and chat with artisans.
- Artisans can register, complete their professional profile, manage incoming requests, follow bookings, and communicate with clients.

The project includes a Flutter mobile app, an Express.js backend API, PostgreSQL persistence, file uploads, JWT authentication, rate limiting, and real-time messaging powered by Socket.IO.

---

## Screenshots

### Authentication Flow

<p align="center">
  <img src="screenshots/readme/splashScreen-phone.png" width="170" alt="Splash screen">
  <img src="screenshots/readme/login-phone.png" width="170" alt="Login screen">
  <img src="screenshots/readme/registerClient-phone.png" width="170" alt="Client sign up screen">
  <img src="screenshots/readme/registerArtisan-phone.png" width="170" alt="Artisan sign up screen">
</p>

<p align="center">
  <img src="screenshots/readme/registerClient2-phone.png" width="170" alt="Client details screen">
  <img src="screenshots/readme/registerArtisan2-phone.png" width="170" alt="Artisan details screen">
  <img src="screenshots/readme/UploadCIN-phone.png" width="170" alt="CIN upload screen">
  <img src="screenshots/readme/locationAcces-phone.png" width="170" alt="Location access screen">
</p>

### Client Experience

<p align="center">
  <img src="screenshots/readme/AcceuilClient-phone.png" width="170" alt="Client home screen">
  <img src="screenshots/readme/searchArtisan-phone.png" width="170" alt="Artisan search screen">
  <img src="screenshots/readme/map-phone.png" width="170" alt="Map search screen">
  <img src="screenshots/readme/profileArtisan-phone.png" width="170" alt="Artisan profile screen">
</p>

<p align="center">
  <img src="screenshots/readme/favoris-phone.png" width="170" alt="Favorite artisans screen">
  <img src="screenshots/readme/suivi-phone.png" width="170" alt="Client booking tracking screen">
  <img src="screenshots/readme/compteClient-phone.png" width="170" alt="Client account screen">
  <img src="screenshots/readme/chat-phone.png" width="170" alt="Real-time chat screen">
</p>

### Artisan Experience

<p align="center">
  <img src="screenshots/readme/AcceuileArtisan-phone.png" width="170" alt="Artisan home screen">
  <img src="screenshots/readme/suiviArtisan-phone.png" width="170" alt="Artisan request tracking screen">
  <img src="screenshots/readme/compteArtisan-phone.png" width="170" alt="Artisan account screen">
  <img src="screenshots/readme/compteArtisan2-phone.png" width="170" alt="Artisan profile settings screen">
</p>

---

## Features

- Role-based onboarding for clients and artisans.
- JWT authentication with protected API endpoints.
- Artisan discovery with search, profile details, and location-aware browsing.
- Interactive map support using Flutter Map and geolocation.
- Booking management and request tracking for both clients and artisans.
- Real-time chat between clients and artisans using Socket.IO.
- Favorite artisans list for faster future access.
- CIN/file upload flow with backend upload handling.
- Reviews and complaints backend modules.
- Dockerized backend and PostgreSQL database setup.

---

## Tech Stack

| Layer | Technologies |
| --- | --- |
| Mobile app | Flutter, Dart, Provider, HTTP, Shared Preferences |
| Maps and location | flutter_map, latlong2, geolocator |
| Real-time messaging | Socket.IO, socket_io_client |
| Backend | Node.js, Express.js |
| Database | PostgreSQL |
| Auth and security | JWT, bcryptjs, express-rate-limit, express-validator |
| Uploads | Multer |
| DevOps | Docker, Docker Compose |

---

## Project Structure

```text
Lmaalem-project/
+-- db/
|   +-- init.sql
+-- maalem_app/
|   +-- lib/
|   |   +-- core/
|   |   +-- data/
|   |   +-- presentation/
|   |   +-- providers/
|   |   +-- shared/
|   +-- pubspec.yaml
+-- maalem_server/
|   +-- src/
|   |   +-- controllers/
|   |   +-- middleware/
|   |   +-- models/
|   |   +-- routes/
|   |   +-- app.js
|   +-- Dockerfile
|   +-- package.json
+-- screenshots/
+-- uploads/
+-- docker-compose.yml
+-- README.md
```

---

## Getting Started

### Prerequisites

Make sure you have the following installed:

- Flutter SDK 3.x
- Dart SDK
- Node.js 18+
- npm
- Docker and Docker Compose

### Environment Variables

Create a `.env` file in the project root:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASSWORD=your_database_password
PORT=8081
JWT_SECRET=your_long_random_jwt_secret
```

When running with Docker Compose, the backend uses the `maalem-db` service as its database host internally.

---

## Run with Docker

From the project root:

```bash
docker compose up --build
```

The backend API will be available at:

```text
http://localhost:8081
```

The PostgreSQL database will be exposed on:

```text
localhost:5432
```

---

## Run the Backend Locally

```bash
cd maalem_server
npm install
npm run dev
```

The server starts on:

```text
http://localhost:8081
```

---

## Run the Flutter App

```bash
cd maalem_app
flutter pub get
flutter run
```

If you run the app on an Android emulator, make sure the API base URL points to your host machine correctly, commonly:

```text
http://10.0.2.2:8081
```

For a physical device, use your machine's local network IP address.

---

## API Modules

The backend exposes modules for:

- Authentication
- Artisan search and profile management
- Bookings
- Messages
- Reviews
- Complaints
- Uploads

Main API entry points include:

```text
/auth
/api/bookings
/api/messages
/api/reviews
/api/complaints
/api
/uploads
```

---

## Roadmap

- Improve artisan verification workflow.
- Add push notifications for bookings and messages.
- Add automated tests for API modules and Flutter flows.
- Prepare production deployment configuration.

---

## Author

Built by [Goujil-F0](https://github.com/Goujil-F0).

---

## License

No license has been specified yet. Add a license before distributing or accepting external contributions.
