    
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

-- CREATE PROCEDURE EditSale(
--     IN p_SaleID INT,
--     IN p_NewProductID INT,
--     IN p_NewCustomerID INT,
--     IN p_NewQuantity INT,
--     IN p_NewPaymentMethod ENUM('cash', 'card', 'online')
-- )
-- BEGIN
--     DECLARE v_OriginalProductID INT;
--     DECLARE v_OriginalQuantity INT;

--     -- Get original product ID and quantity for the sale
--     SELECT ProductID, Quantity INTO v_OriginalProductID, v_OriginalQuantity
--     FROM Sales
--     WHERE SaleID = p_SaleID;

--     -- Restore stock for the original product
--     UPDATE Products
--     SET Stock = Stock + v_OriginalQuantity
--     WHERE ProductID = v_OriginalProductID;

--     -- Check stock availability for the new product
--     IF EXISTS (
--         SELECT 1
--         FROM Products
--         WHERE ProductID = p_NewProductID AND Stock >= p_NewQuantity
--     ) THEN
--         -- Update the sale record
--         UPDATE Sales
--         SET ProductID = p_NewProductID,
--             CustomerID = p_NewCustomerID,
--             Quantity = p_NewQuantity,
--             Payment_Method = p_NewPaymentMethod,
--             Date = NOW(),
--             Total_Amount = p_NewQuantity * (SELECT Selling_Price FROM Products WHERE ProductID = p_NewProductID)
--         WHERE SaleID = p_SaleID;

--         -- Deduct stock for the new product
--         UPDATE Products
--         SET Stock = Stock - p_NewQuantity
--         WHERE ProductID = p_NewProductID;

--         SELECT 'Sale updated successfully' AS Message;
--     ELSE
--         -- Revert stock restoration if new product stock is insufficient
--         UPDATE Products
--         SET Stock = Stock - v_OriginalQuantity
--         WHERE ProductID = v_OriginalProductID;

--         SELECT 'Not enough stock for the new quantity' AS Message;
--     END IF;
-- END; //

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




