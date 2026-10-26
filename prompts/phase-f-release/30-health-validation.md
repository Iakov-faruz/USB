# פרומפט 30 — בדיקת בריאות כוללת (Health Validation)

## מטרה
איך לבדוק שהכל עובד יחד לפני שחרור. יישום סקריפט בדיקת בריאות קריאה בלבד עם PASS/FAIL לכל בדיקה.

## קבצים צפויים
`validate_all.sh`

## קריטריון אימות
הרץ את הסקריפט וודא שכל הבדיקות מדווחות.

## מה לומדים
איך לבדוק שהכל עובד יחד לפני שחרור.

---

```text
PROMPT 30 — Health Validation

Implement validate_all.sh:

Check:
1. Configuration syntax and values.
2. File permissions and ownership.
3. Service status (timer active, last run successful).
4. IPC connectivity.
5. Backup availability and rotation.
6. Log files exist; validate owner, group and mode without writing.
7. TTL file validity.
8. Lock path owner, mode and accessibility without acquiring/changing it.

Output:
- PASS/FAIL for each check.
- Summary with overall status.
- Exit code 0 if all pass, non-zero otherwise.

Constraints:
- Read-only checks only: do not create, truncate, rotate, or write files to test writability.
- Do not modify state.

Run the validation and report results.
```

## משימות מפורטות
ממש סקריפט בדיקת בריאות כולל.

בדוק:
1. תחביר וערכי תצורה.
2. הרשאות ובעלות קבצים.
3. סטטוס שירות (טיימר פעיל, הרצה אחרונה הצליחה).
4. קישוריות IPC.
5. זמינות גיבוי ורוטציה.
6. קובצי לוג קיימים; בדוק בעלות, קבוצה ו-mode בלי לכתוב אליהם.
7. תקינות קובץ TTL.
8. נגישות קובץ נעילה.

פלט:
- PASS/FAIL לכל בדיקה.
- סיכום עם סטטוס כללי.
- קוד יציאה 0 אם הכל עבר, לא אפס אחרת.

## איסורים

- בדיקות קריאה בלבד.
- אל תבדוק כתיבה באמצעות יצירת קובץ או כתיבה בפועל; אמת הרשאות ובעלות בלבד.
- אל תשנה מצב.