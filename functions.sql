DELIMITER //

-- Check if username exists
DROP FUNCTION IF EXISTS fn_username_exists;
CREATE FUNCTION fn_username_exists(p_username VARCHAR(50)) 
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE v_exists BOOLEAN;
    SELECT COUNT(*) > 0 INTO v_exists FROM Users WHERE username = p_username;
    RETURN v_exists;
END //

-- Check if email exists
DROP FUNCTION IF EXISTS fn_email_exists;
CREATE FUNCTION fn_email_exists(p_email VARCHAR(100)) 
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE v_exists BOOLEAN;
    SELECT COUNT(*) > 0 INTO v_exists FROM Users WHERE email = p_email;
    RETURN v_exists;
END //

-- Validate password strength
DROP FUNCTION IF EXISTS fn_validate_password;
CREATE FUNCTION fn_validate_password(p_password VARCHAR(255)) 
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    -- At least 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
    RETURN p_password REGEXP '^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*]).{8,}$';
END //

-- Get user role
DROP FUNCTION IF EXISTS fn_get_user_role;
CREATE FUNCTION fn_get_user_role(p_user_id INT) 
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE v_role VARCHAR(20);
    
    -- Check if user is a trustee
    SELECT 'Trustee' INTO v_role FROM Trustees WHERE user_id = p_user_id LIMIT 1;
    IF v_role IS NOT NULL THEN RETURN v_role; END IF;
    
    -- Check if user is a donor
    SELECT 'Donor' INTO v_role FROM Donors WHERE user_id = p_user_id LIMIT 1;
    IF v_role IS NOT NULL THEN RETURN v_role; END IF;
    
    -- Check if user is an adopter
    SELECT 'Adopter' INTO v_role FROM Adopters WHERE user_id = p_user_id LIMIT 1;
    IF v_role IS NOT NULL THEN RETURN v_role; END IF;
    
    RETURN 'Regular User';
END //

-- donation functions
-- Calculate total donations by a user
DROP FUNCTION IF EXISTS fn_get_user_total_donations;
CREATE FUNCTION fn_get_user_total_donations(p_user_id INT) 
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);
    SELECT COALESCE(SUM(amount), 0) INTO v_total 
    FROM Donations 
    WHERE user_id = p_user_id;
    RETURN v_total;
END //

-- Calculate total donations to an NGO
DROP FUNCTION IF EXISTS fn_get_ngo_total_donations;
CREATE FUNCTION fn_get_ngo_total_donations(p_ngo_id INT) 
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);
    SELECT COALESCE(SUM(amount), 0) INTO v_total 
    FROM Donations 
    WHERE ngo_id = p_ngo_id;
    RETURN v_total;
END //

-- Get donor's favorite NGO (most donated to)
DROP FUNCTION IF EXISTS fn_get_donor_favorite_ngo;
CREATE FUNCTION fn_get_donor_favorite_ngo(p_donor_id INT) 
RETURNS VARCHAR(255)
READS SQL DATA
BEGIN
    DECLARE v_ngo_name VARCHAR(255);
    SELECT n.name INTO v_ngo_name
    FROM Donations d
    JOIN NGOs n ON d.ngo_id = n.ngo_id
    WHERE d.donor_id = p_don_id
    GROUP BY d.ngo_id, n.name
    ORDER BY SUM(d.amount) DESC
    LIMIT 1;
    RETURN v_ngo_name;
END //

-- Check if donation is eligible for tax deduction
DROP FUNCTION IF EXISTS fn_is_tax_deductible;
CREATE FUNCTION fn_is_tax_deductible(p_ngo_id INT) 
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_deductible BOOLEAN;
    -- Assuming you have a field in NGOs table or can determine by category
    SELECT COUNT(*) > 0 INTO v_deductible 
    FROM NGO_Categories 
    WHERE ngo_id = p_ngo_id AND category_name IN ('Education', 'Health', 'Environment');
    RETURN v_deductible;
END //

-- ngo analysis function
-- Calculate NGO average rating
DROP FUNCTION IF EXISTS fn_get_ngo_avg_rating;
CREATE FUNCTION fn_get_ngo_avg_rating(p_ngo_id INT) 
RETURNS DECIMAL(3,2)
READS SQL DATA
BEGIN
    DECLARE v_avg_rating DECIMAL(3,2);
    SELECT COALESCE(AVG(rating), 0) INTO v_avg_rating 
    FROM Reviews 
    WHERE ngo_id = p_ngo_id;
    RETURN v_avg_rating;
END //

-- Count active beneficiaries for an NGO
DROP FUNCTION IF EXISTS fn_count_ngo_beneficiaries;
CREATE FUNCTION fn_count_ngo_beneficiaries(p_ngo_id INT) 
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count 
    FROM Beneficiaries 
    WHERE ngo_id = p_ngo_id;
    RETURN v_count;
END //

-- Count upcoming events for an NGO
DROP FUNCTION IF EXISTS fn_count_upcoming_events;
CREATE FUNCTION fn_count_upcoming_events(p_ngo_id INT) 
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count 
    FROM Events 
    WHERE ngo_id = p_ngo_id AND event_date >= CURDATE();
    RETURN v_count;
END //

-- Get NGO's primary category
DROP FUNCTION IF EXISTS fn_get_ngo_primary_category; 	
CREATE FUNCTION fn_get_ngo_primary_category(p_ngo_id INT) 
RETURNS VARCHAR(100)
READS SQL DATA
BEGIN
    DECLARE v_category VARCHAR(100);
    SELECT category_name INTO v_category
    FROM NGO_Categories
    WHERE ngo_id = p_ngo_id
    LIMIT 1;
    RETURN v_category;
END //

-- location based function

-- Calculate distance between two locations (simplified)
DROP FUNCTION IF EXISTS fn_calculate_distance;
CREATE FUNCTION fn_calculate_distance(
    lat1 DECIMAL(9,6), 
    lon1 DECIMAL(9,6), 
    lat2 DECIMAL(9,6), 
    lon2 DECIMAL(9,6)
) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    -- Simple approximation for short distances
    RETURN SQRT(POW(69.1 * (lat2 - lat1), 2) + 
                POW(69.1 * (lon2 - lon1) * COS(lat1 / 57.3), 2));
END //

-- Find NGOs within radius (miles)
DROP FUNCTION IF EXISTS fn_count_ngos_nearby;
CREATE FUNCTION fn_count_ngos_nearby(
    p_latitude DECIMAL(9,6),
    p_longitude DECIMAL(9,6),
    p_radius DECIMAL(10,2)
) 
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM NGOs n
    JOIN Locations l ON n.location_id = l.location_id
    WHERE fn_calculate_distance(p_latitude, p_longitude, l.latitude, l.longitude) <= p_radius;
    RETURN v_count;
END //

-- utility functions
-- Calculate age from birth date (for beneficiaries)
DROP FUNCTION IF EXISTS fn_calculate_age;
CREATE FUNCTION fn_calculate_age(p_birth_date DATE) 
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_birth_date, CURDATE());
END //

-- Format donation amount with currency
DROP FUNCTION IF EXISTS fn_format_donation_amount;
CREATE FUNCTION fn_format_donation_amount(p_amount DECIMAL(10,2)) 
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    RETURN CONCAT('$', FORMAT(p_amount, 2));
END //

-- Get days until next NGO event
DROP FUNCTION IF EXISTS fn_days_until_next_event;
CREATE FUNCTION fn_days_until_next_event(p_ngo_id INT) 
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_days INT;
    SELECT DATEDIFF(MIN(event_date), CURDATE()) INTO v_days
    FROM Events
    WHERE ngo_id = p_ngo_id AND event_date >= CURDATE();
    RETURN COALESCE(v_days, -1); -- Returns -1 if no upcoming events
END //

DELIMITER ;