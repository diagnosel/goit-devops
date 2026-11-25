from django.db import connection
from django.http import JsonResponse


def home(request):
    with connection.cursor() as cursor:
        cursor.execute("SELECT current_database()")
        database_name = cursor.fetchone()[0]

    return JsonResponse(
        {
            "message": "Django is running behind Nginx.",
            "database": database_name,
        }
    )
