# פרומפט 21 — תפוגה וניקוי (TTL Expiration and Reaper)

## מטרה
איך לנקות אחרי פעולות שפג תוקפן בלי לעשות נזק. יישום Reaper עם הבחנה קריטית בין הסרת כלל לחסימת התקן.

## קבצים צפויים
`scripts/cleanup-expired.sh`, `scripts/lib/revocation.sh`,
`tests/unit/test_cleanup.sh`, `tests/unit/test_revocation.sh`

## קריטריון אימות
הרץ את הבדיקות וודא שההבחנה בין "הכלל הוסר" ל"ההתקן נחסם" נבדקת.

## מה לומדים
איך לנקות אחרי פעולות שפג תוקפן בלי לעשות נזק.

---

```text
PROMPT 21 — TTL Expiration and Reaper

Implement scripts/cleanup-expired.sh and the separate revocation service in
scripts/lib/revocation.sh:

Workflow (SRS section 14):
1. Acquire lock.
2. Load TTL records.
3. Verify clock reliability.
4. Read current USBGuard state and reconcile records.
5. If an active TTL rule is missing, or an earlier run left a pending record,
   mark it recovery_required when safely writable. Do not recreate, remove,
   or re-apply any policy rule automatically.
6. Find expired records.
7. Locate the matching temporary rule (unique canonical match required).
8. Get the current Rule ID and verify the rule still matches.
9. Remove ONLY the identified temporary rule.
10. Verify removal succeeded.
11. Update the TTL record.
12. Write audit entry.
13. Release lock.

CRITICAL DISTINCTION:
- Removing a temporary rule does NOT prove the device is blocked.
- After removal, check device state separately.
- If another rule still allows the device, report that explicitly.
- Do NOT run block-device as part of TTL expiration. A connected device that
  remains allowed is reported and may be handled only through the separate,
  explicit administrator workflow below.

Separate explicit revocation (never called by the Reaper or timer):
- Require an expired --managed-id and a current USBGuard --device ID.
- Show device identity and impact, then require interactive administrator
  confirmation; provide no unattended approval mode.
- Acquire the global lock, re-fetch state, and revalidate the expired record,
  current device identity/state, and effective policy after confirmation.
- If the device is disconnected, already blocked, ambiguous, or allowed by an
  independent rule, do not call block-device; report the exact reason.
- Only for a uniquely matched device still allowed without an independent
  allow rule, call the G-01-verified block-device operation and verify the
  device is blocked. Do not edit the persistent policy or TTL record.
- Audit the explicit action and report policy and audit outcomes separately.
- Never retry an uncertain block automatically.

Error cases:
- Clock unreliable: do not change policy; mark recovery_required when safely
  writable, and report EXIT_INCONSISTENT.
- Ambiguous match: stop, mark recovery_required.
- IPC unavailable before attempting a policy change: leave policy and TTL
  unchanged, report EXIT_OPERATION, and retry on a later scheduled run.
- Removal result uncertain: do not retry automatically; report
  EXIT_INCONSISTENT and require recovery.
- Missing rule for an active record or a stale pending record: do not replay
  or restore policy; require an explicit, audited administrator recovery.
- Removal verified but TTL commit fails: preserve the prior atomic file and
  evidence; do not repeat removal or restore policy automatically. A later
  reconciliation must require explicit recovery rather than infer expiration.
- A restore journal exists: do not reconcile or mutate policy/TTL; stop and
  report that restore recovery must complete first.

Create tests with mock adapter. Run and report results.
Also test the separate revocation service with a mock adapter; never run its
policy-changing tests outside the approved lab.
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
- אל תפעיל `block-device` כחלק מתהליך תפוגה. ה-SRS מתיר אותו רק בכלי
  נפרד, אחרי אישור מפורש של מנהל.
- אם ההתקן עדיין מאושר, דווח זאת במפורש.
- אם אי אפשר לקבוע את מצבו, דווח `unknown` או מצב שקול שהוגדר בפרויקט.
- אל תסמן תפוגה כ"התקן נחסם" אם הדבר לא אומת.

אם השעון אינו מהימן, ה-IPC אינו זמין או התאמת הכלל עמומה, אין לבצע הסרה אוטומטית.

## זרימת ביטול הרשאה נפרדת

ממש את `scripts/lib/revocation.sh` בנפרד מה-Reaper. הכלי יקבל מזהה רשומת
TTL במצב `expired` ומזהה התקן נוכחי מ-USBGuard, יציג את ההתקן ואת השפעת
החסימה וידרוש אישור אינטראקטיבי. לאחר האישור, רכוש נעילה, בצע Re-fetch
ואמת מחדש את הרשומה, זהות/מצב ההתקן וה-policy.

- התקן מנותק או כבר חסום: דווח שאין צורך בחסימה.
- התאמה עמומה או כלל עצמאי שמאפשר את ההתקן: אל תחסום; דווח את הסיבה.
- רק התקן מחובר ומותר, ללא כלל עצמאי אחר, עם התאמה יחידה ו-G-01 מאומת,
  ניתן להעביר ל-`block-device`; אמת לאחר מכן שההתקן חסום.
- אין לשנות כלל קבוע או רשומת TTL, ואין לאפשר אישור אוטומטי/לא-אינטראקטיבי.
- כתוב Audit נפרד עם תוצאת policy ותוצאת Audit; בתוצאה לא ודאית אל תנסה שוב.

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
- Reaper אינו מפעיל `block-device`.
- ביטול נפרד: אישור, נעילה ו-Re-fetch, התקן מנותק/חסום, כלל עצמאי,
  התאמה עמומה, הצלחה מאומתת, כשל Audit ותוצאה לא ודאית.
- journal שחזור לא פתור עוצר את ה-Reaper ללא שינוי policy או TTL.
