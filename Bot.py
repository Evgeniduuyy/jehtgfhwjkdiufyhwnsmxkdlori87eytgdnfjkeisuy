
import asyncio
import json
import os
import random
from pathlib import Path

from telebot.async_telebot import AsyncTeleBot
import telebot.types as types

from telethon import TelegramClient, events
from telethon.tl.functions.messages import GetDiscussionMessageRequest
from telethon.errors import (
    SessionPasswordNeededError,
    PhoneCodeExpiredError,
    PhoneCodeInvalidError,
    FloodWaitError,
    PasswordHashInvalidError,
    AuthKeyUnregisteredError,
    UserDeactivatedBanError,
)

# ─── Константы ────────────────────────────────────────────────────────────────

BOT_TOKEN    = "8943670667:AAGN06tJeSJ0trMrwA9NnEmAK-eqrYo3PDE"
API_ID       = int(os.environ.get("TELETHON_API_ID",   "35989820"))
API_HASH     = os.environ.get("TELETHON_API_HASH", "18cec00c9bef93d0dd475baba4e6c3f4")
SESSION_FILE = "userbot.session"
CONFIG_FILE  = "bot_config.json"
OWNER_ID     = 853173723
CHANNELS_PER_PAGE = 40

# ─── Конфиг ───────────────────────────────────────────────────────────────────

def load_cfg():
    if Path(CONFIG_FILE).exists():
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        # Миграция старого формата: одиночная строка → список
        if "message" in data and "messages" not in data:
            data["messages"] = [data.pop("message")]
        elif "messages" not in data:
            data["messages"] = ["первый"]
        return data
    return {"messages": ["первый"], "all_channels": True, "target_channels": [], "is_running": False}


def get_random_message() -> str:
    msgs = cfg.get("messages", ["первый"])
    return random.choice(msgs) if msgs else "первый"

def save_cfg(cfg):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)

cfg = load_cfg()

# ─── Глобальное состояние ─────────────────────────────────────────────────────

bot          = AsyncTeleBot(BOT_TOKEN)
auth_state: dict    = {}
channel_cache: list = []
userbot: TelegramClient | None = None
_monitor_handler    = None
_monitor_chat: int | None = None

# ─── Утилиты ──────────────────────────────────────────────────────────────────

def esc(t: str) -> str:
    return str(t).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

async def is_authorized() -> bool:
    if userbot is None:
        return False
    try:
        if not userbot.is_connected():
            await userbot.connect()
        return await userbot.is_user_authorized()
    except Exception:
        return False

async def get_me_name() -> str:
    try:
        me = await userbot.get_me()
        return me.first_name + (f" @{me.username}" if me.username else "")
    except Exception:
        return "—"

async def fetch_channels() -> list:
    global channel_cache
    tmp = []
    try:
        async for dialog in userbot.iter_dialogs(limit=None):
            ent = dialog.entity
            if dialog.is_channel and getattr(ent, "broadcast", False):
                tmp.append({
                    "id":       ent.id,
                    "title":    dialog.title,
                    "username": getattr(ent, "username", None),
                })
    except Exception:
        pass
    channel_cache = tmp
    return channel_cache

async def status_text() -> str:
    auth  = await is_authorized()
    state = "🟢 Работает" if cfg["is_running"] else "🔴 Остановлен"
    acc   = esc(await get_me_name()) if auth else "не вошёл"
    ch    = "все каналы" if cfg["all_channels"] else f"{len(cfg['target_channels'])} канал(ов)"
    msgs  = cfg.get("messages", ["первый"])
    if len(msgs) == 1:
        msgs_line = f"<code>{esc(msgs[0])}</code>"
    else:
        previews = " / ".join(esc(m) for m in msgs[:5])
        suffix   = f" <i>+ещё {len(msgs)-5}</i>" if len(msgs) > 5 else ""
        msgs_line = f"<code>{previews}</code>{suffix} (рандом, {len(msgs)} вар.)"
    return (
        f"<b>First Comment Bot</b>\n\n"
        f"Статус: {state}\n"
        f"Аккаунт: {acc}\n"
        f"Каналы: {ch}\n"
        f"Сообщения: {msgs_line}"
    )

# ─── Клавиатуры ───────────────────────────────────────────────────────────────

def kb_main() -> types.InlineKeyboardMarkup:
    btn = "🔴 Остановить бота" if cfg["is_running"] else "🟢 Запустить бота"
    markup = types.InlineKeyboardMarkup()
    markup.add(types.InlineKeyboardButton(btn, callback_data="toggle_run"))
    markup.add(types.InlineKeyboardButton("📋 Выбрать каналы", callback_data="channels_0"))
    markup.add(types.InlineKeyboardButton("✏️ Изменить сообщение", callback_data="set_message"))
    markup.add(types.InlineKeyboardButton("👤 Аккаунт", callback_data="account"))
    return markup

def kb_channels(selected_ids: set, page: int = 0) -> types.InlineKeyboardMarkup:
    markup = types.InlineKeyboardMarkup()
    mark_all = "✅" if cfg["all_channels"] else "☑️"
    markup.add(types.InlineKeyboardButton(f"{mark_all} Все каналы сразу", callback_data="ch_all"))

    start = page * CHANNELS_PER_PAGE
    end   = start + CHANNELS_PER_PAGE
    page_channels = channel_cache[start:end]

    for ch in page_channels:
        m     = "✅" if (not cfg["all_channels"] and ch["id"] in selected_ids) else "☑️"
        uname = f" @{ch['username']}" if ch.get("username") else ""
        label = f"{m} {ch['title']}{uname}"[:60]
        markup.add(types.InlineKeyboardButton(label, callback_data=f"ch_{ch['id']}"))

    nav = []
    if page > 0:
        nav.append(types.InlineKeyboardButton("◀️ Назад", callback_data=f"channels_{page-1}"))
    if end < len(channel_cache):
        nav.append(types.InlineKeyboardButton("Вперёд ▶️", callback_data=f"channels_{page+1}"))
    if nav:
        markup.row(*nav)

    markup.add(types.InlineKeyboardButton("➕ Добавить канал вручную", callback_data="ch_add"))
    markup.add(types.InlineKeyboardButton("🔄 Обновить список", callback_data="ch_refresh"))
    markup.add(types.InlineKeyboardButton("✔️ Готово", callback_data="ch_done"))
    return markup

def kb_numpad(entered: str) -> types.InlineKeyboardMarkup:
    display = " ".join(entered) if entered else "—"
    markup = types.InlineKeyboardMarkup()
    markup.add(types.InlineKeyboardButton(f"🔢 Код: {display}", callback_data="noop"))
    markup.row(
        types.InlineKeyboardButton("1", callback_data="d1"),
        types.InlineKeyboardButton("2", callback_data="d2"),
        types.InlineKeyboardButton("3", callback_data="d3"),
    )
    markup.row(
        types.InlineKeyboardButton("4", callback_data="d4"),
        types.InlineKeyboardButton("5", callback_data="d5"),
        types.InlineKeyboardButton("6", callback_data="d6"),
    )
    markup.row(
        types.InlineKeyboardButton("7", callback_data="d7"),
        types.InlineKeyboardButton("8", callback_data="d8"),
        types.InlineKeyboardButton("9", callback_data="d9"),
    )
    markup.row(
        types.InlineKeyboardButton("⬅️ Удалить", callback_data="ddel"),
        types.InlineKeyboardButton("0", callback_data="d0"),
        types.InlineKeyboardButton("✅ Готово", callback_data="dok"),
    )
    return markup

def kb_account() -> types.InlineKeyboardMarkup:
    markup = types.InlineKeyboardMarkup()
    markup.add(types.InlineKeyboardButton("🚪 Выйти из аккаунта", callback_data="logout"))
    markup.add(types.InlineKeyboardButton("◀️ Назад", callback_data="main"))
    return markup

# ─── Мониторинг постов ────────────────────────────────────────────────────────

async def _post_handler(event):
    try:
        if not event.is_channel:
            return
        if not getattr(event.message, "post", False):
            return
        if event.message.reply_to is not None:
            return

        entity = await event.get_chat()
        if not getattr(entity, "broadcast", False):
            return
        if not cfg["is_running"]:
            return
        if not cfg["all_channels"]:
            if entity.id not in set(cfg["target_channels"]):
                return

        title   = getattr(entity, "title", str(entity.id))
        post_id = event.message.id

        try:
            disc      = await userbot(GetDiscussionMessageRequest(peer=entity, msg_id=post_id))
            disc_msg  = disc.messages[0]
            disc_peer = disc.chats[0] if disc.chats else None
            if disc_peer is None:
                if _monitor_chat:
                    await bot.send_message(_monitor_chat, f"⚠️ [{esc(title)}] — комментарии отключены")
                return
            chosen = get_random_message()
            await userbot.send_message(
                entity=disc_peer, message=chosen, reply_to=disc_msg.id
            )
            if _monitor_chat:
                await bot.send_message(
                    _monitor_chat,
                    f"✅ Написал «{esc(chosen)}» в <b>{esc(title)}</b>",
                    parse_mode="HTML"
                )
        except FloodWaitError as e:
            await asyncio.sleep(e.seconds)
        except Exception as e:
            err = str(e).lower()
            if _monitor_chat:
                if "discussion" in err or "megagroup" in err:
                    await bot.send_message(_monitor_chat, f"⚠️ [{esc(title)}] — нет группы обсуждений")
    except Exception:
        pass

async def start_monitor(chat_id: int):
    global _monitor_handler, _monitor_chat
    if not await is_authorized():
        return
    if _monitor_handler is not None:
        try:
            userbot.remove_event_handler(_monitor_handler)
        except Exception:
            pass
        _monitor_handler = None
    _monitor_chat = chat_id
    userbot.add_event_handler(_post_handler, events.NewMessage())
    _monitor_handler = _post_handler
    cfg["is_running"] = True
    save_cfg(cfg)

async def stop_monitor():
    global _monitor_handler
    if _monitor_handler is not None:
        try:
            userbot.remove_event_handler(_monitor_handler)
        except Exception:
            pass
        _monitor_handler = None
    cfg["is_running"] = False
    save_cfg(cfg)

# ─── Обнаружение потери сессии ────────────────────────────────────────────────

async def handle_session_lost():
    global _monitor_handler
    if _monitor_handler is not None:
        try:
            userbot.remove_event_handler(_monitor_handler)
        except Exception:
            pass
        _monitor_handler = None
    cfg["is_running"] = False
    save_cfg(cfg)
    Path(SESSION_FILE).unlink(missing_ok=True)
    try:
        await bot.send_message(
            OWNER_ID,
            "⚠️ Сессия аккаунта истекла или ты вышел.\n\nНажми /start чтобы войти заново."
        )
    except Exception:
        pass

# ─── Фоновые задачи ───────────────────────────────────────────────────────────

async def session_watcher():
    was_auth = await is_authorized()
    while True:
        await asyncio.sleep(10)
        try:
            if userbot is None:
                continue
            if not userbot.is_connected():
                try:
                    await userbot.connect()
                except Exception:
                    continue
            auth = await userbot.is_user_authorized()
            if was_auth and not auth:
                was_auth = False
                await handle_session_lost()
            elif auth:
                was_auth = True
        except (AuthKeyUnregisteredError, UserDeactivatedBanError):
            was_auth = False
            await handle_session_lost()
        except Exception:
            pass

async def channel_refresher():
    while True:
        await asyncio.sleep(300)
        try:
            if userbot and userbot.is_connected() and await userbot.is_user_authorized():
                await fetch_channels()
        except Exception:
            pass

# ─── /start ───────────────────────────────────────────────────────────────────

@bot.message_handler(commands=["start"])
async def cmd_start(message: types.Message):
    uid = message.from_user.id
    if uid != OWNER_ID:
        await bot.reply_to(message, "⛔ Нет доступа.")
        return
    if await is_authorized():
        if not channel_cache:
            await bot.reply_to(message, "⏳ Загружаю каналы…")
            await fetch_channels()
        await bot.send_message(
            message.chat.id,
            await status_text(),
            parse_mode="HTML",
            reply_markup=kb_main()
        )
    else:
        auth_state[uid] = {"step": "phone"}
        await bot.send_message(
            message.chat.id,
            "👋 Привет! Введи номер телефона аккаунта Telegram\n"
            "(например <code>+79001234567</code>):",
            parse_mode="HTML"
        )

# ─── Текстовые сообщения ──────────────────────────────────────────────────────

@bot.message_handler(func=lambda m: m.content_type == "text" and not m.text.startswith("/"))
async def on_text(message: types.Message):
    uid  = message.from_user.id
    if uid != OWNER_ID:
        return
    text = message.text.strip()
    step = auth_state.get(uid, {}).get("step")

    # ── добавить канал вручную ──
    if step == "add_channel":
        auth_state.pop(uid, None)
        raw = text.lstrip("@").replace("https://t.me/", "").replace("t.me/", "").strip()
        await bot.reply_to(message, "🔍 Ищу канал…")
        try:
            entity = await userbot.get_entity(raw)
            if not getattr(entity, "broadcast", False):
                await bot.send_message(
                    message.chat.id,
                    "❌ Это не канал. Введи @username канала (не группы)."
                )
                return
            ch_id, ch_title, ch_user = entity.id, entity.title, getattr(entity, "username", None)
            if not any(c["id"] == ch_id for c in channel_cache):
                channel_cache.append({"id": ch_id, "title": ch_title, "username": ch_user})
            cfg["all_channels"] = False
            sel = set(cfg["target_channels"])
            sel.add(ch_id)
            cfg["target_channels"] = list(sel)
            save_cfg(cfg)
            await bot.send_message(
                message.chat.id,
                f"✅ Канал <b>{esc(ch_title)}</b> добавлен!\n\nВыбери ещё или нажми «Готово»:",
                parse_mode="HTML",
                reply_markup=kb_channels(sel)
            )
        except Exception:
            await bot.send_message(
                message.chat.id,
                "❌ Канал не найден.\n"
                "Убедись что канал публичный и введи правильный @username или ссылку."
            )
        return

    # ── изменить текст комментария ──
    if step == "set_message":
        # Разбиваем по пробелам и переносам строк, убираем пустые
        words = [w.strip() for w in text.replace("\n", " ").split(" ") if w.strip()]
        if not words:
            words = [text.strip()]
        cfg["messages"] = words
        save_cfg(cfg)
        auth_state.pop(uid, None)
        if len(words) == 1:
            preview = f"<code>{esc(words[0])}</code>"
        else:
            preview = " / ".join(f"<code>{esc(w)}</code>" for w in words)
        await bot.send_message(
            message.chat.id,
            f"✅ Сохранено {len(words)} вар.: {preview}\n\n" + await status_text(),
            parse_mode="HTML",
            reply_markup=kb_main()
        )
        return

    # ── номер телефона ──
    if step == "phone":
        auth_state[uid]["phone"] = text
        await bot.reply_to(message, "📨 Отправляю код…")
        try:
            if not userbot.is_connected():
                await userbot.connect()
            sent = await userbot.send_code_request(text)
            auth_state[uid].update({"hash": sent.phone_code_hash, "step": "code", "entered": ""})
            await bot.send_message(
                message.chat.id,
                "📲 Код отправлен! Нажимай цифры:",
                reply_markup=kb_numpad("")
            )
        except Exception:
            await bot.send_message(
                message.chat.id,
                "❌ Не удалось отправить код. Проверь номер и введи снова:"
            )
        return

    # ── 2FA пароль ──
    if step == "2fa":
        try:
            await userbot.sign_in(password=text)
            auth_state.pop(uid, None)
            await bot.reply_to(message, "✅ Вошёл! Загружаю каналы…")
            await fetch_channels()
            await bot.send_message(
                message.chat.id,
                await status_text(),
                parse_mode="HTML",
                reply_markup=kb_main()
            )
        except PasswordHashInvalidError:
            await bot.reply_to(message, "❌ Неверный пароль. Попробуй ещё раз:")
        except FloodWaitError as e:
            await bot.reply_to(
                message,
                f"⏳ Слишком много попыток. Подожди {e.seconds} сек. и попробуй снова."
            )
        except Exception as e:
            await bot.reply_to(
                message,
                f"❌ Ошибка ({type(e).__name__}). Попробуй нажать /start и войти заново."
            )

# ─── Inline-кнопки ────────────────────────────────────────────────────────────

@bot.callback_query_handler(func=lambda call: True)
async def on_callback(call: types.CallbackQuery):
    uid  = call.from_user.id
    if uid != OWNER_ID:
        await bot.answer_callback_query(call.id, "⛔ Нет доступа.", show_alert=True)
        return

    await bot.answer_callback_query(call.id)
    data = call.data
    chat_id    = call.message.chat.id
    message_id = call.message.message_id

    # ── noop ──
    if data == "noop":
        return

    # ── цифровая клавиатура (код подтверждения) ──
    if data.startswith("d") and auth_state.get(uid, {}).get("step") == "code":
        entered = auth_state[uid].get("entered", "")
        if data == "ddel":
            entered = entered[:-1]
        elif data == "dok":
            if not entered:
                await bot.answer_callback_query(call.id, "Введи хотя бы одну цифру!", show_alert=True)
                return
            phone = auth_state[uid]["phone"]
            phash = auth_state[uid]["hash"]
            try:
                await userbot.sign_in(phone, entered, phone_code_hash=phash)
                auth_state.pop(uid, None)
                await bot.edit_message_text("✅ Вошёл! Загружаю каналы…", chat_id, message_id)
                await fetch_channels()
                await bot.send_message(
                    chat_id,
                    await status_text(),
                    parse_mode="HTML",
                    reply_markup=kb_main()
                )
            except SessionPasswordNeededError:
                auth_state[uid]["step"] = "2fa"
                await bot.edit_message_text(
                    "🔐 Нужен пароль двухфакторной аутентификации.\n\nВведи его сообщением:",
                    chat_id, message_id
                )
            except (PhoneCodeInvalidError, PhoneCodeExpiredError):
                auth_state[uid]["entered"] = ""
                await bot.edit_message_text(
                    "❌ Неверный или истёкший код. Попробуй снова:",
                    chat_id, message_id,
                    reply_markup=kb_numpad("")
                )
            except Exception:
                await bot.edit_message_text(
                    "❌ Ошибка входа. Нажми /start и попробуй снова.",
                    chat_id, message_id
                )
            return
        else:
            if len(entered) < 8:
                entered += data[1:]
        auth_state[uid]["entered"] = entered
        await bot.edit_message_reply_markup(chat_id, message_id, reply_markup=kb_numpad(entered))
        return

    # ── главное меню ──
    if data == "main":
        await bot.edit_message_text(
            await status_text(), chat_id, message_id,
            parse_mode="HTML", reply_markup=kb_main()
        )

    # ── запуск/остановка ──
    elif data == "toggle_run":
        if not await is_authorized():
            await bot.edit_message_text(
                "❌ Сначала войди в аккаунт — нажми /start", chat_id, message_id
            )
            return
        if cfg["is_running"]:
            await stop_monitor()
            await bot.edit_message_text(
                "🔴 Бот остановлен.", chat_id, message_id, reply_markup=kb_main()
            )
        else:
            await start_monitor(chat_id)
            ch = "все каналы" if cfg["all_channels"] else f"{len(cfg['target_channels'])} канал(ов)"
            await bot.edit_message_text(
                f"🟢 Бот запущен!\nСлежу за: {ch}\nВарианты: {len(cfg.get('messages', ['первый']))} шт. (рандом)",
                chat_id, message_id, reply_markup=kb_main()
            )

    # ── список каналов (с пагинацией) ──
    elif data.startswith("channels_"):
        if not await is_authorized():
            await bot.edit_message_text(
                "❌ Сначала войди в аккаунт — /start", chat_id, message_id
            )
            return
        page = int(data.split("_")[1])
        if not channel_cache:
            await bot.edit_message_text("⏳ Загружаю все каналы…", chat_id, message_id)
            await fetch_channels()
        total     = len(channel_cache)
        page_info = (
            f" (страница {page+1}/{max(1,(total-1)//CHANNELS_PER_PAGE+1)}, каналов: {total})"
            if total else ""
        )
        await bot.edit_message_text(
            f"📋 Выбери каналы{page_info}:\n✅ — выбран, ☑️ — не выбран",
            chat_id, message_id,
            reply_markup=kb_channels(set(cfg["target_channels"]), page)
        )

    # ── все каналы ──
    elif data == "ch_all":
        cfg["all_channels"] = True
        cfg["target_channels"] = []
        save_cfg(cfg)
        await bot.edit_message_reply_markup(chat_id, message_id, reply_markup=kb_channels(set()))

    # ── добавить вручную ──
    elif data == "ch_add":
        auth_state[uid] = {"step": "add_channel"}
        await bot.edit_message_text(
            "➕ Введи @username или ссылку канала:\n"
            "(например <code>@durov</code> или <code>https://t.me/durov</code>)",
            chat_id, message_id,
            parse_mode="HTML"
        )

    # ── обновить список ──
    elif data == "ch_refresh":
        await bot.edit_message_text("🔄 Обновляю список каналов…", chat_id, message_id)
        await fetch_channels()
        total = len(channel_cache)
        await bot.edit_message_text(
            f"📋 Загружено каналов: {total}. Выбери нужные:",
            chat_id, message_id,
            reply_markup=kb_channels(set(cfg["target_channels"]))
        )

    # ── выбор/снятие канала ──
    elif data.startswith("ch_") and data not in ("ch_all", "ch_done", "ch_add", "ch_refresh"):
        ch_id = int(data[3:])
        cfg["all_channels"] = False
        sel = set(cfg["target_channels"])
        sel.discard(ch_id) if ch_id in sel else sel.add(ch_id)
        cfg["target_channels"] = list(sel)
        save_cfg(cfg)
        await bot.edit_message_reply_markup(chat_id, message_id, reply_markup=kb_channels(sel))

    # ── готово ──
    elif data == "ch_done":
        if cfg["all_channels"]:
            info = "✅ Режим: все каналы"
        else:
            n    = len(cfg["target_channels"])
            info = f"✅ Выбрано {n} канал(ов)" if n else "⚠️ Ни одного канала не выбрано"
        await bot.edit_message_text(
            f"{info}\n\n" + await status_text(),
            chat_id, message_id,
            parse_mode="HTML",
            reply_markup=kb_main()
        )

    # ── изменить сообщение ──
    elif data == "set_message":
        auth_state[uid] = {"step": "set_message"}
        await bot.edit_message_text(
            f"✏️ Текущие варианты: <code>{esc(' '.join(cfg.get('messages', ['первый'])))}</code>\n\n"
            f"Напиши слова через пробел — бот будет отправлять рандомное:\n"
            f"<i>Пример: первый топ лучший огонь</i>",
            chat_id, message_id,
            parse_mode="HTML"
        )

    # ── аккаунт ──
    elif data == "account":
        if await is_authorized():
            name = esc(await get_me_name())
            await bot.edit_message_text(
                f"👤 Аккаунт: <b>{name}</b>",
                chat_id, message_id,
                parse_mode="HTML",
                reply_markup=kb_account()
            )
        else:
            await bot.edit_message_text(
                "❌ Аккаунт не подключён. Нажми /start", chat_id, message_id
            )

    # ── выход ──
    elif data == "logout":
        try:
            await userbot.log_out()
        except Exception:
            pass
        await stop_monitor()
        Path(SESSION_FILE).unlink(missing_ok=True)
        await bot.edit_message_text(
            "🚪 Вышел из аккаунта.\n\nНажми /start чтобы войти снова.",
            chat_id, message_id
        )

# ─── Main ─────────────────────────────────────────────────────────────────────

async def main():
    global userbot

    userbot = TelegramClient(SESSION_FILE, API_ID, API_HASH)
    await userbot.connect()

    if await userbot.is_user_authorized():
        await fetch_channels()
        cfg["is_running"] = False
        save_cfg(cfg)

    print("🤖 Бот запущен. Открой его в Telegram и нажми /start")

    asyncio.create_task(session_watcher())
    asyncio.create_task(channel_refresher())

    await bot.polling(non_stop=True, request_timeout=30)

if __name__ == "__main__":
    asyncio.run(main())

