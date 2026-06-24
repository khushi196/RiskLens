import unittest
from unittest.mock import patch

from app import main


class MainRouteTests(unittest.TestCase):
    def test_generate_route_delegates_to_ai_service(self):
        expected = {
            "project_name": "Wallet",
            "score": 88,
            "level": "High Attention",
            "summary": "AI generated summary",
            "executive_brief": {
                "top_concern": "Payments",
                "recommended_next_step": "Run reliability review",
                "leadership_decision_needed": "Approve backup provider",
            },
            "risks": [],
            "source": "gemini",
            "fallback_reason": None,
        }
        request = main.RiskRegisterRequest(
            project_name="Wallet",
            description="KYC and payments app",
            industry="Fintech",
            mode="Executive",
        )

        with patch("app.main.generate_ai_risk_register", return_value=expected) as generate:
            response = main.generate_risk_register(request)

        self.assertEqual(response, expected)
        generate.assert_called_once_with(
            project_name="Wallet",
            description="KYC and payments app",
            industry="Fintech",
            mode="Executive",
        )

    def test_health_includes_deployment_status(self):
        response = main.health_check()
        self.assertEqual(response["status"], "ok")
        self.assertIn("provider", response)
        self.assertIn("fallback_enabled", response)


if __name__ == "__main__":
    unittest.main()
