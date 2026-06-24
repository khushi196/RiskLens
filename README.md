# RiskLens

RiskLens is a Flutter Web + FastAPI application that generates a project risk register using Gemini when available and a deterministic fallback engine when the AI provider is unavailable or rate-limited.

## Features

- Flutter Web dashboard for project risk analysis
- FastAPI backend with validated request payloads
- Gemini-powered risk generation with structured JSON output
- Dynamic fallback risk engine for reliable demos
- Calculated risk score and level from severity, probability, and impact
- Source tracking: `gemini` or `fallback`
- Browser local storage for report history
- Exportable text report
- Backend health check and configurable frontend API URL

## Tech Stack

- Frontend: Flutter Web, Dart, shared_preferences, http
- Backend: FastAPI, Pydantic, Uvicorn
- AI: Gemini API via REST
- Storage: browser local storage
- Deployment: Render for backend, Netlify/Vercel/static hosting for frontend

## Local Setup

### Backend

```powershell
cd backend
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
copy .env.example .env
```

Edit `backend/.env`:

```env
AI_PROVIDER=gemini
GEMINI_API_KEY=your_key_here
GEMINI_MODEL=gemini-2.5-flash-lite
AI_FALLBACK_TO_MOCK=true
ALLOWED_ORIGINS=*
```

Run backend:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Health check:

```text
http://127.0.0.1:8000/health
```

### Frontend

```powershell
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Open:

```text
http://127.0.0.1:8080
```

For a deployed backend:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://your-api.onrender.com
```

## Deployment

### Backend on Render

Use `render.yaml` or create a Render Web Service manually.

Backend settings:

- Root directory: `backend`
- Build command: `pip install -r requirements.txt`
- Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Health path: `/health`

Environment variables:

```env
AI_PROVIDER=gemini
GEMINI_API_KEY=your_key_here
GEMINI_MODEL=gemini-2.5-flash-lite
AI_FALLBACK_TO_MOCK=true
ALLOWED_ORIGINS=https://your-frontend-domain.netlify.app
```

### Frontend on Netlify

Set this Netlify environment variable:

```env
API_BASE_URL=https://your-api.onrender.com
```

Build command:

```bash
flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
```

Publish directory:

```text
build/web
```

## API

### POST `/generate-risk-register`

Request:

```json
{
  "project_name": "ClinicFlow",
  "description": "A healthcare booking platform with patient records, doctor calendars, SMS reminders, and online payments.",
  "industry": "Healthcare",
  "mode": "Detailed"
}
```

Response includes:

- `score`
- `level`
- `summary`
- `executive_brief`
- `risks`
- `source`
- `fallback_reason`

