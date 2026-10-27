"""SmartTrack realtime event hub.

Two mechanisms share one contract:

* ``hub.publish(topic, action, **data)`` — in-process broadcast to every
  connected WebSocket client (instant push).
* ``fingerprint(db)`` — cheap DB-derived change token used by the Flutter
  client's polling fallback (so the UI still refreshes if the socket drops).

Topics currently published: ``documents``, ``travels``, ``users``,
``compliance``, ``requirements``, ``announcements``.
"""
from __future__ import annotations

import asyncio
import hashlib
import json
import logging
from datetime import datetime, timezone
from typing import Any, Dict, Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)


class RealtimeHub:
    """Fan-out queue set + monotonic sequence counter."""

    def __init__(self) -> None:
        self._queues: set[asyncio.Queue] = set()
        self._loop: Optional[asyncio.AbstractEventLoop] = None
        self._seq = 0
        self._last: Dict[str, Any] = {}

    # -- lifecycle ---------------------------------------------------------
    def bind_loop(self, loop: asyncio.AbstractEventLoop) -> None:
        self._loop = loop

    @property
    def seq(self) -> int:
        return self._seq

    @property
    def last_event(self) -> Dict[str, Any]:
        return dict(self._last)

    @property
    def connections(self) -> int:
        return len(self._queues)

    # -- pub/sub -----------------------------------------------------------
    def subscribe(self) -> asyncio.Queue:
        queue: asyncio.Queue = asyncio.Queue(maxsize=200)
        self._queues.add(queue)
        return queue

    def unsubscribe(self, queue: asyncio.Queue) -> None:
        self._queues.discard(queue)

    def publish(self, topic: str, action: str, **data: Any) -> None:
        """Broadcast an event. Safe to call from sync or async code."""
        self._seq += 1
        message = {
            "type": "event",
            "seq": self._seq,
            "topic": topic,
            "action": action,
            "ts": datetime.now(timezone.utc).isoformat(),
            **data,
        }
        self._last = message
        if not self._queues:
            return

        loop = self._loop
        if loop is None or loop.is_closed():
            return

        payload = json.dumps(message, default=str)

        def _fanout() -> None:
            for queue in list(self._queues):
                try:
                    queue.put_nowait(payload)
                except asyncio.QueueFull:  # slow client: drop, next event wins
                    pass

        try:
            if loop.is_running():
                loop.call_soon_threadsafe(_fanout)
            else:  # pragma: no cover - loop should always be running
                _fanout()
        except RuntimeError:  # pragma: no cover - loop shutting down
            logger.debug("realtime publish skipped (loop closed)")


hub = RealtimeHub()


_FINGERPRINT_SQL = text(
    """
    SELECT
      (SELECT count(*) FROM system_core.documents)                       AS documents,
      (SELECT coalesce(max(uploaded_at), TIMESTAMP 'epoch')
         FROM system_core.documents)                                     AS documents_ts,
      (SELECT coalesce(max(status), '')
         FROM system_core.documents)                                     AS documents_state,
      (SELECT count(*) FROM system_core.travels)                         AS travels,
      (SELECT coalesce(max(updated_at), TIMESTAMP 'epoch')
         FROM system_core.travels)                                       AS travels_ts,
      (SELECT count(*) FROM system_core.remark_history)                  AS remarks,
      (SELECT coalesce(max(created_at), TIMESTAMP 'epoch')
         FROM system_core.remark_history)                                AS remarks_ts,
      (SELECT count(*) FROM system_core.compliance_records)              AS compliance,
      (SELECT coalesce(max(updated_at), TIMESTAMP 'epoch')
         FROM system_core.compliance_records)                            AS compliance_ts,
      (SELECT count(*) FROM system_core.users)                           AS users,
      (SELECT coalesce(max(created_at), TIMESTAMP 'epoch')
         FROM system_core.users)                                         AS users_ts,
      (SELECT count(*) FROM system_core.users WHERE is_active)           AS users_active,
      (SELECT coalesce(max(created_at), TIMESTAMP 'epoch')
         FROM system_core.audit_logs)                                    AS audit_ts
    """
)


def fingerprint(db: Session) -> Dict[str, Any]:
    """Return a change token for the monitoring datasets.

    The Flutter polling fallback compares ``fingerprint`` between ticks and
    refreshes only when it actually changed.
    """
    try:
        row = db.execute(_FINGERPRINT_SQL).mappings().one()
        raw = json.dumps({k: str(v) for k, v in row.items()}, sort_keys=True)
        token = hashlib.sha256(raw.encode("utf-8")).hexdigest()[:16]
        return {"fingerprint": token, "seq": hub.seq}
    except Exception as exc:  # pragma: no cover - defensive
        logger.warning("realtime fingerprint failed: %s", exc)
        return {"fingerprint": f"seq-{hub.seq}", "seq": hub.seq}
