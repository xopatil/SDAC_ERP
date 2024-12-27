DELIMITER //

CREATE PROCEDURE AddProduct(
    IN pName VARCHAR(255),
    IN pCategory VARCHAR(255),
    IN pCost DECIMAL(10, 2),
    IN pSellingPrice DECIMAL(10, 2),
    IN pStock INT,
    IN pReorderLevel INT,
    IN pSupplierInfo VARCHAR(255)
)
BEGIN
    INSERT INTO Products (Name, Category, Cost, Selling_Price, Stock, Reorder_Level, Supplier_Info)
    VALUES (pName, pCategory, pCost, pSellingPrice, pStock, pReorderLevel, pSupplierInfo);
END;//

CREATE PROCEDURE EditProduct(
    IN pProductID INT,
    IN pName VARCHAR(255),
    IN pCategory VARCHAR(255),
    IN pCost DECIMAL(10, 2),
    IN pSellingPrice DECIMAL(10, 2),
    IN pStock INT,
    IN pReorderLevel INT,
    IN pSupplierInfo VARCHAR(255)
)
BEGIN
    UPDATE Products
    SET Name = pName, Category = pCategory, Cost = pCost, Selling_Price = pSellingPrice, 
        Stock = pStock, Reorder_Level = pReorderLevel, Supplier_Info = pSupplierInfo
    WHERE ProductID = pProductID;
END;//

CREATE PROCEDURE DeleteProduct(IN pProductID INT)
BEGIN
    DELETE FROM Products WHERE ProductID = pProductID;
END;//

CREATE VIEW View_Products AS
SELECT ProductID, Name, Category, Cost, SellingPrice, Stock, SupplierInfo, Profitability
FROM Products;

DELIMITER ;
