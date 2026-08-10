from django.db import models
from datetime import date
from users.models import Parent, Teacher


class Group(models.Model):
    name = models.CharField(max_length=255)
    teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, related_name="groups")
    subject = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    def student_count(self):
        return self.memberships.count()


class Schedule(models.Model):
    DAYS = [
        (0, "Monday"), (1, "Tuesday"), (2, "Wednesday"),
        (3, "Thursday"), (4, "Friday"), (5, "Saturday"), (6, "Sunday"),
    ]
    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="schedules")
    day_of_week = models.IntegerField(choices=DAYS)
    start_time = models.TimeField()
    end_time = models.TimeField()

    def day_name(self):
        return dict(self.DAYS).get(self.day_of_week, "")

    def __str__(self):
        return f"{self.group.name} - {self.day_name()} {self.start_time}-{self.end_time}"


class Student(models.Model):
    full_name = models.CharField(max_length=255)
    parent = models.ForeignKey(Parent, on_delete=models.SET_NULL, null=True, blank=True, related_name="children")
    total_points = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.full_name


class GroupMembership(models.Model):
    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="memberships")
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="memberships")
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("group", "student")

    def __str__(self):
        return f"{self.student.full_name} in {self.group.name}"


class Payment(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="payments")
    group = models.ForeignKey(Group, on_delete=models.SET_NULL, null=True, blank=True, related_name="payments")
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_date = models.DateField()
    next_payment_date = models.DateField(null=True, blank=True)
    note = models.TextField(blank=True)
    reminder_3_days_sent = models.BooleanField(default=False)
    overdue_reminder_sent = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.student.full_name} payment {self.amount} on {self.payment_date}"

    def days_until_due(self):
        if not self.next_payment_date:
            return None
        return (self.next_payment_date - date.today()).days

    def status_label(self):
        if not self.next_payment_date:
            return "Next payment date not set"
        days = self.days_until_due()
        if days is None:
            return "Next payment date not set"
        if days < 0:
            return f"Overdue by {-days} days"
        if days == 0:
            return "Due today"
        if days <= 3:
            return f"Due in {days} days"
        return f"Next due in {days} days"


class MarketItem(models.Model):
    ITEM_TYPES = [
        ("product", "Mahsulot (Product)"),
        ("discount", "Kurs uchun chegirma (Course Discount)"),
    ]
    teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, related_name="market_items")
    title = models.CharField(max_length=255)
    item_type = models.CharField(max_length=20, choices=ITEM_TYPES, default="product")
    points_cost = models.PositiveIntegerField()
    quantity = models.PositiveIntegerField(default=1)
    discount_percent = models.PositiveIntegerField(null=True, blank=True, help_text="Percentage discount for courses (e.g. 10)")
    image = models.ImageField(upload_to="market/", null=True, blank=True)
    image_url = models.URLField(max_length=500, blank=True, null=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} ({self.points_cost} pts)"

    def get_image_display_url(self):
        if self.image:
            return self.image.url
        if self.image_url:
            return self.image_url
        return None


class MarketOrder(models.Model):
    STATUS_CHOICES = [
        ("pending", "Kutilmoqda"),
        ("approved", "Tasdiqlandi"),
        ("delivered", "Topshirildi"),
        ("cancelled", "Bekor qilindi"),
    ]
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="market_orders")
    item = models.ForeignKey(MarketItem, on_delete=models.CASCADE, related_name="orders")
    points_spent = models.PositiveIntegerField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.student.full_name} -> {self.item.title} ({self.status})"


class Test(models.Model):
    teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, related_name="tests")
    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name="tests")
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    deadline = models.DateTimeField(null=True, blank=True)
    time_limit_minutes = models.PositiveIntegerField(default=0, help_text="Test davomiyligi (daqiqalarda), 0 = cheklovsiz")
    question_interval_seconds = models.PositiveIntegerField(default=0, help_text="Savollar orasidagi interval vaqti (sekundlarda), 0 = cheklovsiz")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} ({self.group.name})"

    def question_count(self):
        return self.questions.count()

    def is_expired(self):
        if not self.deadline:
            return False
        from django.utils import timezone
        return timezone.now() > self.deadline


class TestQuestion(models.Model):
    test = models.ForeignKey(Test, on_delete=models.CASCADE, related_name="questions")
    question_text = models.TextField()
    points = models.PositiveIntegerField(default=1, help_text="Har bir to'g'ri javob uchun beriladigan ball")
    order = models.PositiveIntegerField(default=1)

    class Meta:
        ordering = ["order", "id"]

    def __str__(self):
        return f"Q{self.order}: {self.question_text[:30]}"


class TestOption(models.Model):
    question = models.ForeignKey(TestQuestion, on_delete=models.CASCADE, related_name="options")
    option_text = models.CharField(max_length=255)
    is_correct = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.option_text} ({'✓' if self.is_correct else '✗'})"


class TestSubmission(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="test_submissions")
    test = models.ForeignKey(Test, on_delete=models.CASCADE, related_name="submissions")
    score = models.PositiveIntegerField(default=0)
    total_questions = models.PositiveIntegerField(default=0)
    max_possible_points = models.PositiveIntegerField(default=0)
    completed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-completed_at"]
        unique_together = ("student", "test")

    def __str__(self):
        return f"{self.student.full_name} -> {self.test.title}: {self.score}/{self.total_questions}"


