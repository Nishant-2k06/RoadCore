# RoadCore — Intelligent Toll Integrity & Highway Intelligence Platform
**B.Tech Minor Project (BTP 5)**  
**Department of Computer Science & Engineering**  
**Mentor:** Dr. Bhupendra Singh  
**Team Members:** Mayuresh, Omkar, Parth, Nishant (Database & Backend Lead), Pradnyesh  

---

## 📌 Project Overview
RoadCore is a software intelligence and trust layer on top of highway Multi-Lane Free Flow (MLFF) tolling. Rather than replacing physical tolling hardware, RoadCore connects multi-gantry camera observations, reconstructs journeys over a digital road graph, computes travel distance and class tolls, detects evasion anomalies, and secures evidence using SHA-256 cryptographic hashes for human-verifiable enforcement.

> *"Existing MLFF detects and collects; RoadCore connects, verifies, explains and proves."*

---

## 🏗️ Repository Architecture & Module Boundaries

```
BTP 5/
├── docker-compose.yml       # PostgreSQL 16 (PostGIS) & MinIO Object Storage
├── database/
│   └── init.sql             # Complete PostGIS DDL, 12 Core Tables, Spatial Indices
├── backend/
│   ├── package.json         # Node.js Express & TypeScript dependencies
│   ├── tsconfig.json        # TypeScript compiler configuration
│   ├── .env.example         # Environment configuration template
│   └── src/                 # (Ready for Phase 1 code scaffolding)
├── docs/
│   ├── IMPLEMENTATION_PLAN.md # Comprehensive 8-phase implementation roadmap
│   └── API_CONTRACTS.md       # Exact JSON REST contracts for Frontend & AI teams
└── README.md
```

---

## 📋 Division of Work & Role Scope
- **Nishant (This Workspace):** Database (PostgreSQL + PostGIS, MinIO) & Node.js/Express Backend (Auth, Ingestion, Journey Reconstruction, Fraud Detection, SHA-256 Evidence Ledger, REST APIs).
- **Mayuresh, Omkar, Parth, Pradnyesh:** 
  - **AI / ML Service (Python FastAPI):** YOLO Plate Detection, OCR, Attribute Extraction, TransReID Vehicle Matching.
  - **Client Applications (React):** Government Dashboard, Enforcement Portal, Traveller Portal.

---

## 🚀 Getting Started (When Ready for Implementation)

### 1. Start Infrastructure Services
Launch Docker Desktop on your machine and run:
```bash
docker compose up -d
```
Services exposed:
- **PostgreSQL + PostGIS:** `localhost:5432` (DB: `roadcore_db`, User: `roadcore_user`)
- **MinIO Console:** `http://localhost:9001` (User: `roadcore_admin`)
- **MinIO S3 API:** `http://localhost:9000`

### 2. Backend Setup
```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

---

## 📖 Specifications & Design Documents
- **Phase-Wise Roadmap:** [docs/IMPLEMENTATION_PLAN.md](file:///c:/Users/nisha/Project/BTP%205/docs/IMPLEMENTATION_PLAN.md)
- **API Contracts:** [docs/API_CONTRACTS.md](file:///c:/Users/nisha/Project/BTP%205/docs/API_CONTRACTS.md)
- **Database Schema (DDL):** [database/init.sql](file:///c:/Users/nisha/Project/BTP%205/database/init.sql)
