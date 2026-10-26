# פרומפט 23 — ממשק פקודה (CLI Implementation)

## מטרה
איך לבנות ממשק שמשתמשים יכולים להפעיל משורת הפקודה. יישום נקודות כניסה ל-CLI עם ולידציה של ארגומנטים וקודי יציאה מדויקים.

## קבצים צפויים
`scripts/usb-approve.sh`, `scripts/usbguard-status.sh`, `tests/unit/test_cli.sh`

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

Constraints:
- Use the service layer (stages.sh), do not duplicate logic.
- Do not expose sensitive information.
- Support both human-readable and JSON output.
- JSON output includes schema_version and separate policy/audit results.
- Do not add --vidpid or approval by VID:PID alone; --device must identify
  a device from the current USBGuard state.

Create tests for argument parsing and exit codes.
Run tests and report results.
```

## משימות מפורטות
בפרומפט זה ממש את `usb-approve.sh` ואת `usbguard-status.sh` בלבד. ממשקי
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

## בדיקות

- כל פקודה תקינה.
- ארגומנטים חסרים.
- אפשרות לא מוכרת.
- הרשאות חסרות.
- JSON תקין.
- קודי יציאה.
- `--dry-run` משאיר policy, TTL, Audit וכל State ללא שינוי.
- fake USBGuard.

## איסורים

- אל תוסיף פקודות או דגלים שלא הוגדרו ללא אישור.
