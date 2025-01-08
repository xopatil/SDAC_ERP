
DELIMITER //

CREATE TRIGGER After_Sale_Insert
AFTER INSERT ON Sales
FOR EACH ROW
BEGIN
    DECLARE v_Stock INT;
    DECLARE v_SellingPrice DECIMAL(10, 2);

    -- Fetch stock and selling price for the product
    SELECT Stock, Selling_Price INTO v_Stock, v_SellingPrice
    FROM Products
    WHERE ProductID = NEW.ProductID;

    -- Check if stock is sufficient for the sale
    IF v_Stock < NEW.Quantity THEN
        -- If not enough stock, cancel the sale by deleting the record (optional)
        DELETE FROM Sales WHERE SaleID = NEW.SaleID;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for this sale.';
    ELSE
        -- Update stock after the sale
        UPDATE Products
        SET Stock = Stock - NEW.Quantity
        WHERE ProductID = NEW.ProductID;

        -- Update Sales_Data in the Products table (store information about the sale)
        UPDATE Products
        SET Sales_Data = CONCAT_WS('\n', IFNULL(Sales_Data, ''),
                                   CONCAT('Sale ID: ', NEW.SaleID, ', Quantity: ', NEW.Quantity, ', Date: ', NOW()))
        WHERE ProductID = NEW.ProductID;

        -- Update purchase_history and loyalty points in the Customers table
        UPDATE Customers
        SET Purchase_History = CONCAT_WS('\n', IFNULL(Purchase_History, ''),
                                          CONCAT('Sale ID: ', NEW.SaleID, ', Quantity: ', NEW.Quantity, ', Date: ', NOW())),
            Loyalty_Points = IFNULL(Loyalty_Points, 0) + 20
        WHERE CustomerID = NEW.CustomerID;
    END IF;
END; //

-- CREATE TRIGGER After_Sale_Update
-- AFTER UPDATE ON Sales
-- FOR EACH ROW
-- BEGIN
--     -- Update Sales_Data in the Products table
--     UPDATE Products
--     SET Sales_Data = CONCAT_WS('\n', IFNULL(Sales_Data, ''), 
--                                CONCAT('ProductID: ', NEW.ProductID, ', New Quantity: ', NEW.Quantity, ', Date: ', NOW()))
--     WHERE ProductID = NEW.ProductID;

--     -- Update Purchase_History and increment Loyalty Points in the Customers table
--     UPDATE Customers
--     SET Purchase_History = CONCAT_WS('\n', IFNULL(Purchase_History, ''), 
--                                      CONCAT('ProductID: ', NEW.ProductID, ', New Quantity: ', NEW.Quantity, ', Date: ', NOW())),
--         Loyalty_Points = IFNULL(Loyalty_Points, 0) + 20
--     WHERE CustomerID = NEW.CustomerID;
-- END; //

CREATE TRIGGER After_User_Insert
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    -- Insert into Customers table only if the Role is 'Regular'
    IF NEW.Role = 'Regular' THEN
        INSERT INTO Customers (CustomerID, Email, Name, Loyalty_Points, Purchase_History)
        VALUES (NEW.UserID, NEW.MailID, NEW.Name, 0, '');
    END IF;
END; //

CREATE TRIGGER UpdateUserOnCustomerUpdate
AFTER UPDATE ON Customers
FOR EACH ROW
BEGIN
    -- Update the Users table only if email or name changes
    IF OLD.Email != NEW.Email OR OLD.Name != NEW.Name THEN
        UPDATE Users
        SET MailID = NEW.Email, Name = NEW.Name
        WHERE UserID = NEW.CustomerID;
    END IF;
END //

DELIMITER ;
