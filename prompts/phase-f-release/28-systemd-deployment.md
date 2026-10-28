# פרומפט 28 — יחידות מערכת (systemd Units)

## מטרה
איך להגדיר שירות שרץ אוטומטית במערכת. יצירת קובצי יחידת systemd עבור שירות הניקוי וטיימר מחזורי.

## קבצים צפויים
`systemd/usbguard-approval-ttl.service`, `systemd/usbguard-approval-ttl.timer`

## קריטריון אימות
הרץ את פקודת האימות וודא שאין שגיאות תחביר.

## מה לומדים
איך להגדיר שירות שרץ אוטומטית במערכת.

---

```text
PROMPT 28 — systemd Units

Create systemd unit files:

1. usbguard-approval-ttl.service:
   - Type=oneshot
   - User=root, Group=root (required for the privileged USBGuard policy
     operations and protected state paths defined by the SRS)
   - ExecStart=/usr/libexec/usbguard-approval-manager/cleanup-expired.sh
   - After=usbguard.service
   - Hardening: ProtectSystem=strict, PrivateTmp=true, NoNewPrivileges=true
   - ReadWritePaths: state dir, log dir, lock path; do NOT grant the Reaper
     write access to the backup directory.

2. usbguard-approval-ttl.timer:
   - OnBootSec=1min
   - OnUnitActiveSec=5min

Constraints:
- Do NOT add CAP_DAC_OVERRIDE by default.
- Include lock path in ReadWritePaths.
- Use exact paths from SRS.

Verify syntax with: systemd-analyze verify <unit-file>
Report results.
```

## משימות מפורטות
ממש את קובצי הפריסה ואת יחידות systemd לפי ה-SRS.

1. שירות ה-Reaper רץ כ-`root:root` לפי סעיפים 18–19 ב-USB.md. קבוצת
   `usbadmins` משמשת לגישת קריאה ללוגים ולהפעלת entry points מאושרים דרך
   sudoers; היא אינה מקבלת גישת IPC ישירה או הרשאות לשירות עצמו.
2. הגדר בעלות והרשאות מדויקות לקבצים ולספריות (על פי סעיף 10 ב-USB.md).
3. אל תפעיל את השירות בהרשאה רחבה יותר מהנדרש; עבור Reaper נדרשת הרשאת root לפי ה-SRS. צמצם capabilities והקשח את היחידה בלי לשבור IPC.
4. הגדר `ReadWritePaths` רק לנתיבים שה-Reaper חייב לכתוב אליהם: מצב, לוגים ונעילה. אין להעניק לשירות כתיבה לתיקיית הגיבויים; פעולות גיבוי/שחזור מקבלות הרשאה רק בזמן הפעולה המאושרת.
5. השתמש בהגבלות systemd המתאימות ליכולות השירות.
6. אל תחסום גישה הנדרשת ל-USBGuard IPC.
7. הגדר התנהגות בעת restart וכשל.
8. ודא שהתקנת גרסה חדשה אינה מוחקת TTL, Audit או גיבויים קיימים.
9. הוסף מנגנון rollback של פריסה בהתאם ל-SRS.
10. אל תפעיל את השירות באופן אוטומטי על מחשב העבודה כחלק מהבדיקה.
11. בצע בדיקות התקנה והסרה בסביבת מעבדה.
12. אין להפעיל `systemctl enable` או שירות בעל השפעה על policy מחוץ לסביבת המעבדה המאושרת.

## בדיקות

- בדיקת תחביר יחידות systemd.
- הרשאות קבצים.
- גישה נדרשת ל-IPC.
- נתיבי כתיבה.
- restart.
- שימור נתונים.
- rollback.
- אימות שהשירות רץ תחת `root:root`.
- הפעלה תחת `root:root` כפי שהוגדר ב-SRS.
- `sudoers` אינו מאפשר shell, פקודות כלליות או עקיפת validation דרך ארגומנטים.
