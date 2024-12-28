DELIMITER //

CREATE FUNCTION RegisterUser(
    pMailID VARCHAR(255),
    pName VARCHAR(255),
    pPassword VARCHAR(255),
    pConfirmPassword VARCHAR(255),
    pPhoneNumber VARCHAR(15),
    pRole ENUM('Admin', 'Regular')
) RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE resultMessage VARCHAR(255);

    -- Validate email format using a basic pattern
    IF pMailID NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SET resultMessage = 'Invalid email format.';
    -- Validate phone number format (only digits and 10-15 characters)
    ELSEIF pPhoneNumber NOT REGEXP '^[0-9]{10,15}$' THEN
        SET resultMessage = 'Invalid phone number. Must contain only 10 digits.';
    -- Check if passwords match
    ELSEIF pPassword <> pConfirmPassword THEN
        SET resultMessage = 'Passwords do not match.';
    ELSE
        -- Check if the user already exists
        IF EXISTS (SELECT 1 FROM Users WHERE MailID = pMailID) THEN
            SET resultMessage = 'User already exists.';
        ELSE
            -- Insert new user with hashed password
            INSERT INTO Users (MailID, Name, Password, Role)
            VALUES (pMailID, pName, SHA2(pPassword, 256), pRole);
            SET resultMessage = 'Registration successful.';
        END IF;
    END IF;

    RETURN resultMessage;
END;

//
DELIMITER ;