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

DROP PROCEDURE IF EXISTS GetTrusteeBeneficiaries //
CREATE PROCEDURE GetTrusteeBeneficiaries(IN p_user_id INT)
BEGIN
    DECLARE v_ngo_id INT;
    SELECT ngo_id INTO v_ngo_id FROM Trustees WHERE user_id = p_user_id;
    SELECT * FROM Beneficiaries WHERE ngo_id = v_ngo_id;
END //

-- Add NGO
DROP PROCEDURE IF EXISTS AddNGO //
CREATE PROCEDURE AddNGO(
    IN p_name VARCHAR(255),
    IN p_description TEXT,
    IN p_website VARCHAR(255),
    IN p_contact_email VARCHAR(100),
    IN p_contact_phone VARCHAR(20),
    IN p_city VARCHAR(100),
    IN p_state VARCHAR(100),
    IN p_country VARCHAR(100),
    IN p_latitude DECIMAL(9,6),
    IN p_longitude DECIMAL(9,6)
)
BEGIN
    DECLARE v_location_id INT;
    
    -- Insert or get existing location
    INSERT INTO Locations (city, state, country, latitude, longitude)
    VALUES (p_city, p_state, p_country, p_latitude, p_longitude)
    ON DUPLICATE KEY UPDATE location_id = LAST_INSERT_ID(location_id);
    
    SET v_location_id = LAST_INSERT_ID();
    
    -- Insert NGO
    INSERT INTO NGOs (name, description, website, contact_email, contact_phone, location_id)
    VALUES (p_name, p_description, p_website, p_contact_email, p_contact_phone, v_location_id);
END //

-- Update NGO
DROP PROCEDURE IF EXISTS UpdateNGO //
CREATE PROCEDURE UpdateNGO(
    IN p_ngo_id INT,
    IN p_name VARCHAR(255),
    IN p_description TEXT,
    IN p_website VARCHAR(255),
    IN p_contact_email VARCHAR(100),
    IN p_contact_phone VARCHAR(20)
)
BEGIN
    UPDATE NGOs
    SET name = p_name,
        description = p_description,
        website = p_website,
        contact_email = p_contact_email,
        contact_phone = p_contact_phone
    WHERE ngo_id = p_ngo_id;
END //

-- Delete NGO
DROP PROCEDURE IF EXISTS DeleteNGO //
CREATE PROCEDURE DeleteNGO(IN p_ngo_id INT)
BEGIN
    DELETE FROM NGOs WHERE ngo_id = p_ngo_id;
END //

DROP PROCEDURE IF EXISTS AdminGetTableData //
CREATE PROCEDURE AdminGetTableData(IN p_table_name VARCHAR(64))
BEGIN
    -- Prevent SQL injection by validating table name
    SET @table_name = NULL;
    CASE p_table_name
        WHEN 'Users' THEN SET @table_name = 'Users';
        WHEN 'NGOs' THEN SET @table_name = 'NGOs';
        WHEN 'Locations' THEN SET @table_name = 'Locations';
        WHEN 'Donors' THEN SET @table_name = 'Donors';
        WHEN 'Donations' THEN SET @table_name = 'Donations';
        WHEN 'Beneficiaries' THEN SET @table_name = 'Beneficiaries';
        WHEN 'Adopters' THEN SET @table_name = 'Adopters';
        WHEN 'Adoptions' THEN SET @table_name = 'Adoptions';
        WHEN 'Trustees' THEN SET @table_name = 'Trustees';
        WHEN 'Events' THEN SET @table_name = 'Events';
        WHEN 'Reviews' THEN SET @table_name = 'Reviews';
        WHEN 'NGO_Categories' THEN SET @table_name = 'NGO_Categories';
        ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid table name';
    END CASE;

    SET @sql = CONCAT('SELECT * FROM ', @table_name);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;
