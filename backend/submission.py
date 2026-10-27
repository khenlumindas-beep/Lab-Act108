"""Submission status helpers.

One place that decides how "has this faculty member submitted anything yet?"
is answered, so the API and the UI never disagree.

Status ladder (highest first):

* ``Complete``             — every required checklist item is verified
* ``Verified``             — documents exist and all uploaded ones are verified
* ``Partially Verified``   — at least one document verified, not all
* ``Submitted``            — files uploaded, none verified yet
* ``Not Yet Submitted``    — no files at all
"""
from __future__ import annotations

from typing import Optional

NOT_SUBMITTED = "Not Yet Submitted"
SUBMITTED = "Submitted"
PARTIALLY_VERIFIED = "Partially Verified"
VERIFIED = "Verified"
COMPLETE = "Complete"

ALL_STATUSES = (
    NOT_SUBMITTED,
    SUBMITTED,
    PARTIALLY_VERIFIED,
    VERIFIED,
    COMPLETE,
)


def status_from_counts(
    total_documents: int,
    verified_documents: int = 0,
    required_total: Optional[int] = None,
    required_verified: Optional[int] = None,
) -> str:
    """Derive the submission status from document counters.

    ``required_total`` / ``required_verified`` are only known where the
    checklist is evaluated (the requirements report); the travel list uses the
    document counters alone.
    """
    if not total_documents:
        return NOT_SUBMITTED

    if required_total:
        verified = required_verified or 0
        if verified >= required_total:
            return COMPLETE
        if verified > 0:
            return PARTIALLY_VERIFIED
        return SUBMITTED

    if verified_documents >= total_documents:
        return VERIFIED
    if verified_documents > 0:
        return PARTIALLY_VERIFIED
    return SUBMITTED
