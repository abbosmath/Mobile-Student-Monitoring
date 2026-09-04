from django.urls import path
from api import views_auth, views_teacher, views_student

urlpatterns = [
    path("", views_auth.api_root_view, name="api_root"),
    path("ping/", views_auth.ping_view, name="api_ping"),
    # Auth
    path("auth/login/teacher/", views_auth.teacher_login_view, name="api_teacher_login"),
    path("auth/login/student/", views_auth.student_login_view, name="api_student_login"),
    path("auth/me/", views_auth.me_view, name="api_me"),

    # Teacher Endpoints
    path("teacher/groups/", views_teacher.teacher_groups_view, name="api_teacher_groups"),
    path("teacher/groups/<int:group_id>/", views_teacher.teacher_group_detail_view, name="api_teacher_group_detail"),
    path("teacher/groups/<int:group_id>/add-student/", views_teacher.teacher_group_add_student_view, name="api_teacher_group_add_student"),
    path("teacher/groups/<int:group_id>/remove-student/<int:student_id>/", views_teacher.teacher_group_remove_student_view, name="api_teacher_group_remove_student"),
    
    path("teacher/students/", views_teacher.teacher_students_view, name="api_teacher_students"),
    path("teacher/students/<int:student_id>/", views_teacher.teacher_student_detail_view, name="api_teacher_student_detail"),
    path("teacher/students/<int:student_id>/points/", views_teacher.teacher_student_points_view, name="api_teacher_student_points"),
    path("teacher/students/<int:student_id>/payment/", views_teacher.teacher_student_payment_view, name="api_teacher_student_payment"),
    
    path("teacher/attendance/<int:group_id>/", views_teacher.teacher_take_attendance_view, name="api_teacher_take_attendance"),
    
    path("teacher/market/items/", views_teacher.teacher_market_items_view, name="api_teacher_market_items"),
    path("teacher/market/orders/", views_teacher.teacher_market_orders_view, name="api_teacher_market_orders"),
    
    path("teacher/tests/", views_teacher.teacher_tests_view, name="api_teacher_tests"),
    path("teacher/tests/<int:test_id>/", views_teacher.teacher_test_detail_view, name="api_teacher_test_detail"),

    # Student Endpoints
    path("student/dashboard/", views_student.student_dashboard_view, name="api_student_dashboard"),
    path("student/tests/", views_student.student_tests_view, name="api_student_tests"),
    path("student/tests/<int:test_id>/", views_student.student_test_detail_view, name="api_student_test_detail"),
    path("student/tests/<int:test_id>/submit/", views_student.student_test_submit_view, name="api_student_test_submit"),
    path("student/leaderboard/", views_student.student_leaderboard_view, name="api_student_leaderboard"),
    path("student/market/items/", views_student.student_market_items_view, name="api_student_market_items"),
    path("student/market/buy/", views_student.student_market_buy_view, name="api_student_market_buy"),
    path("student/market/orders/", views_student.student_market_orders_view, name="api_student_market_orders"),
    path("student/stats/", views_student.student_stats_view, name="api_student_stats"),
]
