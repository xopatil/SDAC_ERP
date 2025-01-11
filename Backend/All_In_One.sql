-- Create tables------------------------------------------------------------
USE erp;

CREATE TABLE Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    MailID VARCHAR(255) NOT NULL UNIQUE,
    Name VARCHAR(255) NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Role ENUM('Admin', 'Regular') NOT NULL
);

CREATE TABLE Products (
    ProductID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Category VARCHAR(255) NOT NULL,
    Cost DECIMAL(10, 2) NOT NULL,
    Selling_Price DECIMAL(10, 2) NOT NULL,
    Stock INT,
    Reorder_Level INT,
    Supplier_Info VARCHAR(255),
    Expiry_Date DATE,
    Sales_Data TEXT
);

CREATE TABLE Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    Phone VARCHAR(15),
    Address TEXT,
    Purchase_History TEXT,
    Loyalty_Points INT DEFAULT 0 CONSTRAINT chk_loyalty_points_nonnegative CHECK (Loyalty_Points >= 0)
);

CREATE TABLE Sales (
    SaleID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NULL,
    CustomerID INT NOT NULL,
    Date DATE NOT NULL,
    Quantity INT CONSTRAINT chk_quantity_positive CHECK (Quantity > 0),
    Total_Amount DECIMAL(10, 2) ,
    Payment_Method ENUM('Cash', 'Card', 'Online') NOT NULL,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE SET NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Feedback (
    FeedbackID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    Comments TEXT,
    Ratings INT CHECK (Ratings BETWEEN 1 AND 5),
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    Response TEXT,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Logs (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    Algorithm_Name VARCHAR(255),
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    Results TEXT
);

-- Registration------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE RegisterUser(
    IN pMailID VARCHAR(255),
    IN pName VARCHAR(255),
    IN pPassword VARCHAR(255),
    IN pConfirmPassword VARCHAR(255),
    IN pRole ENUM('Admin', 'Regular')
)
BEGIN
    -- Validate email format
    IF pMailID NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SELECT 'Invalid email format.' AS Message;

    -- Check if passwords match
    ELSEIF pPassword <> pConfirmPassword THEN
        SELECT 'Passwords do not match.' AS Message;

    -- Check if the user already exists
    ELSEIF EXISTS (SELECT 1 FROM Users WHERE MailID = pMailID) THEN
        SELECT 'User already exists.' AS Message;

    ELSE
        -- Insert the new user
        INSERT INTO Users (MailID, Name, Password, Role)
        VALUES (pMailID, pName, SHA2(pPassword, 256), pRole);

        SELECT 'Registration successful.' AS Message;
    END IF;
END; //

call erp.RegisterUser('poonu34@gmail.com', 'poonu', '23', '23', 'regular');
delimiter //
CREATE TRIGGER After_User_Insert
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    -- Insert into Customers table only if the Role is 'Regular'
    IF NEW.Role = 'Regular' THEN
        INSERT INTO Customers (Email, Name, Loyalty_Points, Purchase_History)
        VALUES (NEW.MailID, NEW.Name, 0, '');
    END IF;
END; //

-- Login------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE LoginUser(
    IN pMailID VARCHAR(255),
    IN pPassword VARCHAR(255)
)
BEGIN
    DECLARE userRole ENUM('Admin', 'Regular');

    -- Validate user credentials and get the user's role
    SELECT Role INTO userRole 
    FROM Users 
    WHERE MailID = pMailID AND Password = SHA2(pPassword, 256);

    -- Provide appropriate feedback directly
    IF userRole IS NOT NULL THEN
        SELECT CONCAT('Login successful. Role: ', userRole) AS Message;
    ELSE
        SELECT 'Invalid email or password.' AS Message;
    END IF;
END; //
DELIMITER ;

call erp.LoginUser('poonu34@gmail.com', '23');

-- User------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE EditUser(
    IN user_id INT,
    IN new_mail_id VARCHAR(255),
    IN new_name VARCHAR(255),
    IN new_role ENUM('Admin', 'Regular')
)
BEGIN
    -- Validate email format if a new email is provided
    IF new_mail_id IS NOT NULL AND new_mail_id NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        -- Return a message if email is invalid
        SELECT 'Invalid email format. Please provide a valid email.' AS Message;
    ELSE
        -- Update only the fields provided (non-NULL values)
        UPDATE Users
        SET 
            MailID = CASE WHEN new_mail_id IS NOT NULL THEN new_mail_id ELSE MailID END,
            Name = CASE WHEN new_name IS NOT NULL THEN new_name ELSE Name END,
            Role = CASE WHEN new_role IS NOT NULL THEN new_role ELSE Role END
        WHERE UserID = user_id;

        -- Return a success message
        SELECT 'User details updated successfully.' AS Message;
    END IF;
END; //

call erp.EditUser(500, 'poonu@gmail.com', null , 'regular');

CREATE PROCEDURE DeleteUserAndCustomer(IN user_mail VARCHAR(255))
BEGIN
    -- Delete the customer if associated with the given user email
    DELETE FROM Customers WHERE Email = user_mail;

    -- Delete the user
    DELETE FROM Users WHERE MailID = user_mail;

    -- Display the single-line deletion message
    SELECT 'User and associated customer (if any) have been deleted.' AS DeletionMessage;
END; //

call erp.DeleteUserAndCustomer('poonu12@gmail.com');

CREATE VIEW ShowUsers AS
SELECT UserID, MailID, Name, Role
FROM Users;

SELECT * FROM erp.showusers;

-- Customer------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE EditCustomer(
    IN customer_id INT,
    IN new_name VARCHAR(255),
    IN new_phone VARCHAR(15),
    IN new_address TEXT,
    IN new_email VARCHAR(255)
)
BEGIN
    -- Validate email format
    IF new_email IS NOT NULL AND new_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SELECT 'Invalid email format.' AS Message;

    -- Validate phone number format (only digits and 10-15 characters)
    ELSEIF new_phone IS NOT NULL AND new_phone NOT REGEXP '^[0-9]{10,15}$' THEN
        SELECT 'Invalid phone number. Must contain only 10-15 digits.' AS Message;

    ELSE
        -- Update only the fields that are not NULL
        UPDATE Customers
        SET 
            Name = CASE WHEN new_name IS NOT NULL THEN new_name ELSE Name END,
            Phone = CASE WHEN new_phone IS NOT NULL THEN new_phone ELSE Phone END,
            Address = CASE WHEN new_address IS NOT NULL THEN new_address ELSE Address END,
            Email = CASE WHEN new_email IS NOT NULL THEN new_email ELSE Email END
        WHERE CustomerID = customer_id;

        SELECT 'Customer details updated successfully.' AS Message;
    END IF;
END; //

call erp.EditCustomer(1, null, 5555552435, 'ABC street',  null);

CREATE TRIGGER UpdateUserOnCustomerUpdate
AFTER UPDATE ON Customers
FOR EACH ROW
BEGIN
    -- Update the Users table only if email or name changes
    IF OLD.Email != NEW.Email OR OLD.Name != NEW.Name THEN
        UPDATE Users
        SET MailID = NEW.Email, Name = NEW.Name
        WHERE UserID = NEW.CustomerID;
    END IF;
END //

DELIMITER //
CREATE PROCEDURE DeactivateInactiveCustomers()
BEGIN
    DECLARE currentDate DATE;
    DECLARE lastPurchaseDate DATETIME;
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id INT;
    DECLARE v_user_mail VARCHAR(255);
    DECLARE v_history TEXT;

    DECLARE curs CURSOR FOR 
        SELECT CustomerID, Email, Purchase_History 
        FROM Customers 
        ORDER BY CustomerID;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    SET currentDate = CURDATE();

    OPEN curs;

    read_loop: LOOP
        FETCH curs INTO v_id, v_user_mail, v_history;

        IF v_done THEN
            LEAVE read_loop;
        END IF;

        SET lastPurchaseDate = (
            SELECT
                CASE
                    WHEN INSTR(v_history, 'Date: ') > 0 THEN
                        STR_TO_DATE(
                            TRIM(
                                SUBSTRING_INDEX(
                                    SUBSTRING_INDEX(v_history, 'Date: ', -1), 
                                    ', ', 1
                                )
                            ),
                            '%Y-%m-%d %H:%i:%s'
                        )
                    ELSE NULL
                END
        );

        IF lastPurchaseDate IS NULL THEN
            ITERATE read_loop;
        END IF;

        IF DATEDIFF(currentDate, lastPurchaseDate) > 365 THEN
            CALL DeleteUserAndCustomer(v_user_mail);
        END IF;

    END LOOP;

    CLOSE curs;

    SELECT 'Customers deactivated' AS Message;
END; //

call erp.DeactivateInactiveCustomers();

CREATE VIEW ShowCustomers AS
SELECT CustomerID, Name, Email, Phone, Address, Purchase_History, Loyalty_Points
FROM Customers;

SELECT * FROM erp.showcustomers;

-- Products------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE AddProduct(
    IN pName VARCHAR(255),
    IN pCategory VARCHAR(255),
    IN pCost DECIMAL(10, 2),
    IN pSellingPrice DECIMAL(10, 2),
    IN pStock INT,
    IN pReorderLevel INT,
    IN pSupplierInfo VARCHAR(255),
    IN pExpiryDate DATE
)
BEGIN
    INSERT INTO Products (Name, Category, Cost, Selling_Price, Stock, Reorder_Level, Supplier_Info, Expiry_Date)
    VALUES (pName, pCategory, pCost, pSellingPrice, pStock, pReorderLevel, pSupplierInfo, pExpiryDate);

	-- Check if insertion was successful by checking if a product ID was generated
    IF LAST_INSERT_ID() > 0 THEN
        SELECT 'Success: Product inserted successfully!' AS Message;
    ELSE
        SELECT 'Error: Product insertion failed!' AS Message;
    END IF;
END; //

call erp.AddProduct('Shirt', 'Clothing', 500, 600, 100, 5, 'tejas', '2026-07-04');

CREATE PROCEDURE EditProduct(
    IN pProductID INT,
    IN pName VARCHAR(255),
    IN pCategory VARCHAR(255),
    IN pCost DECIMAL(10, 2),
    IN pSellingPrice DECIMAL(10, 2),
    IN pReorderLevel INT
)
BEGIN
    -- Update the product details, only updating non-NULL values
    UPDATE Products
    SET 
        Name = CASE WHEN pName IS NOT NULL THEN pName ELSE Name END,
        Category = CASE WHEN pCategory IS NOT NULL THEN pCategory ELSE Category END,
        Cost = CASE WHEN pCost IS NOT NULL THEN pCost ELSE Cost END,
        Selling_Price = CASE WHEN pSellingPrice IS NOT NULL THEN pSellingPrice ELSE Selling_Price END,
        Reorder_Level = CASE WHEN pReorderLevel IS NOT NULL THEN pReorderLevel ELSE Reorder_Level END
    WHERE ProductID = pProductID;

    -- Check if any rows were affected by the update
    IF ROW_COUNT() > 0 THEN
        SELECT 'Product updated successfully!' AS Message;
    ELSE
        SELECT 'No changes made or ProductID not found!' AS Message;
    END IF;
END; //

call erp.EditProduct(5, null, null, 600 , 750 , 10);

CREATE PROCEDURE DeleteProduct(IN pProductID INT)
BEGIN
    -- Delete the product
    DELETE FROM Products WHERE ProductID = pProductID;

    -- Check if deletion was successful
    IF ROW_COUNT() > 0 THEN
        SELECT 'Success: Product deleted successfully!' AS Message;
    ELSE
        SELECT 'Error: No product found with the given ProductID!' AS Message;
    END IF;
END; //

call erp.DeleteProduct(2);

CREATE VIEW ShowProducts AS
SELECT ProductID, Name, Category, Cost, Selling_Price, Stock, Supplier_Info, Expiry_Date, Reorder_Level, Sales_Data
FROM Products;

SELECT * FROM erp.showproducts;

CREATE PROCEDURE RestockProduct(
    IN p_ProductID INT,
    IN p_StockQuantity INT,
    IN p_ExpiryDate DATE
)
BEGIN
    -- Check if the product exists and has stock = 0
    IF EXISTS (SELECT * FROM Products WHERE ProductID = p_ProductID AND Stock <= Reorder_Level) THEN
        -- Update the stock and expiry date
        UPDATE Products
        SET Stock = Stock + p_StockQuantity,
            Expiry_Date = p_ExpiryDate
        WHERE ProductID = p_ProductID;

        SELECT CONCAT('Product ID ', p_ProductID, ' has been restocked with ', p_StockQuantity, ' units and expiry date updated to ', p_ExpiryDate) AS Status;
   
    END IF;
END; //
DELIMITER ;

call erp.RestockProduct(6, 200, '2026-04-01');

-- Sales------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE AddSale(
    IN p_ProductID INT,
    IN p_CustomerID INT,
    IN p_Quantity INT,
    IN p_PaymentMethod ENUM('cash', 'card', 'online')
)
BEGIN
    DECLARE v_Stock INT;
    DECLARE v_ReorderLevel INT;
    DECLARE v_SellingPrice DECIMAL(10,2);
    DECLARE v_TotalAmount DECIMAL(10,2);

    -- Fetch stock, reorder level, and selling price for the product
    SELECT Stock, Reorder_Level, Selling_Price 
    INTO v_Stock, v_ReorderLevel, v_SellingPrice
    FROM Products
    WHERE ProductID = p_ProductID;

    -- Check stock availability
    IF v_Stock < p_Quantity THEN
        -- Not enough stock to process the order
        SELECT 'Order not processed: Insufficient stock.' AS Message;
    ELSE
        -- Sufficient stock, calculate total amount
        SET v_TotalAmount = p_Quantity * v_SellingPrice;

        -- Insert sale into Sales table
        INSERT INTO Sales (ProductID, CustomerID, Quantity, Total_Amount, Payment_Method, Date)
        VALUES (p_ProductID, p_CustomerID, p_Quantity, v_TotalAmount, p_PaymentMethod, NOW());

        -- Check if stock falls below reorder level after processing the order
        IF (v_Stock - p_Quantity) < v_ReorderLevel THEN
            SELECT 'Order processed, but stock is below reorder level: Restocking needed.' AS Message;
        ELSE
            SELECT 'Order processed successfully.' AS Message;
        END IF;
    END IF;
END; //

call erp.AddSale(22, 20, 3, 'cash');

CREATE PROCEDURE EditSale(
    IN p_SaleID INT,
    IN p_NewProductID INT,
    IN p_NewCustomerID INT,
    IN p_NewQuantity INT,
    IN p_NewPaymentMethod ENUM('cash', 'card', 'online')
)
BEGIN
    DECLARE v_OriginalProductID INT;
    DECLARE v_OriginalQuantity INT;
    DECLARE v_OriginalTotalAmount DECIMAL(10, 2);
    DECLARE v_SellingPrice DECIMAL(10, 2);

    -- Get original product ID and quantity for the sale
    SELECT ProductID, Quantity, Total_Amount INTO v_OriginalProductID, v_OriginalQuantity, v_OriginalTotalAmount
    FROM Sales
    WHERE SaleID = p_SaleID;

    -- Restore stock for the original product
    IF v_OriginalProductID IS NOT NULL AND v_OriginalQuantity IS NOT NULL THEN
        UPDATE Products
        SET Stock = Stock + v_OriginalQuantity
        WHERE ProductID = v_OriginalProductID;
    END IF;

    -- Check stock availability for the new product if product ID and quantity are provided
    IF p_NewProductID IS NOT NULL AND p_NewQuantity IS NOT NULL THEN
        SELECT Selling_Price INTO v_SellingPrice
        FROM Products
        WHERE ProductID = p_NewProductID;

        IF v_SellingPrice IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid Product ID provided.';
        END IF;

        IF (SELECT Stock FROM Products WHERE ProductID = p_NewProductID) < p_NewQuantity THEN
            -- Revert stock restoration if new product stock is insufficient
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Not enough stock for the new quantity.';
        ELSE
            -- Deduct stock for the new product
            UPDATE Products
            SET Stock = Stock - p_NewQuantity
            WHERE ProductID = p_NewProductID;
        END IF;
    END IF;

    -- Update the sale record with CASE statements
    UPDATE Sales
    SET 
        ProductID = CASE 
            WHEN p_NewProductID IS NOT NULL THEN p_NewProductID 
            ELSE ProductID 
        END,
        CustomerID = CASE 
            WHEN p_NewCustomerID IS NOT NULL THEN p_NewCustomerID 
            ELSE CustomerID 
        END,
        Quantity = CASE 
            WHEN p_NewQuantity IS NOT NULL THEN p_NewQuantity 
            ELSE Quantity 
        END,
        Payment_Method = CASE 
            WHEN p_NewPaymentMethod IS NOT NULL THEN p_NewPaymentMethod 
            ELSE Payment_Method 
        END,
        Total_Amount = CASE
            WHEN p_NewQuantity IS NOT NULL AND p_NewProductID IS NOT NULL THEN 
                p_NewQuantity * v_SellingPrice
            ELSE Total_Amount
        END,
        Date = NOW()
    WHERE SaleID = p_SaleID;

    SELECT 'Sale updated successfully' AS Message;
END //

CREATE TRIGGER After_Sale_Update
AFTER UPDATE ON Sales
FOR EACH ROW
BEGIN
    -- Update Sales_Data in the Products table
    UPDATE Products
    SET Sales_Data = CONCAT_WS('\n', IFNULL(Sales_Data, ''), 
                               CONCAT('ProductID: ', NEW.ProductID, ', New Quantity: ', NEW.Quantity, ', Date: ', NOW()))
    WHERE ProductID = NEW.ProductID;

    -- Update Purchase_History and increment Loyalty Points in the Customers table
    UPDATE Customers
    SET Purchase_History = CONCAT_WS('\n', IFNULL(Purchase_History, ''), 
                                     CONCAT('ProductID: ', NEW.ProductID, ', New Quantity: ', NEW.Quantity, ', Date: ', NOW())),
        Loyalty_Points = IFNULL(Loyalty_Points, 0) + 20
    WHERE CustomerID = NEW.CustomerID;
END; //

call erp.EditSale(41, 33, 44, 2, 'online');

CREATE PROCEDURE DeleteSale(IN p_SaleID INT)
BEGIN
    -- Restore stock and delete sale in a single transaction
    UPDATE Products P
    JOIN Sales S ON P.ProductID = S.ProductID
    SET P.Stock = P.Stock + S.Quantity
    WHERE S.SaleID = p_SaleID;

    -- Delete the sale record
    DELETE FROM Sales
    WHERE SaleID = p_SaleID;

    SELECT 'Sale deleted successfully' AS Message;
END; //

call erp.DeleteSale(18);

CREATE TRIGGER After_Sale_Insert
AFTER INSERT ON Sales
FOR EACH ROW
BEGIN
    DECLARE v_Stock INT;
    DECLARE v_SellingPrice DECIMAL(10, 2);

    -- Fetch stock and selling price for the product
    SELECT Stock, Selling_Price INTO v_Stock, v_SellingPrice
    FROM Products
    WHERE ProductID = NEW.ProductID;

    -- Check if stock is sufficient for the sale
    IF v_Stock < NEW.Quantity THEN
        -- If not enough stock, cancel the sale by deleting the record (optional)
        DELETE FROM Sales WHERE SaleID = NEW.SaleID;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for this sale.';
    ELSE
        -- Update stock after the sale
        UPDATE Products
        SET Stock = Stock - NEW.Quantity
        WHERE ProductID = NEW.ProductID;

        -- Update Sales_Data in the Products table (store information about the sale)
        UPDATE Products
        SET Sales_Data = CONCAT_WS('\n', IFNULL(Sales_Data, ''),
                                   CONCAT('Sale ID: ', NEW.SaleID, ', Quantity: ', NEW.Quantity, ', Date: ', NOW()))
        WHERE ProductID = NEW.ProductID;

        -- Update purchase_history and loyalty points in the Customers table
        UPDATE Customers
        SET Purchase_History = CONCAT_WS('\n', IFNULL(Purchase_History, ''),
                                          CONCAT('Sale ID: ', NEW.SaleID, ', Quantity: ', NEW.Quantity, ', Date: ', NOW())),
            Loyalty_Points = IFNULL(Loyalty_Points, 0) + 20
        WHERE CustomerID = NEW.CustomerID;
    END IF;
END; //

CREATE VIEW SalesInsights AS
SELECT 
    P.Name AS ProductName,
    SUM(S.Quantity) AS TotalSales,
    SUM(S.Total_Amount) AS TotalRevenue,
    AVG(F.Ratings) AS AverageRating
FROM Sales S
JOIN Products P ON S.ProductID = P.ProductID
LEFT JOIN Feedback F ON P.ProductID = F.ProductID
GROUP BY P.Name;

SELECT * FROM erp.salesinsights;

CREATE VIEW ShowSales AS
SELECT SaleID, ProductID, CustomerID, Date, Quantity, Total_Amount, Payment_Method
FROM Sales;

SELECT * FROM erp.sales;

-- Feedback------------------------------------------------------------
DELIMITER //

-- Add Feedback Procedure
CREATE PROCEDURE AddFeedback(
    IN p_ProductID INT,
    IN p_CustomerID INT,
    IN p_Comments VARCHAR(255),
    IN p_Ratings INT
)
BEGIN
    -- Insert new feedback into the FEEDBACK table
    INSERT INTO FEEDBACK (ProductID, CustomerID, Comments, Ratings, Timestamp)
    VALUES (p_ProductID, p_CustomerID, p_Comments, p_Ratings, NOW());

    IF LAST_INSERT_ID() > 0 THEN
        SELECT 'Feedback added successfully!' AS Message;
    ELSE
        SELECT 'Error: Unable to add feedback!' AS Message;
    END IF;
END;//

call erp.AddFeedback(54 ,15, 'Goood', 3);

CREATE PROCEDURE EditFeedback(
    IN p_FeedbackID INT,
    IN p_Comments VARCHAR(255),
    IN p_Ratings INT
)
BEGIN
    -- Update the feedback record in the FEEDBACK table only if the value is provided
    UPDATE FEEDBACK
    SET 
        Comments = IFNULL(p_Comments, Comments),  -- Only update if new comment is provided
        Ratings = IFNULL(p_Ratings, Ratings),  -- Only update if new rating is provided
        Timestamp = NOW()  
    WHERE FeedbackID = p_FeedbackID;

    IF ROW_COUNT() > 0 THEN
        SELECT 'Feedback updated successfully!' AS Message;
    ELSE
        SELECT 'Error: No feedback found with the given ID or no changes made!' AS Message;
    END IF;
END; //

call erp.EditFeedback(1, 'bad' , 2);

CREATE PROCEDURE DeleteFeedback(
    IN p_FeedbackID INT
)
BEGIN
    -- Delete the feedback record from the FEEDBACK table
    DELETE FROM FEEDBACK
    WHERE FeedbackID = p_FeedbackID;

    IF ROW_COUNT() > 0 THEN
        SELECT 'Feedback deleted successfully!' AS Message;
    ELSE
        SELECT 'Error: No feedback found with the given ID!' AS Message;
    END IF;
END; //

call erp.DeleteFeedback(1);

-- Respond to Feedback Procedure
DELIMITER //
-- Respond to Feedback Procedure
CREATE PROCEDURE RespondToFeedback(
    IN pFeedbackID INT
)
BEGIN
    DECLARE pFeedbackText TEXT;
    DECLARE sentimentTone VARCHAR(50);
    DECLARE positiveKeywords TEXT DEFAULT 'good,excellent,amazing,awesome,positive,happy,satisfied';
    DECLARE negativeKeywords TEXT DEFAULT 'bad,poor,terrible,horrible,negative,angry,unsatisfied';
    DECLARE positiveCount INT DEFAULT 0;
    DECLARE negativeCount INT DEFAULT 0;
    DECLARE autoResponse TEXT;
    DECLARE keyword TEXT;
    DECLARE keywordList TEXT;

    -- Fetch the feedback text for the given FeedbackID
    SELECT Comments INTO pFeedbackText
    FROM Feedback
    WHERE FeedbackID = pFeedbackID;

    -- Check if feedback text was found
    IF pFeedbackText IS NOT NULL THEN

        -- Count Positive Keywords
        SET keywordList = positiveKeywords;
        WHILE LOCATE(',', keywordList) > 0 DO
            SET keyword = TRIM(SUBSTRING_INDEX(keywordList, ',', 1));
            SET positiveCount = positiveCount + 
                (LENGTH(LOWER(pFeedbackText)) - LENGTH(REPLACE(LOWER(pFeedbackText), LOWER(keyword), ''))) / LENGTH(keyword);
            SET keywordList = SUBSTRING(keywordList FROM LOCATE(',', keywordList) + 1);
        END WHILE;

        -- Last positive keyword
        SET keyword = TRIM(keywordList);
        IF keyword IS NOT NULL AND keyword != '' THEN
            SET positiveCount = positiveCount + 
                (LENGTH(LOWER(pFeedbackText)) - LENGTH(REPLACE(LOWER(pFeedbackText), LOWER(keyword), ''))) / LENGTH(keyword);
        END IF;

        -- Count Negative Keywords
        SET keywordList = negativeKeywords;
        WHILE LOCATE(',', keywordList) > 0 DO
            SET keyword = TRIM(SUBSTRING_INDEX(keywordList, ',', 1));
            SET negativeCount = negativeCount + 
                (LENGTH(LOWER(pFeedbackText)) - LENGTH(REPLACE(LOWER(pFeedbackText), LOWER(keyword), ''))) / LENGTH(keyword);
            SET keywordList = SUBSTRING(keywordList FROM LOCATE(',', keywordList) + 1);
        END WHILE;

        -- Last negative keyword
        SET keyword = TRIM(keywordList);
        IF keyword IS NOT NULL AND keyword != '' THEN
            SET negativeCount = negativeCount + 
                (LENGTH(LOWER(pFeedbackText)) - LENGTH(REPLACE(LOWER(pFeedbackText), LOWER(keyword), ''))) / LENGTH(keyword);
        END IF;

        -- Determine Sentiment Tone
        IF positiveCount > negativeCount THEN
            SET sentimentTone = 'Positive';
        ELSEIF negativeCount > positiveCount THEN
            SET sentimentTone = 'Negative';
        ELSE
            SET sentimentTone = 'Neutral';
        END IF;

        -- Generate Auto-Response Based on Sentiment
        IF sentimentTone = 'Positive' THEN
            SET autoResponse = 'Thank you for your positive feedback! We are thrilled you had a great experience.';
        ELSEIF sentimentTone = 'Negative' THEN
            SET autoResponse = 'We are sorry to hear about your experience. Your feedback is important, and we will work to improve.';
        ELSE
            SET autoResponse = 'Thank you for your feedback! We appreciate your input.';
        END IF;

        -- Update the Response for the Feedback Record
        UPDATE Feedback
        SET Response = autoResponse
        WHERE FeedbackID = pFeedbackID;

        -- Provide Feedback on Success or Failure
        IF ROW_COUNT() > 0 THEN
            SELECT CONCAT('Response added successfully! Detected sentiment: ', sentimentTone) AS Message;
        ELSE
            SELECT 'Error: Could not update the response!' AS Message;
        END IF;

    ELSE
        -- Feedback not found message
        SELECT 'Error: No feedback found with the given ID!' AS Message;
    END IF;
END //

call erp.RespondToFeedback(2 , 'thanks');

DELIMITER //

CREATE PROCEDURE GetFeedbackForCustomer(IN inputCustomerID INT)
BEGIN
    -- Check if the customer exists
    IF NOT EXISTS (
        SELECT 1 
        FROM Customers 
        WHERE CustomerID = inputCustomerID
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer with the given ID does not exist.';
    END IF;

    -- Check if feedback exists for the customer
    IF NOT EXISTS (
        SELECT 1
        FROM Feedback
        WHERE CustomerID = inputCustomerID
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No feedback available for the given customer.';
    END IF;

    -- Retrieve feedback for the customer
    SELECT 
        p.Name AS ProductName,
        f.Comments,
        f.Ratings,
        f.Timestamp
    FROM 
        Feedback f
    JOIN 
        Products p ON f.ProductID = p.ProductID
    WHERE 
        f.CustomerID = inputCustomerID;
END //

call erp.GetFeedbackForCustomer(16);

CREATE PROCEDURE GetProductFeedbackByName(IN inputProductName VARCHAR(255))
BEGIN
    -- Check if the product exists
    IF NOT EXISTS (
        SELECT 1 
        FROM Products 
        WHERE Name = inputProductName
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product with the given name does not exist.';
    END IF;

    -- Check if feedback exists for the product
    IF NOT EXISTS (
        SELECT 1
        FROM Feedback f
        JOIN Products p ON f.ProductID = p.ProductID
        WHERE p.Name = inputProductName
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No feedback available for the given product.';
    END IF;

    -- Retrieve feedback for the product
    SELECT 
        f.Comments,
        f.Ratings
    FROM 
        Feedback f
    JOIN 
        Products p ON f.ProductID = p.ProductID
    WHERE 
        p.Name = inputProductName;
END //

call erp.GetProductFeedbackByName('Appear Pro');

CREATE PROCEDURE GenerateFeedbackInsights()
BEGIN
    SELECT ProductID, AVG(Ratings) AS AverageRating, COUNT(*) AS TotalFeedbacks
    FROM Feedback
    GROUP BY ProductID;
END;//

call erp.GenerateFeedbackInsights();

CREATE VIEW ShowFeedback AS
SELECT FeedbackID, ProductID, CustomerID, Comments, Ratings, Timestamp, Response
FROM Feedback;

SELECT * FROM erp.showfeedback;

DELIMITER ;

-- Algorithms------------------------------------------------------------
DELIMITER //

CREATE FUNCTION ABC_Classification()
RETURNS JSON -- Return results in JSON format
DETERMINISTIC
BEGIN
    DECLARE total_sales DECIMAL(10,2);
    DECLARE cumulative_sales DECIMAL(10,2) DEFAULT 0;
    DECLARE threshold_a DECIMAL(10,2);
    DECLARE threshold_b DECIMAL(10,2);
    DECLARE finished INT DEFAULT 0;
    DECLARE product_id INT;
    DECLARE product_sales DECIMAL(10,2);
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    
    -- Cursor for product sales
    DECLARE sales_cursor CURSOR FOR
        SELECT ProductID, SUM(TOTAL_AMOUNT) AS PRODUCT_SALES
        FROM Sales
        GROUP BY ProductID
        ORDER BY PRODUCT_SALES DESC;

    -- Handler for end of data
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

    -- Calculate total sales
    SELECT SUM(TOTAL_AMOUNT) INTO total_sales FROM Sales;

    -- Define thresholds
    SET threshold_a = total_sales * 0.80;
    SET threshold_b = total_sales * 0.95;

    -- Open the cursor
    OPEN sales_cursor;

    -- Process each product
    fetch_loop: LOOP
        FETCH sales_cursor INTO product_id, product_sales;
        IF finished THEN
            LEAVE fetch_loop;
        END IF;

        -- Accumulate sales
        SET cumulative_sales = cumulative_sales + product_sales;

        -- Categorize products and append to result
        IF cumulative_sales <= threshold_a THEN
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'CATEGORY', 'A'));
        ELSEIF cumulative_sales <= threshold_b THEN
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'CATEGORY', 'B'));
        ELSE
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'CATEGORY', 'C'));
        END IF;
    END LOOP;

    -- Close the cursor
    CLOSE sales_cursor;

    -- Return the JSON result
    RETURN result;
END //

DELIMITER ;

select erp.ABC_Classification();

DELIMITER //

CREATE FUNCTION Demand_Forecasting_Months(months INT)
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE product_id INT;
    DECLARE product_name VARCHAR(100);
    DECLARE slope DECIMAL(10, 5);
    DECLARE intercept DECIMAL(10, 5);
    DECLARE predicted_demand DECIMAL(10, 2);
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE done INT DEFAULT 0;

        -- Step 1: Calculate regression parameters for the last 12 months (1 year)
        DECLARE sum_x INT DEFAULT 0;
        DECLARE sum_y INT DEFAULT 0;
        DECLARE sum_x2 INT DEFAULT 0;
        DECLARE sum_xy INT DEFAULT 0;
        DECLARE count_data INT DEFAULT 0;
    -- Cursor declaration
    DECLARE product_cursor CURSOR FOR
    SELECT ProductID, Name
    FROM Products;

    -- Handler for end of cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open the cursor
    OPEN product_cursor;

    -- Iterate through all products
    product_loop: LOOP
        FETCH product_cursor INTO product_id, product_name;

        IF done THEN
            LEAVE product_loop;
        END IF;

        SELECT COUNT(*), 
               SUM(PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(Date, '%Y%m'))), 
               SUM(Quantity), 
               SUM(POW(PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(Date, '%Y%m')), 2)), 
               SUM(PERIOD_DIFF(DATE_FORMAT(CURDATE(), '%Y%m'), DATE_FORMAT(Date, '%Y%m')) * Quantity)
        INTO count_data, sum_x, sum_y, sum_x2, sum_xy
        FROM Sales
        WHERE ProductID = product_id
          AND Date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH);

        -- Prevent division by zero in case of no data
        IF count_data = 0 OR (count_data * sum_x2 - POW(sum_x, 2)) = 0 THEN
            SET slope = 0;
            SET intercept = 0;
        ELSE
            SET slope = (count_data * sum_xy - sum_x * sum_y) / (count_data * sum_x2 - POW(sum_x, 2));
            SET intercept = (sum_y - slope * sum_x) / count_data;
        END IF;

        -- Step 2: Predict total demand for the next 'months'
        SET predicted_demand = slope * months + intercept;

        -- Step 3: Add result to JSON object
        SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT(
            'ProductID', product_id,
            'ProductName', product_name,
            'PredictedDemandForNextPeriod', GREATEST(CEIL(predicted_demand), 0) -- Ensure non-negative demand
        ));
    END LOOP;

    CLOSE product_cursor;

    RETURN result;
END //

DELIMITER ;

select erp.Demand_Forecasting_Months(6);

CREATE VIEW MonthlyBeginningInventoryView AS
SELECT
    p.ProductID,
    p.Name AS ProductName,
    p.Cost AS UnitCost,
    rm.MonthStart,
    CASE
        WHEN rm.MonthStart = '2023-01-01' THEN 100
        ELSE 100 - COALESCE(
            (
                SELECT SUM(s.Quantity)
                FROM sales s
                WHERE s.ProductID = p.ProductID
                AND s.Date < rm.MonthStart
            ), 0
        )
    END AS BeginningInventory
FROM
    products p
CROSS JOIN
    (
        -- Generate months as a derived table
        WITH RECURSIVE RecursiveMonths AS (
            SELECT DATE('2023-01-01') AS MonthStart
            UNION ALL
            SELECT DATE_ADD(MonthStart, INTERVAL 1 MONTH)
            FROM RecursiveMonths
            WHERE MonthStart < '2025-01-01'
        )
        SELECT MonthStart FROM RecursiveMonths
    ) AS rm -- Ensure the derived table has an alias
ORDER BY
    p.ProductID, rm.MonthStart;

DELIMITER //

CREATE FUNCTION Inventory_Turnover_Ratio()
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE current_month_start DATE;
    DECLARE current_month_end DATE;
    
    -- Get the start and end date of the current month
    SET current_month_start = DATE_FORMAT(CURDATE(), '%Y-%m-01');
    SET current_month_end = LAST_DAY(CURDATE());
    
    SET result = JSON_SET(
        result,
        '$.InventoryTurnoverRatios',
        (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'ProductID', p.ProductID,
                    'ProductName', p.Name,
                    'BeginningInventory', mbiv.BeginningInventory,
                    'EndingInventory', p.Stock,
                    'COGS', (
                        SELECT COALESCE(SUM(s.Quantity), 0) * p.Cost
                        FROM sales s
                        WHERE s.ProductID = p.ProductID
                        AND s.Date >= current_month_start
                        AND s.Date <= current_month_end
                    ),
                    'AverageInventory', ((mbiv.BeginningInventory + p.Stock) / 2) * p.Cost,
                    'InventoryTurnoverRatio',
                    CASE
                        WHEN ((mbiv.BeginningInventory + p.Stock) / 2) = 0 THEN 0
                        ELSE (
                            SELECT COALESCE(SUM(s.Quantity), 0) * p.Cost
                            FROM sales s
                            WHERE s.ProductID = p.ProductID
                            AND s.Date >= current_month_start
                            AND s.Date <= current_month_end
                        ) / (((mbiv.BeginningInventory + p.Stock) / 2) * p.Cost)
                    END
                )
            )
            FROM products p
            JOIN MonthlyBeginningInventoryView mbiv ON mbiv.ProductID = p.ProductID
            WHERE mbiv.MonthStart = current_month_start
        )
    );
    
    RETURN result;
END //

DELIMITER ;

select erp.Inventory_Turnover_Ratio()

DELIMITER //

CREATE FUNCTION GetProfitabilityRegressionWithProducts() 
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;

    -- Variables for linear regression
    DECLARE n INT;
    DECLARE sumX DECIMAL(10, 2) DEFAULT 0;
    DECLARE sumY DECIMAL(10, 2) DEFAULT 0;
    DECLARE sumXY DECIMAL(10, 2) DEFAULT 0;
    DECLARE sumX2 DECIMAL(10, 2) DEFAULT 0;
    DECLARE slope DECIMAL(10, 4) DEFAULT 0;
    DECLARE intercept DECIMAL(10, 4) DEFAULT 0;

    -- Temporary table to store product-wise profitability
    DROP TEMPORARY TABLE IF EXISTS ProfitData;
    CREATE TEMPORARY TABLE ProfitData AS
    SELECT 
        MONTH(S.Date) AS X,  -- Month as X (independent variable)
        SUM((S.Total_Amount / S.Quantity - P.Cost) * S.Quantity) AS Y,  -- Profit as Y (dependent variable)
        P.ProductID,
        P.Name AS ProductName
    FROM 
        Products P
    JOIN 
        Sales S ON P.ProductID = S.ProductID
    GROUP BY 
        YEAR(S.Date), MONTH(S.Date), P.ProductID;

    -- Step 2: Calculate the necessary sums for linear regression (overall profitability)
    SELECT 
        COUNT(*) AS n,
        SUM(X) AS sumX,
        SUM(Y) AS sumY,
        SUM(X * Y) AS sumXY,
        SUM(X * X) AS sumX2
    INTO 
        n, sumX, sumY, sumXY, sumX2
    FROM 
        ProfitData;

    -- Step 3: Calculate slope (m) and intercept (b) for overall profitability
    SET slope = (n * sumXY - sumX * sumY) / (n * sumX2 - POW(sumX, 2));
    SET intercept = (sumY - slope * sumX) / n;

    -- Step 4: Prepare the individual product profitability data
    -- Create a temporary table to store product profit data
    DROP TEMPORARY TABLE IF EXISTS ProductProfit;
    CREATE TEMPORARY TABLE ProductProfit AS
    SELECT 
        P.ProductID,
        P.Name AS ProductName,
        SUM((S.Total_Amount / S.Quantity - P.Cost) * S.Quantity) AS TotalProfit,
        AVG(S.Total_Amount / S.Quantity - P.Cost) AS AverageProfitPerUnit
    FROM 
        Products P
    JOIN 
        Sales S ON P.ProductID = S.ProductID
    GROUP BY 
        P.ProductID;

    -- Step 5: Generate JSON result for overall profitability trend and individual product profitabilities
    SET result = JSON_OBJECT(
        'OverallTrend', JSON_OBJECT(
            'Slope', slope,
            'Intercept', intercept,
            'TrendLineEquation', CONCAT('y = ', slope, 'x + ', intercept)
        ),
        'ProductProfitabilities', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'ProductID', ProductID,
                    'ProductName', ProductName,
                    'TotalProfit', TotalProfit,
                    'AverageProfitPerUnit', AverageProfitPerUnit
                )
            )
            FROM ProductProfit
        )
    );

    -- Return the result as JSON
    RETURN result;
END//

DELIMITER ;

select erp.GetProfitabilityRegressionWithProducts();

DELIMITER //

CREATE FUNCTION Sales_Tnd_Analysis() RETURNS JSON DETERMINISTIC
BEGIN
    DECLARE product_id INT;
    DECLARE sales_date DATE;
    DECLARE monthly_sales DECIMAL(10,2);
    DECLARE sum_x DECIMAL(10,2) DEFAULT 0;
    DECLARE sum_y DECIMAL(10,2) DEFAULT 0;
    DECLARE sum_x2 DECIMAL(10,2) DEFAULT 0;
    DECLARE sum_xy DECIMAL(10,2) DEFAULT 0;
    DECLARE n INT DEFAULT 0;
    DECLARE slope DECIMAL(10,6);
    DECLARE abs_slope DECIMAL(10,6);
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE finished_products INT DEFAULT 0;
    DECLARE finished_sales INT DEFAULT 0;

    -- Cursor to iterate through all products
    DECLARE product_cursor CURSOR FOR
        SELECT DISTINCT ProductID FROM Sales;

    -- Handler for end of product cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished_products = 1;

    -- Open product cursor
    OPEN product_cursor;

    product_loop: LOOP
        FETCH product_cursor INTO product_id;

        IF finished_products THEN
            LEAVE product_loop;
        END IF;

        -- Reset aggregates for the new product
        SET sum_x = 0, sum_y = 0, sum_x2 = 0, sum_xy = 0, n = 0;
        SET finished_sales = 0;

        -- Declare and open monthly sales cursor in a separate block to allow a handler
        BEGIN
            -- Cursor for monthly sales data for a specific product
            DECLARE monthly_sales_cursor CURSOR FOR
                SELECT
                    DATE_FORMAT(Date, '%Y-%m-01') AS SalesMonth,
                    SUM(Total_Amount) AS MonthlySales
                FROM Sales
                WHERE ProductID = product_id
                GROUP BY SalesMonth
                ORDER BY SalesMonth;

            -- Handler for end of monthly sales cursor
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished_sales = 1;

            -- Open monthly sales cursor
            OPEN monthly_sales_cursor;

            sales_loop: LOOP
                FETCH monthly_sales_cursor INTO sales_date, monthly_sales;

                IF finished_sales THEN
                    LEAVE sales_loop;
                END IF;

                -- Update aggregates for regression
                SET n = n + 1;
                SET sum_x = sum_x + n;
                SET sum_y = sum_y + monthly_sales;
                SET sum_x2 = sum_x2 + n * n;
                SET sum_xy = sum_xy + n * monthly_sales;
            END LOOP;

            -- Close the monthly sales cursor
            CLOSE monthly_sales_cursor;
        END;

        -- Compute regression slope (m)
        IF n > 1 THEN
            SET slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x);
            SET abs_slope = ABS(slope); -- Ensure slope is non-negative for plotting
        ELSE
            SET slope = 0; -- Not enough data points for regression
            SET abs_slope = 0;
        END IF;

        -- Categorize trend and include numeric slope
        IF slope > 0 THEN
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'TREND', 'Increasing', 'SLOPE', abs_slope));
        ELSEIF slope < 0 THEN
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'TREND', 'Decreasing', 'SLOPE', abs_slope));
        ELSE
            SET result = JSON_ARRAY_APPEND(result, '$', JSON_OBJECT('PRODUCT_ID', product_id, 'TREND', 'Stable', 'SLOPE', abs_slope));
        END IF;
    END LOOP;

    -- Close product cursor
    CLOSE product_cursor;

    -- Return the result as JSON
    RETURN result;
END //

DELIMITER ;

select erp.Sales_Tnd_Analysis();

-- Logs------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE AddLog(
    IN p_Algorithm_Name VARCHAR(255),
    IN p_New_Result JSON
)
BEGIN
    DECLARE existing_results JSON;

    -- Step 1: Check if there's an existing result for the given algorithm
    SET existing_results = (
        SELECT Results
        FROM erp.Logs
        WHERE Algorithm_Name = p_Algorithm_Name
        LIMIT 1
    );

    -- Step 2: If no existing results, initialize the result as an empty JSON array
    IF existing_results IS NULL THEN
        SET existing_results = JSON_ARRAY();
    END IF;

    -- Step 3: Append the new result to the existing result array
    SET existing_results = JSON_ARRAY_APPEND(existing_results, '$', p_New_Result);

    -- Step 4: Update the existing record or insert a new one if not found
    IF EXISTS (SELECT 1 FROM erp.Logs WHERE Algorithm_Name = p_Algorithm_Name) THEN
        UPDATE erp.Logs
        SET Results = existing_results, Timestamp = NOW()
        WHERE Algorithm_Name = p_Algorithm_Name;
    ELSE
        INSERT INTO erp.Logs (Algorithm_Name, Results, Timestamp)
        VALUES (p_Algorithm_Name, existing_results, NOW());
    END IF;

END; //

DELIMITER ;

-- Execution of algorithms and inserting into logs
SET SQL_SAFE_UPDATES = 0;
SET @results = erp.Demand_Forecasting_Months(6);
CALL erp.AddLog('Demand Forecasting', @results);
SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;
SET @results = erp.GetProfitabilityRegressionWithProducts();
CALL erp.AddLog('Product Profitability', @results);
SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;
SET @results = erp.Inventory_Turnover_Ratio();
CALL erp.AddLog('Inventory Turn Over Ratio', @results);
SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;
SET @results = erp.ABC_Classification();
CALL erp.AddLog('ABC Classification', @results);
SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;
SET @results = erp.Sales_Tnd_Analysis();
CALL erp.AddLog('Sales_Trend_Analysis', @results);
SET SQL_SAFE_UPDATES = 1;

CREATE VIEW ShowLogs AS
SELECT LogID, Algorithm_Name, Timestamp, Results
FROM Logs;

SELECT * FROM erp.showlogs;


















