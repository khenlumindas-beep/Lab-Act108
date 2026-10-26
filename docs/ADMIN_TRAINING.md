# SmartTrack — Administrator Training Guide (Phase 10)

Audience: OIGE administrators and super-admins. Covers every admin screen in the
Flutter web app. Faculty-facing workflows are in FACULTY_ORIENTATION.md.

## 1. Logging in

1. Open the site (root URL → Flutter app, or `flutter-web/index.html`).
2. Enter your admin email and password → **Sign In**.
3. Your name appears in the top bar. Use the avatar menu to open **Profile**
   or **Logout**.

> Passwords are seeded per install. Change them on first login
> (Profile → Change password: current + new + confirm).

## 2. Navigation

Left rail: **Dashboard · Travels · Documents · Plans · More**.
Everything else is under **More** (grid of tiles):

| Tile | What it is for |
|------|----------------|
| Verification | Approve/reject submitted travel requests; per-document verify/reject; **AI Check** |
| Compliance | BR-07 compliance records (score, required vs verified docs, pre/post/re-entry flags) |
| Lifecycle | Post-travel requirements & re-entry activity monitoring |
| Audit Log | Who did what, when (status changes, verifications, logins…) |
| Remarks | Full remark history across travels (add/edit/delete per policy) |
| Students | User directory (students/faculty); create, edit, reset roles |
| Reports | Aggregated statistics and charts (by year, type, country, college) |
| Doc Types | Configure required document types & categories |
| SIAP | Institutional mobility plan records |
| Plans | Yearly mobility plans |
| AI Analysis | AI document insights + **Compliance Insights** (priority recommendations) |
| Settings | Colleges/departments and system configuration |
| Announcements | Post campus-wide announcements |
| Notifications | Your notification feed |
| Profile | Your account |

## 3. Core workflows

### 3.1 Review a travel request (Verification)

1. **More → Verification**. Cards list submitted travels newest-first.
2. Click a card to open details (participant, dates, college, compliance snapshot).
3. **Approve** or **Reject**. Rejection should include a remark — the faculty
   member is notified and sees it under their Remarks.
4. Optional: **AI Check** on a card — shows AI-suggested document type,
   confidence, extracted fields, flagged issues, and a suggested admin remark
   you can copy. AI output is advisory only; your decision is what counts.

### 3.2 Verify documents

1. Open a travel → its documents list.
2. Per document: **Verify** (green) or **Reject** (with reason).
3. Verified/required counts feed the compliance score automatically (BR-07).

### 3.3 Monitor compliance (Compliance tile)

- Each travel shows a compliance **score** and **status**:
  - **Fully Compliant** (green) — all required pre-travel docs verified.
  - **Partially Compliant** (yellow) — some action remains.
  - **Needs Action** (red) — overdue, rejected, or critical requirements missing.
- Use filters to focus on non-compliant or high-risk travels.
- Re-running compliance happens automatically on workflow changes; you can also
  trigger a refresh from the AI Analysis screen.

### 3.4 Lifecycle (post-travel & re-entry)

- **Post-travel**: track required reports/evidence after the trip; mark items
  received or overdue.
- **Re-entry**: track dissemination/activity-plan items (e.g. lecture, MOV,
  photos). Overdue items surface in AI insights and notifications.

### 3.5 Remarks & follow-up

- **Remarks** tile: complete history, filterable. Remarks record previous → new
  status so the chain of decisions is auditable.
- AI suggested remarks appear in the verification dialog and insights — they
  start with `[AI suggested]` and are meant to be edited before sending.

### 3.6 AI Analysis (monitoring)

**More → AI Analysis**:

1. **Compliance Insights** card — auto-generated findings:
   - `compliance_summary` — overall status per travel.
   - `priority` — travels needing follow-up (medium/high).
   - `document_issue` — blocking/missing documents.
2. Filters: **All / High / Medium / Low**. **Regenerate** recomputes insights
   from live data (un-accepted stale rows are replaced; acknowledged ones are kept).
3. **Acknowledge** on an insight marks it accepted (green check) — useful as an
   internal “handled” flag.
4. **Suggested remark** box — copy/edit into Remarks before sending to faculty.

### 3.7 Reports

- **Reports** tile: totals by year, mobility type, top countries, college
  breakdowns; charts for presentations.
- Export/print from the browser as needed (PDF/Excel print views).

### 3.8 Users & settings

- **Students**: create faculty/staff/student accounts, change roles, deactivate.
- **Doc Types**: add/remove required documents per category (Pre-Travel,
  Post-Travel, Re-Entry). Changes affect what faculty must upload and what
  compliance counts.
- **Settings**: colleges/departments reference data.
- **Announcements**: publish updates visible on every faculty dashboard.

## 4. Account security

- Change the seeded password immediately after install.
- Use distinct accounts per person; never share the admin login.
- Audit Log is your accountability record — investigate anything unexpected.
- If `SECRET_KEY` on the server is rotated, all sessions expire; users simply
  log in again.

## 5. What AI does (and does not do)

- **Does:** suggests document types from filenames, extracts simple fields
  (dates, size class), flags placeholder/generic/mismatched/oversized files,
  summarizes compliance, ranks priority follow-ups, drafts remarks.
- **Does not:** read scanned image content (no OCR), chat with users, or make
  binding decisions. Every AI output shows confidence where relevant — treat it
  as a second opinion, never as policy.

## 6. Quick checklist for new admins

1. Log in → change password.
2. Post an announcement so faculty know the system is live.
3. Review **Doc Types** against your current requirement list.
4. Walk one test travel end-to-end (Verification → Compliance → Remarks).
5. Open **AI Analysis** → Regenerate → Acknowledge one insight.
6. Confirm **Audit Log** captured your actions.
