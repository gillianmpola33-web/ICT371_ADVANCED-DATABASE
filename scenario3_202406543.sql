DROP TABLE IF EXISTS exam_registrations CASCADE;
DROP TABLE IF EXISTS exams CASCADE;

CREATE TABLE exams (
    exam_id SERIAL PRIMARY KEY,
    exam_name VARCHAR(100),
    available_seats INT
);

CREATE TABLE exam_registrations (
    registration_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    exam_id INT REFERENCES exams(exam_id),
    seats_reserved INT,
    status VARCHAR(20)
);

INSERT INTO exams (exam_name, available_seats)
VALUES ('Database Exam', 10),
       ('Networking Exam', 5),
       ('AI Exam', 2);

DO $$
DECLARE seats INT;
BEGIN
    SELECT available_seats INTO seats FROM exams WHERE exam_name='AI Exam';
    IF seats = 0 THEN
        RAISE NOTICE 'No seats available';
    ELSIF seats = 1 THEN
        RAISE NOTICE 'Only one seat left';
    ELSE
        RAISE NOTICE 'Seats available';
    END IF;
END;
$$;

DO $$
DECLARE i INT := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE '%', 'Reminder ' || i || ': Confirm your exam registration';
        i := i + 1;
    END LOOP;
END;
$$;

DO $$
BEGIN
    FOR i IN 1..3 LOOP
        RAISE NOTICE '%', 'Exam schedule slot ' || i;
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE register_exam(p_student VARCHAR, p_exam INT, p_seats INT)
LANGUAGE plpgsql AS $$
DECLARE seats INT;
BEGIN
    IF p_seats <= 0 THEN
        RAISE EXCEPTION 'Invalid seat number';
    END IF;

    SELECT available_seats INTO seats FROM exams WHERE exam_id = p_exam;

    IF seats >= p_seats THEN
        UPDATE exams SET available_seats = available_seats - p_seats WHERE exam_id = p_exam;
        INSERT INTO exam_registrations(student_number, exam_id, seats_reserved, status)
        VALUES (p_student, p_exam, p_seats, 'Registered');
    ELSE
        RAISE NOTICE 'Not enough seats available';
    END IF;
END;
$$;

CALL register_exam('STU201', 1, 2);
CALL register_exam('STU202', 2, 5);
CALL register_exam('STU203', 3, 5);

CREATE OR REPLACE PROCEDURE cancel_registration(p_registration INT)
LANGUAGE plpgsql AS $$
DECLARE r_status VARCHAR(20);
        r_exam INT;
        r_seats INT;
BEGIN
    SELECT status, exam_id, seats_reserved INTO r_status, r_exam, r_seats
    FROM exam_registrations WHERE registration_id = p_registration;

    IF r_status = 'Registered' THEN
        UPDATE exams SET available_seats = available_seats + r_seats WHERE exam_id = r_exam;
        UPDATE exam_registrations SET status = 'Cancelled' WHERE registration_id = p_registration;
    ELSE
        RAISE NOTICE 'Registration already cancelled';
    END IF;
END;
$$;

DO $$
DECLARE
    cur_exams CURSOR FOR SELECT exam_name, available_seats FROM exams WHERE available_seats <= 1;
    rec RECORD;
BEGIN
    OPEN cur_exams;
    LOOP
        FETCH cur_exams INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE '%', 'Exam: ' || rec.exam_name || ', Seats left: ' || rec.available_seats;
    END LOOP;
    CLOSE cur_exams;
END;
$$;

DO $$
BEGIN
    CALL register_exam('STU204', 1, 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Handled expected error: %', SQLERRM;
END;
$$;

SELECT * FROM exams;
SELECT * FROM exam_registrations;
