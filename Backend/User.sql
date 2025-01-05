DELIMITER //

CREATE PROCEDURE EditUser(
    IN user_id INT,
    IN new_mail_id VARCHAR(255),
    IN new_name VARCHAR(255),
    IN new_role ENUM('Admin', 'Regular')
)
BEGIN
    -- Validate email format if a new email is provided
    IF new_mail_id IS NOT NULL AND new_mail_id NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        -- Return a message if email is invalid
        SELECT 'Invalid email format. Please provide a valid email.' AS Message;
    ELSE
        -- Update only the fields provided (non-NULL values)
        UPDATE Users
        SET 
            MailID = CASE WHEN new_mail_id IS NOT NULL THEN new_mail_id ELSE MailID END,
            Name = CASE WHEN new_name IS NOT NULL THEN new_name ELSE Name END,
            Role = CASE WHEN new_role IS NOT NULL THEN new_role ELSE Role END
        WHERE UserID = user_id;

        -- Return a success message
        SELECT 'User details updated successfully.' AS Message;
    END IF;
END; //

CREATE PROCEDURE DeleteUserAndCustomer(IN user_mail VARCHAR(255))
BEGIN
    -- Delete the customer if associated with the given user email
    DELETE FROM Customers WHERE Email = user_mail;

    -- Delete the user
    DELETE FROM Users WHERE MailID = user_mail;

    -- Display the single-line deletion message
    SELECT 'User and associated customer (if any) have been deleted.' AS DeletionMessage;
END; //

DELIMITER ;

