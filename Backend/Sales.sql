DELIMITER //

CREATE PROCEDURE AddSale(IN p_ProductID INT, IN p_CustomerID INT, IN p_Quantity INT, IN p_PaymentMethod ENUM('cash', 'card', 'paypal'))
BEGIN
    DECLARE v_Stock INT;
    DECLARE v_SellingPrice DECIMAL(10,2);
    DECLARE v_TotalAmount DECIMAL(10,2);
    
    -- Get product stock and selling price
    SELECT Stock, Selling_Price INTO v_Stock, v_SellingPrice FROM Products WHERE ProductID = p_ProductID;
    
    IF v_Stock >= p_Quantity THEN
        SET v_TotalAmount = v_SellingPrice * p_Quantity;
        
        -- Insert sale record
        INSERT INTO Sales (ProductID, CustomerID, Quantity, Total_Amount, Payment_Method) 
        VALUES (p_ProductID, p_CustomerID, p_Quantity, v_TotalAmount, p_PaymentMethod);
        
        -- Update product stock
        UPDATE Products SET Stock = v_Stock - p_Quantity WHERE ProductID = p_ProductID;
    ELSE
        SELECT 'Not enough stock' AS Message;
    END IF;
END; //

CREATE VIEW ShowSales AS
SELECT SaleID, ProductID, CustomerID, Date, Quantity, Total_Amount, Payment_Method
FROM Sales;


CREATE PROCEDURE UpdateSale(
    IN p_SaleID INT,
    IN p_NewProductID INT,
    IN p_NewCustomerID INT,
    IN p_NewQuantity INT,
    IN p_NewPaymentMethod ENUM('cash', 'card', 'paypal'),
    IN p_NewDate DATE
)
BEGIN
    DECLARE v_OriginalProductID INT;
    DECLARE v_OriginalCustomerID INT;
    DECLARE v_OriginalQuantity INT;
    DECLARE v_OriginalStock INT;
    DECLARE v_OriginalSellingPrice DECIMAL(10, 2);
    DECLARE v_OriginalTotalAmount DECIMAL(10, 2);
    DECLARE v_NewStock INT;
    DECLARE v_NewSellingPrice DECIMAL(10, 2);
    DECLARE v_NewTotalAmount DECIMAL(10, 2);
    
    -- Get original product ID, customer ID, quantity, and stock information for the sale
    SELECT ProductID, CustomerID, Quantity INTO v_OriginalProductID, v_OriginalCustomerID, v_OriginalQuantity
    FROM Sales
    WHERE SaleID = p_SaleID;
    
    -- Get product stock and selling price for the original product
    SELECT Stock, Selling_Price INTO v_OriginalStock, v_OriginalSellingPrice
    FROM Products
    WHERE ProductID = v_OriginalProductID;
    
    -- Calculate the original total amount
    SET v_OriginalTotalAmount = v_OriginalSellingPrice * v_OriginalQuantity;
    
    -- Get new product stock and selling price
    SELECT Stock, Selling_Price INTO v_NewStock, v_NewSellingPrice
    FROM Products
    WHERE ProductID = p_NewProductID;
    
    -- Calculate the new total amount
    SET v_NewTotalAmount = v_NewSellingPrice * p_NewQuantity;
    
    -- Check if there is enough stock for the new quantity
    IF v_NewStock >= p_NewQuantity THEN
        -- Update the sale record
        UPDATE Sales
        SET ProductID = p_NewProductID,
            CustomerID = p_NewCustomerID,
            Quantity = p_NewQuantity,
            Payment_Method = p_NewPaymentMethod,
            Date = p_NewDate,
            Total_Amount = v_NewTotalAmount
        WHERE SaleID = p_SaleID;
        
        -- Update the original product stock
        UPDATE Products
        SET Stock = v_OriginalStock + v_OriginalQuantity
        WHERE ProductID = v_OriginalProductID;

        -- Update the new product stock
        UPDATE Products
        SET Stock = v_NewStock - p_NewQuantity
        WHERE ProductID = p_NewProductID;

        SELECT 'Sale updated successfully' AS Message;
    ELSE
        SELECT 'Not enough stock for the new quantity' AS Message;
    END IF;
END; //

CREATE PROCEDURE DeleteSale(IN p_SaleID INT)
BEGIN
    DECLARE v_ProductID INT;
    DECLARE v_Quantity INT;
    DECLARE v_Stock INT;

    -- Get the sale's product ID and quantity
    SELECT ProductID, Quantity INTO v_ProductID, v_Quantity
    FROM Sales
    WHERE SaleID = p_SaleID;
    
    -- Get product stock
    SELECT Stock INTO v_Stock
    FROM Products
    WHERE ProductID = v_ProductID;
    
    -- Delete the sale record
    DELETE FROM Sales WHERE SaleID = p_SaleID;
    
    -- Update the product stock
    UPDATE Products
    SET Stock = v_Stock + v_Quantity
    WHERE ProductID = v_ProductID;

    SELECT 'Sale deleted successfully' AS Message;
END; //







CREATE VIEW SalesInsights AS
SELECT 
    P.Name AS ProductName,
    SUM(S.Quantity) AS TotalSales,
    SUM(S.TotalAmount) AS TotalRevenue,
    AVG(F.Ratings) AS AverageRating
FROM Sales S
JOIN Products P ON S.ProductID = P.ProductID
LEFT JOIN Feedback F ON P.ProductID = F.ProductID
GROUP BY P.Name;







DELIMITER ;




