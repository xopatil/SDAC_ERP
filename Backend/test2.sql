DELIMITER //

CREATE FUNCTION Product_Profitability() RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE totalProfit DECIMAL(10, 2);
    DECLARE product_id INT;
    DECLARE done INT DEFAULT 0;

    -- Cursor declaration to iterate through all products in the Sales and Products tables
    DECLARE product_cursor CURSOR FOR
        SELECT 
            s.ProductID, 
            SUM((IFNULL(s.Total_Amount / s.Quantity, 0) - IFNULL(p.Cost, 0)) * s.Quantity) AS TotalProfit
        FROM 
            Sales s
        JOIN 
            Products p ON s.ProductID = p.ProductID
        GROUP BY 
            s.ProductID;

    -- Handler for end of cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open the cursor
    OPEN product_cursor;

    -- Iterate through all products and append their profitability to the result JSON
    product_loop: LOOP
        FETCH product_cursor INTO product_id, totalProfit;

        IF done THEN
            LEAVE product_loop;
        END IF;

        -- If no sales data exists, set profit to 0
        IF totalProfit IS NULL THEN
            SET totalProfit = 0;
        END IF;

        -- Append the product's profitability to the JSON array
        SET result = JSON_ARRAY_APPEND(
            result,
            '$',
            JSON_OBJECT('ProductID', product_id, 'Profit', totalProfit)
        );
    END LOOP;

    -- Close the cursor
    CLOSE product_cursor;

    -- Return the result JSON object
    RETURN result;
END //

DELIMITER ;


DELIMITER //

CREATE FUNCTION Inventory_Turnover_Ratio(
    p_ProductID INT
) RETURNS JSON 
DETERMINISTIC
BEGIN
    -- Variables to store intermediate results
	DECLARE result JSON DEFAULT JSON_OBJECT('Timestamp', NOW());
    DECLARE v_COGS DECIMAL(10, 2);
    DECLARE v_Current_Stock INT;
    DECLARE v_Beginning_Stock INT;
    DECLARE v_Average_Inventory DECIMAL(10, 2);

    -- Calculate Cost of Goods Sold (COGS)
    SET v_COGS = (
        SELECT SUM(s.Quantity * p.Cost)
        FROM sales s
        JOIN products p ON s.ProductID = p.ProductID
        WHERE p.ProductID = p_ProductID
    );

    -- Get the current stock
    SET v_Current_Stock = (
        SELECT Stock
        FROM products
        WHERE ProductID = p_ProductID
    );

    -- Calculate beginning stock
    SET v_Beginning_Stock = (
        SELECT (v_Current_Stock + IFNULL(SUM(s.Quantity), 0))
        FROM sales s
        WHERE s.ProductID = p_ProductID
    );

    -- Calculate Average Inventory
    SET v_Average_Inventory = (v_Beginning_Stock + v_Current_Stock) / 2;

    -- Handle division by zero
    IF v_Average_Inventory = 0 THEN
        RETURN NULL; -- Return NULL if Average Inventory is zero
    END IF;

-- 	SET result = v_COGS / v_Average_Inventory;
    
    SET result = JSON_SET(result, '$.InventoryTurnoverRatio', v_COGS / v_Average_Inventory);

    -- Calculate and return Inventory Turnover Ratio
    RETURN result;
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

    -- Get original product ID and quantity for the sale
    SELECT ProductID, Quantity INTO v_OriginalProductID, v_OriginalQuantity
    FROM Sales
    WHERE SaleID = p_SaleID;

    -- Restore stock for the original product
    UPDATE Products
    SET Stock = Stock + v_OriginalQuantity
    WHERE ProductID = v_OriginalProductID;

    -- Check stock availability for the new product
    IF EXISTS (
        SELECT 1
        FROM Products
        WHERE ProductID = p_NewProductID AND Stock >= p_NewQuantity
    ) THEN
        -- Update the sale record
        UPDATE Sales
        SET ProductID = p_NewProductID,
            CustomerID = p_NewCustomerID,
            Quantity = p_NewQuantity,
            Payment_Method = p_NewPaymentMethod,
            Date = NOW(),
            Total_Amount = p_NewQuantity * (SELECT Selling_Price FROM Products WHERE ProductID = p_NewProductID)
        WHERE SaleID = p_SaleID;

        -- Deduct stock for the new product
        UPDATE Products
        SET Stock = Stock - p_NewQuantity
        WHERE ProductID = p_NewProductID;

        SELECT 'Sale updated successfully' AS Message;
    ELSE
        -- Revert stock restoration if new product stock is insufficient
        UPDATE Products
        SET Stock = Stock - v_OriginalQuantity
        WHERE ProductID = v_OriginalProductID;

        SELECT 'Not enough stock for the new quantity' AS Message;
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

CREATE PROCEDURE GenerateFeedbackInsights()
BEGIN
    SELECT ProductID, AVG(Ratings) AS AverageRating, COUNT(*) AS TotalFeedbacks
    FROM Feedback
    GROUP BY ProductID;
END;//

