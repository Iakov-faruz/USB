# פרומפט 20 — אישור קבוע (Permanent Approval Flow)

## מטרה
איך לבצע פעולה שמשאירה חותמת קבועה במערכת. יישום זרימת אישור קבוע עם אימות התמדה.

## קבצים צפויים
`scripts/lib/stages.sh` (חלק אישור קבוע), `tests/unit/test_permanent_approval.sh`

## קריטריון אימות
הרץ את הבדיקות וודא שההתמדה נבדקת.

## מה לומדים
איך לבצע פעולה שמשאירה חותמת קבועה במערכת.

---

```text
PROMPT 20 — Permanent Approval Flow

Implement permanent approval in scripts/lib/stages.sh:

Workflow:
1. Validate request and device info.
2. Read current policy and existing rules.
3. Check for duplicates.
4. Choose the correct USBGuard action(s) for permanent approval based on
   G-01. Do not repeat a separate append if the verified command already
   approves the device and persists the rule.
5. Apply the selected action(s).
6. Verify the connected device, active policy, and persistent RuleFile/
   RuleFolder independently.
7. Write audit entry distinguishing permanent from temporary.

Constraints:
- Do NOT blindly run allow-device followed by append-rule.
- Do NOT use Rule ID as permanent identifier.
- Verify persistence according to target configuration.
- If a command's combined behavior is not proven by G-01, stop as UNVERIFIED.

Create tests with mock adapter. Run and report results.
```

## משימות מפורטות
ממש את זרימת האישור הקבוע לפי ה-SRS ולפי תוצאות G-01.

## דרישות

1. אמת את הבקשה ואת פרטי ההתקן.
2. בדוק את הכללים הקיימים.
3. בחר פעולה שמתאימה במדויק לתרחיש.
4. אל תבצע `allow-device --permanent` ולאחריו `append-rule` נוסף באופן עיוור.
5. מנע יצירת כללים כפולים.
6. אמת את התוצאה בפועל.
7. בדוק שההתנהגות הקבועה תואמת לקובץ המדיניות ולהגדרות היעד.
8. הפק Audit עם תוצאה מדויקת.
9. אם שינוי policy הצליח אך Audit נכשל, שמור על ההבחנה שנקבעה ב-SRS.
10. אל תבצע rollback אוטומטי שעלול לגרום לחסימה או לשינוי נוסף בלתי צפוי.

## בדיקות

- כלל קבוע חדש.
- כלל קבוע שכבר קיים.
- מניעת כפילות.
- כשל USBGuard.
- כשל Audit.
- אימות persistence במעבדה.

## איסורים

- אל תשתמש ב-Rule ID כמזהה קבוע.
- אין אישור קבוע לפני אימות G-01.
