DELIMITER //

CREATE FUNCTION LoginUser(
    pMailID VARCHAR(255),
    pPassword VARCHAR(255)
) RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE resultMessage VARCHAR(255);
    DECLARE userRole ENUM('Admin', 'Regular');
    
    -- Validate user credentials
    SELECT Role INTO userRole 
    FROM Users 
    WHERE MailID = pMailID AND Password = SHA2(pPassword, 256);
    
    IF userRole IS NOT NULL THEN
        SET resultMessage = CONCAT('Login successful. Role: ', userRole);
    ELSE
        SET resultMessage = 'Invalid email or password.';
    END IF;
    
    RETURN resultMessage;
END;

//
DELIMITER ;