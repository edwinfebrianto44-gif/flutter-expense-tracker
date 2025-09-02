-- MySQL Schema & Seed for Expense Tracker
-- Requirement: users, categories, transactions with relations, index on transactions.trans_date, >=20 dummy rows each table
-- Safe to run on a fresh database. DO NOT run on production without review.

SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- Optionally create database (uncomment if needed)
-- CREATE DATABASE IF NOT EXISTS expense_tracker CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE expense_tracker;

DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(120) NOT NULL,
  password_hash VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_users_username (username),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  type ENUM('income','expense') NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_categories_name_type (name, type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE transactions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
  description VARCHAR(255) NULL,
  trans_date DATE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  KEY idx_transactions_trans_date (trans_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==================== SEED DATA ====================
-- Users (20 rows)
INSERT INTO users (id, username, email, password_hash, created_at) VALUES
 (1,'alice','alice@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ2','2025-01-01 00:00:00'),
 (2,'bob','bob@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ3','2025-01-02 00:00:00'),
 (3,'charlie','charlie@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ4','2025-01-03 00:00:00'),
 (4,'diana','diana@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ5','2025-01-04 00:00:00'),
 (5,'erik','erik@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ6','2025-01-05 00:00:00'),
 (6,'fiona','fiona@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ7','2025-01-06 00:00:00'),
 (7,'george','george@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ8','2025-01-07 00:00:00'),
 (8,'hannah','hannah@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ9','2025-01-08 00:00:00'),
 (9,'ivan','ivan@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ10','2025-01-09 00:00:00'),
 (10,'julia','julia@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ11','2025-01-10 00:00:00'),
 (11,'kevin','kevin@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ12','2025-01-11 00:00:00'),
 (12,'lisa','lisa@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ13','2025-01-12 00:00:00'),
 (13,'michael','michael@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ14','2025-01-13 00:00:00'),
 (14,'nina','nina@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ15','2025-01-14 00:00:00'),
 (15,'oscar','oscar@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ16','2025-01-15 00:00:00'),
 (16,'paula','paula@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ17','2025-01-16 00:00:00'),
 (17,'quentin','quentin@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ18','2025-01-17 00:00:00'),
 (18,'rachel','rachel@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ19','2025-01-18 00:00:00'),
 (19,'steve','steve@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ20','2025-01-19 00:00:00'),
 (20,'tina','tina@example.com','$2y$10$abcdefghijklmnopqrstuvCjzv7xWFu1oH0DuNQ21','2025-01-20 00:00:00');

-- Categories (20 rows: 10 income, 10 expense)
INSERT INTO categories (id, name, type, created_at) VALUES
 (1,'Salary','income','2025-01-01 00:00:00'),
 (2,'Bonus','income','2025-01-01 00:00:00'),
 (3,'Freelance','income','2025-01-01 00:00:00'),
 (4,'Dividends','income','2025-01-01 00:00:00'),
 (5,'Interest','income','2025-01-01 00:00:00'),
 (6,'Rental Income','income','2025-01-01 00:00:00'),
 (7,'Gift Income','income','2025-01-01 00:00:00'),
 (8,'Refund','income','2025-01-01 00:00:00'),
 (9,'Sale','income','2025-01-01 00:00:00'),
 (10,'Investment Gain','income','2025-01-01 00:00:00'),
 (11,'Food','expense','2025-01-01 00:00:00'),
 (12,'Transport','expense','2025-01-01 00:00:00'),
 (13,'Housing','expense','2025-01-01 00:00:00'),
 (14,'Utilities','expense','2025-01-01 00:00:00'),
 (15,'Entertainment','expense','2025-01-01 00:00:00'),
 (16,'Health','expense','2025-01-01 00:00:00'),
 (17,'Education','expense','2025-01-01 00:00:00'),
 (18,'Insurance','expense','2025-01-01 00:00:00'),
 (19,'Taxes','expense','2025-01-01 00:00:00'),
 (20,'Travel','expense','2025-01-01 00:00:00');

-- Transactions (>=20 rows)
INSERT INTO transactions (id, user_id, category_id, amount, description, trans_date, created_at) VALUES
 (1,1,1,5000.00,'Monthly salary','2025-02-01','2025-02-01 08:00:00'),
 (2,1,11,15.50,'Breakfast','2025-02-01','2025-02-01 09:00:00'),
 (3,2,12,3.20,'Bus ticket','2025-02-01','2025-02-01 09:05:00'),
 (4,2,2,300.00,'Quarter bonus','2025-02-02','2025-02-02 10:00:00'),
 (5,3,11,8.90,'Lunch','2025-02-02','2025-02-02 12:30:00'),
 (6,4,15,25.00,'Cinema','2025-02-03','2025-02-03 20:00:00'),
 (7,5,16,60.00,'Medical check','2025-02-03','2025-02-03 14:00:00'),
 (8,6,3,420.00,'Freelance project','2025-02-04','2025-02-04 18:00:00'),
 (9,7,11,12.75,'Dinner','2025-02-04','2025-02-04 19:00:00'),
 (10,8,17,120.00,'Online course','2025-02-05','2025-02-05 10:00:00'),
 (11,9,13,950.00,'Rent','2025-02-05','2025-02-05 09:00:00'),
 (12,10,14,110.40,'Electricity + Water','2025-02-06','2025-02-06 11:00:00'),
 (13,11,18,70.00,'Insurance premium','2025-02-06','2025-02-06 08:30:00'),
 (14,12,4,150.00,'Dividend payout','2025-02-07','2025-02-07 07:00:00'),
 (15,13,19,400.00,'Quarterly taxes','2025-02-07','2025-02-07 13:00:00'),
 (16,14,20,350.00,'Weekend trip','2025-02-08','2025-02-08 06:00:00'),
 (17,15,5,35.00,'Interest income','2025-02-08','2025-02-08 09:15:00'),
 (18,16,6,800.00,'Apartment rent received','2025-02-09','2025-02-09 12:00:00'),
 (19,17,7,50.00,'Birthday gift cash','2025-02-09','2025-02-09 15:00:00'),
 (20,18,8,45.00,'Product refund','2025-02-10','2025-02-10 11:45:00'),
 (21,19,9,200.00,'Old bike sale','2025-02-10','2025-02-10 16:20:00'),
 (22,20,10,95.00,'Investment gain','2025-02-11','2025-02-11 17:00:00');

-- Verify counts (optional)
-- SELECT 'users' tbl, COUNT(*) FROM users UNION ALL SELECT 'categories', COUNT(*) FROM categories UNION ALL SELECT 'transactions', COUNT(*) FROM transactions;

-- End of schema & seed
