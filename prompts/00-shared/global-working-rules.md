# פרומפט 00 — כללי עבודה גלובליים (Global Working Rules)

## מטרה
לאלף את הסוכן שיעבוד לפי הכללים של המשתמש ולא ימציא דרישות, נתיבים או התנהגויות שלא במפרט. שלב זה אינו כותב קוד — הוא רק קובע את מסגרת העבודה לכל המשימות הבאות.

## קבצים צפויים
אין קבצי קוד. הסוכן צריך לאשר את הכללים ולעצור.

## קריטריון אימות
הסוכן מחזיר את ההודעה "כללי העבודה התקבלו" ועוצר בהמתנה לאישור לפני המשך למשימה הבאה.

## מה לומדים
איך להגדיר מקור אמת (Source of Truth), משמעת ביצוע, כללי אבטחה ותהליך דיווח לפני שמתחילים לכתוב קוד כלשהו.

---

```text
PROMPT 00 — Global Working Rules

You are working on the USBGuard Approval Manager project.

SOURCE OF TRUTH:
- USB.md v4.5 (approved 2026-10-28) is the authoritative SRS and implementation baseline.
- v4.4 is retained as historical reference only. Do not silently substitute it for v4.5.
- G-01 and restore/deployment safety evidence remain mandatory gates before implementing or enabling dependent policy-changing operations.
- Do not invent requirements, paths, or behaviors not in the SRS.
- If the SRS is ambiguous or a prompt/roadmap adds an unapproved requirement, stop and report the exact issue.

EXECUTION DISCIPLINE:
- Work only on the current task. Do not proceed without approval.
- Begin with read-only inspection. Modify files only when authorized.
- Keep implementation modular, cohesive, and easy to extend; prefer small
  focused files and functions over monolithic components.
- Keep code readable and lightweight, follow existing conventions, and add
  concise comments only where they clarify non-obvious intent.
- Never use destructive Git commands (reset --hard, clean -fd).
- Preserve unrelated user changes.
- Do not commit or create checkpoints unless explicitly requested.

SECURITY:
- Do not modify active USBGuard policy on the development host.
- Tests that modify USBGuard policy run only in the isolated VM lab with USB passthrough and a verified recovery path.
- Never assume removing a temporary rule guarantees device blocking.
- If state becomes uncertain, stop and report instead of auto-recovering.
- Never run a policy-changing integration test or the Reaper on the development host.

REPORTING:
After every task, report: files changed, tests run, actual results,
remaining gaps, and the exact next step. Do not claim a test passed without
evidence. Stop and wait for approval.
```

**אימות:** אין קוד. הסוכן צריך להחזיר "כללי העבודה התקבלו" ולעצור.
