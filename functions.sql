-- Drop commands for existing functions
DROP FUNCTION IF EXISTS GetAverageRating;
DROP FUNCTION IF EXISTS CheckAdoptionConflict;
DROP FUNCTION IF EXISTS EncryptPassword;
DROP FUNCTION IF EXISTS GetUserRole;

-- Calculate Average Rating for an NGO
DELIMITER //
CREATE FUNCTION GetAverageRating(p_ngo_id INT) 
RETURNS DECIMAL(3,2)
DETERMINISTIC
BEGIN
    DECLARE avg_rating DECIMAL(3,2);
    SELECT AVG(rating) INTO avg_rating
    FROM Reviews
    WHERE ngo_id = p_ngo_id;
    RETURN COALESCE(avg_rating, 0);
END //

CREATE FUNCTION CheckAdoptionConflict(p_beneficiary_id INT) 
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE is_adopted BOOLEAN;
    SELECT COUNT(*) > 0 INTO is_adopted
    FROM Adoptions
    WHERE beneficiary_id = p_beneficiary_id;
    RETURN is_adopted;
END //

CREATE FUNCTION GetUserRole(p_user_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE role VARCHAR(20);
    DECLARE v_username VARCHAR(50);
    
    SELECT username INTO v_username FROM Users WHERE user_id = p_user_id;
    
    IF v_username = 'admin' THEN
        SET role = 'Admin';
    ELSEIF EXISTS (SELECT 1 FROM Donors WHERE user_id = p_user_id) THEN
        SET role = 'Donor';
    ELSEIF EXISTS (SELECT 1 FROM Adopters WHERE user_id = p_user_id) THEN
        SET role = 'Adopter';
    ELSEIF EXISTS (SELECT 1 FROM Trustees WHERE user_id = p_user_id) THEN
        SET role = 'Trustee';
    ELSE
        SET role = 'User';
    END IF;
    RETURN role;
END //
DELIMITER ;
