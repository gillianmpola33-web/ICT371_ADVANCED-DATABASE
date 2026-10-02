DROP TABLE IF EXISTS lab_reservations CASCADE;
DROP TABLE IF EXISTS labs CASCADE;

CREATE TABLE labs (
    lab_id SERIAL PRIMARY KEY,
    lab_name VARCHAR(50),
    available_slots INT
);

CREATE TABLE lab_reservations (
    reservation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    lab_id INT REFERENCES labs(lab_id),
    slots_reserved INT,
    status VARCHAR(20)
);

INSERT INTO labs (lab_name, available_slots)
VALUES ('Networking Lab', 5),
       ('Database Lab', 3),
       ('AI Lab', 2);

DO $$
DECLARE slots INT;
BEGIN
    SELECT available_slots INTO slots FROM labs WHERE lab_name='AI Lab';
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
        RAISE NOTICE '%', 'Reminder ' || i || ': Confirm your reservation';
        i := i + 1;
    END LOOP;
END;
$$;

DO $$
BEGIN
    FOR i IN 1..3 LOOP
        RAISE NOTICE '%', 'Lab schedule slot ' || i;
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE reserve_lab(p_student VARCHAR, p_lab INT, p_slots INT)
LANGUAGE plpgsql AS $$
DECLARE slots INT;
BEGIN
    IF p_slots <= 0 THEN
        RAISE EXCEPTION 'Invalid slot number';
    END IF;

    SELECT available_slots INTO slots FROM labs WHERE lab_id = p_lab;

    IF slots >= p_slots THEN
        UPDATE labs SET available_slots = available_slots - p_slots WHERE lab_id = p_lab;
        INSERT INTO lab_reservations(student_number, lab_id, slots_reserved, status)
        VALUES (p_student, p_lab, p_slots, 'Reserved');
    ELSE
        RAISE NOTICE 'Not enough slots available';
    END IF;
END;
$$;

CALL reserve_lab('STU101', 1, 2);
CALL reserve_lab('STU102', 2, 3);
CALL reserve_lab('STU103', 3, 5);

CREATE OR REPLACE PROCEDURE cancel_reservation(p_reservation INT)
LANGUAGE plpgsql AS $$
DECLARE r_status VARCHAR(20);
        r_lab INT;
        r_slots INT;
BEGIN
    SELECT status, lab_id, slots_reserved INTO r_status, r_lab, r_slots
    FROM lab_reservations WHERE reservation_id = p_reservation;

    IF r_status = 'Reserved' THEN
        UPDATE labs SET available_slots = available_slots + r_slots WHERE lab_id = r_lab;
        UPDATE lab_reservations SET status = 'Cancelled' WHERE reservation_id = p_reservation;
    ELSE
        RAISE NOTICE 'Reservation already cancelled';
    END IF;
END;
$$;

DO $$
DECLARE
    cur_labs CURSOR FOR SELECT lab_name, available_slots FROM labs WHERE available_slots <= 1;
    rec RECORD;
BEGIN
    OPEN cur_labs;
    LOOP
        FETCH cur_labs INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE '%', 'Lab: ' || rec.lab_name || ', Slots left: ' || rec.available_slots;
    END LOOP;
    CLOSE cur_labs;
END;
$$;

DO $$
BEGIN
    CALL reserve_lab('STU104', 1, 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Handled expected error: %', SQLERRM;
END;
$$;

SELECT * FROM labs;
SELECT * FROM lab_reservations;
