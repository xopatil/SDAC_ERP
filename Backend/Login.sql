DELIMITER //

CREATE PROCEDURE LoginUser(
    IN pMailID VARCHAR(255),
    IN pPassword VARCHAR(255)
)
BEGIN
    DECLARE userRole ENUM('Admin', 'Regular');

    -- Validate user credentials and get the user's role
    SELECT Role INTO userRole 
    FROM Users 
    WHERE MailID = pMailID AND Password = SHA2(pPassword, 256);

    -- Provide appropriate feedback directly
    IF userRole IS NOT NULL THEN
        SELECT CONCAT('Login successful. Role: ', userRole) AS Message;
    ELSE
        SELECT 'Invalid email or password.' AS Message;
    END IF;
END;

//
DELIMITER ;
