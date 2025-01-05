DELIMITER //

CREATE PROCEDURE RegisterUser(
    IN pMailID VARCHAR(255),
    IN pName VARCHAR(255),
    IN pPassword VARCHAR(255),
    IN pConfirmPassword VARCHAR(255),
    IN pRole ENUM('Admin', 'Regular')
)
BEGIN
    -- Validate email format
    IF pMailID NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SELECT 'Invalid email format.' AS Message;

    -- Check if passwords match
    ELSEIF pPassword <> pConfirmPassword THEN
        SELECT 'Passwords do not match.' AS Message;

    -- Check if the user already exists
    ELSEIF EXISTS (SELECT 1 FROM Users WHERE MailID = pMailID) THEN
        SELECT 'User already exists.' AS Message;

    ELSE
        -- Insert the new user
        INSERT INTO Users (MailID, Name, Password, Role)
        VALUES (pMailID, pName, SHA2(pPassword, 256), pRole);

        SELECT 'Registration successful.' AS Message;
    END IF;
END;

//
DELIMITER ;
