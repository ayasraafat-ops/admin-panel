"""إدارة اتصالات WebSocket"""

import json
from fastapi import WebSocket


class SocketManager:

    def __init__(self):
        self.pool: dict[str, WebSocket] = {}

    async def connect(self, sid: str, ws: WebSocket):
        await ws.accept()
        self.pool[sid] = ws

    def disconnect(self, sid: str):
        self.pool.pop(sid, None)

    async def emit(self, sid: str, event: str, data):
        ws = self.pool.get(sid)
        if not ws:
            return
        try:
            txt = json.dumps(
                {"event": event, "data": data},
                ensure_ascii=False,
            )
            await ws.send_text(txt)
        except Exception:
            pass

    async def log(self, sid: str, msg: str, level: str = "info"):
        await self.emit(sid, "log", {"msg": str(msg), "level": level})

    async def progress(self, sid: str, pct: int, label: str = ""):
        await self.emit(sid, "progress", {"pct": pct, "label": label})

    async def screenshot(self, sid: str, img_b64: str, label: str = ""):
        await self.emit(sid, "screenshot", {"img": img_b64, "label": label})

    async def done(self, sid: str, data: dict):
        await self.emit(sid, "done", data)


# مثيل واحد مشترك
io = SocketManager()