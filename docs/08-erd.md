# ERD E-Ma'had

Diagram ini merupakan rancangan sebelum SQL database dibuat.

```mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : has

    PROFILES ||--o{ USER_ROLES : owns
    ROLES ||--o{ USER_ROLES : assigned

    PROFILES ||--o| STAFF : represents
    PROFILES ||--o| GUARDIANS : represents

    GUARDIANS ||--o{ GUARDIAN_STUDENTS : linked
    STUDENTS ||--o{ GUARDIAN_STUDENTS : linked

    ACADEMIC_YEARS ||--o{ CLASSES : contains
    CLASSES ||--o{ CLASS_ENROLLMENTS : has
    STUDENTS ||--o{ CLASS_ENROLLMENTS : enrolled

    ACADEMIC_YEARS ||--o{ CARE_GROUPS : contains
    CARE_GROUPS ||--o{ CARE_GROUP_MEMBERS : contains
    STUDENTS ||--o{ CARE_GROUP_MEMBERS : joins

    STAFF ||--o{ CAREGIVER_ASSIGNMENTS : assigned
    CARE_GROUPS ||--o{ CAREGIVER_ASSIGNMENTS : managed

    ACADEMIC_YEARS ||--o{ TAHFIZ_GROUPS : contains
    TAHFIZ_GROUPS ||--o{ TAHFIZ_GROUP_MEMBERS : contains
    STUDENTS ||--o{ TAHFIZ_GROUP_MEMBERS : joins

    STAFF ||--o{ TAHFIZ_SUPERVISOR_ASSIGNMENTS : assigned
    TAHFIZ_GROUPS ||--o{ TAHFIZ_SUPERVISOR_ASSIGNMENTS : managed

    CAREGIVER_ASSIGNMENTS ||--o{ CARE_JOURNALS : creates
    CARE_JOURNALS ||--o{ CARE_JOURNAL_ENTRIES : contains
    STUDENTS ||--o{ CARE_JOURNAL_ENTRIES : observed
    STAFF ||--o{ CARE_JOURNALS : reviews

    TAHFIZ_GROUPS ||--o{ TAHFIZ_REPORT_BATCHES : owns
    TAHFIZ_SUPERVISOR_ASSIGNMENTS ||--o{ TAHFIZ_REPORT_BATCHES : creates
    TAHFIZ_REPORT_BATCHES ||--o{ TAHFIZ_WEEKLY_REPORTS : contains
    STUDENTS ||--o{ TAHFIZ_WEEKLY_REPORTS : receives

    STUDENTS ||--o{ TAHSIN_CASES : has
    TAHFIZ_WEEKLY_REPORTS ||--o{ TAHSIN_CASES : refers
    STAFF ||--o{ TAHSIN_CASES : creates
    TAHSIN_CASES ||--o{ TAHSIN_SESSIONS : contains
    STAFF ||--o{ TAHSIN_SESSIONS : mentors

    TAHSIN_SESSIONS ||--o{ TAHSIN_SESSION_DIAGNOSES : has
    TAHSIN_DIAGNOSES ||--o{ TAHSIN_SESSION_DIAGNOSES : selected

    FEE_TYPES ||--o{ STUDENT_BILLS : categorizes
    STUDENTS ||--o{ STUDENT_BILLS : billed

    GUARDIANS ||--o{ PAYMENTS : makes
    PAYMENTS ||--o{ PAYMENT_BILL_ITEMS : allocates
    STUDENT_BILLS ||--o{ PAYMENT_BILL_ITEMS : paid_by

    STAFF ||--o{ HEAD_JOURNALS : creates
    HEAD_JOURNALS ||--o{ HEAD_JOURNAL_ACTIVITIES : contains
    HEAD_ACTIVITY_CATALOG ||--o{ HEAD_JOURNAL_ACTIVITIES : selected

    PROFILES ||--o{ FILES : uploads
    FILES ||--o{ FILE_ATTACHMENTS : attached
    PROFILES ||--o{ AUDIT_LOGS : changes
```

## Relasi Utama

### Akun Orang Tua

```text
auth.users
    ↓
profiles
    ↓
guardians
    ↓
guardian_students
    ↓
students
```

### Pengasuhan

```text
staff
    ↓
caregiver_assignments
    ↓
care_groups
    ↓
care_group_members
    ↓
students
```

### Tahfiz

```text
staff
    ↓
tahfiz_supervisor_assignments
    ↓
tahfiz_groups
    ↓
tahfiz_group_members
    ↓
students
```

### Laporan Tahfiz

```text
tahfiz_report_batches
    ↓
tahfiz_weekly_reports
    ↓
students
```

### Klinik Tahsin

```text
tahfiz_weekly_reports
    ↓
tahsin_cases
    ↓
tahsin_sessions
    ↓
tahsin_session_diagnoses
```

Klinik Tahsin hanya dapat diakses secara internal.

### Pembayaran Beberapa Bulan

```text
payments
    ↓
payment_bill_items
    ↓
student_bills
```

Satu pembayaran dapat melunasi beberapa tagihan bulanan.