    
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
END //

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

CREATE VIEW ShowSales AS
SELECT SaleID, ProductID, CustomerID, Date, Quantity, Total_Amount, Payment_Method
FROM Sales;

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

DELIMITER ;




