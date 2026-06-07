# Workshop Booking System — MySQL Database

A relational database system for managing educational workshop registrations, designed and implemented for BCS 306 (Database Management Systems) at Canadian University Dubai.

---

## Repository Name

`workshop-booking-db`

## Description

> MySQL database for a university workshop booking system — supports group reservations, real-time capacity control, waitlisting, and administrative analytics via stored procedures and triggers.

---

## Project Overview

This system acts as a centralized platform for managing workshop bookings in an educational environment. It handles both individual and group reservations, enforces strict capacity limits through database-level triggers, and provides rich reporting through stored procedures.

**Course:** BCS 306 – Database Management Systems | FA 2025-26  
**Institution:** Canadian University Dubai  
**Tool:** MySQL Workbench

---

## Features

- Group and individual booking management with leader assignment
- Automatic overbooking prevention via `BEFORE INSERT` trigger
- Booking lifecycle tracking: `pending → confirmed → cancelled → waitlisted`
- Real-time slot availability and utilization reporting
- Double-booking prevention through a `UNIQUE` constraint on `(std_id, time_slot_id)`
- Fully normalized schema (1NF → 2NF → 3NF)
- 11 stored procedures covering operational and analytical queries

---

## Database Schema

### Tables

| Table | Description |
|---|---|
| `students` | Student profiles and academic information |
| `std_address` | Student addresses (normalized, separate table) |
| `Groups_` | Group metadata and member count |
| `leader` | One-to-one mapping of group leaders |
| `workshops` | Workshop offerings by department |
| `time_slots` | Scheduled sessions with capacity and room info |
| `bookings` | Reservation records with status and availability |
| `instructors` | Facilitator profiles |
| `teaches` | Many-to-many junction table (instructors ↔ workshops) |
| `inst_address` | Instructor addresses (normalized) |
| `facilities` | Room and building allocations |

### Key Relationships

- `Students` → `Groups_` : Many-to-one
- `Students` → `Bookings` : One-to-many
- `Workshops` → `Time Slots` : One-to-many
- `Workshops` ↔ `Instructors` : Many-to-many (via `teaches`)
- `Facilities` → `Time Slots` : One-to-many
- `Groups_` → `Leader` : One-to-one

---

## Stored Procedures

| Procedure | Purpose |
|---|---|
| `get_famous()` | Workshops with total seats booked > 30 |
| `get_student_history(p_std_id)` | Booking history for a specific student |
| `get_booking_history()` | Full booking log ordered by booking ID |
| `get_reg_trackk(p_group_id)` | Group registration tracker with booking details |
| `get_demand_analysis()` | Per-workshop booking count, total and avg seats |
| `get_booking_trends()` | Booking counts and seats grouped by status |
| `get_peak_usage()` | Time slots ranked by total seats taken |
| `get_student_participationn()` | Students ranked by number of bookings |
| `slots_avlb()` | Slots with remaining available seats |
| `slots_taken()` | Slots showing total seats occupied |
| `booking_rate()` | Booking fill percentage per slot |

---

## Trigger

**`check_before_insert`** — fires `BEFORE INSERT` on `bookings`. If a time slot already has 40 or more bookings, the insert is rejected with the error message:

```
Maximum of 40 students reached for this time slot.
```

---

## Normalization

The schema satisfies **Third Normal Form (3NF)**:

- **1NF:** All attributes are atomic with no repeating groups.
- **2NF:** Every non-key attribute is fully dependent on its table's primary key (no partial dependencies).
- **3NF:** No transitive dependencies — every attribute depends only on the primary key. Address data for students and instructors is stored in separate tables. Many-to-many relationships use junction tables (`teaches`).

Composite primary keys were added to `std_address`, `inst_address`, and `teaches` to eliminate any potential reliance on non-key attributes.

---

## Getting Started

### Prerequisites

- MySQL 8.0+ or MySQL Workbench
- A MySQL user with `CREATE`, `INSERT`, `EXECUTE` privileges

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/workshop-booking-db.git
   cd workshop-booking-db
   ```

2. Run the schema file in MySQL Workbench or via the CLI:
   ```bash
   mysql -u your_username -p < workshop_booking_system.sql
   ```

   The script automatically creates the `project` database and runs all table creation, constraints, triggers, and procedures.

3. Verify setup by calling a procedure:
   ```sql
   USE project;
   CALL get_booking_history();
   ```

---

## File Structure

```
workshop-booking-db/
├── workshop_booking_system.sql   # Full schema: tables, constraints, trigger, procedures
└── README.md
```

---

## Sample Data (from testing)

The system was tested with the following sample records:

- 5 students across 4 groups (`std_id` 101–105)
- 3 workshops: AI (301), Robotics (302), Engineering (303)
- 4 time slots across November–December 2025
- 6 bookings with statuses: confirmed, pending, cancelled
- Booking rate ranging from 45% to 98% capacity utilization

---

## Team

| Student ID | Name |
|---|---|
| 20210001983 | Leanne Jessica Rodrigo |
| 20220002458 | Aysha Ejaz |
| 20230003798 | Yasmin Issa |

**Instructor:** Dr. Sahil Garg  
**Course:** BCS 306 – Database Management Systems  
**Institution:** Canadian University Dubai
