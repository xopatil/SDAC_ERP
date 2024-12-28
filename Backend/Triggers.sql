DELIMITER //

CREATE TRIGGER After_Sale_Insert
AFTER INSERT ON Sales
FOR EACH ROW
BEGIN
    -- Update sales_data in the Products table
    UPDATE Products
    SET Sales_Data = CONCAT(IFNULL(Sales_Data, ''), 
                            'ProductID: ', NEW.ProductID, ', Quantity: ', NEW.Quantity, ', Date: ', NEW.Date, '\n')
    WHERE ProductID = NEW.ProductID;

    -- Update purchase_history in the Customers table
    UPDATE Customers
    SET Purchase_History = CONCAT(IFNULL(Purchase_History, ''), 
                                  'ProductID: ', NEW.ProductID, ', Quantity: ', NEW.Quantity, ', Date: ', NEW.Date, '\n')
    WHERE CustomerID = NEW.CustomerID;

    -- Update loyalty points in the Customers table
    UPDATE Customers
    SET Loyalty_Points = IFNULL(Loyalty_Points, 0) + 20
    WHERE CustomerID = NEW.CustomerID;
END //

DELIMITER //

CREATE TRIGGER After_Sale_Update
AFTER UPDATE ON Sales
FOR EACH ROW
BEGIN
    -- Update Sales_Data in the Products table
    UPDATE Products
    SET Sales_Data = CONCAT(IFNULL(Sales_Data, ''), 
                            ' ProductID: ', NEW.ProductID, 
                            ', New Quantity: ', NEW.Quantity, 
                            ', Date: ', NOW(), '\n')
    WHERE ProductID = NEW.ProductID;

    -- Update Purchase_History in the Customers table
    UPDATE Customers
    SET Purchase_History = CONCAT(IFNULL(Purchase_History, ''), 
                                  ' ProductID: ', NEW.ProductID, 
                                  ', New Quantity: ', NEW.Quantity, 
                                  ', Date: ', NOW(), '\n')
    WHERE CustomerID = NEW.CustomerID;

    -- Increment Loyalty Points by 20 for each sale
    UPDATE Customers
    SET Loyalty_Points = IFNULL(Loyalty_Points, 0) + 20
    WHERE CustomerID = NEW.CustomerID;
    
END; //

DELIMITER //

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

DELIMITER //

CREATE TRIGGER UpdateUserOnCustomerUpdate
AFTER UPDATE ON Customers
FOR EACH ROW
BEGIN
    -- Update the Users table when a customer's name or email is updated
    IF OLD.Email != NEW.Email OR OLD.Name != NEW.Name THEN
        UPDATE Users
        SET 
            MailID = NEW.Email,
            Name = NEW.Name
        WHERE MailID = OLD.Email;
    END IF;
END;//

DELIMITER ;
