-- ============================================================
-- Workshop Booking System Database
-- BCS 306 - Database Management Systems | FA 2025-26
-- Canadian University Dubai
-- ============================================================

CREATE DATABASE IF NOT EXISTS project;
USE project;

-- ============================================================
-- TABLE DEFINITIONS
-- ============================================================

CREATE TABLE students (
    std_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gpa DOUBLE,
    credit_hours INT,
    major VARCHAR(50),
    seniority INT,
    phone INT,
    std_mail VARCHAR(256),
    group_id INT
);

CREATE TABLE std_address (
    std_id INT,
    std_city VARCHAR(50),
    std_street VARCHAR(50),
    std_villa_apt VARCHAR(50),
    FOREIGN KEY (std_id) REFERENCES students (std_id)
);

CREATE TABLE Groups_ (
    group_id INT PRIMARY KEY,
    number_in INT
);

CREATE TABLE leader (
    group_id INT PRIMARY KEY,
    leader_id INT UNIQUE,
    FOREIGN KEY (group_id) REFERENCES Groups_ (group_id),
    FOREIGN KEY (leader_id) REFERENCES students (std_id)
);

CREATE TABLE workshops (
    workshop_id INT PRIMARY KEY,
    department VARCHAR(50),
    time_span INT
);

CREATE TABLE time_slots (
    workshop_id INT,
    time_slot_id INT PRIMARY KEY AUTO_INCREMENT,
    slot_date DATE,
    start_time TIME,
    end_time TIME,
    max_capacity INT,
    room_num INT,
    building VARCHAR(50),
    FOREIGN KEY (workshop_id) REFERENCES workshops (workshop_id)
);

CREATE TABLE bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    std_id INT,
    workshop_id INT,
    seats_taken INT,
    time_slot_id INT,
    availability ENUM ('yes', 'no'),
    booking_status ENUM('pending', 'confirmed', 'cancelled', 'waitlisted'),
    FOREIGN KEY (std_id) REFERENCES students (std_id),
    FOREIGN KEY (workshop_id) REFERENCES workshops (workshop_id),
    FOREIGN KEY (time_slot_id) REFERENCES time_slots (time_slot_id),
    CONSTRAINT uniq_student_slot UNIQUE (std_id, time_slot_id)
);

CREATE TABLE instructors (
    inst_id INT PRIMARY KEY,
    inst_Fname VARCHAR(50),
    inst_Lname VARCHAR(50),
    inst_phone INT,
    inst_mail VARCHAR(256)
);

CREATE TABLE teaches (
    inst_id INT,
    workshop_id INT,
    FOREIGN KEY (inst_id) REFERENCES instructors (inst_id),
    FOREIGN KEY (workshop_id) REFERENCES workshops (workshop_id)
);

CREATE TABLE inst_address (
    inst_id INT,
    inst_city VARCHAR(50),
    inst_street VARCHAR(50),
    inst_villa_apt VARCHAR(50),
    FOREIGN KEY (inst_id) REFERENCES instructors (inst_id)
);

CREATE TABLE facilities (
    workshop_id INT,
    room_num INT,
    building VARCHAR(50),
    PRIMARY KEY (room_num, building)
);

-- ============================================================
-- ALTER STATEMENTS (constraints added after table creation)
-- ============================================================

ALTER TABLE facilities ADD CONSTRAINT workshop FOREIGN KEY (workshop_id) REFERENCES workshops(workshop_id);
ALTER TABLE students ADD CONSTRAINT students_group FOREIGN KEY (group_id) REFERENCES Groups_ (group_id);
ALTER TABLE time_slots ADD CONSTRAINT location FOREIGN KEY (room_num, building) REFERENCES facilities (room_num, building);
ALTER TABLE std_address ADD PRIMARY KEY (std_id, std_city, std_street, std_villa_apt);
ALTER TABLE inst_address ADD PRIMARY KEY (inst_id, inst_city, inst_street, inst_villa_apt);
ALTER TABLE teaches ADD PRIMARY KEY (inst_id, workshop_id);

-- ============================================================
-- TRIGGER: Prevent overbooking beyond 40 students per slot
-- ============================================================

DELIMITER //
CREATE TRIGGER check_before_insert
BEFORE INSERT ON bookings FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*)
        FROM bookings
        WHERE time_slot_id = NEW.time_slot_id) >= 40 THEN

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Maximum of 40 students reached for this time slot.';
    END IF;
END;//
DELIMITER ;

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

-- Popular workshops (total seats > 30)
DELIMITER //
CREATE PROCEDURE get_famous()
BEGIN
    SELECT workshop_id, SUM(seats_taken) AS total_seats
    FROM bookings
    GROUP BY workshop_id
    HAVING SUM(seats_taken) > 30;
END;//
DELIMITER ;

-- Booking history for a specific student
DELIMITER //
CREATE PROCEDURE get_student_history(IN p_std_id INT)
BEGIN
    SELECT booking_id, workshop_id, time_slot_id, seats_taken, booking_status, availability
    FROM bookings
    WHERE std_id = p_std_id;
END//
DELIMITER ;

-- Full booking history (all records)
DELIMITER //
CREATE PROCEDURE get_booking_history()
BEGIN
    SELECT booking_id, std_id, workshop_id, time_slot_id, seats_taken, booking_status, availability
    FROM bookings
    ORDER BY booking_id;
END//
DELIMITER ;

-- Group registration tracking
DELIMITER //
CREATE PROCEDURE get_reg_trackk(IN p_group_id INT)
BEGIN
    SELECT std.group_id, std.std_id, std.first_name, std.last_name,
           bkng.booking_id, bkng.workshop_id, bkng.time_slot_id,
           bkng.seats_taken, bkng.booking_status, bkng.availability
    FROM students std
    LEFT JOIN bookings bkng ON std.std_id = bkng.std_id
    WHERE std.group_id = p_group_id
    ORDER BY std.std_id, bkng.booking_id;
END//
DELIMITER ;

-- Workshop demand analysis
DELIMITER //
CREATE PROCEDURE get_demand_analysis()
BEGIN
    SELECT
        workshop_id,
        COUNT(*)         AS num_bookings,
        SUM(seats_taken) AS total_seats,
        AVG(seats_taken) AS avg_seats_per_booking
    FROM bookings
    GROUP BY workshop_id
    ORDER BY total_seats DESC;
END//
DELIMITER ;

-- Booking trends by status
DELIMITER //
CREATE PROCEDURE get_booking_trends()
BEGIN
    SELECT booking_status, COUNT(*) AS num_bookings, SUM(seats_taken) AS total_seats
    FROM bookings
    GROUP BY booking_status;
END//
DELIMITER ;

-- Peak usage time slots
DELIMITER //
CREATE PROCEDURE get_peak_usage()
BEGIN
    SELECT time_slot_id, SUM(seats_taken) AS total_seats
    FROM bookings
    GROUP BY time_slot_id
    ORDER BY total_seats DESC;
END//
DELIMITER ;

-- Student participation tracking
DELIMITER //
CREATE PROCEDURE get_student_participationn()
BEGIN
    SELECT std_id, COUNT(*) AS num_bookings
    FROM bookings
    GROUP BY std_id
    ORDER BY num_bookings DESC;
END//
DELIMITER ;

-- Available slots (seats remaining > 0)
DELIMITER //
CREATE PROCEDURE slots_avlb()
BEGIN
    SELECT w.workshop_id, w.department, w.time_span,
           slot.slot_date, slot.start_time, slot.end_time,
           slot.time_slot_id, slot.room_num, slot.building,
           (slot.max_capacity - SUM(b.seats_taken)) AS avlb_seats
    FROM workshops w
    JOIN time_slots slot ON w.workshop_id = slot.workshop_id
    LEFT JOIN bookings b ON b.time_slot_id = slot.time_slot_id
    GROUP BY slot.time_slot_id
    HAVING avlb_seats > 0
    ORDER BY slot.slot_date ASC;
END//
DELIMITER ;

-- Slots with seats taken
DELIMITER //
CREATE PROCEDURE slots_taken()
BEGIN
    SELECT w.workshop_id, w.department, w.time_span,
           slot.slot_date, slot.start_time, slot.end_time,
           slot.time_slot_id, slot.room_num, slot.building,
           IFNULL(SUM(b.seats_taken), 0) AS seats_taken
    FROM workshops w
    JOIN time_slots slot ON w.workshop_id = slot.workshop_id
    LEFT JOIN bookings b ON b.time_slot_id = slot.time_slot_id
    GROUP BY w.workshop_id, w.department, w.time_span,
             slot.slot_date, slot.start_time, slot.end_time,
             slot.time_slot_id, slot.room_num, slot.building
    ORDER BY slot.slot_date ASC;
END//
DELIMITER ;

-- Booking rate (% capacity filled per slot)
DELIMITER //
CREATE PROCEDURE booking_rate()
BEGIN
    SELECT w.workshop_id, w.department, slot.slot_date, slot.max_capacity,
           SUM(b.seats_taken) AS booked,
           ROUND((IFNULL(SUM(b.seats_taken), 0) / slot.max_capacity) * 100, 0) AS booking_percent
    FROM workshops w
    JOIN time_slots slot ON w.workshop_id = slot.workshop_id
    LEFT JOIN bookings b ON b.time_slot_id = slot.time_slot_id
    GROUP BY w.workshop_id, w.department, slot.slot_date, slot.max_capacity
    ORDER BY slot.slot_date ASC;
END//
DELIMITER ;

-- ============================================================
-- SAMPLE PROCEDURE CALLS
-- ============================================================

CALL get_famous();
CALL get_student_history(103);
CALL get_booking_history();
CALL get_reg_trackk(4);
CALL get_demand_analysis();
CALL get_booking_trends();
CALL get_peak_usage();
CALL get_student_participationn();
CALL slots_avlb();
CALL slots_taken();
CALL booking_rate();
