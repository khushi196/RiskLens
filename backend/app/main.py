import os

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from app.ai_service import AIServiceError, configured_model, configured_provider
from app.ai_service import generate_risk_register as generate_ai_risk_register


def allowed_origins() -> list[str]:
    raw = os.getenv("ALLOWED_ORIGINS", "*").strip()
    if raw == "*":
        return ["*"]
    return [origin.strip() for origin in raw.split(",") if origin.strip()]


app = FastAPI(title="RiskLens API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins(),
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


class RiskRegisterRequest(BaseModel):
    project_name: str = Field(min_length=2, max_length=90)
    description: str = Field(min_length=12, max_length=2400)
    industry: str = Field(min_length=2, max_length=60)
    mode: str = Field(pattern="^(Quick|Detailed|Executive)$")


@app.get("/")
def root():
    return {"service": "risklens-api", "docs": "/docs", "health": "/health"}


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "risklens-api",
        "provider": configured_provider(),
        "model": configured_model(),
        "fallback_enabled": os.getenv("AI_FALLBACK_TO_MOCK", "true").lower()
        in {"1", "true", "yes", "on"},
    }


@app.post("/generate-risk-register")
def generate_risk_register(request: RiskRegisterRequest):
    try:
        return generate_ai_risk_register(
            project_name=request.project_name.strip(),
            description=request.description.strip(),
            industry=request.industry.strip(),
            mode=request.mode.strip(),
        )
    except AIServiceError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

