import json
from datetime import date
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db import transaction
from api.auth import api_auth_required
from students.models import (
    Student, Group, GroupMembership, MarketItem, MarketOrder,
    Test, TestQuestion, TestOption, TestSubmission
)
from attendance.models import Performance, Attendance
from students.services.stats import student_summary, get_period_range


@csrf_exempt
@api_auth_required(roles=["student"])
def student_dashboard_view(request):
    student_id = request.api_user["student_id"]
    student = Student.objects.filter(pk=student_id).select_related("parent").first()

    if not student:
        return JsonResponse({"error": "Student not found"}, status=404)

    memberships = GroupMembership.objects.filter(student=student).select_related("group", "group__teacher")
    groups_data = [{
        "id": m.group.id,
        "name": m.group.name,
        "subject": m.group.subject,
        "teacher_name": m.group.teacher.full_name,
    } for m in memberships]

    recent_submissions = TestSubmission.objects.filter(student=student).select_related("test")[:5]
    submissions_data = [{
        "test_id": s.test.id,
        "test_title": s.test.title,
        "score": s.score,
        "total_questions": s.total_questions,
        "completed_at": s.completed_at.strftime("%Y-%m-%d %H:%M"),
    } for s in recent_submissions]

    return JsonResponse({
        "student": {
            "id": student.id,
            "full_name": student.full_name,
            "total_points": student.total_points,
            "parent_name": student.parent.full_name if student.parent else None,
            "groups": groups_data,
            "recent_test_submissions": submissions_data,
        }
    })


@csrf_exempt
@api_auth_required(roles=["student"])
def student_tests_view(request):
    student_id = request.api_user["student_id"]
    student = Student.objects.filter(pk=student_id).first()

    if not student:
        return JsonResponse({"error": "Student not found"}, status=404)

    group_ids = GroupMembership.objects.filter(student=student).values_list("group_id", flat=True)
    tests = Test.objects.filter(group_id__in=group_ids, is_active=True).select_related("group").order_by("-created_at")

    submissions = TestSubmission.objects.filter(student=student, test__in=tests)
    sub_map = {s.test_id: s for s in submissions}

    data = []
    for t in tests:
        sub = sub_map.get(t.id)
        data.append({
            "id": t.id,
            "title": t.title,
            "group_name": t.group.name,
            "question_count": t.question_count(),
            "deadline": t.deadline.strftime("%Y-%m-%d %H:%M") if t.deadline else None,
            "time_limit_minutes": t.time_limit_minutes,
            "is_expired": t.is_expired(),
            "has_submitted": sub is not None,
            "submission": {
                "score": sub.score,
                "total_questions": sub.total_questions,
                "completed_at": sub.completed_at.strftime("%Y-%m-%d %H:%M"),
            } if sub else None,
        })

    return JsonResponse({"tests": data})


@csrf_exempt
@api_auth_required(roles=["student"])
def student_test_detail_view(request, test_id):
    student_id = request.api_user["student_id"]
    student = Student.objects.filter(pk=student_id).first()
    test = Test.objects.filter(pk=test_id, is_active=True).select_related("group").first()

    if not test:
        return JsonResponse({"error": "Test not found or inactive"}, status=404)

    # Check if student is member of test's group
    is_member = GroupMembership.objects.filter(group=test.group, student=student).exists()
    if not is_member:
        return JsonResponse({"error": "You are not enrolled in the group for this test"}, status=403)

    existing_sub = TestSubmission.objects.filter(student=student, test=test).first()
    if existing_sub:
        return JsonResponse({
            "message": "Test already completed",
            "has_submitted": True,
            "submission": {
                "score": existing_sub.score,
                "total_questions": existing_sub.total_questions,
                "completed_at": existing_sub.completed_at.strftime("%Y-%m-%d %H:%M"),
            }
        })

    if test.is_expired():
        return JsonResponse({"error": "This test has expired"}, status=400)

    questions = TestQuestion.objects.filter(test=test).prefetch_related("options")
    questions_data = []
    for q in questions:
        opts = [{
            "id": opt.id,
            "option_text": opt.option_text,
        } for opt in q.options.all()]
        questions_data.append({
            "id": q.id,
            "question_text": q.question_text,
            "image_url": q.get_image_display_url(),
            "points": q.points,
            "options": opts,
        })

    return JsonResponse({
        "test": {
            "id": test.id,
            "title": test.title,
            "group_name": test.group.name,
            "time_limit_minutes": test.time_limit_minutes,
            "deadline": test.deadline.strftime("%Y-%m-%d %H:%M") if test.deadline else None,
            "questions": questions_data,
        }
    })


@csrf_exempt
@api_auth_required(roles=["student"])
def student_test_submit_view(request, test_id):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    student_id = request.api_user["student_id"]
    student = Student.objects.filter(pk=student_id).first()
    test = Test.objects.filter(pk=test_id, is_active=True).select_related("group").first()

    if not test:
        return JsonResponse({"error": "Test not found"}, status=404)

    existing_sub = TestSubmission.objects.filter(student=student, test=test).first()
    if existing_sub:
        return JsonResponse({"error": "Test already submitted"}, status=400)

    try:
        body = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    answers = body.get("answers", {})  # dict of {question_id: selected_option_id}

    questions = list(TestQuestion.objects.filter(test=test).prefetch_related("options"))
    total_questions = len(questions)
    score = 0
    breakdown = []

    for q in questions:
        selected_opt_id = answers.get(str(q.id)) or answers.get(q.id)
        correct_opt = None
        selected_opt = None

        for opt in q.options.all():
            if opt.is_correct:
                correct_opt = opt
            if selected_opt_id and opt.id == int(selected_opt_id):
                selected_opt = opt

        is_correct = bool(selected_opt and selected_opt.is_correct)
        if is_correct:
            score += q.points

        breakdown.append({
            "question_id": q.id,
            "question_text": q.question_text,
            "selected_option": selected_opt.option_text if selected_opt else None,
            "correct_option": correct_opt.option_text if correct_opt else None,
            "is_correct": is_correct,
            "points_earned": q.points if is_correct else 0,
        })

    with transaction.atomic():
        student = Student.objects.select_for_update().get(pk=student_id)
        sub = TestSubmission.objects.create(
            student=student,
            test=test,
            score=score,
            total_questions=total_questions,
            max_possible_points=total_questions,
        )

        if score > 0:
            student.total_points += score
            student.save()

            Performance.objects.create(
                student=student,
                teacher=test.teacher,
                points=score,
                performance_type="exam",
                comment=f"📝 Test: {test.title} ({score}/{total_questions})",
                date=date.today()
            )

    return JsonResponse({
        "message": "Test submitted successfully!",
        "result": {
            "score": score,
            "total_questions": total_questions,
            "new_total_points": student.total_points,
            "breakdown": breakdown,
        }
    })


@csrf_exempt
@api_auth_required(roles=["student"])
def student_leaderboard_view(request):
    student_id = request.api_user["student_id"]
    student = Student.objects.filter(pk=student_id).first()
    if not student:
        return JsonResponse({"error": "Student not found"}, status=404)

    group_ids = GroupMembership.objects.filter(student=student).values_list("group_id", flat=True)
    groups = Group.objects.filter(id__in=group_ids)

    leaderboards = []
    for g in groups:
        memberships = GroupMembership.objects.filter(group=g).select_related("student").order_by("-student__total_points", "student__full_name")
        rankings = []
        for idx, m in enumerate(memberships, start=1):
            st = m.student
            rankings.append({
                "rank": idx,
                "student_id": st.id,
                "full_name": st.full_name,
                "total_points": st.total_points,
                "is_current_student": st.id == student_id,
            })

        leaderboards.append({
            "group_id": g.id,
            "group_name": g.name,
            "subject": g.subject,
            "rankings": rankings,
        })

    return JsonResponse({"leaderboards": leaderboards})


@csrf_exempt
@api_auth_required(roles=["student"])
def student_market_items_view(request):
    student_id = request.api_user["student_id"]
    student = Student.objects.filter(pk=student_id).first()

    items = MarketItem.objects.filter(is_active=True, quantity__gt=0).order_by("-created_at")
    data = [{
        "id": item.id,
        "title": item.title,
        "item_type": item.item_type,
        "points_cost": item.points_cost,
        "quantity": item.quantity,
        "discount_percent": item.discount_percent,
        "image_url": item.get_image_display_url(),
        "description": item.description,
        "can_afford": student.total_points >= item.points_cost if student else False,
    } for item in items]

    return JsonResponse({
        "student_points": student.total_points if student else 0,
        "items": data
    })


@csrf_exempt
@api_auth_required(roles=["student"])
def student_market_buy_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    student_id = request.api_user["student_id"]

    try:
        body = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    item_id = body.get("item_id")
    if not item_id:
        return JsonResponse({"error": "item_id is required"}, status=400)

    with transaction.atomic():
        student = Student.objects.select_for_update().filter(pk=student_id).first()
        item = MarketItem.objects.select_for_update().filter(pk=item_id, is_active=True).first()

        if not student or not item:
            return JsonResponse({"error": "Student or Item not found"}, status=404)

        if item.quantity <= 0:
            return JsonResponse({"error": f"Item '{item.title}' is out of stock"}, status=400)

        if student.total_points < item.points_cost:
            return JsonResponse({
                "error": f"Insufficient points! You have {student.total_points} ⭐, item costs {item.points_cost} ⭐"
            }, status=400)

        # Deduct points & reduce stock
        student.total_points -= item.points_cost
        student.save()

        item.quantity -= 1
        item.save()

        order = MarketOrder.objects.create(
            student=student,
            item=item,
            points_spent=item.points_cost,
            status="pending"
        )

        Performance.objects.create(
            student=student,
            teacher=item.teacher,
            points=-item.points_cost,
            performance_type="manual",
            comment=f"🛒 Market purchase: {item.title}",
            date=date.today()
        )

    return JsonResponse({
        "message": f"Successfully purchased '{item.title}'!",
        "new_total_points": student.total_points,
        "order": {
            "id": order.id,
            "item_title": item.title,
            "points_spent": item.points_cost,
            "status": order.status,
        }
    })


@csrf_exempt
@api_auth_required(roles=["student"])
def student_market_orders_view(request):
    student_id = request.api_user["student_id"]
    orders = MarketOrder.objects.filter(student_id=student_id).select_related("item").order_by("-created_at")

    data = [{
        "id": o.id,
        "item_title": o.item.title,
        "points_spent": o.points_spent,
        "status": o.status,
        "created_at": o.created_at.strftime("%Y-%m-%d %H:%M"),
    } for o in orders]

    return JsonResponse({"orders": data})


@csrf_exempt
@api_auth_required(roles=["student"])
def student_stats_view(request):
    student_id = request.api_user["student_id"]
    student = Student.objects.filter(pk=student_id).first()

    if not student:
        return JsonResponse({"error": "Student not found"}, status=404)

    stats_periods = {}
    for period, label in [("monthly", "Monthly"), ("weekly", "Weekly"), ("overall", "Overall")]:
        start, end = get_period_range(period)
        s = student_summary(student, start, end)
        stats_periods[period] = {
            "label": label,
            "points": s["points"],
            "present": s["present"],
            "absent": s["absent"],
        }

    return JsonResponse({
        "student_id": student.id,
        "full_name": student.full_name,
        "total_points": student.total_points,
        "periods": stats_periods,
    })
