import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import authenticate
from users.models import Teacher, Parent
from students.models import Student
from api.auth import generate_token, get_auth_payload, api_auth_required


@csrf_exempt
def api_root_view(request):
    return JsonResponse({
        "status": "ok",
        "message": "Student Monitoring REST API is online!",
        "endpoints": {
            "teacher_login": "/api/auth/login/teacher/",
            "student_login": "/api/auth/login/student/",
            "me": "/api/auth/me/",
        }
    })


@csrf_exempt
def teacher_login_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON body"}, status=400)

    username = data.get("username", "").strip()
    password = data.get("password", "").strip()

    if not username or not password:
        return JsonResponse({"error": "Username and password are required"}, status=400)

    user = authenticate(request, username=username, password=password)
    if user is None:
        return JsonResponse({"error": "Incorrect username or password"}, status=400)

    try:
        teacher = user.teacher
    except Teacher.DoesNotExist:
        # Fallback if teacher record doesn't exist for user
        teacher = Teacher.objects.create(user=user, full_name=user.get_full_name() or user.username)

    payload = {
        "role": "teacher",
        "user_id": user.id,
        "teacher_id": teacher.id,
        "username": user.username,
        "full_name": teacher.full_name or user.username,
    }
    token = generate_token(payload)

    return JsonResponse({
        "token": token,
        "role": "teacher",
        "teacher": {
            "id": teacher.id,
            "username": user.username,
            "full_name": teacher.full_name,
            "subject": teacher.subject,
        }
    })


@csrf_exempt
def student_login_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON body"}, status=400)

    login_input = str(data.get("identifier", "")).strip()

    if not login_input:
        return JsonResponse({"error": "Student ID, Phone, or Telegram ID is required"}, status=400)

    student = None
    # 1. Try finding student by numeric ID
    if login_input.isdigit():
        student = Student.objects.filter(pk=int(login_input)).first()

    # 2. Try finding by telegram_id via Parent
    if not student and login_input.isdigit():
        parent = Parent.objects.filter(telegram_id=int(login_input)).first()
        if parent:
            student = parent.children.first()

    # 3. Try finding by phone or full_name
    if not student:
        student = Student.objects.filter(full_name__icontains=login_input).first()

    if not student:
        # Check by parent phone
        parent = Parent.objects.filter(phone__icontains=login_input).first()
        if parent:
            student = parent.children.first()

    if not student:
        return JsonResponse({"error": "No student found with the given credentials"}, status=404)

    payload = {
        "role": "student",
        "student_id": student.id,
        "full_name": student.full_name,
    }
    token = generate_token(payload)

    return JsonResponse({
        "token": token,
        "role": "student",
        "student": {
            "id": student.id,
            "full_name": student.full_name,
            "total_points": student.total_points,
            "parent_name": student.parent.full_name if student.parent else None,
            "parent_telegram_id": student.parent.telegram_id if student.parent else None,
        }
    })


@csrf_exempt
@api_auth_required()
def me_view(request):
    payload = request.api_user
    role = payload.get("role")

    if role == "teacher":
        try:
            teacher = Teacher.objects.get(pk=payload["teacher_id"])
            return JsonResponse({
                "role": "teacher",
                "user": {
                    "id": teacher.id,
                    "full_name": teacher.full_name,
                    "subject": teacher.subject,
                    "username": payload.get("username"),
                }
            })
        except Teacher.DoesNotExist:
            return JsonResponse({"error": "Teacher profile not found"}, status=404)

    elif role == "student":
        try:
            student = Student.objects.get(pk=payload["student_id"])
            return JsonResponse({
                "role": "student",
                "user": {
                    "id": student.id,
                    "full_name": student.full_name,
                    "total_points": student.total_points,
                    "parent_name": student.parent.full_name if student.parent else None,
                }
            })
        except Student.DoesNotExist:
            return JsonResponse({"error": "Student profile not found"}, status=404)

    return JsonResponse({"error": "Unknown role"}, status=400)
