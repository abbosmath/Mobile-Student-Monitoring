from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.utils import timezone
from datetime import datetime
from students.models import Group, Student, Test, TestQuestion, TestOption, TestSubmission, GroupMembership


@login_required
def tests_list(request):
    teacher = request.user.teacher
    group_id = request.GET.get("group_id")

    tests = Test.objects.filter(teacher=teacher).select_related("group")
    if group_id:
        tests = tests.filter(group_id=group_id)

    groups = Group.objects.filter(teacher=teacher)

    return render(request, "tests/list.html", {
        "tests": tests,
        "groups": groups,
        "selected_group_id": int(group_id) if group_id and group_id.isdigit() else None,
        "now": timezone.now(),
    })


@login_required
def test_create(request):
    teacher = request.user.teacher
    groups = Group.objects.filter(teacher=teacher)

    if not groups.exists():
        messages.warning(request, "Test yaratish uchun avval kamida bitta guruh yaratishingiz kerak.")
        return redirect("groups_list")

    if request.method == "POST":
        title = request.POST.get("title", "").strip()
        group_id = request.POST.get("group_id")
        description = request.POST.get("description", "").strip()
        deadline_str = request.POST.get("deadline", "").strip()
        time_limit_minutes = int(request.POST.get("time_limit_minutes", 0))
        question_interval_seconds = int(request.POST.get("question_interval_seconds", 0))

        group = get_object_or_404(Group, id=group_id, teacher=teacher)

        deadline = None
        if deadline_str:
            try:
                deadline = datetime.fromisoformat(deadline_str)
                if timezone.is_naive(deadline):
                    deadline = timezone.make_aware(deadline)
            except ValueError:
                deadline = None

        if not title:
            messages.error(request, "Test nomini kiriting.")
        else:
            test = Test.objects.create(
                teacher=teacher,
                group=group,
                title=title,
                description=description,
                deadline=deadline,
                time_limit_minutes=time_limit_minutes,
                question_interval_seconds=question_interval_seconds,
                is_active=True,
            )

            # Process questions & options from dynamic form
            question_texts = request.POST.getlist("question_text[]")
            for q_idx, q_text in enumerate(question_texts):
                q_text = q_text.strip()
                if not q_text:
                    continue

                question = TestQuestion.objects.create(
                    test=test,
                    question_text=q_text,
                    points=1,
                    order=q_idx + 1,
                )

                # Get options for this question index
                option_texts = request.POST.getlist(f"option_text_{q_idx}[]")
                correct_option_idx = request.POST.get(f"correct_option_{q_idx}")

                for opt_idx, opt_text in enumerate(option_texts):
                    opt_text = opt_text.strip()
                    if not opt_text:
                        continue
                    is_correct = (str(opt_idx) == str(correct_option_idx))
                    TestOption.objects.create(
                        question=question,
                        option_text=opt_text,
                        is_correct=is_correct,
                    )

            messages.success(request, f"'{test.title}' testi muvaffaqiyatli yaratildi! ({test.questions.count()} ta savol)")
            return redirect("test_detail", test_id=test.id)

    return render(request, "tests/form.html", {
        "groups": groups,
        "title": "Yangi Test Yaratish",
        "action": "create",
    })


@login_required
def test_detail(request, test_id):
    teacher = request.user.teacher
    test = get_object_or_404(Test, id=test_id, teacher=teacher)
    questions = test.questions.prefetch_related("options").all()

    # Calculate statistics
    total_students = GroupMembership.objects.filter(group=test.group).count()
    submissions_count = test.submissions.count()

    return render(request, "tests/detail.html", {
        "test": test,
        "questions": questions,
        "total_students": total_students,
        "submissions_count": submissions_count,
        "now": timezone.now(),
    })


@login_required
def test_results(request, test_id):
    teacher = request.user.teacher
    test = get_object_or_404(Test, id=test_id, teacher=teacher)

    submissions = test.submissions.select_related("student", "student__parent").order_by("-score", "-completed_at")
    submitted_student_ids = submissions.values_list("student_id", flat=True)

    # Students in the group who haven't solved the test yet
    unsubmitted_memberships = GroupMembership.objects.filter(
        group=test.group
    ).exclude(student_id__in=submitted_student_ids).select_related("student", "student__parent")

    return render(request, "tests/results.html", {
        "test": test,
        "submissions": submissions,
        "unsubmitted_memberships": unsubmitted_memberships,
    })


@login_required
def test_delete(request, test_id):
    teacher = request.user.teacher
    test = get_object_or_404(Test, id=test_id, teacher=teacher)
    if request.method == "POST":
        title = test.title
        test.delete()
        messages.success(request, f"'{title}' testi o'chirildi.")
    return redirect("tests_list")
