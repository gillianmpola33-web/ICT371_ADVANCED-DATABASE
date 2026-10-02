DROP TABLE IF EXISTS course_registrations CASCADE;
DROP TABLE IF EXISTS courses CASCADE;

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100),
    available_slots INT
);

CREATE TABLE course_registrations (
    registration_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    course_id INT REFERENCES courses(course_id),
    slots_reserved INT,
    status VARCHAR(20)
);

INSERT INTO courses (course_name, available_slots)
VALUES ('Database Systems', 20),
       ('Computer Networks', 15),
       ('Artificial Intelligence', 5);

DO $$
DECLARE slots INT;
BEGIN
    SELECT available_slots INTO slots FROM courses WHERE course_name='Artificial Intelligence';
    IF slots = 0 THEN
        RAISE NOTICE 'No slots available';
    ELSIF slots = 1 THEN
        RAISE NOTICE 'Only one slot left';
    ELSE
        RAISE NOTICE 'Slots available';
    END IF;
END;
$$;

DO $$
DECLARE i INT := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE '%', 'Reminder ' || i || ': Confirm your course registration';
        i := i + 1;
    END LOOP;
END;
$$;

DO $$
BEGIN
    FOR i IN 1..3 LOOP
        RAISE NOTICE '%', 'Course schedule slot ' || i;
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE register_course(p_student VARCHAR, p_course INT, p_slots INT)
LANGUAGE plpgsql AS $$
DECLARE slots INT;
BEGIN
    IF p_slots <= 0 THEN
        RAISE EXCEPTION 'Invalid slot number';
    END IF;

    SELECT available_slots INTO slots FROM courses WHERE course_id = p_course;

    IF slots >= p_slots THEN
        UPDATE courses SET available_slots = available_slots - p_slots WHERE course_id = p_course;
        INSERT INTO course_registrations(student_number, course_id, slots_reserved, status)
        VALUES (p_student, p_course, p_slots, 'Registered');
    ELSE
        RAISE NOTICE 'Not enough slots available';
    END IF;
END;
$$;

CALL register_course('STU301', 1, 2);
CALL register_course('STU302', 2, 10);
CALL register_course('STU303', 3, 6);

CREATE OR REPLACE PROCEDURE cancel_course_registration(p_registration INT)
LANGUAGE plpgsql AS $$
DECLARE r_status VARCHAR(20);
        r_course INT;
        r_slots INT;
BEGIN
    SELECT status, course_id, slots_reserved INTO r_status, r_course, r_slots
    FROM course_registrations WHERE registration_id = p_registration;

    IF r_status = 'Registered' THEN
        UPDATE courses SET available_slots = available_slots + r_slots WHERE course_id = r_course;
        UPDATE course_registrations SET status = 'Cancelled' WHERE registration_id = p_registration;
    ELSE
        RAISE NOTICE 'Registration already cancelled';
    END IF;
END;
$$;

DO $$
DECLARE
    cur_courses CURSOR FOR SELECT course_name, available_slots FROM courses WHERE available_slots <= 1;
    rec RECORD;
BEGIN
    OPEN cur_courses;
    LOOP
        FETCH cur_courses INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE '%', 'Course: ' || rec.course_name || ', Slots left: ' || rec.available_slots;
    END LOOP;
    CLOSE cur_courses;
END;
$$;

DO $$
BEGIN
    CALL register_course('STU304', 1, 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Handled expected error: %', SQLERRM;
END;
$$;

SELECT * FROM courses;
SELECT * FROM course_registrations;
