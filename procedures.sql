-- User Authentication
DELIMITER //
DROP PROCEDURE IF EXISTS AuthenticateUser;
CREATE PROCEDURE AuthenticateUser(IN p_username VARCHAR(50), IN p_password_hash VARCHAR(255))
BEGIN
    SELECT user_id, username, email 
    FROM Users 
    WHERE username = p_username AND password_hash = p_password_hash;
END;

DROP PROCEDURE IF EXISTS ResetPassword;
CREATE PROCEDURE ResetPassword(IN p_email VARCHAR(100), IN p_new_hash VARCHAR(255))
BEGIN
    UPDATE Users 
    SET password_hash = p_new_hash 
    WHERE email = p_email;
END;

DROP PROCEDURE IF EXISTS SubmitReview;
CREATE PROCEDURE SubmitReview(IN p_user_id INT, IN p_ngo_id INT, IN p_rating INT, IN p_text TEXT)
BEGIN
    INSERT INTO Reviews (user_id, ngo_id, rating, review_text)
    VALUES (p_user_id, p_ngo_id, p_rating, p_text);
END;

DROP PROCEDURE IF EXISTS CreateEvent;
CREATE PROCEDURE CreateEvent(
    IN p_name VARCHAR(255), 
    IN p_description TEXT, 
    IN p_ngo_id INT, 
    IN p_event_date DATE, 
    IN p_location TEXT
)
BEGIN
    INSERT INTO Events (name, description, ngo_id, event_date, location)
    VALUES (p_name, p_description, p_ngo_id, p_event_date, p_location);
END //
DELIMITER ;
