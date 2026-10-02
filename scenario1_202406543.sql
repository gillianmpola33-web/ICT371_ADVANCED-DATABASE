DROP TABLE IF EXISTS book_loans CASCADE;
DROP TABLE IF EXISTS books CASCADE;

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100),
    available_copies INT
);

CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    book_id INT REFERENCES books(book_id),
    quantity INT,
    status VARCHAR(20)
);

INSERT INTO books (title, available_copies)
VALUES ('Database Systems', 3),
       ('Computer Networks', 2),
       ('AI Fundamentals', 1);

DO $$
DECLARE copies INT;
BEGIN
    SELECT available_copies INTO copies FROM books WHERE title='AI Fundamentals';
    IF copies = 0 THEN
        RAISE NOTICE 'Book unavailable';
    ELSIF copies = 1 THEN
        RAISE NOTICE 'Low on copies';
    ELSE
        RAISE NOTICE 'Sufficiently stocked';
    END IF;
END;
$$;

DO $$
DECLARE i INT := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE '%', 'Overdue reminder ' || i;
        i := i + 1;
    END LOOP;
END;
$$;

DO $$
BEGIN
    FOR i IN 1..3 LOOP
        RAISE NOTICE '%', 'Shelf number ' || i;
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE borrow_book(p_student VARCHAR, p_book INT, p_qty INT)
LANGUAGE plpgsql AS $$
DECLARE copies INT;
BEGIN
    IF p_qty <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity';
    END IF;

    SELECT available_copies INTO copies FROM books WHERE book_id = p_book;

    IF copies >= p_qty THEN
        UPDATE books SET available_copies = available_copies - p_qty WHERE book_id = p_book;
        INSERT INTO book_loans(student_number, book_id, quantity, status)
        VALUES (p_student, p_book, p_qty, 'Borrowed');
    ELSE
        RAISE NOTICE 'Not enough copies available';
    END IF;
END;
$$;

CALL borrow_book('STU001', 1, 1);
CALL borrow_book('STU002', 2, 2);
CALL borrow_book('STU003', 3, 5);

CREATE OR REPLACE PROCEDURE return_book(p_loan INT)
LANGUAGE plpgsql AS $$
DECLARE l_status VARCHAR(20);
        l_book INT;
        l_qty INT;
BEGIN
    SELECT status, book_id, quantity INTO l_status, l_book, l_qty
    FROM book_loans WHERE loan_id = p_loan;

    IF l_status = 'Borrowed' THEN
        UPDATE books SET available_copies = available_copies + l_qty WHERE book_id = l_book;
        UPDATE book_loans SET status = 'Returned' WHERE loan_id = p_loan;
    ELSE
        RAISE NOTICE 'Loan already returned';
    END IF;
END;
$$;

DO $$
DECLARE
    cur_books CURSOR FOR SELECT title, available_copies FROM books WHERE available_copies <= 1;
    rec RECORD;
BEGIN
    OPEN cur_books;
    LOOP
        FETCH cur_books INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE '%', 'Book: ' || rec.title || ', Copies left: ' || rec.available_copies;
    END LOOP;
    CLOSE cur_books;
END;
$$;

DO $$
BEGIN
CALL borrow_book('STU004', 1, 0);
 EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Handled expected error: %', SQLERRM;
END;
$$;

SELECT * FROM books;
SELECT * FROM book_loans;
