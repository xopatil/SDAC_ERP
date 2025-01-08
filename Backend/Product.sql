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
END;//

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

CREATE VIEW ShowProducts AS
SELECT ProductID, Name, Category, Cost, Selling_Price, Stock, Supplier_Info, Expiry_Date, Reorder_Level, Sales_Data
FROM Products;

DELIMITER ;



DELIMITER //

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
