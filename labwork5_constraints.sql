-- LabWork5: Database Constraints - PostgreSQL
-- Student: Noor Mohammad Shirzad
-- Course: Database
-- Objective: Practice implementing and testing constraints in PostgreSQL


-- PART 1: CHECK CONSTRAINTS


-- Task 1.1: Basic CHECK Constraint
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

-- Valid Inserts
INSERT INTO employees (first_name, last_name, age, salary) VALUES ('Ali', 'Khan', 30, 50000);
INSERT INTO employees (first_name, last_name, age, salary) VALUES ('Sara', 'Noor', 45, 60000);

-- Invalid Inserts (will fail due to CHECK constraint)
-- INSERT INTO employees (first_name, last_name, age, salary) VALUES ('John', 'Doe', 17, 40000); -- age < 18
-- INSERT INTO employees (first_name, last_name, age, salary) VALUES ('Jane', 'Smith', 25, -1000); -- salary < 0


-- Task 1.2: Named CHECK Constraint
CREATE TABLE products_catalog (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND discount_price > 0 AND discount_price < regular_price
    )
);

-- Valid Inserts
INSERT INTO products_catalog (product_name, regular_price, discount_price) VALUES ('Laptop', 1500, 1200);
INSERT INTO products_catalog (product_name, regular_price, discount_price) VALUES ('Mouse', 50, 35);

-- Invalid Inserts
-- INSERT INTO products_catalog (product_name, regular_price, discount_price) VALUES ('Keyboard', -20, 10); -- regular_price invalid
-- INSERT INTO products_catalog (product_name, regular_price, discount_price) VALUES ('Monitor', 200, 250); -- discount_price > regular_price


-- Task 1.3: Multiple Column CHECK
CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

-- Valid Inserts
INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES ('2025-10-01', '2025-10-05', 3);
INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES ('2025-11-10', '2025-11-15', 2);

-- Invalid Inserts
-- INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES ('2025-10-10', '2025-10-08', 2); -- invalid date order
-- INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES ('2025-09-01', '2025-09-05', 15); -- num_guests > 10



-- PART 2: NOT NULL CONSTRAINTS


CREATE TABLE customers (
    customer_id SERIAL NOT NULL PRIMARY KEY,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

-- Valid
INSERT INTO customers (email, phone, registration_date) VALUES ('ali@example.com', '123456789', '2025-01-01');

-- Invalid (NULL in NOT NULL fields)
-- INSERT INTO customers (email, registration_date) VALUES (NULL, '2025-01-01'); -- email is NOT NULL


CREATE TABLE inventory (
    item_id SERIAL NOT NULL PRIMARY KEY,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO inventory (item_name, quantity, unit_price, last_updated)
VALUES ('Pen', 100, 2.5, NOW());

-- Invalid
-- INSERT INTO inventory (item_name, quantity, unit_price, last_updated)
-- VALUES ('Pencil', -5, 1.0, NOW()); -- quantity < 0



-- PART 3: UNIQUE CONSTRAINTS


CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Valid Inserts
INSERT INTO users (username, email, created_at) VALUES ('noor', 'noor@gmail.com', NOW());
INSERT INTO users (username, email, created_at) VALUES ('ali', 'ali@gmail.com', NOW());

-- Invalid (duplicate username/email)
-- INSERT INTO users (username, email, created_at) VALUES ('noor', 'another@gmail.com', NOW());
-- INSERT INTO users (username, email, created_at) VALUES ('userx', 'ali@gmail.com', NOW());


-- Multi-column UNIQUE
CREATE TABLE course_enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);

-- Named UNIQUE constraints
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);



-- PART 4: PRIMARY KEY CONSTRAINTS


CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments (dept_name, location) VALUES ('IT', 'Almaty');
INSERT INTO departments (dept_name, location) VALUES ('HR', 'Astana');
INSERT INTO departments (dept_name, location) VALUES ('Finance', 'Almaty');

-- Invalid
-- INSERT INTO departments (dept_id, dept_name) VALUES (1, 'Marketing'); -- duplicate dept_id


CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);



-- PART 5: FOREIGN KEY CONSTRAINTS


CREATE TABLE employees_dept (
    emp_id SERIAL PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

-- Valid
INSERT INTO employees_dept (emp_name, dept_id, hire_date) VALUES ('Zahir', 1, '2025-01-01');

-- Invalid
-- INSERT INTO employees_dept (emp_name, dept_id, hire_date) VALUES ('Kamal', 99, '2025-01-02'); -- dept_id not found


-- Library Schema with Multiple Foreign Keys
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id SERIAL PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);


-- ON DELETE behaviors
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);



-- PART 6: PRACTICAL APPLICATION (E-COMMERCE)


CREATE TABLE customers_ecom (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products_ecom (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ecom (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers_ecom(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC,
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details_ecom (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_ecom(product_id),
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC
);

-- Sample Inserts
INSERT INTO customers_ecom (name, email, phone, registration_date) VALUES
('Ali Khan', 'ali@shop.com', '123456789', '2025-01-01'),
('Sara Noor', 'sara@shop.com', '987654321', '2025-01-02');

INSERT INTO products_ecom (name, description, price, stock_quantity) VALUES
('Laptop', 'Gaming laptop', 1500, 10),
('Mouse', 'Wireless mouse', 30, 50),
('Keyboard', 'Mechanical keyboard', 80, 20);

INSERT INTO orders_ecom (customer_id, order_date, total_amount, status) VALUES
(1, '2025-01-05', 1530, 'shipped'),
(2, '2025-01-06', 110, 'pending');

INSERT INTO order_details_ecom (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1500),
(1, 2, 1, 30),
(2, 3, 1, 80);

-- End of LabWork5
