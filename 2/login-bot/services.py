"""خدمات خارجية: Gemini AI + 2Captcha + HTML Parser"""

import asyncio
import json
import re
from html.parser import HTMLParser
from urllib.parse import urljoin

import httpx


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🔍 محلل HTML
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class FormParser(HTMLParser):
    """يحلل HTML ويستخرج الفورم وحقول الإدخال"""

    def __init__(self):
        super().__init__()
        self.forms = []
        self.inputs = []
        self.current_form = None

    def handle_starttag(self, tag, attrs):
        d = dict(attrs)

        if tag == "form":
            self.current_form = {
                "action": d.get("action", ""),
                "method": d.get("method", "POST").upper(),
                "inputs": [],
            }

        if tag == "input":
            inp = {
                "name": d.get("name", ""),
                "type": d.get("type", "text").lower(),
                "id": d.get("id", ""),
                "value": d.get("value", ""),
                "placeholder": d.get("placeholder", ""),
                "autocomplete": d.get("autocomplete", ""),
            }
            self.inputs.append(inp)
            if self.current_form:
                self.current_form["inputs"].append(inp)

    def handle_endtag(self, tag):
        if tag == "form" and self.current_form:
            self.forms.append(self.current_form)
            self.current_form = None

    def find_user_field(self):
        keywords = [
            "username", "email", "login", "user",
            "user_login", "log", "mail", "account",
            "userid", "signin-email",
        ]
        for inp in self.inputs:
            if inp["type"] in ("hidden", "password", "submit", "button", "checkbox"):
                continue
            name = inp["name"].lower()
            iid = inp["id"].lower()
            ph = inp["placeholder"].lower()
            ac = inp["autocomplete"].lower()

            for kw in keywords:
                if kw in name or kw in iid or kw in ph:
                    return inp
            if inp["type"] == "email":
                return inp
            if ac in ("username", "email"):
                return inp

        # fallback
        for inp in self.inputs:
            if inp["type"] in ("text", "email") and inp["name"]:
                return inp
        return None

    def find_pass_field(self):
        for inp in self.inputs:
            if inp["type"] == "password":
                return inp
        for inp in self.inputs:
            if "pass" in inp["name"].lower() or "pwd" in inp["name"].lower():
                return inp
        return None

    def get_login_form(self):
        for form in self.forms:
            for inp in form["inputs"]:
                if inp["type"] == "password":
                    return form
        return self.forms[0] if self.forms else None

    def get_hidden_fields(self):
        hidden = {}
        for inp in self.inputs:
            if inp["type"] == "hidden" and inp["name"]:
                hidden[inp["name"]] = inp["value"]
        return hidden


def extract_title(html: str) -> str:
    m = re.search(r"<title[^>]*>(.*?)</title>", html, re.IGNORECASE | re.DOTALL)
    return m.group(1).strip()[:100] if m else ""


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🤖 Gemini AI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async def gemini_analyze(api_key: str, html: str) -> dict | None:
    if not api_key:
        return None

    prompt = (
        "Analyze this login page HTML. Find the form field names.\n"
        "Return ONLY valid JSON:\n"
        '{"user_field":"name attr","pass_field":"name attr",'
        '"action":"form action url","method":"POST",'
        '"extra_fields":{"hidden_name":"value"}}\n\n'
    )
    prompt += html[:4000]

    url = (
        "https://generativelanguage.googleapis.com/v1beta"
        "/models/gemini-2.0-flash-lite:generateContent"
        "?key=" + api_key
    )

    try:
        async with httpx.AsyncClient(timeout=20) as c:
            r = await c.post(url, json={
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {
                    "temperature": 0.05,
                    "maxOutputTokens": 400,
                },
            })
            r.raise_for_status()
            txt = (
                r.json()
                .get("candidates", [{}])[0]
                .get("content", {})
                .get("parts", [{}])[0]
                .get("text", "")
            )
            a = txt.find("{")
            b = txt.rfind("}") + 1
            if a >= 0 and b > a:
                return json.loads(txt[a:b])
    except Exception:
        pass
    return None


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🔓 2Captcha
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async def solve_captcha_2captcha(
    api_key: str,
    sitekey: str,
    page_url: str,
    sid: str = "",
    logger=None,
) -> str | None:
    if not api_key:
        return None

    try:
        async with httpx.AsyncClient(timeout=20) as c:
            r = await c.post("http://2captcha.com/in.php", data={
                "key": api_key, "json": 1,
                "method": "userrecaptcha",
                "googlekey": sitekey,
                "pageurl": page_url,
            })
            j = r.json()
            if j.get("status") != 1:
                return None
            tid = j["request"]

            for sec in range(5, 130, 5):
                await asyncio.sleep(5)
                if logger and sid:
                    await logger.log(sid, f"⏳ كابتشا ({sec}ث)...")
                r2 = await c.get("http://2captcha.com/res.php", params={
                    "key": api_key, "action": "get",
                    "id": tid, "json": 1,
                })
                j2 = r2.json()
                if j2.get("status") == 1:
                    return j2["request"]
                if j2["request"] != "CAPCHA_NOT_READY":
                    return None
    except Exception:
        pass
    return None