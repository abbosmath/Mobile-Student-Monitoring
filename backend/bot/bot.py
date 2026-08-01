"""
Standalone Telegram bot process.
Run with: python bot/bot.py
On Railway this runs as a separate process via ProcFile.txt.
"""
import asyncio
import sys
import os

from dotenv import load_dotenv

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

import django
django.setup()

from aiogram import Bot, Dispatcher
from aiogram.types import Message, CallbackQuery, InlineKeyboardMarkup, InlineKeyboardButton, FSInputFile, URLInputFile
from aiogram.filters import Command
from aiogram.fsm.storage.memory import MemoryStorage
from aiogram.types import ReplyKeyboardMarkup, KeyboardButton
from asgiref.sync import sync_to_async
from django.db import transaction
from datetime import date
from users.models import Parent
from students.models import MarketItem, MarketOrder, Student
from attendance.models import Performance
from students.services.stats import student_summary, get_period_range
from django.conf import settings
import os

load_dotenv()

BOT_TOKEN = os.getenv("BOT_TOKEN") or getattr(settings, "BOT_TOKEN", "")
if not BOT_TOKEN:
    raise ValueError("BOT_TOKEN is not set in environment variables or settings!")

bot = Bot(token=BOT_TOKEN)
dp = Dispatcher(storage=MemoryStorage())


@sync_to_async
def get_or_create_parent(telegram_id, full_name):
    return Parent.objects.get_or_create(
        telegram_id=telegram_id,
        defaults={"full_name": full_name},
    )


@sync_to_async
def get_parent_children(telegram_id):
    try:
        parent = Parent.objects.get(telegram_id=telegram_id)
        children = list(parent.children.all())
        return parent, children
    except Parent.DoesNotExist:
        return None, []


# -- Keyboard layout --
def get_main_keyboard():
    kb = [
        [KeyboardButton(text="🛒 Do'kon"), KeyboardButton(text="📊 Statistika")],
        [KeyboardButton(text="/mystudents")]
    ]
    return ReplyKeyboardMarkup(keyboard=kb, resize_keyboard=True)


@dp.message(Command("start"))
async def cmd_start(message: Message):
    telegram_id = message.from_user.id
    full_name = message.from_user.full_name

    parent, created = await get_or_create_parent(telegram_id, full_name)

    if created:
        text = (
            "✅ <b>Tizimga muvaffaqiyatli ulandingiz!</b>\n\n"
            "Endi farzandingizning darsga qatnashishi, baholari va market xaridlari haqida "
            "avtomatik xabarnomalar olasiz.\n\n"
            f"🪪 <b>Sizning Telegram ID:</b> <code>{telegram_id}</code>\n\n"
            "📌 Ushbu ID-ni o'qituvchiga bering — u sizni tizimda farzandingizga bog'laydi."
        )
    else:
        text = (
            f"👋 <b>Qaytganingizdan xursandmiz, {parent.full_name}!</b>\n\n"
            f"🪪 <b>Sizning Telegram ID:</b> <code>{telegram_id}</code>"
        )

    await message.answer(text, parse_mode="HTML", reply_markup=get_main_keyboard())


@dp.message(Command("id"))
async def cmd_id(message: Message):
    await message.answer(
        f"🪪 <b>Sizning Telegram ID:</b> <code>{message.from_user.id}</code>",
        parse_mode="HTML",
    )


@dp.message(Command("mystudents"))
async def cmd_mystudents(message: Message):
    parent, children = await get_parent_children(message.from_user.id)

    if parent is None:
        await message.answer(
            "❌ Siz tizimda ro'yxatdan o'tmagansiz.\n"
            "/start buyrug'ini yuboring.",
            parse_mode="HTML",
        )
        return

    if not children:
        await message.answer(
            "ℹ️ Hali farzand bog'lanmagan.\n"
            "O'qituvchingizga Telegram ID-ingizni bering.",
            parse_mode="HTML",
        )
        return

    lines = [f"👨‍👩‍👧 <b>Farzandlaringiz:</b>\n"]
    for child in children:
        lines.append(f"• <b>{child.full_name}</b> — {child.total_points} ball ⭐")

    await message.answer("\n".join(lines), parse_mode="HTML", reply_markup=get_main_keyboard())


@sync_to_async
def get_stats_for_parent(telegram_id):
    try:
        parent = Parent.objects.get(telegram_id=telegram_id)
        children = list(parent.children.all())
        if not children:
            return None, "ℹ️ Hali farzand bog'lanmagan."

        response_lines = ["📊 <b>STATISTIKA</b>\n"]
        for child in children:
            response_lines.append(f"🧑 <b>{child.full_name}</b>\n")

            for period, label in [("monthly", "Oylik"), ("weekly", "Haftalik"), ("overall", "Umumiy")]:
                start, end = get_period_range(period)
                stats = student_summary(child, start, end)

                score_emoji = "⭐" if stats["points"] >= 0 else "❌"
                response_lines.append(
                    f"🔹 <i>{label}</i>:\n"
                    f"   Ball: <b>{stats['points']} {score_emoji}</b>\n"
                    f"   Keldi: <b>{stats['present']}</b> marta\n"
                    f"   Kelmadi: <b>{stats['absent']}</b> marta\n"
                )

        return parent, "\n".join(response_lines)
    except Parent.DoesNotExist:
        return None, "❌ Siz tizimda ro'yxatdan o'tmagansiz.\n/start buyrug'ini yuboring."


@dp.message(Command("stats"))
@dp.message(lambda msg: msg.text == "📊 Statistika")
async def cmd_stats(message: Message):
    parent, text = await get_stats_for_parent(message.from_user.id)
    await message.answer(text, parse_mode="HTML", reply_markup=get_main_keyboard())


# -- MARKET / DO'KON FUNCTIONS --

@sync_to_async
def get_market_data_for_parent(telegram_id):
    try:
        parent = Parent.objects.get(telegram_id=telegram_id)
        children = list(parent.children.all())
        if not children:
            return None, [], [], "ℹ️ Hali farzand bog'lanmagan."
        items = list(MarketItem.objects.filter(is_active=True, quantity__gt=0).order_by("-created_at"))
        if not items:
            return parent, children, [], "🛒 Hozircha do'konda faol mahsulotlar yo'q."
        return parent, children, items, None
    except Parent.DoesNotExist:
        return None, [], [], "❌ Siz tizimda ro'yxatdan o'tmagansiz.\n/start buyrug'ini yuboring."


@sync_to_async
def process_market_purchase(telegram_id, item_id, child_id):
    try:
        parent = Parent.objects.get(telegram_id=telegram_id)
        student = parent.children.filter(id=child_id).first()
        if not student:
            return False, "❌ Farzand topilmadi."

        with transaction.atomic():
            student = Student.objects.select_for_update().get(pk=student.id)
            item = MarketItem.objects.select_for_update().get(pk=item_id)

            if not item.is_active or item.quantity <= 0:
                return False, f"❌ Kechirasiz, '{item.title}' tugab qoldi."

            if student.total_points < item.points_cost:
                return False, f"❌ Yetarli ball yo'q!\n\nFarzandingizda: <b>{student.total_points} ⭐</b>\nMahsulot narxi: <b>{item.points_cost} ⭐</b>"

            # Deduct points & reduce stock quantity
            student.total_points -= item.points_cost
            student.save()

            item.quantity -= 1
            item.save()

            # Create market order
            MarketOrder.objects.create(
                student=student,
                item=item,
                points_spent=item.points_cost,
                status="pending"
            )

            # Create Performance record (logs deduction in points history)
            Performance.objects.create(
                student=student,
                teacher=item.teacher,
                points=-item.points_cost,
                comment=f"🛒 Do'kon xaridi: {item.title}",
                date=date.today()
            )

            success_msg = (
                f"🎉 <b>MUVAFFAQIYATLI XARID!</b>\n\n"
                f"Farzandingiz <b>{student.full_name}</b> "
                f"\"{item.title}\" mahsulotini <b>{item.points_cost} ⭐</b> ga xarid qildi!\n\n"
                f"⭐ Qolgan ballari: <b>{student.total_points} ⭐</b>\n\n"
                f"📌 O'qituvchiga (saytda) bildirishnoma yuborildi. Topshirilgach o'qituvchi holatni o'zgartiradi."
            )
            return True, success_msg
    except Exception as e:
        return False, f"❌ Xatolik yuz berdi: {str(e)}"


def get_full_image_url(item):
    url = item.get_image_display_url()
    if not url:
        return None
    if url.startswith("http://") or url.startswith("https://"):
        return url
    domain = os.getenv("HOST_DOMAIN", "https://student-monitoring-production.up.railway.app")
    return f"{domain.rstrip('/')}{url}"


@dp.message(Command("market"))
@dp.message(lambda msg: msg.text == "🛒 Do'kon")
async def cmd_market(message: Message):
    parent, children, items, err = await get_market_data_for_parent(message.from_user.id)
    if err:
        await message.answer(err, parse_mode="HTML", reply_markup=get_main_keyboard())
        return

    summary_lines = ["🛒 <b>GAMIFICATION DO'KONI (MARKET)</b>\n"]
    for child in children:
        summary_lines.append(f"👤 <b>{child.full_name}</b>: {child.total_points} ⭐")
    summary_lines.append("\n🎁 <b>Mavjud Mahsulot va Chegirmalar:</b>")

    await message.answer("\n".join(summary_lines), parse_mode="HTML", reply_markup=get_main_keyboard())

    for item in items:
        icon = "🏷️" if item.item_type == "discount" else "📦"
        discount_info = f" ({item.discount_percent}% chegirma)" if item.discount_percent else ""
        desc = f"\n📝 <i>{item.description}</i>" if item.description else ""

        caption = (
            f"{icon} <b>{item.title}</b>{discount_info}\n"
            f"💰 Narxi: <b>{item.points_cost} ⭐</b> | Qoldiq: <b>{item.quantity} ta</b>{desc}"
        )

        inline_keyboard_rows = []
        for child in children:
            btn_text = f"🛒 Xarid qilish: {item.title} ({item.points_cost} ⭐)"
            if len(children) > 1:
                btn_text = f"🛒 {child.full_name}: {item.title} ({item.points_cost} ⭐)"
            inline_keyboard_rows.append([
                InlineKeyboardButton(
                    text=btn_text,
                    callback_data=f"buy_item:{item.id}:{child.id}"
                )
            ])

        reply_markup = InlineKeyboardMarkup(inline_keyboard=inline_keyboard_rows)

        photo = None
        if item.image:
            try:
                if os.path.exists(item.image.path):
                    photo = FSInputFile(item.image.path)
            except Exception:
                photo = None

        if not photo:
            image_url = get_full_image_url(item)
            if image_url:
                photo = URLInputFile(image_url) if image_url.startswith("http") else image_url

        if photo:
            try:
                await message.answer_photo(
                    photo=photo,
                    caption=caption,
                    parse_mode="HTML",
                    reply_markup=reply_markup
                )
            except Exception as e:
                print(f"[Bot image send error for {item.title}]: {e}")
                await message.answer(
                    text=caption,
                    parse_mode="HTML",
                    reply_markup=reply_markup
                )
        else:
            await message.answer(
                text=caption,
                parse_mode="HTML",
                reply_markup=reply_markup
            )



@dp.callback_query(lambda c: c.data and c.data.startswith("buy_item:"))
async def process_buy_callback(callback_query: CallbackQuery):
    parts = callback_query.data.split(":")
    item_id = int(parts[1])
    child_id = int(parts[2])

    success, msg = await process_market_purchase(callback_query.from_user.id, item_id, child_id)
    await callback_query.answer()
    await callback_query.message.answer(msg, parse_mode="HTML", reply_markup=get_main_keyboard())


@dp.message(Command("help"))
async def cmd_help(message: Message):
    await message.answer(
        "📚 <b>Mavjud buyruqlar:</b>\n\n"
        "/start — Tizimga ulanish\n"
        "/id — Telegram ID-ingizni ko'rish\n"
        "/mystudents — Farzandlaringizni ko'rish\n"
        "/stats — 📊 Statistika ko'rish\n"
        "/market — 🛒 Do'kon (Gamification)\n"
        "/help — Yordam",
        parse_mode="HTML",
    )


async def main():
    while True:
        try:
            print("🤖 Bot ishga tushdi...")
            await bot.delete_webhook(drop_pending_updates=True)
            await dp.start_polling(bot, allowed_updates=["message", "callback_query"])
        except Exception as e:
            print(f"Bot crashed: {e}")
            await asyncio.sleep(5)


if __name__ == "__main__":
    asyncio.run(main())

