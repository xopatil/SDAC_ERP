DELIMITER //

CREATE FUNCTION Product_Profitability(
    pProductID INT
) RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE sellingPrice DECIMAL(10, 2);
    DECLARE costPrice DECIMAL(10, 2);
    DECLARE totalQuantitySold INT;
    DECLARE totalProfit DECIMAL(10, 2);

    -- Retrieve the selling price, cost price, and total quantity sold for the product
    SELECT MAX(Selling_Price), MAX(Cost), 
           COALESCE(SUM(Quantity), 0)
    INTO sellingPrice, costPrice, totalQuantitySold
    FROM Products
    LEFT JOIN Sales ON Products.ProductID = Sales.ProductID
    WHERE Products.ProductID = pProductID;

    -- Calculate the total profit for the product
    SET totalProfit = (sellingPrice - costPrice) * totalQuantitySold;
    
    INSERT INTO Logs (Algorithm_Name, Timestamp, Results)
    VALUES ('Product Profitability', NOW(), totalProfit);

    RETURN totalProfit;
END;

//
DELIMITER ;
