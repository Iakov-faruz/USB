# פרומפט 12 — בדיקות זמן ושעון (Time Guards)

## מטרה
איך לטפל בזמן בצורה בטוחה (לא לסמוך על השעון בעיוורון). יישום פונקציות קריאת Epoch, בדיקת אמינות שעון וזיהוי קפיצות שעון.

## קבצים צפויים
`scripts/lib/time-guards.sh`, `tests/unit/test_time_guards.sh`

## קריטריון אימות
הרץ את הבדיקות. ודא שאף בדיקה לא משנה את שעון המערכת.

## מה לומדים
איך לטפל בזמן בצורה בטוחה (לא לסמוך על השעון בעיוורון).

---

```text
PROMPT 12 — Time Guards

Implement scripts/lib/time-guards.sh:

1. Function get_current_epoch(): return current Unix timestamp.

2. Function is_clock_reasonable():
   - Check current time > MIN_REASONABLE_EPOCH
   - Do not invent a calendar upper bound.
   - A plausible Epoch is not proof of synchronization.

3. Function detect_clock_jump(last_known_time):
   - Compare with the last positively trusted time, if one exists.
   - Treat a missing trusted baseline, missing synchronization evidence,
     or a jump beyond the SRS threshold as untrusted.
   - Do NOT change system clock

4. Note: TTL is calendar-based (Epoch). If clock is unreliable after
   reboot, do NOT auto-restore permissions (SRS time model).

5. Implement the trust check using the time-sync source and evidence
   verified by G-01 for the target. Missing/unsupported status fails closed.

Create tests/unit/test_time_guards.sh that tests:
- Current Epoch above MIN_REASONABLE_EPOCH
- Simulated missing/negative values rejected
- Synchronized and unsynchronized provider results
- Jump over and under MAX_CLOCK_JUMP_SECONDS
- Missing last trusted baseline

Run tests and report results.
```

## משימות מפורטות
1. השתמש ב-Epoch לציון זמני תפוגה, לפי ה-SRS.
2. השתמש בזמן הנוכחי וב-`expires_at` לפי הסכמה; אל תוסיף שדות TTL שאינם מוגדרים ב-SRS.
3. ודא שערכים שליליים, חסרים או לא תקינים נדחים.
4. בדוק overflow וטווחים בלתי סבירים.
5. אל תסיק שהשעון אמין רק משום שהוא מחזיר timestamp.
6. יישם רק קריטריוני clock trust שאושרו ב-SRS וב-G-01; תעד את המקור והראיה.
7. אם אין דרך להוכיח שהשעון אמין לאחר reboot, החזר מצב מפורש שמונע תפוגה או הארכה אוטומטית מסוכנת.
8. אל תשנה את שעון המערכת כחלק מהבדיקה.
9. אל תוסיף גבול קלנדרי עליון או סף סטייה חדש. `MAX_CLOCK_JUMP_SECONDS` הוא סף חריגה ואינו הוכחת סנכרון.
10. אל תוסיף עדיין Reaper שמבצע שינויי policy.

## בדיקות
- זמן תקין.
- זמן לא תקין.
- תפוגה שכבר חלפה.
- שעון שאינו מהימן.
- התנהגות לאחר reboot מדומה.
- ערכי קצה.

## ערך הנדרש
הצג מה הבדיקות מוכיחות ומה מחייב בדיקה במערכת אמיתית.

## איסורים
- אין Reaper מבצע שינויי policy בשלב זה.