from django.contrib import admin
from .models import Group, Student, GroupMembership, Schedule, MarketItem, MarketOrder


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

