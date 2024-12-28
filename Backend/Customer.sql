DELIMITER //

CREATE PROCEDURE EditCustomer(
    IN customer_id INT,
    IN new_name VARCHAR(255),
    IN new_phone VARCHAR(15),
    IN new_address TEXT,
    IN new_email VARCHAR(255)
)
BEGIN

	IF new_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
		SELECT 'Invalid email format.' AS Message;
    -- Validate phone number format (only digits and 10-15 characters)
    ELSEIF new_phone NOT REGEXP '^[0-9]{10,15}$' THEN
        SELECT 'Invalid phone number. Must contain only 10 digits.' AS Message;
	ELSE
		UPDATE Customers
		SET 
			Name = new_name,
			Phone = new_phone,
			Address = new_address,
			Email = new_email
		WHERE CustomerID = customer_id;
		
		SELECT 'Customer details updated successfully.' AS Message;
	END IF;
END; //


CREATE PROCEDURE DeactivateInactiveCustomers()
BEGIN
    -- Declare all variables at the start
    DECLARE currentDate DATE;
    DECLARE last_purchase_date DATE;
    DECLARE done INT DEFAULT 0;
    DECLARE customer_id INT;
    DECLARE purchase_history TEXT;
    DECLARE customer_cursor CURSOR FOR
        SELECT CustomerID, Purchase_History FROM Customers;

    -- Declare handler for when the cursor reaches the end of the result set
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Set the current date
    SET currentDate = CURDATE();

    -- Open the cursor
    OPEN customer_cursor;

    -- Loop through the cursor and process each customer
    read_loop: LOOP
        FETCH customer_cursor INTO customer_id, purchase_history;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Extract the date of the most recent purchase
        SET last_purchase_date = STR_TO_DATE(
            REGEXP_SUBSTR(purchase_history, 'Date: ([0-9-]+)'),  -- Corrected the REGEXP_SUBSTR usage
            '%Y-%m-%d'
        );

        -- Check if the last purchase date is older than 1 year (365 days)
        IF last_purchase_date IS NOT NULL AND DATEDIFF(currentDate, last_purchase_date) > 365 THEN
            DELETE FROM Customers WHERE CustomerID = customer_id;
        END IF;
    END LOOP;

    -- Close the cursor
    CLOSE customer_cursor;

    -- Return the number of rows affected
    SELECT ROW_COUNT() AS 'Number of customers deactivated';
END //

CREATE VIEW ShowCustomers AS
SELECT CustomerID, Name, Email, Phone, Address, Purchase_History, Loyalty_Points
FROM Customers;

DELIMITER ;
