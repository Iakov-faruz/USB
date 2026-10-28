# פרומפט 23 — ממשק פקודה (CLI Implementation)

## מטרה
איך לבנות ממשק שמשתמשים יכולים להפעיל משורת הפקודה. יישום נקודות כניסה ל-CLI עם ולידציה של ארגומנטים וקודי יציאה מדויקים.

## קבצים צפויים
`scripts/usb-approve.sh`, `scripts/usbguard-status.sh`,
`scripts/usb-revoke.sh`, `tests/unit/test_cli.sh`

## קריטריון אימות
הרץ `./scripts/usb-approve.sh --help` ו-`./scripts/usbguard-status.sh --help`.

## מה לומדים
איך לבנות ממשק שמשתמשים יכולים להפעיל משורת הפקודה.

---

```text
PROMPT 23 — CLI Implementation

Implement CLI entry points:

1. scripts/usb-approve.sh:
   - Arguments: --device, --type, --ttl, --dry-run, --help
   - Allow repeated --device values as specified by the SRS; reject
     duplicate IDs before any policy change and report every item separately.
   - Validate arguments before executing.
   - Return appropriate exit codes.
   - Read-only commands must not modify state.

2. scripts/usbguard-status.sh:
   - Arguments: --json, --watch, --help
   - Report daemon status, IPC status, timer status, TTL counts.
   - Return non-zero if daemon is down.

3. scripts/usb-revoke.sh:
   - Arguments: --managed-id, --device, --dry-run, --help.
   - Require an expired TTL record, a current USBGuard device ID, and
     interactive administrator confirmation; provide no unattended approval.
   - Call the dedicated revocation service; never implement policy logic in
     the entry point.
   - Re-fetch and revalidate under the global lock before any action.
   - Report separately if disconnected, already blocked, ambiguous, or allowed
     by an independent rule; do not call block-device in those cases.

Constraints:
- Use the service layer (stages.sh), do not duplicate logic.
- Do not expose sensitive information.
- Support both human-readable and JSON output.
- JSON output includes schema_version and separate policy/audit results.
- Do not add --vidpid or approval by VID:PID alone; --device must identify
  a device from the current USBGuard state.
- Do not let the Reaper, timer, restore, or recovery invoke usb-revoke.sh.
- Stop before any policy/state mutation when a restore journal is unresolved.

Create tests for argument parsing and exit codes.
Run tests and report results.
```

## משימות מפורטות
בפרומפט זה ממש את `usb-approve.sh`, `usbguard-status.sh` ואת נקודת הכניסה
המפורשת `usb-revoke.sh` בלבד. ממשקי
הגיבוי, השחזור, הייבוא והייצוא מטופלים בפרומפטים 26–27; אין להמציא עבורם
דגלים בפרומפט זה.

1. ממש את הפקודות והדגלים שהוגדרו בלבד.
2. הוסף `--help` ותיעוד שימוש.
3. אמת ארגומנטים לפני ביצוע פעולה.
4. החזר קודי יציאה מדויקים התואמים לשכבת התוצאות.
5. הפרד בין פלט אנושי ל-JSON אם שניהם נדרשים.
6. אל תחשוף מידע רגיש.
7. אל תאפשר לעקוף הרשאות דרך CLI.
8. כל פעולה שמשנה policy חייבת להשתמש ב-locking, validation, Audit ו-recovery המתאימים.
9. פקודות קריאה בלבד אינן משנות מצב.
10. טפל בביטול, קלט לא תקין ו-USBGuard לא זמין.
11. `usb-revoke.sh` דורש אישור אינטראקטיבי, רשומת `expired` ומזהה התקן
    עדכני; אינו משנה TTL או מדיניות קבועה, ומאמת חסימה לאחר פעולה שאושרה
    ב-G-01.

## בדיקות

- כל פקודה תקינה.
- ארגומנטים חסרים.
- אפשרות לא מוכרת.
- הרשאות חסרות.
- JSON תקין.
- קודי יציאה.
- `--dry-run` משאיר policy, TTL, Audit וכל State ללא שינוי.
- בדיקות ביטול הרשאה: קלט לא תקין, חסר אישור, התקן מנותק/חסום, כלל עצמאי,
  התאמה עמומה, הצלחה מאומתת ותוצאה לא ודאית.
- fake USBGuard.

## איסורים

- אל תוסיף פקודות או דגלים שלא הוגדרו ללא אישור.
