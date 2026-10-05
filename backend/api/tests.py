import json

from django.test import TestCase

from users.models import Parent


class VerifyTelegramViewTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        Parent.objects.create(
            full_name="Verification Test Parent",
            telegram_id=5577138147,
        )

    def test_existing_telegram_id_is_verified(self):
        response = self.client.post(
            "/api/verify-telegram/",
            data=json.dumps({"telegram_id": "5577138147"}),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {"success": True, "telegram_id": "5577138147"},
        )

    def test_unknown_telegram_id_is_rejected(self):
        response = self.client.post(
            "/api/verify-telegram/",
            data=json.dumps({"telegram_id": "9999999999"}),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json(),
            {"success": False, "error": "invalid_code"},
        )

    def test_malformed_telegram_id_is_rejected(self):
        response = self.client.post(
            "/api/verify-telegram/",
            data=json.dumps({"telegram_id": "557713814"}),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["error"], "invalid_code")

    def test_get_is_not_allowed(self):
        response = self.client.get("/api/verify-telegram/")

        self.assertEqual(response.status_code, 405)