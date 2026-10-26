# פרומפט 21 — תפוגה וניקוי (TTL Expiration and Reaper)

## מטרה
איך לנקות אחרי פעולות שפג תוקפן בלי לעשות נזק. יישום Reaper עם הבחנה קריטית בין הסרת כלל לחסימת התקן.

## קבצים צפויים
`scripts/cleanup-expired.sh`, `tests/unit/test_cleanup.sh`

## קריטריון אימות
הרץ את הבדיקות וודא שההבחנה בין "הכלל הוסר" ל"ההתקן נחסם" נבדקת.

## מה לומדים
איך לנקות אחרי פעולות שפג תוקפן בלי לעשות נזק.

---

```text
PROMPT 21 — TTL Expiration and Reaper

Implement scripts/cleanup-expired.sh:

Workflow (SRS section 14):
1. Acquire lock.
2. Load TTL records.
3. Verify clock reliability.
4. Find expired records.
5. Read current USBGuard state.
6. Locate the matching temporary rule (unique match required).
7. Get current Rule ID and verify rule still matches.
8. Remove ONLY the identified temporary rule.
9. Verify removal succeeded.
10. Update TTL record.
11. Write audit entry.
12. Release lock.

CRITICAL DISTINCTION:
- Removing a temporary rule does NOT prove the device is blocked.
- After removal, check device state separately.
- If another rule still allows the device, report that explicitly.
- Do NOT run block-device as part of TTL expiration. The SRS does not authorize
  that action in the Reaper; any future block workflow requires a separate
  explicit SRS requirement and approval.

Error cases:
- Clock unreliable: do not change policy; mark recovery_required when safely
  writable, and report EXIT_INCONSISTENT.
- Ambiguous match: stop, mark recovery_required.
- IPC unavailable before attempting a policy change: leave policy and TTL
  unchanged, report EXIT_OPERATION, and retry on a later scheduled run.
- Removal result uncertain: do not retry automatically; report
  EXIT_INCONSISTENT and require recovery.
- Removal verified but TTL commit fails: preserve the prior atomic file and
  evidence; do not repeat removal or restore policy automatically. A later
  reconciliation must require explicit recovery rather than infer expiration.

Create tests with mock adapter. Run and report results.
```

## משימות מפורטות
ממש את Reaper לפי ה-SRS.

## זרימת העבודה

1. רכוש נעילה.
2. טען מחדש את מצב TTL.
3. אמת את אמינות השעון.
4. מצא רשומות שפג תוקפן.
5. קרא את מצב USBGuard העדכני.
6. אתר את הכלל הזמני המתאים באופן חד-משמעי.
7. מצא את Rule ID הנוכחי ואמת שהכלל עדיין תואם.
8. הסר רק את הכלל הזמני המתאים.
9. אמת את תוצאת ההסרה.
10. עדכן TTL באופן אטומי.
11. הפק Audit.
12. אם פעולה חלקית או לא ודאית, העבר למצב המתאים במקום לדווח הצלחה מלאה.

## הבחנה קריטית: הסרת כלל לעומת חסימת התקן

הסרת כלל זמני **אינה מוכיחה שההתקן נחסם**.

לאחר ההסרה:
- בדוק את מצב ההתקן.
- בדוק אם כלל קבוע אחר עדיין מאפשר אותו.
- אל תפעיל `block-device` כחלק מתהליך תפוגה: ה-SRS אינו מתיר פעולה זו ב-Reaper.
- אם ההתקן עדיין מאושר, דווח זאת במפורש.
- אם אי אפשר לקבוע את מצבו, דווח `unknown` או מצב שקול שהוגדר בפרויקט.
- אל תסמן תפוגה כ"התקן נחסם" אם הדבר לא אומת.

אם השעון אינו מהימן, ה-IPC אינו זמין או התאמת הכלל עמומה, אין לבצע הסרה אוטומטית.

## בדיקות

- כלל שפג תוקפו.
- כלל שכבר הוסר.
- Rule ID שהשתנה.
- כלל קבוע חופף.
- התקן שנשאר מאושר.
- מעבר לרשומת `expired` רק לאחר אימות הסרת הכלל, תוך שמירת הרשומה.
- שעון לא מהימן.
- USBGuard לא זמין.
- כשל עדכון TTL.
- כשל Audit.
- תוצאת הסרה לא ודאית אינה גורמת לניסיון הסרה חוזר.
