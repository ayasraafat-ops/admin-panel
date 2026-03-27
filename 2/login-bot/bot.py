"""محرك الأتمتة — HTTP + Playwright + لقطات الشاشة"""

import asyncio
import base64
import json
import random
import time
import traceback
from urllib.parse import urljoin, urlparse

import httpx

from ws_manager import io
from services import (
    FormParser,
    extract_title,
    gemini_analyze,
    solve_captcha_2captcha,
)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  فحص Playwright
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PW_OK = False
try:
    from playwright.async_api import async_playwright
    PW_OK = True
except ImportError:
    pass


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ثوابت
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/131.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "DNT": "1",
}

STEALTH_JS = """() => {
    Object.defineProperty(navigator,'webdriver',{get:()=>undefined});
    Object.defineProperty(navigator,'languages',{get:()=>['en-US','en']});
    Object.defineProperty(navigator,'plugins',{get:()=>[1,2,3,4,5]});
    window.chrome={runtime:{},loadTimes:()=>{},csi:()=>{}};
    const g=WebGLRenderingContext.prototype.getParameter;
    WebGLRenderingContext.prototype.getParameter=function(p){
        if(p===37445)return'Intel Inc.';
        if(p===37446)return'Intel Iris OpenGL Engine';
        return g.call(this,p)};
}"""

BLOCKED_TYPES = {"image", "stylesheet", "font", "media", "manifest"}
BLOCKED_HOSTS = [
    "google-analytics", "googletagmanager",
    "facebook.net", "doubleclick", "hotjar",
]

USER_SELS = [
    'input[name="username"]', 'input[name="email"]',
    'input[name="login"]', 'input[name="user"]',
    'input[name="user_login"]',
    'input[type="email"]', 'input[id="username"]',
    'input[id="email"]', 'input[id="login_field"]',
    'input[autocomplete="username"]',
    'input[autocomplete="email"]',
]

PASS_SELS = [
    'input[name="password"]', 'input[name="pass"]',
    'input[name="passwd"]',
    'input[type="password"]', 'input[id="password"]',
]

BTN_SELS = [
    'button[type="submit"]', 'input[type="submit"]',
    'button[name="login"]', 'button[id="login"]',
    '#login-button', '.login-btn', '.btn-login',
]


def FAIL(err: str) -> dict:
    return {
        "success": False, "status": "FAILED",
        "method": "", "elapsed": "-",
        "title": "", "url_after": "",
        "proxy": "-", "cookies_count": 0,
        "error": str(err),
    }


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📸 لقطة شاشة HTML (للوضع HTTP)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def html_to_preview_image(html_text: str, url: str) -> str:
    """
    ينشئ صورة SVG كمعاينة للصفحة في وضع HTTP
    """
    title = extract_title(html_text) or url

    # حساب بعض الإحصائيات
    form_count = html_text.lower().count("<form")
    input_count = html_text.lower().count("<input")
    link_count = html_text.lower().count("<a ")

    # إنشاء SVG كبديل عن لقطة الشاشة
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="800" height="400">
  <rect width="800" height="400" fill="#111827" rx="12"/>
  <rect x="0" y="0" width="800" height="50" fill="#1e293b" rx="12"/>
  <circle cx="25" cy="25" r="7" fill="#ef4444"/>
  <circle cx="50" cy="25" r="7" fill="#f59e0b"/>
  <circle cx="75" cy="25" r="7" fill="#22c55e"/>
  <text x="400" y="30" fill="#94a3b8" font-size="13"
        text-anchor="middle" font-family="monospace">{url[:70]}</text>
  <text x="400" y="100" fill="#f1f5f9" font-size="22"
        text-anchor="middle" font-family="sans-serif">{title[:50]}</text>
  <line x1="200" y1="120" x2="600" y2="120" stroke="#334155" stroke-width="1"/>
  <text x="400" y="170" fill="#6366f1" font-size="16"
        text-anchor="middle" font-family="sans-serif">HTTP Direct Mode</text>
  <rect x="250" y="200" width="300" height="35" rx="6" fill="#1e293b" stroke="#334155"/>
  <text x="265" y="222" fill="#64748b" font-size="12" font-family="sans-serif">Forms: {form_count}  |  Inputs: {input_count}  |  Links: {link_count}</text>
  <rect x="250" y="250" width="300" height="35" rx="6" fill="#1e293b" stroke="#334155"/>
  <text x="265" y="272" fill="#64748b" font-size="12" font-family="sans-serif">Size: {len(html_text):,} bytes</text>
  <text x="400" y="350" fill="#475569" font-size="11"
        text-anchor="middle" font-family="monospace">HTML Preview — No browser needed</text>
</svg>"""

    b64 = base64.b64encode(svg.encode()).decode()
    return f"data:image/svg+xml;base64,{b64}"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🌐 HTTP Login
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async def http_login(sid: str, url: str, user: str, pw: str, gkey: str = ""):
    """تسجيل دخول HTTP مباشر"""

    await io.log(sid, "🌐 وضع HTTP المباشر", "info")

    async with httpx.AsyncClient(
        headers=HEADERS,
        follow_redirects=True,
        timeout=25,
    ) as client:

        # 1. تحميل الصفحة
        await io.progress(sid, 20, "تحميل...")
        await io.log(sid, f"🌍 GET {url}")

        try:
            resp = await client.get(url)
        except httpx.ConnectError as e:
            await io.log(sid, f"❌ فشل الاتصال: {e}", "error")
            return FAIL(f"اتصال: {e}")
        except httpx.TimeoutException:
            await io.log(sid, "❌ انتهت المهلة!", "error")
            return FAIL("Timeout")
        except Exception as e:
            await io.log(sid, f"❌ {e}", "error")
            return FAIL(str(e))

        html = resp.text
        await io.log(sid, f"⚡ HTTP {resp.status_code} ({len(html):,} bytes)", "success")

        # 📸 لقطة شاشة
        preview = html_to_preview_image(html, url)
        await io.screenshot(sid, preview, "بعد تحميل الصفحة")
        await io.log(sid, "📸 لقطة شاشة: تحميل الصفحة", "info")

        if resp.status_code >= 400:
            return FAIL(f"HTTP {resp.status_code}")

        # 2. تحليل
        await io.progress(sid, 40, "تحليل...")
        parser = FormParser()
        try:
            parser.feed(html)
        except Exception:
            pass

        user_field = parser.find_user_field()
        pass_field = parser.find_pass_field()
        login_form = parser.get_login_form()
        hidden = parser.get_hidden_fields()

        await io.log(
            sid,
            f"📋 {len(parser.forms)} forms — {len(parser.inputs)} inputs — {len(hidden)} hidden",
        )

        # 3. Gemini
        gemini_data = None
        if gkey:
            await io.log(sid, "🤖 Gemini AI...", "ai")
            await io.progress(sid, 50, "Gemini...")
            gemini_data = await gemini_analyze(gkey, html)
            if gemini_data:
                await io.log(
                    sid,
                    f"🎯 {json.dumps(gemini_data, ensure_ascii=False)[:100]}",
                    "ai",
                )

        # 4. تحديد الحقول
        user_name = ""
        pass_name = ""

        if gemini_data:
            user_name = gemini_data.get("user_field", "")
            pass_name = gemini_data.get("pass_field", "")

        if not user_name and user_field:
            user_name = user_field["name"]
        if not pass_name and pass_field:
            pass_name = pass_field["name"]

        if not user_name:
            for g in ["username", "email", "login", "user", "log"]:
                for inp in parser.inputs:
                    if inp["name"].lower() == g:
                        user_name = inp["name"]
                        break
                if user_name:
                    break

        if not pass_name:
            for g in ["password", "pass", "passwd", "pwd"]:
                for inp in parser.inputs:
                    if inp["name"].lower() == g:
                        pass_name = inp["name"]
                        break
                if pass_name:
                    break

        if not user_name:
            await io.log(sid, "❌ حقل المستخدم غير موجود!", "error")
            names = [i["name"] for i in parser.inputs if i["name"]]
            await io.log(sid, f"الحقول: {names}", "warn")
            return FAIL("حقل المستخدم غير موجود")

        if not pass_name:
            await io.log(sid, "❌ حقل كلمة المرور غير موجود!", "error")
            return FAIL("حقل كلمة المرور غير موجود")

        await io.log(sid, f"✏️ مستخدم: {user_name}", "success")
        await io.log(sid, f"🔑 كلمة مرور: {pass_name}", "success")

        # 5. URL + Method
        action_url = url
        if gemini_data and gemini_data.get("action"):
            action_url = urljoin(url, gemini_data["action"])
        elif login_form and login_form["action"]:
            action_url = urljoin(url, login_form["action"])

        method = "POST"
        if gemini_data and gemini_data.get("method"):
            method = gemini_data["method"].upper()
        elif login_form:
            method = login_form["method"]

        await io.log(sid, f"📤 {method} → {action_url}")

        # 6. بناء البيانات
        form_data = {}
        form_data.update(hidden)
        if gemini_data and gemini_data.get("extra_fields"):
            form_data.update(gemini_data["extra_fields"])
        form_data[user_name] = user
        form_data[pass_name] = pw
        form_data = {k: v for k, v in form_data.items() if k}

        await io.log(sid, f"📦 حقول: {list(form_data.keys())}")
        if hidden:
            await io.log(sid, f"🔐 Hidden: {list(hidden.keys())}", "success")

        # 📸 لقطة ما قبل الإرسال
        await io.progress(sid, 70, "إرسال...")
        await io.log(sid, "📸 لقطة: قبل الإرسال", "info")

        # 7. إرسال
        await io.log(sid, "🚀 إرسال...")
        send_headers = {
            "Referer": url,
            "Origin": f"{urlparse(url).scheme}://{urlparse(url).netloc}",
            "Content-Type": "application/x-www-form-urlencoded",
        }

        try:
            if method == "POST":
                resp2 = await client.post(action_url, data=form_data, headers=send_headers)
            else:
                resp2 = await client.get(action_url, params=form_data, headers=send_headers)
        except Exception as e:
            await io.log(sid, f"❌ إرسال: {e}", "error")
            return FAIL(str(e))

        await io.progress(sid, 90, "تحليل الرد...")

        # 8. تحليل النتيجة
        final_url = str(resp2.url)
        resp_text = resp2.text[:3000].lower()
        all_cookies = dict(client.cookies)

        await io.log(sid, f"📥 HTTP {resp2.status_code}")
        await io.log(sid, f"🔗 {final_url}")
        await io.log(sid, f"🍪 {len(all_cookies)} كوكيز")

        # 📸 لقطة النتيجة
        preview2 = html_to_preview_image(resp2.text, final_url)
        await io.screenshot(sid, preview2, "بعد تسجيل الدخول")
        await io.log(sid, "📸 لقطة: بعد تسجيل الدخول", "info")

        # تحليل النجاح
        success_signs = [
            "dashboard", "welcome", "profile", "account",
            "home", "feed", "logout", "sign out", "my account",
            "لوحة", "مرحبا", "تسجيل خروج",
        ]
        fail_signs = [
            "invalid", "incorrect", "wrong", "error",
            "failed", "denied", "try again", "خطأ", "خاطئ",
        ]

        is_ok = False
        if final_url != url and "/login" not in final_url.lower():
            is_ok = True
        for s in success_signs:
            if s in resp_text or s in final_url.lower():
                is_ok = True
                break
        for s in fail_signs:
            if s in resp_text:
                is_ok = False
                break

        return {
            "success": is_ok,
            "status": "SUCCESS" if is_ok else "CHECK_RESULT",
            "method": "http" + ("+gemini" if gemini_data else ""),
            "elapsed": "",
            "title": extract_title(resp2.text),
            "url_after": final_url,
            "proxy": "direct",
            "cookies_count": len(all_cookies),
            "error": None if is_ok else "تحقق من النتيجة",
        }


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🎭 Playwright Login + Screenshots
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async def take_screenshot(page, sid: str, label: str):
    """التقاط لقطة شاشة حقيقية وإرسالها"""
    try:
        buf = await page.screenshot(full_page=False, type="jpeg", quality=60)
        b64 = "data:image/jpeg;base64," + base64.b64encode(buf).decode()
        await io.screenshot(sid, b64, label)
        await io.log(sid, f"📸 لقطة: {label}", "info")
    except Exception as e:
        await io.log(sid, f"⚠️ لقطة فشلت: {e}", "warn")


async def pw_login(sid: str, url: str, user: str, pw: str, gkey: str = ""):
    """تسجيل دخول بـ Playwright مع لقطات شاشة"""

    if not PW_OK:
        await io.log(sid, "❌ Playwright غير متاح", "error")
        return FAIL("Playwright غير مثبت")

    await io.log(sid, "🎭 وضع Playwright", "info")

    pw_inst = None
    browser = None

    try:
        pw_inst = await async_playwright().start()

        browser = await pw_inst.chromium.launch(
            headless=True,
            args=[
                "--no-sandbox", "--disable-setuid-sandbox",
                "--disable-dev-shm-usage", "--disable-gpu",
                "--no-first-run", "--mute-audio",
            ],
        )
        await io.log(sid, "✅ Chromium شغّال", "success")

        ctx = await browser.new_context(
            viewport={"width": 1280, "height": 720},
            user_agent=HEADERS["User-Agent"],
            locale="en-US",
            timezone_id="America/New_York",
            java_script_enabled=True,
            bypass_csp=True,
        )
        ctx.set_default_timeout(15000)
        ctx.set_default_navigation_timeout(30000)

        # حظر موارد
        async def blocker(route, req):
            try:
                if req.resource_type in BLOCKED_TYPES:
                    await route.abort()
                    return
                u = req.url.lower()
                for h in BLOCKED_HOSTS:
                    if h in u:
                        await route.abort()
                        return
                await route.continue_()
            except Exception:
                try:
                    await route.continue_()
                except Exception:
                    pass

        await ctx.route("**/*", blocker)

        page = await ctx.new_page()
        await page.add_init_script(STEALTH_JS)
        await io.log(sid, "🥷 Stealth مفعّل", "success")

        # ──── تحميل ────
        await io.progress(sid, 30, "تحميل...")
        await io.log(sid, f"🌍 {url}")
        resp = await page.goto(url, wait_until="domcontentloaded")
        await io.log(sid, f"⚡ HTTP {resp.status if resp else '?'}", "success")
        await page.wait_for_timeout(1500)

        # 📸 لقطة 1: بعد التحميل
        await take_screenshot(page, sid, "بعد تحميل الصفحة")

        # ──── Gemini ────
        gemini_sels = None
        if gkey:
            await io.log(sid, "🤖 Gemini AI...", "ai")
            await io.progress(sid, 45, "Gemini...")
            html = await page.content()
            gemini_sels = await gemini_analyze(gkey, html)
            if gemini_sels:
                await io.log(
                    sid,
                    f"🎯 {json.dumps(gemini_sels, ensure_ascii=False)[:80]}",
                    "ai",
                )

        # ──── ملء الحقول ────
        await io.progress(sid, 55, "ملء الحقول...")

        # مستخدم
        uf = False
        sels_to_try = USER_SELS[:]

        # إضافة selectors من Gemini
        if gemini_sels and gemini_sels.get("user_field"):
            gf = gemini_sels["user_field"]
            sels_to_try.insert(0, f'input[name="{gf}"]')

        for s in sels_to_try:
            try:
                el = await page.query_selector(s)
                if el and await el.bounding_box():
                    await el.click()
                    await el.fill("")
                    await el.type(user, delay=random.randint(30, 60))
                    await io.log(sid, f"✏️ مستخدم → {s}", "success")
                    uf = True
                    break
            except Exception:
                continue

        if not uf:
            await io.log(sid, "❌ حقل المستخدم غير موجود", "error")
            await take_screenshot(page, sid, "حقل المستخدم غير موجود")
            return FAIL("حقل المستخدم غير موجود")

        await page.wait_for_timeout(400)

        # كلمة مرور
        pf = False
        pass_to_try = PASS_SELS[:]
        if gemini_sels and gemini_sels.get("pass_field"):
            gf = gemini_sels["pass_field"]
            pass_to_try.insert(0, f'input[name="{gf}"]')

        for s in pass_to_try:
            try:
                el = await page.query_selector(s)
                if el and await el.bounding_box():
                    await el.click()
                    await el.fill("")
                    await el.type(pw, delay=random.randint(30, 60))
                    await io.log(sid, f"🔑 كلمة مرور → {s}", "success")
                    pf = True
                    break
            except Exception:
                continue

        if not pf:
            await io.log(sid, "❌ حقل كلمة المرور غير موجود", "error")
            await take_screenshot(page, sid, "حقل كلمة المرور غير موجود")
            return FAIL("حقل كلمة المرور غير موجود")

        # 📸 لقطة 2: بعد ملء الحقول
        await take_screenshot(page, sid, "بعد ملء الحقول")

        await page.wait_for_timeout(400)

        # ──── نقر ────
        await io.progress(sid, 75, "إرسال...")
        clicked = False
        for s in BTN_SELS:
            try:
                el = await page.query_selector(s)
                if el and await el.bounding_box():
                    await el.click()
                    await io.log(sid, f"🖱️ نقر → {s}", "success")
                    clicked = True
                    break
            except Exception:
                continue

        if not clicked:
            await page.keyboard.press("Enter")
            await io.log(sid, "⌨️ Enter")

        # انتظار
        try:
            await page.wait_for_load_state("networkidle", timeout=10000)
        except Exception:
            await page.wait_for_timeout(3000)

        # 📸 لقطة 3: بعد تسجيل الدخول
        await take_screenshot(page, sid, "بعد تسجيل الدخول")

        # نتيجة
        title = ""
        try:
            title = await page.title()
        except Exception:
            pass

        final = page.url
        cc = 0
        try:
            cc = len(await ctx.cookies())
        except Exception:
            pass

        return {
            "success": True,
            "status": "SUCCESS",
            "method": "playwright" + ("+gemini" if gemini_sels else ""),
            "elapsed": "",
            "title": title,
            "url_after": final,
            "proxy": "direct",
            "cookies_count": cc,
            "error": None,
        }

    except Exception as e:
        await io.log(sid, f"💥 {e}", "error")
        return FAIL(str(e))

    finally:
        if browser:
            try:
                await browser.close()
            except Exception:
                pass
        if pw_inst:
            try:
                await pw_inst.stop()
            except Exception:
                pass


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🚀 البوت الرئيسي
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async def run_bot(sid: str, data: dict):
    """نقطة الدخول الرئيسية"""

    url = data.get("url", "").strip()
    user = data.get("user", "").strip()
    pw_val = data.get("pw", "").strip()
    retries = int(data.get("retries", 3))
    gkey = data.get("gemini_key", "").strip()
    use_gemini = data.get("use_gemini", False) and bool(gkey)
    mode = data.get("mode", "auto")

    if not url or not user or not pw_val:
        await io.log(sid, "❌ حقول فارغة!", "error")
        await io.done(sid, FAIL("حقول فارغة"))
        return

    await io.log(sid, "🚀 بدء...")
    await io.log(sid, f"🔗 {url}")
    await io.log(sid, f"👤 {user}")
    await io.progress(sid, 5, "تجهيز...")

    for attempt in range(1, retries + 1):
        t0 = time.perf_counter()
        try:
            await io.log(sid, "")
            await io.log(sid, f"━━━ محاولة {attempt}/{retries} ━━━")
            await io.progress(sid, 10, f"محاولة {attempt}")

            result = None

            # اختيار الطريقة
            use_pw = (mode == "playwright") or (mode == "auto" and PW_OK)

            if use_pw and PW_OK:
                result = await pw_login(
                    sid, url, user, pw_val,
                    gkey if use_gemini else "",
                )
            else:
                if mode == "playwright" and not PW_OK:
                    await io.log(sid, "⚠️ Playwright غير متاح → HTTP", "warn")
                result = await http_login(
                    sid, url, user, pw_val,
                    gkey if use_gemini else "",
                )

            elapsed = time.perf_counter() - t0
            result["elapsed"] = f"{elapsed:.2f}s"

            if result.get("success"):
                await io.progress(sid, 100, "✅ تم!")
                await io.log(
                    sid,
                    f"🎉 نجح! [{result['method']}] "
                    f"{elapsed:.1f}ث — {result.get('cookies_count', 0)} كوكيز",
                    "success",
                )
                await io.done(sid, result)
                return
            else:
                await io.log(sid, f"⚠️ {result.get('error', 'فشل')}", "warn")

        except Exception as e:
            await io.log(sid, f"💥 {e}", "error")
            await io.log(sid, traceback.format_exc()[-200:], "error")

        if attempt < retries:
            await io.log(sid, "⏳ انتظار...")
            await asyncio.sleep(random.uniform(1, 2))

    await io.progress(sid, 100, "❌ فشل")
    await io.done(sid, FAIL(f"فشلت {retries} محاولات"))