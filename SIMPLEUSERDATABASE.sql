

-- Create the database
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- Table: users
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: products
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0
);

-- Table: orders
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Table: order_items
CREATE TABLE order_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- VIEW: Show order summaries
CREATE VIEW order_summary AS
    SELECT 
        o.order_id,
        u.name AS customer_name,
        SUM(p.price * oi.quantity) AS total_value,
        o.order_date
    FROM
        orders o
            JOIN
        users u ON o.user_id = u.user_id
            JOIN
        order_items oi ON o.order_id = oi.order_id
            JOIN
        products p ON oi.product_id = p.product_id
    GROUP BY o.order_id , u.name , o.order_date;

-- TRIGGER: Automatically decrease stock when a new order item is inserted
DELIMITER //
CREATE TRIGGER update_stock_after_order
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE product_id = NEW.product_id;
END;
//
DELIMITER ;

-- STORED PROCEDURE: Register a new order
DELIMITER //
CREATE PROCEDURE make_order(
    IN userId INT,
    IN productId INT,
    IN qty INT
)
BEGIN
    DECLARE new_order_id INT;

    -- 1. Create order
    INSERT INTO orders (user_id) VALUES (userId);
    SET new_order_id = LAST_INSERT_ID();

    -- 2. Insert product in order_items
    INSERT INTO order_items (order_id, product_id, quantity)
    VALUES (new_order_id, productId, qty);

    -- 3. Confirm
    SELECT CONCAT('Order #', new_order_id, ' created successfully!') AS message;
END;
//
DELIMITER ;

-- Example data
INSERT INTO users (name, email) VALUES ('Sophia', 'sophia@example.com');
INSERT INTO products (name, price, stock) VALUES ('Headphones', 250.00, 10);

-- Run the stored procedure
CALL make_order(1, 1, 2);

-- View order summaries
SELECT * FROM order_summary;
