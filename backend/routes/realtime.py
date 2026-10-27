"""Realtime routes: WebSocket push + polling fingerprint.

* ``GET  /api/realtime/version`` — change token for the polling fallback.
* ``WS   /api/realtime/ws?token=<JWT>`` — instant push channel.

The Flutter client connects the WebSocket and falls back to polling
``/version`` whenever the socket is down, so monitoring screens stay live
even behind flaky networks.
"""
from __future__ import annotations

import asyncio
import logging

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session

from database import get_db
from realtime import fingerprint, hub
from security import AuthenticationManager, TokenData, _live_account_check, get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/realtime", tags=["realtime"])

# Send a keepalive ping if no event arrived for this many seconds.
_PING_INTERVAL = 25.0


@router.get("/version")
async def realtime_version(
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Cheap change token used by clients that cannot keep a socket open."""
    payload = fingerprint(db)
    return {
        **payload,
        "connections": hub.connections,
        "last_event": hub.last_event or None,
    }


@router.websocket("/ws")
async def realtime_ws(websocket: WebSocket, token: str = Query(default="")):
    """Push channel. Auth via ``?token=<access_token>`` (browsers cannot set
    an Authorization header on a WebSocket handshake)."""
    if not token:
        await websocket.close(code=1008, reason="missing token")
        return

    token_data = AuthenticationManager.decode_token(token)
    if token_data is None:
        await websocket.close(code=1008, reason="invalid token")
        return

    try:
        token_data = _live_account_check(token_data)
    except Exception:
        await websocket.close(code=1008, reason="account inactive")
        return

    await websocket.accept()
    queue = hub.subscribe()

    async def _watch_disconnect() -> None:
        """Drain client frames so Starlette notices a dropped connection."""
        try:
            while True:
                await websocket.receive_text()
        except Exception:
            return

    watcher = asyncio.create_task(_watch_disconnect())
    try:
        await websocket.send_json({
            "type": "hello",
            "seq": hub.seq,
            "role": token_data.role,
            "user_id": token_data.user_id,
            "ping_interval": _PING_INTERVAL,
        })
        while not watcher.done():
            try:
                message = await asyncio.wait_for(queue.get(), timeout=_PING_INTERVAL)
            except asyncio.TimeoutError:
                await websocket.send_json({"type": "ping", "seq": hub.seq})
                continue
            await websocket.send_text(message)
    except (WebSocketDisconnect, RuntimeError, asyncio.CancelledError):
        pass
    except Exception as exc:  # pragma: no cover - defensive
        logger.debug("realtime socket closed: %s", exc)
    finally:
        watcher.cancel()
        hub.unsubscribe(queue)
        try:
            await websocket.close()
        except Exception:
            pass
