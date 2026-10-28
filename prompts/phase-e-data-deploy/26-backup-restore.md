# פרומפט 26 — גיבוי ושחזור (Backup and Restore)

## מטרה
איך להגן על נתונים ולשחזר אותם בבטחה. יישום סקריפטי גיבוי ושחזור עם מניפסט ושמירת הרשאות.

## קבצים צפויים
`scripts/backup-rules.sh`, `scripts/restore-rules.sh`, `tests/unit/test_backup_restore.sh`

## קריטריון אימות
הרץ את הבדיקות וודא שגיבוי ושחזור עובדים.

## מה לומדים
איך להגן על נתונים ולשחזר אותם בבטחה.

---

```text
PROMPT 26 — Backup and Restore

Implement backup and restore:

1. backup-rules.sh:
   - Backup only the SRS allowlisted files; never include 00-system.rules.
   - Create a versioned manifest with exact file list, sizes, modes, and SHA-256.
   - Rotate backups according to BACKUP_KEEP.
   - Preserve permissions.

2. restore-rules.sh:
   - Support --recover as the sole allowed state-mutating operation while a
     restore journal is open; it rolls back to the verified pre-restore set.
   - List available backups.
   - Verify manifest before restore.
   - Show what will change before applying.
   - Extract and validate in a staging directory; create and verify rollback
     copies before changing any destination.
   - Write and fsync a durable restore journal before the first replacement.
     Record transaction ID, target list, prior/target hashes, and progress.
   - Atomically replace each validated file, fsync each file and parent
     directory, and keep the journal until every target is verified.
   - On interruption, block all policy/state mutations and idempotently restore
     every target from verified rollback copies. Remove the journal only after
     all prior hashes are verified; otherwise mark recovery_required and
     preserve all evidence.
   - Ensure USBGuard cannot consume a mixed persistent policy during restore
     or recovery; prove the chosen deployment guard using G-01.
   - Do not claim a multi-file restore is atomic merely because each file is
     individually replaced atomically.
   - Reconcile restored TTL records without changing policy: preserve an
     active record only when the clock is trusted, expires_at is future, and
     exactly one matching temporary rule exists in current active policy.
     Convert other non-expired records to recovery_required; pending and
     inconsistent always require recovery. Keep expired terminal.
   - Never recreate a temporary rule, replay a pending action, block a device,
     or invoke the separate revocation workflow during restore.
   - Do NOT restore Rule IDs as valid after reboot.
   - If clock is unreliable, do not auto-expire or preserve a non-expired
     record as active after restore.

Constraints:
- Do NOT overwrite existing state without checks.
- Do NOT delete existing backups during restore.

Create tests for backup, restore, and failure scenarios.
Run tests and report results.
```

## משימות מפורטות
להגן על נתונים קיימים ולמנוע שחזור לא בטוח.

1. גבה את הקבצים הנדרשים בלבד.
2. שמור על הרשאות ו-ownership מתאימים.
3. אמת שלמות, schema וגרסת פורמט לפני שחזור.
4. אל תדרוס מצב קיים בלי בדיקות מקדימות.
5. הצג את הפעולות שהשחזור צפוי לבצע לפני החלתן.
6. הגדר rollback עמיד לקריסה לשחזור רב-קבצים: journal שנכתב ונשמר לפני
   ההחלפה הראשונה, התקדמות, fsync, שחזור idempotent מעותקי rollback מאומתים,
   וחסימת פעולות עד לסגירת ה-journal. בדוק גם נפילת חשמל בכל נקודת החלפה.
7. אל תשחזר Rule IDs של USBGuard כאילו הם תקפים לאחר הפעלה מחדש.
8. התאם TTL למדיניות הפעילה לאחר השחזור בלי לשנות policy: `active` נשמר רק
   עם שעון מהימן, תפוגה עתידית וכלל תואם יחיד; רשומות לא ודאיות עוברות
   ל-`recovery_required`, ו-`pending`/`inconsistent` דורשות התאוששות.
9. אין להפעיל שחזור או חסימה אוטומטיים של כללים זמניים; רשומת `expired`
   נשארת סופית. ביטול התקן מחובר נעשה רק בזרימת מנהל נפרדת.
11. אם השעון אינו מהימן, אל תבצע תפוגה אוטומטית המבוססת על זמן לא אמין.
12. אם לא ניתן לקבוע שהשחזור בטוח, העבר את המערכת למצב התאוששות.
13. אל תמחק Audit או גיבויים קיימים שלא הוגדרו כמועמדים למחיקה.

## בדיקות

- גיבוי תקין.
- שחזור תקין.
- קובץ גיבוי פגום.
- schema לא נתמך.
- נתונים קיימים.
- כשל באמצע השחזור.
- קריסה/הפסקת חשמל בין החלפות, journal עמיד, rollback וחסימת USBGuard
  מפני טעינת policy מעורבת.
- שחזור רשומות active/pending/inconsistent/expired, שעון לא מהימן וכלל חסר.
- rollback.
- Audit.
- path traversal, symlink, unexpected archive member, and manifest mismatch.

## איסורים

- אין לשחזר Rule IDs כמזהים תקפים לאחר הפעלה מחדש.
