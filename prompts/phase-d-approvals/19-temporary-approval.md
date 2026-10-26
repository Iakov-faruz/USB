# פרומפט 19 — אישור זמני (Temporary Approval Flow)

## מטרה
איך לבצע פעולה מורכבת עם הרבה שלבים בצורה בטוחה. יישום זרימת אישור זמני עם פיצוי במצבי כשל.

## קבצים צפויים
`scripts/lib/stages.sh` (חלק אישור זמני), `tests/unit/test_temporary_approval.sh`

## קריטריון אימות
הרץ את הבדיקות וודא שמקרי כשל נבדקים.

## מה לומדים
איך לבצע פעולה מורכבת עם הרבה שלבים בצורה בטוחה.

---

```text
PROMPT 19 — Temporary Approval Flow

Implement temporary approval in scripts/lib/stages.sh:

Workflow (SRS section 12.2):
1. Validate request and device info.
2. Read blocked devices for selection without holding the lock.
3. Acquire the single global lock, re-fetch USBGuard state, and revalidate
   every selected device and policy condition.
4. Check overlap, precedence, and duplicate rule.
5. Create TTL record with status=pending using atomic write.
6. Perform the G-01-verified action(s) to approve the connected device and
   add the temporary policy rule as needed.
7. Verify the live device state and active rule independently.
8. Update TTL record to status=active using atomic write.
9. Write audit entry and report policy/audit outcomes separately.
10. Release lock.

Error handling:
- If policy outcome is known and only the new temporary rule exists, remove
  only that uniquely matched rule and verify; do not assume this reverses
  approval of a connected device.
- If policy outcome or TTL write is uncertain, preserve the pending record,
  mark recovery_required where safely writable, and do not attempt an
  unverified block/rollback.
- If policy and TTL are verified but audit fails, report EXIT_AUDIT and
  preserve the verified policy result.

Constraints:
- Do NOT use permanent rule for temporary approval.
- Do NOT assume rule addition changes connected device state.

Create tests with mock adapter. Run and report results.
```

## משימות מפורטות
ממש את זרימת האישור הזמני לפי ה-SRS ובכפוף לתוצאות G-01.

השתמש ב-fake USBGuard לבדיקות יחידה. בדיקות אינטגרציה משנות policy ירוצו רק במעבדה המאושרת.

## זרימת העבודה

1. אמת את הבקשה ואת פרטי ההתקן.
2. קרא התקנים חסומים לצורך בחירה בלי להחזיק נעילה.
3. רכוש נעילה גלובלית ואז בצע Re-fetch; אין להשתמש בתוצאת הקריאה שלפני הנעילה לצורך commit.
4. בדוק אם כבר קיים כלל תואם או אישור פעיל.
5. מנע יצירת כלל כפול.
6. כתוב רשומת `pending` לפי סכמת TTL וכתיבה אטומית.
7. בצע את פעולת USBGuard שאומתה ב-G-01.
8. אמת בנפרד מצב התקן מחובר וכלל פעיל.
9. עדכן את TTL באופן אטומי.
10. כתוב Audit.
11. אם התהליך נכשל באמצע, סמן מצב מתאים ואל תעמיד פנים שהפעולה הצליחה במלואה.

## איסורים קריטיים

- אסור להשתמש ב-`allow-device --permanent` לצורך אישור זמני.
- אל תניח שכל כשל מחייב rollback אוטומטי. אם מצב policy אינו ודאי, השתמש במנגנון התאוששות.
- לא ליצור כלל נוסף כאשר קיים כלל שמכסה את אותה פעולה.
- לא להחזיר הצלחה אם מצב המדיניות והמצב המקומי אינם תואמים.

## בדיקות

- אישור חדש.
- אישור כפול.
- כשל לפני שינוי policy.
- כשל אחרי שינוי policy.
- כשל בכתיבת TTL.
- אישור התקן הצליח אך הוספת הכלל נכשלה; אין לבצע חסימה אוטומטית.
- כשל Audit.
- timeout.
- שתי בקשות במקביל.
- מצב לא ודאי.
