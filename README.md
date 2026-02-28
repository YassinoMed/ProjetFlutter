<div align="center">
  
  <img src="https://img.icons8.com/color/144/flutter.png" alt="Flutter Logo" width="80" />
  <img src="https://img.icons8.com/color/144/laravel.png" alt="Laravel Logo" width="80" />
  
  <h1>🏥 Medical ERP & Telehealth SaaS</h1>
  <p><strong>A Next-Generation Multi-Tenant Healthcare Solution</strong></p>

  <!-- Badges -->
  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white" alt="Laravel" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white" alt="PHP" />
    <img src="https://img.shields.io/badge/WebSockets-25D366?style=for-the-badge&logo=whatsapp&logoColor=white" alt="WebSockets" />
    <img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL" />
  </p>

  <p>
    <a href="#-architecture">Architecture</a> •
    <a href="#-features">Features</a> •
    <a href="#-getting-started">Getting Started</a>
  </p>
</div>

---

## 🌟 Overview

This project is a high-performance **Healthcare SaaS and ERP platform** built with **Flutter** (Frontend) and **Laravel** (Backend API). It is designed to modernize clinic operations, enhance patient-doctor communication, and provide absolute data security through an advanced **Database-per-Tenant** architecture.

---

## ✨ Features

- **🛡️ Multi-Tenant Architecture:** Total data isolation with a dynamic "Database per Tenant" approach, ensuring the highest level of security and API performance.
- **👨‍⚕️ Doctor & Patient Portals:** Dedicated UI/UX for both patients (booking, medical records) and healthcare providers (schedule management, consultations).
- **💬 Real-Time Chat & Telehealth:** Integrated instant messaging using WebSockets and real-time medical consultations via Video Calls.
- **📁 Digital Medical Records (EMR):** Secure, structured, and easily accessible patient history and prescriptions.
- **⚙️ Admin Dashboard (Livewire):** Powerful backend administration panel to manage clinics, profiles, subscriptions, and system metrics.

---

# Project Architecture Documentation

## Comprehensive Architecture Diagrams

### System Architecture
The system follows a strict Clean Architecture pattern on the frontend, decoupling presentation, domain, and data layers. The backend utilizes Laravel to securely hand-off requests to the appropriate tenant database.

![System Architecture Diagram](link-to-system-architecture-diagram)

### High-Level System Design

```mermaid
graph TD
    classDef mobile fill:#02569B,stroke:#fff,stroke-width:2px,color:#fff;
    classDef backend fill:#FF2D20,stroke:#fff,stroke-width:2px,color:#fff;
    classDef db fill:#4479A1,stroke:#fff,stroke-width:2px,color:#fff;

    subgraph "Frontend (Flutter)"
        P[📱 Patient App]:::mobile
        D[👨‍⚕️ Doctor Panel]:::mobile
    end
    
    subgraph "Backend System (Laravel)"
        API[🌐 RESTful API]:::backend
        WS[⚡ WebSocket Server]:::backend
        Admin[⚙️ Admin Dashboard]:::backend
    end
    
    subgraph "Data Storage"
        DB1[(Tenant DB: Clinic A)]:::db
        DB2[(Tenant DB: Clinic B)]:::db
        DB3[(Tenant DB: Clinic C)]:::db
    end
    
    P <-->|HTTP / Sanctum| API
    P <-->|Real-time| WS
    D <-->|HTTP / Sanctum| API
    D <-->|Real-time| WS
    Admin <-->|Manage| API
    
    API <-->|Dynamic Connection| DB1
    API <-->|Dynamic Connection| DB2
    API <-->|Dynamic Connection| DB3
```

### Data Flow
- Explanation of how data moves through the system.
- Key data sources and sinks.

![Data Flow Diagram](link-to-data-flow-diagram)

### User Flow
- Description of the user journey through the application.
- Key user interactions and use cases.

![User Flow Diagram](link-to-user-flow-diagram)

### Database Schema
- Overview of the database structure.
- Explanation of key tables, relationships, and specifications.

![Database Schema Diagram](link-to-database-schema-diagram)

### Security Layers
- Description of the security architecture.
- Layers of security mechanisms designed to protect data and resources.

![Security Layers Diagram](link-to-security-layers-diagram)

---

## 📱 Screenshots

> *(Add screenshots of your brilliant UI here)*

| Patient Dashboard | Doctor Appointments | Real-Time Chat | Telehealth Video |
| :---: | :---: | :---: | :---: |
| <img src="https://placehold.co/200x400/eee/999?text=Patient+Home" width="200"/> | <img src="https://placehold.co/200x400/eee/999?text=Booking" width="200"/> | <img src="https://placehold.co/200x400/eee/999?text=Chat/WebSockets" width="200"/> | <img src="https://placehold.co/200x400/eee/999?text=Video+Call" width="200"/> |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (`>= 3.0.0`)
- **PHP** (`>= 8.2`) & **Composer**
- **MySQL / PostgreSQL** (for Tenant databases)
- **Node.js** & **NPM** (for WebSockets/Broadcasting, if local)

### Backend Setup (Laravel)

1. **Clone & Navigate:**
   ```bash
   cd backend
   ```
2. **Install Dependencies:**
   ```bash
   composer install
   npm install
   ```
3. **Environment setup:**
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
4. **Database & Migrations:**
   *Set up a central DB in `.env`, then run migrations for the main and tenant databases.*
   ```bash
   php artisan migrate --seed
   ```
5. **Serve Application:**
   ```bash
   php artisan serve
   ```

### Frontend Setup (Flutter)

1. **Navigate to Frontend:**
   ```bash
   cd frontend
   ```
2. **Get Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure API:**
   Ensure `lib/core/constants/api_constants.dart` points to your local or deployed backend IP.
4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!  
Feel free to check [issues page](#).

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---
<div align="center">
  <b>Built with ❤️ by Yassino</b>
</div>
