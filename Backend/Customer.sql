DELIMITER //

CREATE PROCEDURE EditCustomer(
    IN customer_id INT,
    IN new_name VARCHAR(255),
    IN new_phone VARCHAR(15),
    IN new_address TEXT,
    IN new_email VARCHAR(255)
)
BEGIN
    -- Validate email format
    IF new_email IS NOT NULL AND new_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SELECT 'Invalid email format.' AS Message;

    -- Validate phone number format (only digits and 10-15 characters)
    ELSEIF new_phone IS NOT NULL AND new_phone NOT REGEXP '^[0-9]{10,15}$' THEN
        SELECT 'Invalid phone number. Must contain only 10-15 digits.' AS Message;

    ELSE
        -- Update only the fields that are not NULL
        UPDATE Customers
        SET 
            Name = CASE WHEN new_name IS NOT NULL THEN new_name ELSE Name END,
            Phone = CASE WHEN new_phone IS NOT NULL THEN new_phone ELSE Phone END,
            Address = CASE WHEN new_address IS NOT NULL THEN new_address ELSE Address END,
            Email = CASE WHEN new_email IS NOT NULL THEN new_email ELSE Email END
        WHERE CustomerID = customer_id;

        SELECT 'Customer details updated successfully.' AS Message;
    END IF;
END; //

CREATE PROCEDURE DeactivateInactiveCustomers()
BEGIN
    -- Declare variables
    DECLARE currentDate DATE;
    DECLARE lastPurchaseDate DATETIME;
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_id INT;
    DECLARE v_user_mail VARCHAR(255);
    DECLARE v_history TEXT;
    DECLARE deactivatedCount INT DEFAULT 0;

    -- Cursor declaration 
    DECLARE curs CURSOR FOR 
        SELECT CustomerID, Email, Purchase_History 
        FROM Customers 
        ORDER BY CustomerID;

    -- Handler declaration
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    -- Set the current date
    SET currentDate = CURDATE();
	
    -- Open cursor
    OPEN curs;

    read_loop: LOOP
        -- Fetch the data
        FETCH curs INTO v_id, v_user_mail, v_history;
        
        -- Exit if done
        IF v_done THEN
            LEAVE read_loop;
        END IF;
		
        -- Extract the latest purchase date
        SET lastPurchaseDate = (
            SELECT MAX(
                STR_TO_DATE(
                    TRIM(
                        SUBSTRING_INDEX(
                            SUBSTRING_INDEX(v_history, 'Date: ', -1), 
                            ', ', 1
                        )
                    ),
                    '%Y-%m-%d %H:%i:%s'
                )
            )
            FROM (
                SELECT 1 AS seq UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
            ) AS seq
            WHERE INSTR(v_history, 'Date:') > 0
        );

--         SELECT 
--             v_id AS ProcessingCustomerID,
--             lastPurchaseDate AS ExtractedDate,
--             DATEDIFF(currentDate, lastPurchaseDate) AS DaysDifference;

        -- Check if the last purchase date is more than 1 day ago
        IF lastPurchaseDate IS NOT NULL AND DATEDIFF(currentDate, lastPurchaseDate) > 1 THEN
            -- Deactivate the customer (delete)
            CALL DeleteUserAndCustomer(v_user_mail);
            
            SET deactivatedCount = deactivatedCount + 1;
        END IF;

    END LOOP;

    -- Close cursor
    CLOSE curs;

    -- Return the number of deactivated customers
    SELECT deactivatedCount AS 'Number of customers deactivated';
END //

CREATE VIEW ShowCustomers AS
SELECT CustomerID, Name, Email, Phone, Address, Purchase_History, Loyalty_Points
FROM Customers;

DELIMITER ;
