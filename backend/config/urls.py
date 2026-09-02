from django.contrib import admin
from django.urls import path, include, re_path
from django.views.generic import RedirectView
from django.conf import settings
from django.views.static import serve

urlpatterns = [
    path("admin/", admin.site.urls),
    path("auth/", include("users.urls")),
    path("groups/", include("students.urls")),
    path("students/", include("students.students_urls")),
    path("attendance/", include("attendance.urls")),
    path("bot/", include("notifications.urls")),
    path("api/", include("api.urls")),
    re_path(r"^media/(?P<path>.*)$", serve, {"document_root": settings.MEDIA_ROOT}),
    path("", RedirectView.as_view(url="/groups/", permanent=False)),
]


