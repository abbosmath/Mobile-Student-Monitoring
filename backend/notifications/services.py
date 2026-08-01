import os
from aiogram import Bot
from django.conf import settings


async def send_message(telegram_id: int, text: str):
    token = getattr(settings, "BOT_TOKEN", os.getenv("BOT_TOKEN", ""))
    bot = Bot(token=token)
    try:
        await bot.send_message(chat_id=telegram_id, text=text, parse_mode="HTML")
    finally:
        await bot.session.close()
