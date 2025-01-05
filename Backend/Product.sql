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
    IN pStock INT,
    IN pReorderLevel INT,
    IN pSupplierInfo VARCHAR(255),
    IN pExpiryDate DATE,
    IN pSalesData TEXT
)
BEGIN
    -- Update the product details, only updating non-NULL values
    UPDATE Products
    SET 
        Name = CASE WHEN pName IS NOT NULL THEN pName ELSE Name END,
        Category = CASE WHEN pCategory IS NOT NULL THEN pCategory ELSE Category END,
        Cost = CASE WHEN pCost IS NOT NULL THEN pCost ELSE Cost END,
        Selling_Price = CASE WHEN pSellingPrice IS NOT NULL THEN pSellingPrice ELSE Selling_Price END,
        Stock = CASE WHEN pStock IS NOT NULL THEN pStock ELSE Stock END,
        Reorder_Level = CASE WHEN pReorderLevel IS NOT NULL THEN pReorderLevel ELSE Reorder_Level END,
        Supplier_Info = CASE WHEN pSupplierInfo IS NOT NULL THEN pSupplierInfo ELSE Supplier_Info END,
        Expiry_Date = CASE WHEN pExpiryDate IS NOT NULL THEN pExpiryDate ELSE Expiry_Date END,
        Sales_Data = CASE WHEN pSalesData IS NOT NULL THEN pSalesData ELSE Sales_Data END
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
