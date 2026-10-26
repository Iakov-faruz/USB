# פרומפט 06 — קריאת הגדרות (Config Parser)

## מטרה
איך לקרוא קובץ הגדרות בבטחה בלי להריץ קוד מתוכו. יישום פונקציית load_config עם ולידציה נוקשה נגד הזרקת פקודות.

## קבצים צפויים
`scripts/lib/config-reader.sh`, `tests/unit/test_config_reader.sh`

## קריטריון אימות
הרץ `bash tests/unit/test_config_reader.sh` — כל הבדיקות צריכות לעבור.

## מה לומדים
איך לקרוא קובץ הגדרות בבטחה בלי להריץ קוד מתוכו.

---

```text
PROMPT 06 — Config Parser

Implement scripts/lib/config-reader.sh:

1. Function load_config(file_path) that reads KEY=VALUE pairs.

2. Validation rules (SRS SEC-01, SEC-02):
   - Keys must match ^[A-Z][A-Z0-9_]*$
   - Accept only keys defined in SRS section 11
   - Reject duplicate keys
   - Reject shell expansion, command substitution, backticks, control characters, and malformed assignments
   - Validate integer ranges for known keys

3. Return non-zero exit code on validation failure with clear error.

Constraints:
- Do NOT use `source` or `eval`.
- Use grep/awk for parsing.

Create tests/unit/test_config_reader.sh that tests:
- Valid config file and defaults
- Config with duplicate key (should fail)
- Config with $(rm -rf /) injection (should fail)
- Config with invalid key name (should fail)
- Unknown key and out-of-range value (should fail)

Run tests and report results.
```

## משימות מפורטות
1. ממש רק את טעינת התצורה ואת הוולידציה שלה; נתיבים וקודי יציאה מוגדרים במקומם המרכזי ולא בפרסר.
2. אפשר רק את מפתחות סעיף 11 ב-USB.md, עם ברירות מחדל וטווחים זהים.
3. קרא מפתחות וערכים כנתונים בלבד; לעולם אל תשתמש ב-`source`, `eval` או shell.
4. דחה כפילויות, מפתחות לא מוכרים, שורות פגומות, הרחבות וערכים מחוץ לטווח.
5. ערכים חסרים יקבלו ברירות מחדל רק לפי ה-SRS; שגיאה לא תומר לברירת מחדל שקטה.

## בדיקות
- כל מפתח תצורה מותר מוגדר ב-SRS ובדוגמת התצורה.
- קלט הגדרות לא תקין נכשל בצורה ברורה.
- אין שינוי מדיניות USBGuard בשלב זה.

## איסורים
- אין פעולת USBGuard בשלב זה.
