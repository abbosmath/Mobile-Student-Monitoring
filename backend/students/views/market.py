from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.db import transaction
from students.models import MarketItem, MarketOrder, Student
from attendance.models import Performance
from datetime import date


@login_required
def market_items_list(request):
    teacher = request.user.teacher
    items = MarketItem.objects.filter(teacher=teacher).order_by("-created_at")
    pending_orders_count = MarketOrder.objects.filter(item__teacher=teacher, status="pending").count()

    return render(request, "market/items_list.html", {
        "items": items,
        "pending_orders_count": pending_orders_count,
    })


@login_required
def market_item_create(request):
    teacher = request.user.teacher
    if request.method == "POST":
        title = request.POST.get("title", "").strip()
        item_type = request.POST.get("item_type", "product")
        points_cost = int(request.POST.get("points_cost", 0))
        quantity = int(request.POST.get("quantity", 1))
        discount_percent_raw = request.POST.get("discount_percent", "").strip()
        discount_percent = int(discount_percent_raw) if discount_percent_raw else None
        image_url = request.POST.get("image_url", "").strip() or None
        description = request.POST.get("description", "").strip()
        image = request.FILES.get("image")

        if not title or points_cost <= 0:
            messages.error(request, "Sarlavha va ball qiymati to'g'ri kiritilishi shart.")
        else:
            MarketItem.objects.create(
                teacher=teacher,
                title=title,
                item_type=item_type,
                points_cost=points_cost,
                quantity=quantity,
                discount_percent=discount_percent,
                image=image,
                image_url=image_url,
                description=description,
                is_active=True,
            )
            messages.success(request, f"'{title}' do'konga muvaffaqiyatli qo'shildi!")
            return redirect("market_items_list")

    return render(request, "market/item_form.html", {
        "title": "Yangi Mahsulot/Chegirma Qo'shish",
        "action": "create",
    })


@login_required
def market_item_edit(request, item_id):
    teacher = request.user.teacher
    item = get_object_or_404(MarketItem, id=item_id, teacher=teacher)

    if request.method == "POST":
        item.title = request.POST.get("title", "").strip()
        item.item_type = request.POST.get("item_type", "product")
        item.points_cost = int(request.POST.get("points_cost", item.points_cost))
        item.quantity = int(request.POST.get("quantity", item.quantity))
        discount_percent_raw = request.POST.get("discount_percent", "").strip()
        item.discount_percent = int(discount_percent_raw) if discount_percent_raw else None
        item.image_url = request.POST.get("image_url", "").strip() or None
        item.description = request.POST.get("description", "").strip()
        item.is_active = True if request.POST.get("is_active") == "on" else False

        if request.FILES.get("image"):
            item.image = request.FILES.get("image")

        item.save()
        messages.success(request, f"'{item.title}' ma'lumotlari yangilandi.")
        return redirect("market_items_list")

    return render(request, "market/item_form.html", {
        "title": f"{item.title} — Tahrirlash",
        "item": item,
        "action": "edit",
    })


@login_required
def market_item_delete(request, item_id):
    teacher = request.user.teacher
    item = get_object_or_404(MarketItem, id=item_id, teacher=teacher)
    if request.method == "POST":
        title = item.title
        item.delete()
        messages.success(request, f"'{title}' o'chirildi.")
    return redirect("market_items_list")


@login_required
def market_orders_list(request):
    teacher = request.user.teacher
    status_filter = request.GET.get("status", "all")

    orders = MarketOrder.objects.filter(item__teacher=teacher).select_related("student", "item")
    if status_filter != "all":
        orders = orders.filter(status=status_filter)

    pending_count = MarketOrder.objects.filter(item__teacher=teacher, status="pending").count()

    return render(request, "market/orders_list.html", {
        "orders": orders,
        "status_filter": status_filter,
        "pending_count": pending_count,
    })


@login_required
def market_order_update_status(request, order_id):
    teacher = request.user.teacher
    order = get_object_or_404(MarketOrder, id=order_id, item__teacher=teacher)

    if request.method == "POST":
        new_status = request.POST.get("status")
        if new_status in ["pending", "approved", "delivered", "cancelled"]:
            old_status = order.status
            if new_status == "cancelled" and old_status != "cancelled":
                # Refund points to student if cancelled
                with transaction.atomic():
                    student = Student.objects.select_for_update().get(pk=order.student.id)
                    student.total_points += order.points_spent
                    student.save()

                    # Re-stock item quantity
                    item = MarketItem.objects.select_for_update().get(pk=order.item.id)
                    item.quantity += 1
                    item.save()

                    order.status = "cancelled"
                    order.save()

                    Performance.objects.create(
                        student=student,
                        teacher=teacher,
                        points=order.points_spent,
                        comment=f"🛒 Bekor qilingan xarid uchun ball qaytarildi ({order.item.title})",
                        date=date.today(),
                    )
                messages.warning(request, f"Buyurtma bekor qilindi. {order.points_spent} ball {student.full_name} ga qaytarildi.")
            else:
                order.status = new_status
                order.save()
                messages.success(request, f"Buyurtma holati '{order.get_status_display()}' ga o'zgartirildi.")

    return redirect("market_orders_list")
