import json
import os
import unittest
from unittest.mock import patch

from app.ai_service import (
    AIServiceError,
    GeminiRiskGenerator,
    RISK_SCHEMA,
    build_prompt,
    calculate_score,
    generate_risk_register,
    mock_risk_register,
    score_level,
)


class FakeResponse:
    def __init__(self, body):
        self.body = body

    def read(self):
        return self.body


class AIServiceTests(unittest.TestCase):
    def test_build_prompt_demands_specific_non_generic_risks(self):
        prompt = build_prompt(
            "ClinicFlow",
            "A healthcare booking platform with patient records and SMS reminders",
            "Healthcare",
            "Detailed",
        )

        self.assertIn("Project name: ClinicFlow", prompt)
        self.assertIn("Industry: Healthcare", prompt)
        self.assertIn("Analysis mode: Detailed", prompt)
        self.assertIn("Do not give generic risks", prompt)
        self.assertIn("why_this_project_is_exposed", prompt)
        self.assertIn("scenario", prompt)
        self.assertNotIn("{{PROJECT_NAME}}", prompt)

    def test_risk_schema_requires_specificity_fields(self):
        risk_item = RISK_SCHEMA["properties"]["risks"]["items"]
        self.assertIn("scenario", risk_item["properties"])
        self.assertIn("why_this_project_is_exposed", risk_item["properties"])
        self.assertIn("scenario", risk_item["required"])
        self.assertIn("why_this_project_is_exposed", risk_item["required"])

    def test_score_is_calculated_from_risk_ratings(self):
        risks = [
            {"severity": "Critical", "probability": "High", "impact": "Critical"},
            {"severity": "High", "probability": "Medium", "impact": "High"},
        ]
        score = calculate_score(risks, "Detailed", "Healthcare")
        self.assertGreaterEqual(score, 85)
        self.assertEqual(score_level(score), "Critical")

    def test_dynamic_fallback_uses_project_context_and_source_metadata(self):
        result = mock_risk_register(
            "ClinicFlow",
            description="Healthcare booking with patient records, SMS reminders, and online payments.",
            industry="Healthcare",
            mode="Detailed",
            fallback_reason="quota",
        )
        titles = {risk["title"] for risk in result["risks"]}

        self.assertEqual(result["project_name"], "ClinicFlow")
        self.assertEqual(result["source"], "fallback")
        self.assertEqual(result["fallback_reason"], "quota")
        self.assertIn("Patient data exposure", titles)
        self.assertIn("Notification delivery gaps", titles)
        self.assertIn("Payment flow failure", titles)
        self.assertIn(result["level"], {"Moderate", "High Attention", "Critical"})

    def test_fallback_for_ai_writing_app_uses_relevant_risks(self):
        result = mock_risk_register(
            "Excuse Translator",
            description=(
                "A lightweight AI web app that turns messy excuses into professional "
                "emails and messages. Users choose professor, manager, client, or friend "
                "tone modes and copy the generated message. It uses an LLM API and browser local storage."
            ),
            industry="SaaS",
            mode="Detailed",
        )
        titles = {risk["title"] for risk in result["risks"]}

        self.assertIn("Misuse for dishonest communication", titles)
        self.assertIn("Private excuse data exposure", titles)
        self.assertIn("Tone mismatch damages credibility", titles)
        self.assertIn("LLM quota or cost spike", titles)
        self.assertNotIn("Notification delivery gaps", titles)
        self.assertIn("AI writing", result["summary"])
    def test_fallback_for_campus_rideshare_uses_safety_and_privacy_risks(self):
        result = mock_risk_register(
            "CampusRide",
            description=(
                "CampusRide is a student-only ride sharing app for college campuses. "
                "Students can request rides from verified student drivers, split fares, "
                "track live location, and rate drivers after each ride. The app stores "
                "student IDs, phone numbers, payment details, trip history, and emergency contact information."
            ),
            industry="SaaS",
            mode="Executive",
        )
        titles = {risk["title"] for risk in result["risks"]}

        self.assertIn("Student rider safety incident", titles)
        self.assertIn("Live location privacy exposure", titles)
        self.assertIn("Driver verification failure", titles)
        self.assertIn("Emergency response gap", titles)
        self.assertNotIn("AI output trust gap", titles)
        self.assertIn("student ride-sharing", result["summary"])
        self.assertGreaterEqual(result["score"], 68)
    def test_gemini_generator_maps_and_normalizes_structured_response(self):
        calls = []

        def fake_opener(request, timeout):
            calls.append((request, timeout))
            body = {
                "candidates": [
                    {
                        "content": {
                            "parts": [
                                {
                                    "text": json.dumps(
                                        {
                                            "score": 10,
                                            "level": "Low",
                                            "summary": "AI summary",
                                            "executive_brief": {
                                                "top_concern": "Payments",
                                                "recommended_next_step": "Run tests",
                                                "leadership_decision_needed": "Approve backup provider",
                                            },
                                            "risks": [
                                                {
                                                    "title": "Payment reliability",
                                                    "category": "Technical",
                                                    "severity": "High",
                                                    "probability": "Medium",
                                                    "impact": "High",
                                                    "owner": "Backend Lead",
                                                    "scenario": "Payment callbacks are delayed during peak checkout traffic.",
                                                    "why_this_project_is_exposed": "The wallet relies on external payment gateway callbacks.",
                                                    "mitigation": "Add retries",
                                                    "warning_signs": "Failures rise",
                                                    "contingency": "Use backup",
                                                }
                                            ],
                                        }
                                    )
                                }
                            ]
                        }
                    }
                ]
            }
            return FakeResponse(json.dumps(body).encode("utf-8"))

        result = GeminiRiskGenerator("test-key", opener=fake_opener).generate(
            project_name="Wallet",
            description="KYC and payments",
            industry="Fintech",
            mode="Executive",
        )

        self.assertEqual(result["project_name"], "Wallet")
        self.assertEqual(result["source"], "gemini")
        self.assertGreater(result["score"], 10)
        self.assertEqual(result["risks"][0]["title"], "Payment reliability")
        self.assertEqual(calls[0][1], 45)
        self.assertIn("generateContent", calls[0][0].full_url)

    def test_gemini_generator_retries_transient_503_before_success(self):
        import urllib.error

        calls = []

        def fake_opener(request, timeout):
            calls.append((request, timeout))
            if len(calls) == 1:
                raise urllib.error.HTTPError(
                    request.full_url,
                    503,
                    "Service Unavailable",
                    hdrs=None,
                    fp=None,
                )
            body = {
                "candidates": [
                    {
                        "content": {
                            "parts": [
                                {
                                    "text": json.dumps(
                                        {
                                            "summary": "Recovered summary",
                                            "executive_brief": {
                                                "top_concern": "Safety",
                                                "recommended_next_step": "Retry worked",
                                                "leadership_decision_needed": "Approve controls",
                                            },
                                            "risks": [
                                                {
                                                    "title": "Safety incident",
                                                    "category": "Operations",
                                                    "severity": "High",
                                                    "probability": "Medium",
                                                    "impact": "High",
                                                    "owner": "Ops Lead",
                                                    "scenario": "A user safety event happens.",
                                                    "why_this_project_is_exposed": "The product coordinates real-world activity.",
                                                    "mitigation": "Add safety workflows.",
                                                    "warning_signs": "Safety complaints increase.",
                                                    "contingency": "Pause launches.",
                                                }
                                            ],
                                        }
                                    )
                                }
                            ]
                        }
                    }
                ]
            }
            return FakeResponse(json.dumps(body).encode("utf-8"))

        result = GeminiRiskGenerator("test-key", opener=fake_opener).generate(
            project_name="CampusRide",
            description="Student ride sharing",
            industry="SaaS",
            mode="Executive",
        )

        self.assertEqual(len(calls), 2)
        self.assertEqual(result["source"], "gemini")
        self.assertEqual(result["summary"], "Recovered summary")
    def test_default_provider_uses_fallback_without_api_key(self):
        with patch.dict(os.environ, {"AI_PROVIDER": "mock"}):
            result = generate_risk_register(
                project_name="Wallet",
                description="Wallet app with KYC and payments.",
                industry="Fintech",
                mode="Executive",
            )
        self.assertEqual(result["project_name"], "Wallet")
        self.assertEqual(result["source"], "fallback")
        self.assertIn("risks", result)

    def test_gemini_provider_can_fallback_to_mock_on_quota_error(self):
        with patch.dict(
            os.environ,
            {
                "AI_PROVIDER": "gemini",
                "GEMINI_API_KEY": "test-key",
                "AI_FALLBACK_TO_MOCK": "true",
            },
        ):
            with patch.object(
                GeminiRiskGenerator,
                "generate",
                side_effect=AIServiceError("Gemini request failed: HTTP Error 429"),
            ):
                result = generate_risk_register(
                    project_name="Wallet",
                    description="Wallet app with KYC and payments.",
                    industry="Fintech",
                    mode="Executive",
                )

        self.assertEqual(result["project_name"], "Wallet")
        self.assertEqual(result["source"], "fallback")
        self.assertIn("HTTP Error 429", result["fallback_reason"])


if __name__ == "__main__":
    unittest.main()



