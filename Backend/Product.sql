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
	DECLARE product_id INT;

    INSERT INTO Products (Name, Category, Cost, Selling_Price, Stock, Reorder_Level, Supplier_Info, Expiry_Date)
    VALUES (pName, pCategory, pCost, pSellingPrice, pStock, pReorderLevel, pSupplierInfo, pExpiryDate);
    
    SET product_id = LAST_INSERT_ID();
	-- Check if insertion was successful by checking if a product ID was generated
    IF product_id > 0 THEN
        SELECT 'Success: Product inserted successfully!' AS Message;
    ELSE
        SELECT 'Error: Product insertion failed!' AS Message;
    END IF;

END;//

DELIMITER //

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
    DECLARE rows_affected INT;

    -- Update the product details
    UPDATE Products
    SET Name = pName,
        Category = pCategory,
        Cost = pCost,
        Selling_Price = pSellingPrice,
        Stock = pStock,
        Reorder_Level = pReorderLevel,
        Supplier_Info = pSupplierInfo,
        Expiry_Date = pExpiryDate,
        Sales_Data = pSalesData
    WHERE ProductID = pProductID;

    -- Get the number of rows affected by the update
    SET rows_affected = ROW_COUNT();

    -- Check the result of the update
    IF rows_affected > 0 THEN
        SELECT 'Product updated successfully!' AS Message;
    ELSE
        SELECT 'No changes made or ProductID not found!' AS Message;
    END IF;
END; //

-- DeleteProduct Procedure
CREATE PROCEDURE DeleteProduct(IN pProductID INT)
BEGIN
    DECLARE rows_affected INT;

    DELETE FROM Products WHERE ProductID = pProductID;

    SET rows_affected = ROW_COUNT();

    -- Check if deletion was successful
    IF rows_affected > 0 THEN
        SELECT 'Success: Product deleted successfully!' AS Message;
    ELSE
        SELECT 'Error: No product found with the given ProductID!' AS Message;
    END IF;
END;//

CREATE VIEW ShowProducts AS
SELECT ProductID, Name, Category, Cost, Selling_Price, Stock, Supplier_Info, Expiry_Date, Reorder_Level, Sales_Data
FROM Products;

DELIMITER ;
