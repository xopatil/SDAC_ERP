DELIMITER $$

CREATE PROCEDURE AddSale(IN p_ProductID INT, IN p_CustomerID INT, IN p_Quantity INT, IN p_PaymentMethod ENUM('cash', 'card', 'paypal'))
BEGIN
    DECLARE v_Stock INT;
    DECLARE v_SellingPrice DECIMAL(10,2);
    DECLARE v_TotalAmount DECIMAL(10,2);
    
    -- Get product stock and selling price
    SELECT Stock, SellingPrice INTO v_Stock, v_SellingPrice FROM Products WHERE ProductID = p_ProductID;
    
    IF v_Stock >= p_Quantity THEN
        SET v_TotalAmount = v_SellingPrice * p_Quantity;
        
        -- Insert sale record
        INSERT INTO Sales (ProductID, CustomerID, Quantity, TotalAmount, PaymentMethod) 
        VALUES (p_ProductID, p_CustomerID, p_Quantity, v_TotalAmount, p_PaymentMethod);
        
        -- Update product stock
        UPDATE Products SET Stock = v_Stock - p_Quantity WHERE ProductID = p_ProductID;
    ELSE
        SELECT 'Not enough stock' AS Message;
    END IF;
END $$

DELIMITER ;



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
