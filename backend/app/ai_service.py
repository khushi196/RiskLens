import json
import os
import time
from typing import Any
from urllib import request as urllib_request
from urllib.error import HTTPError, URLError

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover
    load_dotenv = None

if load_dotenv:
    load_dotenv()

SEVERITY_POINTS = {"Low": 1, "Medium": 2, "High": 3, "Critical": 4}
PROBABILITY_POINTS = {"Low": 1, "Medium": 2, "High": 3, "Critical": 4}
IMPACT_POINTS = {"Low": 1, "Medium": 2, "High": 3, "Critical": 4}

RISK_SCHEMA: dict[str, Any] = {
    "type": "OBJECT",
    "properties": {
        "score": {"type": "INTEGER"},
        "level": {"type": "STRING"},
        "summary": {"type": "STRING"},
        "executive_brief": {
            "type": "OBJECT",
            "properties": {
                "top_concern": {"type": "STRING"},
                "recommended_next_step": {"type": "STRING"},
                "leadership_decision_needed": {"type": "STRING"},
            },
            "required": [
                "top_concern",
                "recommended_next_step",
                "leadership_decision_needed",
            ],
        },
        "risks": {
            "type": "ARRAY",
            "items": {
                "type": "OBJECT",
                "properties": {
                    "title": {"type": "STRING"},
                    "category": {"type": "STRING"},
                    "severity": {"type": "STRING"},
                    "probability": {"type": "STRING"},
                    "impact": {"type": "STRING"},
                    "owner": {"type": "STRING"},
                    "scenario": {"type": "STRING"},
                    "why_this_project_is_exposed": {"type": "STRING"},
                    "mitigation": {"type": "STRING"},
                    "warning_signs": {"type": "STRING"},
                    "contingency": {"type": "STRING"},
                },
                "required": [
                    "title",
                    "category",
                    "severity",
                    "probability",
                    "impact",
                    "owner",
                    "scenario",
                    "why_this_project_is_exposed",
                    "mitigation",
                    "warning_signs",
                    "contingency",
                ],
            },
        },
    },
    "required": ["score", "level", "summary", "executive_brief", "risks"],
}


class AIServiceError(Exception):
    pass


def configured_provider() -> str:
    return os.getenv("AI_PROVIDER", "mock").strip().lower()


def configured_model() -> str:
    return os.getenv("GEMINI_MODEL", "gemini-2.5-flash-lite").strip()


def _env_flag(name: str, default: str = "false") -> bool:
    return os.getenv(name, default).strip().lower() in {"1", "true", "yes", "on"}


def build_prompt(project_name: str, description: str, industry: str, mode: str) -> str:
    return f"""
You are a senior AI risk analyst helping a product team prepare for launch.

Generate a project-specific risk register. Do not give generic risks. Every risk must clearly connect to the project description, industry, users, data, operations, or integrations mentioned below.

Project name: {project_name}
Industry: {industry}
Analysis mode: {mode}
Project description: {description}

Instructions:
- Identify realistic risks that could affect this exact project.
- Avoid vague phrases like "operational issues", "technical problems", "data concerns", or "security risks" unless you explain the exact scenario.
- Do not repeat the same idea in different words.
- Use business-friendly but specific language.
- Owners must be roles, not names.
- Severity, probability, and impact must each be one of: Low, Medium, High, Critical.
- If the description is short, infer reasonable assumptions but mention them through the risks.
- Focus on launch readiness, user trust, compliance, reliability, security, operations, and business impact.

Mode behavior:
- Quick: return exactly 4 risks, concise wording.
- Detailed: return exactly 7 risks with deeper mitigation detail.
- Executive: return exactly 5 risks focused on business impact and leadership decisions.

For each risk, include title, category, severity, probability, impact, owner, scenario, why_this_project_is_exposed, mitigation, warning_signs, and contingency.

Return only valid JSON matching the provided response schema. Score must reflect severity, probability, number of high-impact risks, compliance exposure, and launch complexity.
""".strip()


def _clean_rating(value: Any, default: str = "Medium") -> str:
    text = str(value or default).replace(" probability", "").strip().title()
    return text if text in SEVERITY_POINTS else default


def score_level(score: int) -> str:
    if score >= 85:
        return "Critical"
    if score >= 68:
        return "High Attention"
    if score >= 40:
        return "Moderate"
    return "Low"


def calculate_score(risks: list[dict[str, Any]], mode: str, industry: str) -> int:
    if not risks:
        return 0
    total = 0
    for risk in risks:
        severity = SEVERITY_POINTS.get(_clean_rating(risk.get("severity")), 2)
        probability = PROBABILITY_POINTS.get(_clean_rating(risk.get("probability")), 2)
        impact = IMPACT_POINTS.get(_clean_rating(risk.get("impact")), 2)
        total += severity * 5 + probability * 3 + impact * 4
    average = total / len(risks)
    complexity = min(len(risks) * 3, 18)
    compliance = 8 if industry.lower() in {"fintech", "healthcare"} else 0
    mode_bonus = {"quick": 0, "detailed": 5, "executive": 3}.get(mode.lower(), 2)
    return max(0, min(100, round(average * 1.75 + complexity + compliance + mode_bonus)))


def _normalize_risk(risk: dict[str, Any], project_name: str, description: str) -> dict[str, str]:
    title = str(risk.get("title") or "Launch readiness gap")
    category = str(risk.get("category") or "Operations")
    severity = _clean_rating(risk.get("severity"))
    probability = _clean_rating(risk.get("probability"))
    impact = _clean_rating(risk.get("impact"))
    owner = str(risk.get("owner") or "Product Lead")
    return {
        "title": title,
        "category": category,
        "severity": severity,
        "probability": probability,
        "impact": impact,
        "owner": owner,
        "scenario": str(
            risk.get("scenario")
            or f"{title} could delay or reduce trust in {project_name}."
        ),
        "why_this_project_is_exposed": str(
            risk.get("why_this_project_is_exposed")
            or f"The project description mentions: {description[:180]}."
        ),
        "mitigation": str(risk.get("mitigation") or "Assign an owner, define controls, and review before launch."),
        "warning_signs": str(risk.get("warning_signs") or "Open blockers, repeated failures, or delayed approvals."),
        "contingency": str(risk.get("contingency") or "Pause launch scope and activate the agreed fallback process."),
    }


def normalize_report(
    report: dict[str, Any],
    *,
    project_name: str,
    description: str,
    industry: str,
    mode: str,
    source: str,
    fallback_reason: str | None = None,
) -> dict[str, Any]:
    risks = [
        _normalize_risk(item, project_name, description)
        for item in report.get("risks", [])
        if isinstance(item, dict)
    ]
    score = calculate_score(risks, mode, industry)
    level = score_level(score)
    brief = report.get("executive_brief") or {}
    top_risk = risks[0]["title"] if risks else "Launch readiness"
    return {
        "project_name": project_name,
        "score": score,
        "level": level,
        "summary": str(
            report.get("summary")
            or f"{project_name} is rated {level.lower()} with {len(risks)} launch risks across {industry}. The highest priority area is {top_risk}."
        ),
        "executive_brief": {
            "top_concern": str(brief.get("top_concern") or f"{top_risk} is the highest priority concern."),
            "recommended_next_step": str(brief.get("recommended_next_step") or "Run an owner-led risk review before launch."),
            "leadership_decision_needed": str(brief.get("leadership_decision_needed") or "Confirm whether the launch scope can proceed with the current controls."),
        },
        "risks": risks,
        "source": source,
        "fallback_reason": fallback_reason,
    }


def _has_any(text: str, terms: list[str]) -> bool:
    return any(term in text for term in terms)


def _has_keyword(text: str, terms: list[str]) -> bool:
    padded = f" {text} "
    return any(f" {term} " in padded for term in terms)


def _risk_templates(description: str, industry: str) -> list[dict[str, str]]:
    text = f"{description} {industry}".lower()
    risks: list[dict[str, str]] = []

    def add(risk: dict[str, str]) -> None:
        if all(existing["title"] != risk["title"] for existing in risks):
            risks.append(risk)

    is_ai_writing_app = _has_any(
        text,
        [
            "excuse",
            "professional email",
            "professional emails",
            "professional message",
            "professional messages",
            "tone mode",
            "tone modes",
            "professor",
            "manager",
            "client",
            "copy the generated message",
        ],
    ) and (_has_keyword(text, ["ai", "llm"]) or _has_any(text, ["generated message", "generate a polished"]))

    is_rideshare_app = _has_any(
        text,
        [
            "ride sharing",
            "ride-sharing",
            "rideshare",
            "student driver",
            "student drivers",
            "request rides",
            "live location",
            "trip history",
            "emergency contact",
        ],
    )

    if is_rideshare_app:
        add({
            "title": "Student rider safety incident",
            "category": "Operations",
            "severity": "Critical",
            "probability": "Medium",
            "impact": "Critical",
            "owner": "Operations Lead",
            "scenario": "A rider or driver faces a safety issue during a campus trip and the team cannot respond quickly enough.",
            "why_this_project_is_exposed": "CampusRide coordinates real-world rides between students, so risk is not only digital; it affects physical safety.",
            "mitigation": "Add trip sharing, emergency contact access, ride check-ins, driver rules, and a clear safety escalation process before launch.",
            "warning_signs": "Unverified rides, repeated low driver ratings, late-night incidents, or users contacting support during active trips.",
            "contingency": "Pause new ride requests, contact campus safety, and preserve trip/location records for review.",
        })
        add({
            "title": "Live location privacy exposure",
            "category": "Security",
            "severity": "Critical",
            "probability": "Medium",
            "impact": "Critical",
            "owner": "Security Lead",
            "scenario": "A student\'s live location, trip history, phone number, or emergency contact details are exposed to the wrong person.",
            "why_this_project_is_exposed": "The app stores student IDs, phone numbers, live location, trip history, and emergency contact information.",
            "mitigation": "Limit who can see location data, expire live tracking links, encrypt sensitive fields, and audit access to trip records.",
            "warning_signs": "Users report unwanted contact, location links remain active after rides, or support can view too much student data.",
            "contingency": "Disable live tracking links, rotate exposed tokens, notify affected users, and review access logs.",
        })
        add({
            "title": "Driver verification failure",
            "category": "Compliance",
            "severity": "High",
            "probability": "Medium",
            "impact": "High",
            "owner": "Trust and Safety Lead",
            "scenario": "An unqualified or impersonating student driver gets approved and accepts rides.",
            "why_this_project_is_exposed": "The product depends on verified student drivers, but fake or stale student IDs can bypass weak checks.",
            "mitigation": "Verify student status, require driver eligibility checks, review ratings, and re-check drivers each term.",
            "warning_signs": "Mismatched student records, repeated complaints, suspicious account changes, or drivers sharing accounts.",
            "contingency": "Suspend the driver, cancel active rides, contact affected riders, and require re-verification.",
        })
        add({
            "title": "Emergency response gap",
            "category": "Operations",
            "severity": "High",
            "probability": "Medium",
            "impact": "Critical",
            "owner": "Campus Operations Lead",
            "scenario": "A rider taps for help but the app has no reliable process for contacting campus safety or emergency contacts.",
            "why_this_project_is_exposed": "The app collects emergency contact information, which creates an expectation that emergency workflows will actually work.",
            "mitigation": "Define emergency workflows with campus safety, test contact escalation, and show users what the app can and cannot do.",
            "warning_signs": "Support receives urgent ride messages, emergency contact data is incomplete, or escalation ownership is unclear.",
            "contingency": "Disable the emergency feature until escalation paths are tested and documented.",
        })

    if is_ai_writing_app:
        add({
            "title": "Misuse for dishonest communication",
            "category": "Product",
            "severity": "High",
            "probability": "Medium",
            "impact": "High",
            "owner": "Product Lead",
            "scenario": "Users generate polished excuses that misrepresent attendance, deadlines, or accountability.",
            "why_this_project_is_exposed": "The product explicitly transforms casual excuses into professional messages for professors, managers, clients, or friends.",
            "mitigation": "Add acceptable-use guidance, discourage deception, and position output as drafting help rather than truth creation.",
            "warning_signs": "Prompts mention fake emergencies, fabricated medical issues, or requests to avoid consequences.",
            "contingency": "Block high-risk generations and return a safer template that asks users to be accurate and accountable.",
        })
        add({
            "title": "Private excuse data exposure",
            "category": "Security",
            "severity": "High",
            "probability": "Medium",
            "impact": "High",
            "owner": "Security Lead",
            "scenario": "Users paste sensitive personal, academic, workplace, health, or relationship details into the input box.",
            "why_this_project_is_exposed": "Excuse writing often includes personal context, and the app uses an LLM API plus browser local storage.",
            "mitigation": "Show a privacy notice, avoid server-side storage, redact obvious sensitive details, and let users clear local history.",
            "warning_signs": "Inputs contain phone numbers, emails, medical details, employer names, or other personal identifiers.",
            "contingency": "Disable history for sensitive prompts and provide a clear data deletion action.",
        })
        add({
            "title": "Tone mismatch damages credibility",
            "category": "Customer Experience",
            "severity": "Medium",
            "probability": "High",
            "impact": "Medium",
            "owner": "AI Product Lead",
            "scenario": "The generated message sounds too formal, fake, apologetic, or casual for the selected recipient mode.",
            "why_this_project_is_exposed": "The core feature depends on professor, manager, client, and friend modes producing believable tone differences.",
            "mitigation": "Create mode-specific prompt templates, preview labels, and regenerate options with shorter or warmer variants.",
            "warning_signs": "Users repeatedly regenerate, copy edited versions, or complain that messages sound AI-written.",
            "contingency": "Offer conservative template-based outputs when the model response fails tone checks.",
        })
        add({
            "title": "LLM quota or cost spike",
            "category": "Financial",
            "severity": "Medium",
            "probability": "High",
            "impact": "High",
            "owner": "Engineering Lead",
            "scenario": "A shareable app gets sudden traffic and burns through LLM quota or budget.",
            "why_this_project_is_exposed": "The product is designed to be simple and shareable, and every generation can call an external LLM API.",
            "mitigation": "Add rate limits, daily caps, caching for repeated examples, and fallback templates when quota is exceeded.",
            "warning_signs": "Requests per minute spike, 429 errors increase, or API spend exceeds daily thresholds.",
            "contingency": "Temporarily switch to local templates and show a polite capacity message.",
        })
        add({
            "title": "Prompt abuse creates unsafe outputs",
            "category": "Security",
            "severity": "Medium",
            "probability": "Medium",
            "impact": "High",
            "owner": "AI Safety Lead",
            "scenario": "Users ask the app to generate manipulative, threatening, discriminatory, or policy-violating messages.",
            "why_this_project_is_exposed": "Open-ended text input can be used for more than harmless excuse polishing.",
            "mitigation": "Add input moderation, output safety checks, and refusal templates for harmful communication requests.",
            "warning_signs": "Prompts include harassment, coercion, threats, or requests to impersonate someone else.",
            "contingency": "Return a safe rewrite suggestion or refuse the generation with a short explanation.",
        })

    if _has_any(text, ["payment", "checkout", "wallet", "payout", "refund", "fare", "fares", "split fares"]):
        add({
            "title": "Payment flow failure",
            "category": "Technical",
            "severity": "High",
            "probability": "Medium",
            "impact": "High",
            "owner": "Backend Lead",
            "scenario": "Payment authorization, split fare, refund, or payout events fail during normal usage.",
            "why_this_project_is_exposed": "The project includes money movement, so payment failures directly block users and create support issues.",
            "mitigation": "Add idempotent payment retries, reconciliation jobs, gateway monitoring, and clear refund states.",
            "warning_signs": "Payment failure rate above 2%, delayed callbacks, or growing reconciliation mismatches.",
            "contingency": "Pause affected payment flows and route transactions through a backup process.",
        })
    if not is_rideshare_app and _has_any(text, ["kyc", "identity", "verification", "onboarding"]):
        add({
            "title": "Identity verification backlog",
            "category": "Compliance",
            "severity": "High",
            "probability": "Medium",
            "impact": "High",
            "owner": "Compliance Lead",
            "scenario": "Automated verification fails and manual review queues delay user onboarding.",
            "why_this_project_is_exposed": "The project includes identity or onboarding checks that depend on third-party verification quality.",
            "mitigation": "Create manual review SLAs, provider failover rules, and a risk-based onboarding queue.",
            "warning_signs": "Pending verification count grows for two consecutive days or approval SLA drops below target.",
            "contingency": "Throttle onboarding and switch high-risk users to manual review only.",
        })
    if _has_any(text, ["patient", "health", "clinic", "doctor", "medical"]):
        add({
            "title": "Patient data exposure",
            "category": "Security",
            "severity": "Critical",
            "probability": "Medium",
            "impact": "Critical",
            "owner": "Security Lead",
            "scenario": "Patient records, appointment notes, or reminders are exposed through weak access controls.",
            "why_this_project_is_exposed": "The product handles healthcare data and appointment workflows involving sensitive patient information.",
            "mitigation": "Enforce least-privilege access, audit logs, encrypted storage, and retention controls.",
            "warning_signs": "Unreviewed access logs, broad admin permissions, or failed security test cases.",
            "contingency": "Disable affected data views and run an incident response review.",
        })
    if not is_ai_writing_app and not is_rideshare_app and _has_any(text, ["sms", "notification", "reminder", "delivery receipt"]):
        add({
            "title": "Notification delivery gaps",
            "category": "Customer Experience",
            "severity": "Medium",
            "probability": "High",
            "impact": "Medium",
            "owner": "Product Operations Lead",
            "scenario": "Users miss important reminders because SMS or email delivery fails silently.",
            "why_this_project_is_exposed": "The project relies on outbound notifications to keep users informed and reduce missed actions.",
            "mitigation": "Track delivery receipts, retry failed sends, and expose notification status to support teams.",
            "warning_signs": "Bounce rate rises, delivery receipts are missing, or support tickets mention missed reminders.",
            "contingency": "Switch to alternate channels and manually notify high-priority users.",
        })
    if not is_ai_writing_app and _has_keyword(text, ["ai", "llm", "model", "automation"]):
        add({
            "title": "AI output trust gap",
            "category": "Product",
            "severity": "High",
            "probability": "Medium",
            "impact": "High",
            "owner": "AI Product Lead",
            "scenario": "Generated recommendations are vague, incorrect, or used without human review.",
            "why_this_project_is_exposed": "The product uses AI output in a workflow where users may treat generated content as authoritative.",
            "mitigation": "Add structured prompts, output validation, confidence disclaimers, and human approval checkpoints.",
            "warning_signs": "Repeated edits to AI output, user complaints, or validation failures in generated fields.",
            "contingency": "Disable AI generation for affected flows and switch to reviewed templates.",
        })
    if _has_any(text, ["vendor", "settlement", "marketplace", "payout"]):
        add({
            "title": "Vendor operations breakdown",
            "category": "Operations",
            "severity": "Medium",
            "probability": "Medium",
            "impact": "High",
            "owner": "Operations Manager",
            "scenario": "Vendor setup, settlement, or documentation steps are incomplete at launch.",
            "why_this_project_is_exposed": "The project includes vendor-side workflows that require operational readiness beyond code completion.",
            "mitigation": "Create vendor launch checklists, payout verification, and support escalation playbooks.",
            "warning_signs": "Vendors fail document checks or payout setup repeatedly.",
            "contingency": "Limit launch to verified vendors and defer the rest of the cohort.",
        })

    add({
        "title": "Launch readiness ownership gap",
        "category": "Business",
        "severity": "Medium",
        "probability": "Medium",
        "impact": "Medium",
        "owner": "Product Lead",
        "scenario": "Important launch checks are assumed complete but nobody verifies the full user journey end to end.",
        "why_this_project_is_exposed": "The project crosses product, engineering, operations, safety, and support responsibilities.",
        "mitigation": "Create a launch checklist with named owners, dates, test evidence, and sign-off criteria.",
        "warning_signs": "Open launch blockers have no owner, due date, or decision maker.",
        "contingency": "Move launch to a smaller beta until sign-off is complete.",
    })
    add({
        "title": "Support team cannot resolve incidents quickly",
        "category": "Customer Experience",
        "severity": "Medium",
        "probability": "Medium",
        "impact": "Medium",
        "owner": "Support Lead",
        "scenario": "Users report problems after launch, but support cannot see enough context to help quickly.",
        "why_this_project_is_exposed": "New workflows create unfamiliar failure cases for users and internal teams.",
        "mitigation": "Prepare support scripts, admin lookup views, dashboards, and escalation paths before launch.",
        "warning_signs": "Ticket volume rises, support asks engineering for every issue, or users repeat the same complaint.",
        "contingency": "Limit new signups and add engineering office hours for support until patterns stabilize.",
    })
    return risks


def _fallback_summary(project_name: str, risks: list[dict[str, str]]) -> str:
    titles = {risk.get("title") for risk in risks}
    if "Student rider safety incident" in titles:
        return (
            f"{project_name} is a student ride-sharing product, so the main launch risk is student safety, not just app reliability. "
            "The biggest areas to prove before launch are rider safety, live-location privacy, driver verification, emergency response, and payment handling."
        )
    if "Misuse for dishonest communication" in titles:
        return (
            f"{project_name} is an AI writing tool, so the main launch risk is misuse of generated messages. "
            "The highest-priority areas are honest-use guardrails, privacy for personal excuses, tone quality, LLM cost controls, and unsafe prompt handling."
        )
    top_risk = risks[0]["title"] if risks else "launch readiness"
    return (
        f"{project_name} has {len(risks)} launch risks to review before release. "
        f"The first priority is {top_risk.lower()}, followed by clear ownership, monitoring, and fallback plans."
    )


def mock_risk_register(
    project_name: str,
    description: str = "",
    industry: str = "General",
    mode: str = "Executive",
    fallback_reason: str | None = None,
) -> dict[str, Any]:
    all_risks = _risk_templates(description, industry)
    limit = {"quick": 4, "detailed": 7, "executive": 5}.get(mode.lower(), 5)
    risks = all_risks[:limit]
    top_risk = risks[0]["title"]
    report = {
        "summary": _fallback_summary(project_name, risks),
        "executive_brief": {
            "top_concern": f"{top_risk} is the first risk to resolve before launch.",
            "recommended_next_step": "Review the top risks with the named owners and decide which controls must be proven before launch.",
            "leadership_decision_needed": "Decide whether to launch broadly, run a controlled beta, or delay until the highest-impact controls are ready.",
        },
        "risks": risks,
    }
    return normalize_report(
        report,
        project_name=project_name,
        description=description,
        industry=industry,
        mode=mode,
        source="fallback",
        fallback_reason=fallback_reason,
    )

class GeminiRiskGenerator:
    def __init__(self, api_key: str, model: str | None = None, opener=None):
        if not api_key:
            raise AIServiceError("GEMINI_API_KEY is not set.")
        self.api_key = api_key
        self.model = model or configured_model()
        self.opener = opener or urllib_request.urlopen

    def _request_with_retry(self, req: urllib_request.Request) -> dict[str, Any]:
        transient_statuses = {429, 502, 503, 504}
        last_error: Exception | None = None
        for attempt in range(3):
            try:
                response = self.opener(req, timeout=45)
                return json.loads(response.read().decode("utf-8"))
            except HTTPError as exc:
                last_error = exc
                if exc.code not in transient_statuses or attempt == 2:
                    break
                time.sleep(0.6 * (attempt + 1))
            except (URLError, TimeoutError, OSError) as exc:
                last_error = exc
                if attempt == 2:
                    break
                time.sleep(0.6 * (attempt + 1))
        raise AIServiceError(f"Gemini request failed: {last_error}") from last_error
    def generate(
        self,
        *,
        project_name: str,
        description: str,
        industry: str,
        mode: str,
    ) -> dict[str, Any]:
        payload = {
            "contents": [
                {
                    "parts": [
                        {
                            "text": build_prompt(
                                project_name,
                                description,
                                industry,
                                mode,
                            )
                        }
                    ]
                }
            ],
            "generationConfig": {
                "response_mime_type": "application/json",
                "response_schema": RISK_SCHEMA,
                "temperature": 0.2,
            },
        }
        url = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{self.model}:generateContent?key={self.api_key}"
        )
        req = urllib_request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        data = self._request_with_retry(req)

        try:
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            generated = json.loads(text)
        except (KeyError, IndexError, TypeError, json.JSONDecodeError) as exc:
            raise AIServiceError("Gemini returned an invalid response shape.") from exc

        return normalize_report(
            generated,
            project_name=project_name,
            description=description,
            industry=industry,
            mode=mode,
            source="gemini",
        )


def generate_risk_register(
    *,
    project_name: str,
    description: str,
    industry: str,
    mode: str,
) -> dict[str, Any]:
    provider = configured_provider()
    if provider == "gemini":
        try:
            return GeminiRiskGenerator(os.getenv("GEMINI_API_KEY", "")).generate(
                project_name=project_name,
                description=description,
                industry=industry,
                mode=mode,
            )
        except AIServiceError as exc:
            if _env_flag("AI_FALLBACK_TO_MOCK", "true"):
                return mock_risk_register(
                    project_name,
                    description=description,
                    industry=industry,
                    mode=mode,
                    fallback_reason=str(exc),
                )
            raise
    return mock_risk_register(
        project_name,
        description=description,
        industry=industry,
        mode=mode,
    )





