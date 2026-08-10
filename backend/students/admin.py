from django.contrib import admin
from .models import Group, Student, GroupMembership, Schedule, MarketItem, MarketOrder, Test, TestQuestion, TestOption, TestSubmission


@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ["name", "subject", "teacher", "student_count"]

@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ["full_name", "parent", "total_points"]

@admin.register(GroupMembership)
class GroupMembershipAdmin(admin.ModelAdmin):
    list_display = ["student", "group"]

@admin.register(Schedule)
class ScheduleAdmin(admin.ModelAdmin):
    list_display = ["group", "day_of_week", "start_time", "end_time"]

@admin.register(MarketItem)
class MarketItemAdmin(admin.ModelAdmin):
    list_display = ["title", "teacher", "item_type", "points_cost", "quantity", "discount_percent", "is_active"]
    list_filter = ["item_type", "is_active"]

@admin.register(MarketOrder)
class MarketOrderAdmin(admin.ModelAdmin):
    list_display = ["student", "item", "points_spent", "status", "created_at"]
    list_filter = ["status"]

@admin.register(Test)
class TestAdmin(admin.ModelAdmin):
    list_display = ["title", "group", "teacher", "deadline", "time_limit_minutes", "question_interval_seconds", "is_active", "question_count"]
    list_filter = ["group", "is_active"]

@admin.register(TestQuestion)
class TestQuestionAdmin(admin.ModelAdmin):
    list_display = ["test", "order", "question_text", "points"]

@admin.register(TestOption)
class TestOptionAdmin(admin.ModelAdmin):
    list_display = ["question", "option_text", "is_correct"]

@admin.register(TestSubmission)
class TestSubmissionAdmin(admin.ModelAdmin):
    list_display = ["student", "test", "score", "total_questions", "completed_at"]


