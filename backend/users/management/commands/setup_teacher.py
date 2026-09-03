from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from users.models import Teacher


class Command(BaseCommand):
    help = "Creates or updates default teacher account for production deployment"

    def handle(self, *args, **options):
        user, created = User.objects.get_or_create(username="abbosmath")
        user.set_password("abbosmath")
        user.is_staff = True
        user.is_superuser = True
        user.save()

        teacher, _ = Teacher.objects.get_or_create(
            user=user,
            defaults={"full_name": "Abbosmath Teacher", "subject": "Mathematics"}
        )

        self.stdout.write(self.style.SUCCESS("Successfully set up teacher 'abbosmath' in production database!"))
