# פרומפט 07 — מודל שגיאות ותוצאות (Error Result Model)

## מטרה
למנוע מצב שבו פעולה נכשלה אך המערכת מדווחת הצלחה. הגדרת מודל תוצאה עם הבחנה ברורה בין סוגי כישלון שונים.

## קבצים צפויים
`scripts/lib/result.sh`, `tests/unit/test_result.sh` בלבד.

## קריטריון אימות
הסוכן צריך להחזיר הגדרת מודל תוצאה עם כל מצבי הכשל ורשימת קודי היציאה.

## מה לומדים
איך להגדיר מודל שגיאות ותוצאות שמאפשר זיהוי מדויק של מצבי כשל.

---

```text
PROMPT 07 — Error Result Model

Implement the shared error/result model in scripts/lib/result.sh:

1. Define result states:
   - Operation succeeded
   - Operation failed before policy change
   - Policy change failed
   - Policy change succeeded but Audit write failed (`POLICY_APPLIED_AUDIT_FAILED`)
   - State where it is impossible to know what changed
   - State requiring recovery

2. Map each state to exact exit codes per SRS section 21:
   - EXIT_OK = 0
   - EXIT_OPERATION = 1 (precondition/operational failure before policy change)
   - EXIT_VALIDATION = 7
   - EXIT_INCONSISTENT = 9 (including unknown policy outcome/recovery required)
   - EXIT_PARTIAL = 13
   - EXIT_AUDIT = 14
   - EXIT_CANCELLED = 130

3. Define return structure for CLI and library functions:
   - Action JSON must expose `policy_result` and `audit_result` as separate objects,
     each with a valid `status` and nullable `detail_code`, per SRS v4.5.
   - Use only the SRS status values; do not emit `partial` as a policy or audit
     status. A partial batch's aggregate policy status defaults to `unknown`,
     and its audit status defaults to `not_applicable` unless the caller can
     provide a more accurate allowed status.
   - Provide a per-item result API so batch output retains each item's ID,
     state, exit code, detail, and separate policy/audit result objects.

Do not implement business logic. Add focused unit tests for each result/code mapping.
```

## משימה
ממש שכבת שגיאות ותוצאות מרכזית בלבד. הגדר מודל תוצאה המאפשר להבחין בין:

- פעולה שהצליחה.
- פעולה שנכשלה לפני שינוי מדיניות.
- שינוי מדיניות שנכשל.
- שינוי מדיניות שהצליח אך כתיבת Audit נכשלה (`POLICY_APPLIED_AUDIT_FAILED`).
- מצב שבו אי אפשר לדעת בוודאות מה השתנה.
- מצב המחייב התאוששות.

השתמש בדיוק במיפוי קודי היציאה בסעיף 21 של USB.md. בכשל batch, שמור תוצאה לכל פריט והחל את סדר הקדימות שהוגדר שם. כשל תפעולי לפני שינוי policy הוא `EXIT_OPERATION`; מצב לא עקבי או לא ידוע הוא `EXIT_INCONSISTENT`.
פלט JSON של פעולה חייב להכיל `policy_result` ו-`audit_result` כאובייקטים עם
`status` ו-`detail_code` (מחרוזת או `null`). השתמש רק בערכי הסטטוס המותרים
ב-SRS v4.5. עבור Batch, ספק API ששומר תוצאה מובנית לכל פריט; אין להשתמש
ב-`partial` כערך סטטוס של policy או audit.

## איסורים
- אל תשתמש בתוצאה כללית כגון `false` כאשר יש צורך להבחין בין מצבים בעלי משמעות אבטחתית שונה.
- בדיקות השגיאה אינן מפעילות USBGuard אמיתי.

## בדיקות
- לכל מצב יש תוצאה צפויה.
- תוצאות אינן מתפרשות בטעות כהצלחה.
- כשל Audit לאחר שינוי מוצלח אינו מדווח כאילו המדיניות לא השתנתה.
- `EXIT_CANCELLED` מוחזר רק כאשר לא בוצע שינוי policy.

## ערך החזרה
- הסבר באמצעות דוגמאות קצרות כיצד רכיבים עתידיים ישתמשו במודל התוצאה.