"""FastAPI — الراوتات + WebSocket"""

import asyncio
import json

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse

from ws_manager import io
from bot import run_bot, PW_OK


app = FastAPI(title="Login Bot v9")


@app.get("/", response_class=HTMLResponse)
async def home():
    with open("templates/index.html", "r", encoding="utf-8") as f:
        html = f.read()

    # حقن حالة Playwright
    pw_text = "Playwright: YES" if PW_OK else "Playwright: NO → HTTP mode"
    pw_color = "#22c55e" if PW_OK else "#f59e0b"
    html = html.replace("{{PW_TEXT}}", pw_text)
    html = html.replace("{{PW_COLOR}}", pw_color)

    return HTMLResponse(html)


@app.get("/status")
async def status():
    return {"ok": True, "playwright": PW_OK}


@app.websocket("/ws/{sid}")
async def ws_endpoint(websocket: WebSocket, sid: str):
    await io.connect(sid, websocket)
    try:
        while True:
            raw = await websocket.receive_text()
            try:
                data = json.loads(raw)
            except Exception:
                continue
            if data.get("action") == "start":
                asyncio.create_task(run_bot(sid, data))
    except WebSocketDisconnect:
        io.disconnect(sid)
    except Exception:
        io.disconnect(sid)