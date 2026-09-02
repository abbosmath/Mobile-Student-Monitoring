import json
from datetime import date, datetime
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db import transaction
from api.auth import api_auth_required
from users.models import Teacher, Parent
from students.models import (
    Group, Schedule, Student, GroupMembership, Payment,
    MarketItem, MarketOrder, Test, TestQuestion, TestOption, TestSubmission
)
from attendance.models import Attendance, Performance


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_groups_view(request):
    teacher_id = request.api_user["teacher_id"]

    if request.method == "GET":
        groups = Group.objects.filter(teacher_id=teacher_id).order_by("-created_at")
        data = []
        for g in groups:
            data.append({
                "id": g.id,
                "name": g.name,
                "subject": g.subject,
                "student_count": g.student_count(),
                "created_at": g.created_at.strftime("%Y-%m-%d %H:%M:%S") if g.created_at else None,
            })
        return JsonResponse({"groups": data})

    elif request.method == "POST":
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)

        name = body.get("name", "").strip()
        subject = body.get("subject", "").strip()

        if not name:
            return JsonResponse({"error": "Group name is required"}, status=400)

        teacher = Teacher.objects.get(pk=teacher_id)
        group = Group.objects.create(name=name, subject=subject, teacher=teacher)

        # Handle schedules if provided
        schedules_data = body.get("schedules", [])
        for s in schedules_data:
            day_of_week = int(s.get("day_of_week", 0))
            start_time = s.get("start_time", "09:00")
            end_time = s.get("end_time", "10:30")
            Schedule.objects.create(group=group, day_of_week=day_of_week, start_time=start_time, end_time=end_time)

        return JsonResponse({
            "message": "Group created successfully",
            "group": {
                "id": group.id,
                "name": group.name,
                "subject": group.subject,
                "student_count": 0,
            }
        }, status=201)

    return JsonResponse({"error": "Method not allowed"}, status=405)


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_group_detail_view(request, group_id):
    teacher_id = request.api_user["teacher_id"]
    group = Group.objects.filter(pk=group_id, teacher_id=teacher_id).first()

    if not group:
        return JsonResponse({"error": "Group not found"}, status=404)

    if request.method == "GET":
        memberships = GroupMembership.objects.filter(group=group).select_related("student", "student__parent")
        students_data = []
        for m in memberships:
            st = m.student
            students_data.append({
                "id": st.id,
                "full_name": st.full_name,
                "total_points": st.total_points,
                "parent_name": st.parent.full_name if st.parent else None,
                "parent_telegram_id": st.parent.telegram_id if st.parent else None,
            })

        schedules = Schedule.objects.filter(group=group)
        schedules_data = [{
            "id": s.id,
            "day_of_week": s.day_of_week,
            "day_name": s.day_name(),
            "start_time": s.start_time.strftime("%H:%M"),
            "end_time": s.end_time.strftime("%H:%M"),
        } for s in schedules]

        return JsonResponse({
            "group": {
                "id": group.id,
                "name": group.name,
                "subject": group.subject,
                "student_count": group.student_count(),
                "students": students_data,
                "schedules": schedules_data,
            }
        })

    elif request.method in ["PUT", "PATCH"]:
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)

        if "name" in body:
            group.name = body["name"].strip()
        if "subject" in body:
            group.subject = body["subject"].strip()
        group.save()

        return JsonResponse({"message": "Group updated successfully"})

    elif request.method == "DELETE":
        group.delete()
        return JsonResponse({"message": "Group deleted successfully"})

    return JsonResponse({"error": "Method not allowed"}, status=405)


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_group_add_student_view(request, group_id):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    teacher_id = request.api_user["teacher_id"]
    group = Group.objects.filter(pk=group_id, teacher_id=teacher_id).first()
    if not group:
        return JsonResponse({"error": "Group not found"}, status=404)

    try:
        body = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    student_id = body.get("student_id")
    student = Student.objects.filter(pk=student_id).first()

    if not student:
        return JsonResponse({"error": "Student not found"}, status=404)

    m, created = GroupMembership.objects.get_or_create(group=group, student=student)
    if not created:
        return JsonResponse({"message": "Student is already in this group"})

    return JsonResponse({"message": f"{student.full_name} added to {group.name}"})


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_group_remove_student_view(request, group_id, student_id):
    if request.method != "DELETE":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    teacher_id = request.api_user["teacher_id"]
    group = Group.objects.filter(pk=group_id, teacher_id=teacher_id).first()
    if not group:
        return JsonResponse({"error": "Group not found"}, status=404)

    GroupMembership.objects.filter(group=group, student_id=student_id).delete()
    return JsonResponse({"message": "Student removed from group"})


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_students_view(request):
    if request.method == "GET":
        students = Student.objects.all().select_related("parent").order_by("-created_at")
        data = []
        for st in students:
            data.append({
                "id": st.id,
                "full_name": st.full_name,
                "total_points": st.total_points,
                "parent_name": st.parent.full_name if st.parent else None,
                "parent_telegram_id": st.parent.telegram_id if st.parent else None,
                "parent_phone": st.parent.phone if st.parent else None,
            })
        return JsonResponse({"students": data})

    elif request.method == "POST":
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)

        full_name = body.get("full_name", "").strip()
        parent_name = body.get("parent_name", "").strip()
        telegram_id = body.get("telegram_id")
        phone = body.get("phone", "").strip()

        if not full_name:
            return JsonResponse({"error": "Student full name is required"}, status=400)

        parent = None
        if telegram_id or parent_name:
            if telegram_id:
                try:
                    telegram_id = int(telegram_id)
                except ValueError:
                    telegram_id = None

            if telegram_id:
                parent, _ = Parent.objects.get_or_create(
                    telegram_id=telegram_id,
                    defaults={"full_name": parent_name or full_name, "phone": phone}
                )
            elif parent_name:
                parent = Parent.objects.create(full_name=parent_name, phone=phone)

        student = Student.objects.create(full_name=full_name, parent=parent)

        # Optionally add to group if provided
        group_id = body.get("group_id")
        if group_id:
            group = Group.objects.filter(pk=group_id).first()
            if group:
                GroupMembership.objects.create(group=group, student=student)

        return JsonResponse({
            "message": "Student created successfully",
            "student": {
                "id": student.id,
                "full_name": student.full_name,
                "total_points": student.total_points,
                "parent_name": parent.full_name if parent else None,
            }
        }, status=201)

    return JsonResponse({"error": "Method not allowed"}, status=405)


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_student_detail_view(request, student_id):
    student = Student.objects.filter(pk=student_id).select_related("parent").first()
    if not student:
        return JsonResponse({"error": "Student not found"}, status=404)

    if request.method == "GET":
        payments = Payment.objects.filter(student=student).order_by("-payment_date")
        payments_data = [{
            "id": p.id,
            "amount": float(p.amount),
            "payment_date": p.payment_date.strftime("%Y-%m-%d"),
            "next_payment_date": p.next_payment_date.strftime("%Y-%m-%d") if p.next_payment_date else None,
            "status_label": p.status_label(),
            "note": p.note,
        } for p in payments]

        performances = Performance.objects.filter(student=student).order_by("-created_at")[:20]
        performances_data = [{
            "id": perf.id,
            "points": perf.points,
            "performance_type": perf.performance_type,
            "comment": perf.comment,
            "date": perf.date.strftime("%Y-%m-%d") if perf.date else None,
        } for perf in performances]

        return JsonResponse({
            "student": {
                "id": student.id,
                "full_name": student.full_name,
                "total_points": student.total_points,
                "parent": {
                    "id": student.parent.id if student.parent else None,
                    "full_name": student.parent.full_name if student.parent else None,
                    "telegram_id": student.parent.telegram_id if student.parent else None,
                    "phone": student.parent.phone if student.parent else None,
                } if student.parent else None,
                "payments": payments_data,
                "recent_performance": performances_data,
            }
        })

    elif request.method in ["PUT", "PATCH"]:
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)

        if "full_name" in body:
            student.full_name = body["full_name"].strip()
        student.save()

        if student.parent and "parent_telegram_id" in body:
            try:
                student.parent.telegram_id = int(body["parent_telegram_id"]) if body["parent_telegram_id"] else None
                student.parent.save()
            except ValueError:
                pass

        return JsonResponse({"message": "Student updated successfully"})

    elif request.method == "DELETE":
        student.delete()
        return JsonResponse({"message": "Student deleted successfully"})

    return JsonResponse({"error": "Method not allowed"}, status=405)


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_student_points_view(request, student_id):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    student = Student.objects.filter(pk=student_id).first()
    if not student:
        return JsonResponse({"error": "Student not found"}, status=404)

    try:
        body = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    points = int(body.get("points", 0))
    comment = body.get("comment", "").strip()
    action = body.get("action", "give")  # give or deduct

    if action == "deduct" and points > 0:
        points = -points

    teacher_id = request.api_user["teacher_id"]
    teacher = Teacher.objects.filter(pk=teacher_id).first()

    with transaction.atomic():
        student.total_points += points
        if student.total_points < 0:
            student.total_points = 0
        student.save()

        Performance.objects.create(
            student=student,
            teacher=teacher,
            points=points,
            performance_type="manual",
            comment=comment or ("Points adjustment" if points >= 0 else "Points deduction"),
            date=date.today()
        )

    return JsonResponse({
        "message": f"Points updated. New total: {student.total_points}",
        "total_points": student.total_points
    })


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_student_payment_view(request, student_id):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    student = Student.objects.filter(pk=student_id).first()
    if not student:
        return JsonResponse({"error": "Student not found"}, status=404)

    try:
        body = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    amount = body.get("amount")
    payment_date_str = body.get("payment_date", date.today().strftime("%Y-%m-%d"))
    next_date_str = body.get("next_payment_date")
    note = body.get("note", "").strip()

    if not amount:
        return JsonResponse({"error": "Amount is required"}, status=400)

    p_date = datetime.strptime(payment_date_str, "%Y-%m-%d").date()
    n_date = datetime.strptime(next_date_str, "%Y-%m-%d").date() if next_date_str else None

    payment = Payment.objects.create(
        student=student,
        amount=amount,
        payment_date=p_date,
        next_payment_date=n_date,
        note=note,
    )

    return JsonResponse({
        "message": "Payment recorded successfully",
        "payment": {
            "id": payment.id,
            "amount": float(payment.amount),
            "payment_date": payment.payment_date.strftime("%Y-%m-%d"),
            "next_payment_date": payment.next_payment_date.strftime("%Y-%m-%d") if payment.next_payment_date else None,
            "status_label": payment.status_label(),
        }
    }, status=201)


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_take_attendance_view(request, group_id):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    teacher_id = request.api_user["teacher_id"]
    group = Group.objects.filter(pk=group_id, teacher_id=teacher_id).first()
    if not group:
        return JsonResponse({"error": "Group not found"}, status=404)

    try:
        body = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    att_date_str = body.get("date", date.today().strftime("%Y-%m-%d"))
    att_date = datetime.strptime(att_date_str, "%Y-%m-%d").date()
    records = body.get("records", [])  # list of {student_id, status: present/absent/late, points: int, comment: str}

    teacher = Teacher.objects.get(pk=teacher_id)

    with transaction.atomic():
        for r in records:
            st_id = r.get("student_id")
            st_status = r.get("status", "present")
            st_points = int(r.get("points", 0))
            st_comment = r.get("comment", "")

            student = Student.objects.filter(pk=st_id).first()
            if not student:
                continue

            # Update or create Attendance
            Attendance.objects.update_or_create(
                student=student,
                group=group,
                date=att_date,
                defaults={"status": st_status}
            )

            # Record Performance points if points != 0
            if st_points != 0:
                student.total_points += st_points
                if student.total_points < 0:
                    student.total_points = 0
                student.save()

                Performance.objects.create(
                    student=student,
                    teacher=teacher,
                    points=st_points,
                    performance_type="class",
                    comment=st_comment or f"Attendance points ({st_status})",
                    date=att_date
                )

    return JsonResponse({"message": f"Attendance recorded for {len(records)} students."})


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_market_items_view(request):
    teacher_id = request.api_user["teacher_id"]

    if request.method == "GET":
        items = MarketItem.objects.filter(teacher_id=teacher_id).order_by("-created_at")
        data = [{
            "id": item.id,
            "title": item.title,
            "item_type": item.item_type,
            "points_cost": item.points_cost,
            "quantity": item.quantity,
            "discount_percent": item.discount_percent,
            "image_url": item.get_image_display_url(),
            "description": item.description,
            "is_active": item.is_active,
        } for item in items]
        return JsonResponse({"items": data})

    elif request.method == "POST":
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)

        teacher = Teacher.objects.get(pk=teacher_id)
        item = MarketItem.objects.create(
            teacher=teacher,
            title=body.get("title", "").strip(),
            item_type=body.get("item_type", "product"),
            points_cost=int(body.get("points_cost", 0)),
            quantity=int(body.get("quantity", 1)),
            discount_percent=int(body.get("discount_percent")) if body.get("discount_percent") else None,
            image_url=body.get("image_url"),
            description=body.get("description", "").strip(),
            is_active=body.get("is_active", True)
        )

        return JsonResponse({"message": "Market item created", "id": item.id}, status=201)

    return JsonResponse({"error": "Method not allowed"}, status=405)


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_market_orders_view(request):
    teacher_id = request.api_user["teacher_id"]

    if request.method == "GET":
        orders = MarketOrder.objects.filter(item__teacher_id=teacher_id).select_related("student", "item").order_by("-created_at")
        data = [{
            "id": o.id,
            "student_name": o.student.full_name,
            "student_id": o.student.id,
            "item_title": o.item.title,
            "points_spent": o.points_spent,
            "status": o.status,
            "created_at": o.created_at.strftime("%Y-%m-%d %H:%M:%S") if o.created_at else None,
        } for o in orders]
        return JsonResponse({"orders": data})

    elif request.method == "PATCH":
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)

        order_id = body.get("order_id")
        new_status = body.get("status")
        order = MarketOrder.objects.filter(pk=order_id, item__teacher_id=teacher_id).first()

        if not order:
            return JsonResponse({"error": "Order not found"}, status=404)

        order.status = new_status
        order.save()
        return JsonResponse({"message": "Order status updated", "status": order.status})

    return JsonResponse({"error": "Method not allowed"}, status=405)


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_tests_view(request):
    teacher_id = request.api_user["teacher_id"]

    if request.method == "GET":
        tests = Test.objects.filter(teacher_id=teacher_id).select_related("group").order_by("-created_at")
        data = [{
            "id": t.id,
            "title": t.title,
            "group_name": t.group.name,
            "group_id": t.group.id,
            "question_count": t.question_count(),
            "deadline": t.deadline.strftime("%Y-%m-%d %H:%M:%S") if t.deadline else None,
            "time_limit_minutes": t.time_limit_minutes,
            "is_active": t.is_active,
        } for t in tests]
        return JsonResponse({"tests": data})

    elif request.method == "POST":
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON"}, status=400)

        group_id = body.get("group_id")
        title = body.get("title", "").strip()
        deadline_str = body.get("deadline")
        time_limit = int(body.get("time_limit_minutes", 0))

        teacher = Teacher.objects.get(pk=teacher_id)
        group = Group.objects.filter(pk=group_id, teacher=teacher).first()

        if not group:
            return JsonResponse({"error": "Group not found"}, status=404)

        deadline = datetime.strptime(deadline_str, "%Y-%m-%d %H:%M") if deadline_str else None

        with transaction.atomic():
            test = Test.objects.create(
                teacher=teacher,
                group=group,
                title=title,
                deadline=deadline,
                time_limit_minutes=time_limit,
                description=body.get("description", "").strip(),
            )

            questions_data = body.get("questions", [])
            for q_idx, q in enumerate(questions_data, start=1):
                question = TestQuestion.objects.create(
                    test=test,
                    question_text=q.get("question_text", "").strip(),
                    image_url=q.get("image_url"),
                    points=int(q.get("points", 1)),
                    order=q_idx
                )

                for opt in q.get("options", []):
                    TestOption.objects.create(
                        question=question,
                        option_text=opt.get("option_text", "").strip(),
                        is_correct=bool(opt.get("is_correct", False))
                    )

        return JsonResponse({"message": "Test created successfully", "test_id": test.id}, status=201)

    return JsonResponse({"error": "Method not allowed"}, status=405)


@csrf_exempt
@api_auth_required(roles=["teacher"])
def teacher_test_detail_view(request, test_id):
    teacher_id = request.api_user["teacher_id"]
    test = Test.objects.filter(pk=test_id, teacher_id=teacher_id).select_related("group").first()

    if not test:
        return JsonResponse({"error": "Test not found"}, status=404)

    if request.method == "GET":
        submissions = TestSubmission.objects.filter(test=test).select_related("student").order_by("-completed_at")
        submissions_data = [{
            "student_id": s.student.id,
            "student_name": s.student.full_name,
            "score": s.score,
            "total_questions": s.total_questions,
            "completed_at": s.completed_at.strftime("%Y-%m-%d %H:%M:%S") if s.completed_at else None,
        } for s in submissions]

        questions = TestQuestion.objects.filter(test=test).prefetch_related("options")
        questions_data = []
        for q in questions:
            opts = [{
                "id": opt.id,
                "option_text": opt.option_text,
                "is_correct": opt.is_correct
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
                "deadline": test.deadline.strftime("%Y-%m-%d %H:%M:%S") if test.deadline else None,
                "time_limit_minutes": test.time_limit_minutes,
                "questions": questions_data,
                "submissions": submissions_data,
            }
        })

    elif request.method == "DELETE":
        test.delete()
        return JsonResponse({"message": "Test deleted successfully"})

    return JsonResponse({"error": "Method not allowed"}, status=405)
