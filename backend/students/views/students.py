import threading
import json
from decimal import Decimal
from datetime import date, timedelta

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.db import transaction
from django.db.models import Sum
from students.models import Student, GroupMembership, Group, Payment
from students.services.stats import student_summary, get_period_range
from users.models import Parent

def _send_linked_notification(telegram_id, student_name):
    try:
        import asyncio
        from notifications.services import send_message
        text = (
            f"✅ <b>Muvaffaqiyatli bog'landi!</b>\n\n"
            f"Siz <b>{student_name}</b> ning ota-onasi sifatida tizimga ulangansiz.\n\n"
            f"Endi quyidagi xabarnomalarni olasiz:\n"
            f"📋 Davomat — darsga qatnashganda\n"
            f"⭐ Ballar — o'qituvchi ball berganda\n\n"
            f"Farzandingiz muvaffaqiyatlarini kuzatib boring! 🎓"
        )
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        loop.run_until_complete(send_message(telegram_id, text))
        loop.close()
    except Exception as e:
        print(f"[Link notification error] {e}")


def _send_payment_notification(telegram_id, text):
    try:
        import asyncio
        from notifications.services import send_message
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        loop.run_until_complete(send_message(telegram_id, text))
        loop.close()
    except Exception as e:
        print(f"[Payment notification error] {e}")

@login_required
def students_list(request):
    teacher = request.user.teacher
    q = request.GET.get("q", "").strip()

    memberships = GroupMembership.objects.filter(
        group__teacher=teacher
    ).select_related("student__parent").order_by("student__full_name")

    if q:
        from django.db.models import Q
        memberships = memberships.filter(
            Q(student__full_name__icontains=q) |
            Q(student__parent__full_name__icontains=q) |
            Q(student__parent__phone__icontains=q)
        )

    seen = set()
    student_rows = []
    for m in memberships:
        if m.student.id not in seen:
            seen.add(m.student.id)
            latest_payment = Payment.objects.filter(student=m.student).order_by("-payment_date", "-created_at").first()
            if latest_payment:
                payment_status = latest_payment.status_label()
            else:
                payment_status = "No payment records"
            student_rows.append({
                "student": m.student,
                "latest_payment": latest_payment,
                "payment_status": payment_status,
            })
    return render(request, "students/list.html", {"students": student_rows, "q": q})



@login_required
def student_create(request):
    if request.method == "POST":
        full_name = request.POST.get("full_name")
        Student.objects.create(full_name=full_name, parent=None)
        return redirect("students_list")
    return render(request, "students/create.html")


@login_required
def student_detail(request, student_id):
    from attendance.models import Attendance, Performance
    student = get_object_or_404(Student, id=student_id)
    attendances = Attendance.objects.filter(student=student).order_by("-date")[:20]
    performances = Performance.objects.filter(student=student).order_by("-date")[:20]

    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    labels = []
    attendance_points = []
    classwork_points = []
    homework_points = []
    exam_points = []

    for i in range(3, -1, -1):
        start = week_start - timedelta(weeks=i)
        end = start + timedelta(days=6)
        if end > today:
            end = today

        labels.append(start.strftime("%d %b"))
        attendance_points.append(
            Attendance.objects.filter(
                student=student,
                status="present",
                date__gte=start,
                date__lte=end,
            ).count()
        )
        classwork_points.append(
            Performance.objects.filter(
                student=student,
                performance_type="classwork",
                date__gte=start,
                date__lte=end,
            ).aggregate(total=Sum("points"))["total"] or 0
        )
        homework_points.append(
            Performance.objects.filter(
                student=student,
                performance_type="homework",
                date__gte=start,
                date__lte=end,
            ).aggregate(total=Sum("points"))["total"] or 0
        )
        exam_points.append(
            Performance.objects.filter(
                student=student,
                performance_type="exam",
                date__gte=start,
                date__lte=end,
            ).aggregate(total=Sum("points"))["total"] or 0
        )

    chart_data = json.dumps({
        "labels": labels,
        "attendance": attendance_points,
        "classwork": classwork_points,
        "homework": homework_points,
        "exam": exam_points,
    })

    payments = Payment.objects.filter(student=student).select_related("group").order_by("-payment_date", "-created_at")[:20]
    latest_payment = payments[0] if payments else None
    payment_info = None
    payment_alert = None

    if latest_payment:
        next_due = latest_payment.next_payment_date
        days_until_due = latest_payment.days_until_due()
        payment_info = {
            "amount": latest_payment.amount,
            "payment_date": latest_payment.payment_date,
            "next_payment_date": latest_payment.next_payment_date,
            "status": latest_payment.status_label(),
            "group_name": latest_payment.group.name if latest_payment.group else "—",
            "note": latest_payment.note,
        }

        if next_due is not None and student.parent and student.parent.telegram_id:
            if days_until_due is not None and days_until_due < 0:
                payment_alert = (
                    f"To'lov muddati o'tib ketdi. Iltimos, {latest_payment.group.name if latest_payment.group else 'kurs'} uchun to'lovni zudlik bilan bajaring."
                )
                if not latest_payment.overdue_reminder_sent:
                    parent_text = (
                        f"⚠️ Hurmatli {student.parent.full_name.upper()},\n\n"
                        f"Farzandingiz <b>{student.full_name}</b> ning {latest_payment.group.name if latest_payment.group else 'kurs'} uchun to'lovi {latest_payment.next_payment_date} da muddatdan o'tgan.\n"
                        f"Iltimos, to'lovni darhol bajaring."
                    )
                    threading.Thread(
                        target=_send_payment_notification,
                        args=(student.parent.telegram_id, parent_text),
                        daemon=True,
                    ).start()
                    latest_payment.overdue_reminder_sent = True
                    latest_payment.save(update_fields=["overdue_reminder_sent"])
            elif days_until_due is not None and 0 <= days_until_due <= 3:
                payment_alert = (
                    f"To'lov muddati yaqinlashmoqda: {next_due}. Iltimos, tayyor bo'ling."
                )
                if not latest_payment.reminder_3_days_sent:
                    parent_text = (
                        f"🕒 Hurmatli {student.parent.full_name.upper()},\n\n"
                        f"Farzandingiz <b>{student.full_name}</b> ning {latest_payment.group.name if latest_payment.group else 'kurs'} uchun keyingi to'lovi {next_due} da bo'ladi.\n"
                        f"Qolgan kunlar: {days_until_due}."
                    )
                    threading.Thread(
                        target=_send_payment_notification,
                        args=(student.parent.telegram_id, parent_text),
                        daemon=True,
                    ).start()
                    latest_payment.reminder_3_days_sent = True
                    latest_payment.save(update_fields=["reminder_3_days_sent"])

    return render(request, "students/detail.html", {
        "student": student,
        "attendances": attendances,
        "performances": performances,
        "payments": payments,
        "payment_info": payment_info,
        "payment_alert": payment_alert,
        "weekly_stats": student_summary(student, *get_period_range("weekly")),
        "monthly_stats": student_summary(student, *get_period_range("monthly")),
        "overall_stats": student_summary(student, *get_period_range("overall")),
        "chart_data": chart_data,
    })


@login_required
def student_edit(request, student_id):
    student = get_object_or_404(Student, id=student_id)
    error = None

    if request.method == "POST":
        student.full_name = request.POST.get("full_name")
        student.save()

        if student.parent:
            student.parent.full_name = request.POST.get("parent_name", "")
            student.parent.phone = request.POST.get("parent_phone", "")

            telegram_id_raw = request.POST.get("telegram_id", "").strip()
            if telegram_id_raw:
                try:
                    telegram_id = int(telegram_id_raw)
                    conflict = Parent.objects.filter(
                        telegram_id=telegram_id
                    ).exclude(id=student.parent.id).first()
                    if conflict:
                        error = f"This Telegram ID is already linked to: {conflict.full_name}"
                    else:
                        student.parent.telegram_id = telegram_id
                except ValueError:
                    error = "Telegram ID must be a number only"

            if not error:
                # Notify parent that they are now linked
                threading.Thread(
                    target=_send_linked_notification,
                    args=(telegram_id, student.full_name),
                    daemon=True
                ).start()
                student.parent.save()
                return redirect("student_detail", student_id=student.id)
        else:
            return redirect("student_detail", student_id=student.id)

    return render(request, "students/edit.html", {"student": student, "error": error})

@login_required
def student_delete(request, student_id):
    student = get_object_or_404(Student, id=student_id)
    if request.method == "POST":
        student.delete()
        return redirect("students_list")
    return render(request, "students/confirm_delete.html", {"student": student})


@login_required
def give_points(request, student_id):
    from attendance.models import Performance
    student = get_object_or_404(Student, id=student_id)
    if request.method == "POST":
        points = int(request.POST.get("points", 0))
        comment = request.POST.get("comment", "")
        performance_type = request.POST.get("performance_type", "classwork")

        # Update total_points FIRST before creating Performance
        student.total_points += points
        student.save()

        # Create Performance after save so signal reads correct total
        Performance.objects.create(
            student=student,
            points=points,
            performance_type=performance_type,
            comment=comment,
            date=date.today(),
            teacher=request.user.teacher,
        )
        return redirect("student_detail", student_id=student.id)
    return render(request, "students/give_points.html", {"student": student})


@login_required
def add_payment(request, student_id):
    student = get_object_or_404(Student, id=student_id)
    groups = Group.objects.filter(memberships__student=student, teacher=request.user.teacher).distinct()
    error = None

    if request.method == "POST":
        group_id = request.POST.get("group_id")
        amount_str = request.POST.get("amount", "0").strip()
        payment_date_str = request.POST.get("payment_date", "").strip()
        next_payment_date_str = request.POST.get("next_payment_date", "").strip()
        note = request.POST.get("note", "").strip()

        try:
            amount = Decimal(amount_str)
        except Exception:
            amount = None

        try:
            payment_date = date.fromisoformat(payment_date_str) if payment_date_str else date.today()
        except ValueError:
            payment_date = None

        try:
            next_payment_date = date.fromisoformat(next_payment_date_str) if next_payment_date_str else None
        except ValueError:
            next_payment_date = None

        if not amount or amount <= 0:
            error = "To'lov miqdorini to'g'ri kiriting."
        elif not payment_date:
            error = "To'lov sanasini kiriting."
        else:
            group = None
            if group_id:
                group = Group.objects.filter(id=group_id, teacher=request.user.teacher).first()
                if not group:
                    error = "Tanlangan kurs topilmadi."

            if not error:
                Payment.objects.create(
                    student=student,
                    group=group,
                    amount=amount,
                    payment_date=payment_date,
                    next_payment_date=next_payment_date,
                    note=note,
                )

                if student.parent and student.parent.telegram_id:
                    teacher_name = request.user.teacher.full_name if hasattr(request.user, "teacher") else "O'qituvchi"
                    course_name = group.name if group else "kurs"
                    next_due_text = f"Keyingi to'lov: {next_payment_date}" if next_payment_date else "Keyingi to'lov sanasi belgilanmagan."
                    parent_text = (
                        f"✅ Hurmatli {student.parent.full_name.upper()},\n\n"
                        f"Farzandingiz <b>{student.full_name}</b> uchun {course_name} kursida to'lov qabul qilindi.\n"
                        f"To'langan summa: <b>{amount}</b> UZS\n"
                        f"To'lov sanasi: <b>{payment_date}</b>\n"
                        f"{next_due_text}\n\n"
                        f"Rahmat!"
                    )
                    threading.Thread(
                        target=_send_payment_notification,
                        args=(student.parent.telegram_id, parent_text),
                        daemon=True,
                    ).start()

                return redirect("student_detail", student_id=student.id)

    return render(request, "students/add_payment.html", {
        "student": student,
        "groups": groups,
        "error": error,
        "today": date.today(),
    })


@login_required
def deduct_points(request, student_id):
    """Subtract points from a student (clamped to 0). Telegram notification fires via signal."""
    from attendance.models import Performance
    student = get_object_or_404(Student, id=student_id)
    error = None
    if request.method == "POST":
        try:
            amount = int(request.POST.get("amount", 0))
        except (ValueError, TypeError):
            amount = 0
        comment = request.POST.get("comment", "").strip()
        if amount <= 0:
            error = "Ayiriladigan ball musbat son bo'lishi kerak."
        else:
            with transaction.atomic():
                # Re-fetch with row lock for concurrency safety
                student = Student.objects.select_for_update().get(pk=student_id)
                actual_deduction = min(amount, student.total_points)  # clamp to 0
                student.total_points -= actual_deduction
                student.save(update_fields=["total_points"])
                # Negative Performance record triggers existing signal → Telegram notification
                Performance.objects.create(
                    student=student,
                    points=-actual_deduction,
                    performance_type=request.POST.get("performance_type", "classwork"),
                    comment=comment,
                    date=date.today(),
                    teacher=request.user.teacher,
                )
            return redirect("student_detail", student_id=student.id)
    return render(request, "students/deduct_points.html", {"student": student, "error": error})
