from django.db import connection
from django.test import TestCase


class HomePageTests(TestCase):
    def test_database_is_postgresql(self):
        self.assertEqual(connection.vendor, "postgresql")

    def test_home_page_reads_current_database(self):
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertJSONEqual(
            response.content,
            {
                "message": "Django is running behind Nginx.",
                "database": connection.settings_dict["NAME"],
            },
        )
