DELIMITER //

CREATE PROCEDURE EditUser(
    IN user_id INT,
    IN new_mail_id VARCHAR(255),
    IN new_name VARCHAR(255),
    IN new_role ENUM('Admin', 'Regular')
)
BEGIN
    -- Validate email format using a basic pattern
    IF new_mail_id NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        -- If the email is invalid, return a message and do not proceed with the update
        SELECT 'Invalid email format. Please provide a valid email.' AS Message;
    ELSE
        -- If the email is valid, update the user details
        UPDATE Users
        SET 
            MailID = new_mail_id,
            Name = new_name,
            Role = new_role
        WHERE UserID = user_id;

        -- Return a success message
        SELECT 'User details updated successfully.' AS Message;
    END IF;
END; //

DELIMITER ;


CREATE PROCEDURE DeleteUserAndCustomer(IN user_mail VARCHAR(255))
BEGIN
    DECLARE customer_exists INT;

    -- Check if the customer exists for the given user email
    SELECT COUNT(*) INTO customer_exists
    FROM Customers
    WHERE Email = user_mail;

    -- If a customer exists, delete the customer
    IF customer_exists > 0 THEN
        DELETE FROM Customers WHERE Email = user_mail;
    END IF;

    -- Delete the user
    DELETE FROM Users WHERE MailID = user_mail;

    -- Display the single-line deletion message
    SELECT 'User and associated customer (if any) have been deleted.' AS DeletionMessage;
END //

CREATE PROCEDURE EditUserDetails(
    IN pUserID INT,
    IN pName VARCHAR(255),
    IN pMailID VARCHAR(255),
    IN pRole ENUM('Admin', 'Regular')
)
BEGIN
    UPDATE Users
    SET Name = pName, MailID = pMailID, Role = pRole
    WHERE UserID = pUserID;
END;//

CREATE VIEW ShowUsers AS
SELECT UserID, MailID, Name, Password, Role
FROM Users;

DELIMITER ;