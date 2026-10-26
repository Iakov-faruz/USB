# פרומפט 17 — מודל נתוני רישום זמני (TTL Data Model)

## מטרה
איך לתכנן מבנה נתונים שמייצג מחזור חיים שלם. יישום מודל TTL עם Schema, מצבים וכתיבה אטומית.

## קבצים צפויים
`scripts/lib/ttl-model.sh`, `tests/unit/test_ttl_model.sh`

## קריטריון אימות
הרץ את הבדיקות וודא שכל המעברים נבדקים.

## מה לומדים
איך לתכנן מבנה נתונים שמייצג מחזור חיים שלם.

---

```text
PROMPT 17 — TTL Data Model

Implement scripts/lib/ttl-model.sh:

1. Define the TTL record structure (SRS section 13):
   - managed_id: UUID v4
   - rule: canonical rule string
   - rule_sha256: SHA-256 of the exact UTF-8 bytes of rule
   - expires_at: Epoch
   - status: pending | active | inconsistent | recovery_required | expired
   - correlation_id: UUID v4

Use exactly the six record fields shown in SRS section 13. Do not add
created_at, created_by, scope, or any other field. Never persist a USBGuard
Rule ID. If USBGuard cannot yield one unambiguous canonical rule match, fail
closed and require recovery.

2. Function create_ttl_record(): create new record with pending status.
3. Function get_ttl_record(managed_id): retrieve record by ID.
4. Function update_ttl_status(managed_id, new_status): atomic update.
5. Function list_ttl_records(filter): list records, optionally filtered.

Constraints:
- Use atomic-write.py for all writes.
- Do NOT store Rule ID as permanent identifier.

Create tests/unit/test_ttl_model.sh that tests:
- Create and retrieve record
- Valid/invalid status transitions, including terminal expired
- Invalid status transition rejected
- Corrupt file handling

Run tests and report results.
```

## משימות מפורטות
ממש את מודל הנתונים של TTL לפי ה-SRS. אין עדיין לבצע פעולות שמשנות policy.

קובץ המצב הוא `ttl.json` בנתיב שהוגדר ב-SRS (סעיף 10 ב-USB.md: `/var/lib/usbguard-approval-manager/ttl.json`).

1. השתמש ב-schema ובגרסת פורמט מפורשים (`schema_version`).
2. כלול רק שדות הנדרשים לזיהוי, תזמון והתאוששות.
3. אל תשמור Rule ID כזיהוי יציב.
4. הגדר כיצד מזהים כלל זמני באופן חד-משמעי.
5. דחה רשומות עמומות או פגומות.
6. השתמש בכתיבה אטומית ובנעילה.
7. הגדר טיפול בקובץ חסר ובגרסת schema לא נתמכת.
8. אל תמחק רשומות לא עקביות אוטומטית.
9. ודא שניתן להבחין בין מצב מתוכנן, מצב פעיל ומצב הדורש התאוששות.

## מצבי TTL הנתמכים (רק אלה)

- `pending`
- `active`
- `inconsistent`
- `recovery_required`
- `expired`

הגדר את `expired` כמצב סופי לאחר הסרה מאומתת של הכלל הזמני. מצב זה אינו אומר שההתקן נחסם; שמור את הרשומה לביקורת. אין להוסיף מצבים נוספים ללא שינוי מאושר של ה-SRS.

## בדיקות

- קריאת מצב תקין.
- כתיבת מצב.
- schema לא תקין.
- קובץ פגום.
- רשומה חסרה.
- מצב `recovery_required`.
- round-trip של נתונים.

## איסורים

- אין פעולות שמשנות policy בשלב זה.
