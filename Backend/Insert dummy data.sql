INSERT INTO Users (MailID, Name, Password, Role) VALUES
('admin@example.com', 'Admin', 'adminpassword', 'Admin'),
('user1@example.com', 'User One', 'userpassword1', 'Regular'),
('user2@example.com', 'User Two', 'userpassword2', 'Regular'),
('admin2@example.com', 'Admin Two', 'adminpassword2', 'Admin'),
('user3@example.com', 'User Three', 'userpassword3', 'Regular');

INSERT INTO Products (Name, Category, Cost, Selling_Price, Stock, Reorder_Level, Supplier_Info, Expiry_Date) VALUES
('Product A', 'Category 1', 10.00, 15.00, 100, 10, 'Supplier A', '2025-12-31'),
('Product B', 'Category 2', 20.00, 25.00, 50, 5, 'Supplier B', '2025-06-30'),
('Product C', 'Category 3', 30.00, 40.00, 200, 20, 'Supplier C', '2025-09-15'),
('Product D', 'Category 4', 5.00, 8.00, 500, 50, 'Supplier D', '2025-03-10'),
('Product E', 'Category 5', 12.00, 18.00, 150, 15, 'Supplier E', '2025-11-20');

INSERT INTO Customers (Name, Email, Phone, Address, Loyalty_Points) VALUES
('Customer One', 'customer1@example.com', '1234567890', 'Address 1', 100),
('Customer Two', 'customer2@example.com', '0987654321', 'Address 2', 200),
('Customer Three', 'customer3@example.com', '5678901234', 'Address 3', 300),
('Customer Four', 'customer4@example.com', '3456789012', 'Address 4', 150),
('Customer Five', 'customer5@example.com', '6789012345', 'Address 5', 250);

INSERT INTO Sales (ProductID, CustomerID, Date, Quantity, Total_Amount, Payment_Method) VALUES
(1, 1, '2024-12-25', 10, 150.00, 'Card'),
(2, 2, '2024-12-26', 5, 125.00, 'Online'),
(3, 3, '2024-12-27', 15, 600.00, 'Cash'),
(4, 4, '2024-12-28', 20, 160.00, 'Card'),
(5, 5, '2024-12-29', 12, 216.00, 'Online');

INSERT INTO Feedback (ProductID, CustomerID, Comments, Ratings) VALUES
(1, 1, 'Great quality product!', 5),
(2, 2, 'Good value for money.', 4),
(3, 3, 'Average experience.', 3),
(4, 4, 'Not satisfied with the quality.', 2),
(5, 5, 'Excellent product!', 5);