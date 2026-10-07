# RoadCore REST API Contracts & Schema Specification
**Version:** 1.0  
**Backend:** Node.js / Express  
**Role:** Database & Backend Developer (Nishant)  
**Consumers:** Frontend Team (React Portals) & AI Team (Python FastAPI)

---

## 1. Authentication & User Management

### 1.1 Login
- **Endpoint:** `POST /api/auth/login`
- **Access:** Public
- **Request Body:**
```json
{
  "email": "inspector.sharma@roadcore.gov.in",
  "password": "Password123!"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsIn...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsIn...",
    "user": {
      "id": "e9b581b2-11a5-4841-a67b-1cb8f9d0c24a",
      "name": "Inspector Sharma",
      "email": "inspector.sharma@roadcore.gov.in",
      "role": "ENFORCEMENT"
    }
  }
}
```

### 1.2 Refresh Token
- **Endpoint:** `POST /api/auth/refresh`
- **Request Body:** `{ "refreshToken": "eyJhbGciOi..." }`
- **Response (200 OK):** `{ "accessToken": "new_token..." }`

---

## 2. AI Observation Ingestion Bridge

### 2.1 Ingest Vehicle Observation (Called by Python Service or Simulated Feeds)
- **Endpoint:** `POST /api/observations`
- **Access:** API Key / Service Role
- **Request (Multipart Form-Data or JSON):**
```json
{
  "gantry_code": "G-MUNDAKA-01",
  "timestamp": "2026-10-07T14:32:00.000Z",
  "plate_text": "MH12AB1234",
  "plate_confidence": 0.9420,
  "vehicle_type": "SUV",
  "vehicle_color": "white",
  "reid_confidence": 0.8850,
  "raw_frame_base64": "<base64_string_or_multipart_file>",
  "plate_crop_base64": "<base64_string_or_multipart_file>",
  "metadata": {
    "lane_number": 2,
    "camera_id": "CAM-MUND-N-02",
    "lighting": "DAYLIGHT"
  }
}
```
- **Success Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "observation_id": "4b689a72-7473-455b-b9d5-a3d820525ff6",
    "journey_id": "97e68bc4-9d54-47f2-959f-d51e70404a79",
    "sha256_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "frame_uri": "s3://roadcore-observations/raw-frames/G-MUNDAKA-01/2026/10/07/4b689a72.jpg",
    "status": "RECORDED"
  }
}
```

---

## 3. Journey & Toll Engine APIs

### 3.1 Get Journey by ID
- **Endpoint:** `GET /api/journeys/:id`
- **Access:** `ENFORCEMENT`, `GOVERNMENT`, `TRAVELLER` (Own trips)
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "journey_id": "97e68bc4-9d54-47f2-959f-d51e70404a79",
    "vehicle": {
      "plate_number": "MH12AB1234",
      "type": "SUV",
      "color": "white"
    },
    "entry_gantry": "Mundaka Toll Plaza",
    "exit_gantry": "Choryasi Toll Plaza",
    "entry_time": "2026-10-07T14:00:00.000Z",
    "exit_time": "2026-10-07T14:32:00.000Z",
    "distance_km": 65.20,
    "duration_minutes": 32.0,
    "average_speed_kmh": 122.25,
    "toll_amount": 175.23,
    "status": "COMPLETED",
    "segments": [
      {
        "from": "Mundaka Toll Plaza",
        "to": "Choryasi Toll Plaza",
        "distance_km": 65.20,
        "speed_kmh": 122.25,
        "validation_status": "PLAUSIBLE"
      }
    ]
  }
}
```

---

## 4. Security, Fraud & Evidence Verification APIs

### 4.1 List Security Alerts
- **Endpoint:** `GET /api/alerts?status=OPEN&severity=HIGH`
- **Access:** `ENFORCEMENT`, `GOVERNMENT`
- **Success Response (200 OK):**
```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "id": "7fa8413b-286a-4d76-b6f1-a89a05b2a091",
      "alert_type": "BYPASS_DETECTED",
      "severity": "HIGH",
      "confidence": 0.9100,
      "description": "Vehicle skipped G-CHORYASI-02 intermediate gantry between Mundaka and Gharaunda.",
      "vehicle_plate": "DL04CA9988",
      "created_at": "2026-10-07T15:10:00.000Z"
    }
  ]
}
```

### 4.2 Verify Evidence Integrity (SHA-256)
- **Endpoint:** `POST /api/evidence/verify`
- **Access:** `ENFORCEMENT`, `ADMIN`
- **Request Body:**
```json
{
  "evidence_id": "c13d8082-9694-47b1-91d1-6715f5c091f0"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "evidence_id": "c13d8082-9694-47b1-91d1-6715f5c091f0",
    "verified": true,
    "stored_sha256": "4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945",
    "calculated_sha256": "4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945",
    "timestamp_verified": "2026-10-07T18:45:00.000Z",
    "integrity_status": "AUTHENTIC_UNALTERED"
  }
}
```

---

## 5. Portal-Specific APIs

### 5.1 Government Dashboard — Corridor Overview
- **Endpoint:** `GET /api/dashboard/overview`
- **Access:** `GOVERNMENT`, `ADMIN`
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "corridor": "Western Peripheral - NH48 Baseline",
    "metrics": {
      "total_crossings_today": 128450,
      "expected_revenue_inr": 2761675.00,
      "collected_revenue_inr": 2498500.00,
      "revenue_leakage_rate_pct": 9.53,
      "active_alerts": 42
    },
    "station_health": [
      {
        "gantry_code": "G-MUNDAKA-01",
        "name": "Mundaka Toll Plaza",
        "anpr_avg_confidence": 0.962,
        "status": "OPERATIONAL"
      },
      {
        "gantry_code": "G-CHORYASI-02",
        "name": "Choryasi Toll Plaza",
        "anpr_avg_confidence": 0.714,
        "status": "DEGRADED"
      }
    ]
  }
}
```

### 5.2 Enforcement Portal — Forensic Multi-Attribute Search
- **Endpoint:** `GET /api/search/forensic?plate=MH12&type=SUV&color=white&from=2026-10-07T10:00:00Z`
- **Access:** `ENFORCEMENT`
- **Success Response (200 OK):**
```json
{
  "success": true,
  "results": [
    {
      "observation_id": "4b689a72-7473-455b-b9d5-a3d820525ff6",
      "plate_text": "MH12AB1234",
      "vehicle_type": "SUV",
      "vehicle_color": "white",
      "gantry_name": "Mundaka Toll Plaza",
      "timestamp": "2026-10-07T14:32:00.000Z",
      "plate_crop_url": "/api/evidence/preview/4b689a72_crop.jpg",
      "reid_confidence": 0.885
    }
  ]
}
```

### 5.3 Traveller Portal — Trip History & Appeals
- **Endpoint:** `GET /api/traveller/trips`
- **Access:** `TRAVELLER`
- **Success Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "trip_id": "97e68bc4-9d54-47f2-959f-d51e70404a79",
      "date": "2026-10-07",
      "from": "Mundaka Toll Plaza",
      "to": "Choryasi Toll Plaza",
      "distance_km": 65.20,
      "toll_inr": 175.23,
      "payment_status": "PAID"
    }
  ]
}
```

- **Endpoint:** `POST /api/traveller/appeals`
- **Access:** `TRAVELLER`
- **Request Body:**
```json
{
  "case_number": "CASE-2026-00421",
  "reason": "Vehicle was on flatbed towing truck during recorded crossing; plate was photographed while vehicle was stationary on trailer.",
  "proof_document_url": "s3://roadcore-evidence/appeals/towing_bill_receipt.pdf"
}
```
- **Success Response (201 Created):**
```json
{
  "success": true,
  "message": "Appeal submitted successfully. Case is held in UNDER_REVIEW status pending enforcement evaluation.",
  "appeal_id": "bf82d02c-55c3-4d40-9818-471249b2c3ee"
}
```
