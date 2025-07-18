# 🔁 Subject Change Request System – SQL Project (Extension)

This SQL project extends the Student Subject Allotment System by adding functionality for students to request a subject change after initial allotment. It handles student reallocation based on availability and ensures consistent updates across all related tables.

---

## 📚 Overview

Students may wish to change their allotted subjects based on evolving interests or availability. This system processes such requests by:

- Capturing new subject requests from students
- Verifying seat availability in the requested subject
- Updating current and previous subject allocations
- Ensuring data consistency across all subject-related tables

---

## ⚙️ Components

### 🔸 Tables Created

1. **SubjectRequest**  
   - Captures student requests for new subjects

2. **SubjectAllotments**  
   - Shows all subjects attempted or allotted to students, along with an `Is_valid` status to indicate the current allotment

---

### 🔸 Stored Procedures

1. **`Students_Request`**
   - Inserts a new subject change request into the `SubjectRequest` table

2. **`Subject_Allotments`**
   - Aggregates all existing student-subject records
   - Marks current allotments with `Is_valid = 1`

3. **`update_allotments`**
   - Processes subject change requests one by one using a cursor
   - Validates seat availability
   - Updates:
     - `SubjectAllotments` table (new and old subjects)
     - `SubjectDetails` seat counts
     - `Allotments` master table

---

## 🧠 Logic Summary

- Each student can request a subject change by providing their ID and new Subject ID.
- If:
  - Seats are available in the requested subject
  - Requested subject is different from current allotment
- Then:
  - The old subject is released (seats incremented)
  - The new subject is allotted (seats decremented)
  - Master tables are updated accordingly
- If the student was not previously allotted any subject:
  - The new subject is directly allotted (if seats are available)

---

## ▶️ Example Execution

```sql
-- Student places request
EXEC Students_Request '159103062', 'PO1493';

-- Generate baseline subject allotments from old data
EXEC Subject_Allotments;

-- Process all change requests
EXEC update_allotments;
