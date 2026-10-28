# פרומפט 08 — לוגים וביקורת (Logging and Audit)

## מטרה
לתעד פעולות ותוצאות באופן אמין, לפי ה-SRS. בנייה של שתי זרמי לוג נפרדים (תפעולי וביקורת) עם פורמט מובנה וסניטיזציה של קלט.

## קבצים צפויים
`scripts/lib/logger.sh`, `tests/unit/test_logger.sh`

## קריטריון אימות
בדוק רשומת JSONL תקינה, הרשאות לפי סעיף 10 ב-USB.md, וכשל כתיבה מדווח בלי להסתיר שינוי policy.

## מה לומדים
איך להפריד Audit מלוג תפעולי, למנוע זיוף רשומות ולדווח נכון על כשל Audit.

---

```text
PROMPT 08 — Logging and Audit

Implement scripts/lib/logger.sh:

1. Two separate log streams (SRS SEC-09):
   - log_info/log_error → standard log
   - log_audit → separate audit log

2. Audit format (SRS SEC-09, section 17): one JSON Lines record with
   timestamp_utc (RFC 3339 UTC), actor_uid, action, policy_result,
   correlation_id, and details. Report audit_result separately in the
   operation result; do not make an audit record self-referential.

3. Actor detection:
   - Use the invoking user UID from SUDO_UID when valid; otherwise current UID.
   - If neither is available, report "unknown" explicitly.

4. Use a JSON serializer. Escape JSON correctly; reject or sanitize control
   characters in field values so one input cannot forge additional records.

5. Use ownership/modes from SRS section 10. Report write failures explicitly.
   If policy was already applied, preserve that fact and return EXIT_AUDIT.

Create tests/unit/test_logger.sh that tests:
- Normal audit entry format
- Input with embedded newline (should be sanitized)
- Write failure simulation

Run tests and report results.
```

## משימות מפורטות
1. הפרד בין הודעות תפעוליות לבין אירועי Audit.
2. השתמש בשדות JSONL המדויקים שהוגדרו בסעיף 17 של ה-SRS; אין להמציא פורמט נוסף.
3. אל תשמור סודות, נתוני אימות או מידע רגיש מיותר.
4. השתמש ב-JSON serializer וודא ש-newline/control characters אינם מסוגלים ליצור רשומה נוספת.
5. הגדר הרשאות לפי סעיף 10, תוך הבחנה בין mode של ספרייה לבין mode של קובץ.
6. התנהג נכון כאשר הקובץ אינו ניתן לכתיבה, מלא או אינו זמין.
7. שמור על ההבחנה בין `POLICY_APPLIED` לבין `POLICY_APPLIED_AUDIT_FAILED`.
8. אל תאפשר לכשל Audit להסתיר שינוי מדיניות שכבר בוצע.
9. `log_audit` מחזיר כשל מפורש; הקורא מעדכן את מודל התוצאה ל-
   `POLICY_APPLIED_AUDIT_FAILED` אם שינוי policy כבר אומת, ואינו מנסה לבצעו שוב.

## בדיקות
- אירוע תקין נכתב כרשומת JSONL עם כל השדות הנדרשים; תוצאת ה-Audit מדווחת בנפרד.
- קלט זדוני אינו יוצר רשומת Audit מזויפת.
- כשל כתיבה נבדק.
- התוצאה המוחזרת תואמת למצב האמיתי.
- לא בוצעה פעולת USBGuard.

## איסורים
- לא בוצעה פעולת USBGuard בשלב זה.