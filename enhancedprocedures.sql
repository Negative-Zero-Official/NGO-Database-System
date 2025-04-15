DELIMITER //

-- 1. Enhanced User Registration
DROP PROCEDURE IF EXISTS register_user //
CREATE PROCEDURE register_user(
    IN p_username VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(255)  -- Now accepts plain password
)
BEGIN
    DECLARE v_hashed_password VARCHAR(255);
    
    -- Validate using functions
    IF fn_username_exists(p_username) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username already exists';
    ELSEIF fn_email_exists(p_email) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Email already registered';
    ELSEIF NOT fn_validate_password(p_password) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'Password must be 8+ chars with uppercase, lowercase, number, and special character';
    END IF;
    
    -- Hash password (in production, use proper hashing)
    SET v_hashed_password = SHA2(CONCAT(p_password, 'salt'), 256);
    
    -- Register user
    INSERT INTO Users (username, email, password_hash)
    VALUES (p_username, p_email, v_hashed_password);
    
    -- Return enhanced response
    SELECT 
        user_id,
        username,
        email,
        fn_get_user_role(LAST_INSERT_ID()) AS user_role,
        'Registration successful' AS message
    FROM Users WHERE user_id = LAST_INSERT_ID();
END //

-- 2. Enhanced User Login Verification
DROP PROCEDURE IF EXISTS verify_login //
CREATE PROCEDURE verify_login(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255)  -- Now accepts plain password
)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_stored_hash VARCHAR(255);
    DECLARE v_hashed_input VARCHAR(255);
    
    -- Get stored credentials
    SELECT user_id, password_hash INTO v_user_id, v_stored_hash
    FROM Users WHERE username = p_username;
    
    -- Hash input password (same method as registration)
    SET v_hashed_input = SHA2(CONCAT(p_password, 'salt'), 256);
    
    IF v_user_id IS NULL OR v_stored_hash != v_hashed_input THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid username or password';
    ELSE
        -- Return enhanced response
        SELECT 
            u.user_id,
            u.username,
            u.email,
            fn_get_user_role(v_user_id) AS user_role,
            'Login successful' AS message
        FROM Users u WHERE u.user_id = v_user_id;
    END IF;
END //

-- 3. Enhanced Update User Profile
DROP PROCEDURE IF EXISTS update_user_profile //
CREATE PROCEDURE update_user_profile(
    IN p_user_id INT,
    IN p_new_username VARCHAR(50),
    IN p_new_email VARCHAR(100)
)
BEGIN
    -- Validate using functions
    IF p_new_username != (SELECT username FROM Users WHERE user_id = p_user_id) 
       AND fn_username_exists(p_new_username) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Username already taken';
    ELSEIF p_new_email != (SELECT email FROM Users WHERE user_id = p_user_id) 
          AND fn_email_exists(p_new_email) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'Email already registered';
    END IF;
    
    -- Update profile
    UPDATE Users
    SET username = p_new_username,
        email = p_new_email
    WHERE user_id = p_user_id;
    
    -- Return enhanced response
    SELECT 
        user_id,
        username,
        email,
        fn_get_user_role(p_user_id) AS user_role,
        'Profile updated successfully' AS message
    FROM Users WHERE user_id = p_user_id;
END //

-- 6. Enhanced Process Donation
DROP PROCEDURE IF EXISTS process_donation //
CREATE PROCEDURE process_donation(
    IN p_user_id INT,
    IN p_ngo_id INT,
    IN p_donor_id INT,
    IN p_amount DECIMAL(10,2),
    IN p_payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer')
)
BEGIN
    DECLARE v_tax_deductible BOOLEAN;
    
    -- Validate using functions
    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid user ID';
    ELSEIF NOT EXISTS (SELECT 1 FROM NGOs WHERE ngo_id = p_ngo_id) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Invalid NGO ID';
    ELSEIF NOT EXISTS (SELECT 1 FROM Donors WHERE donor_id = p_donor_id) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'Invalid donor ID';
    ELSEIF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45003' SET MESSAGE_TEXT = 'Donation amount must be positive';
    ELSEIF NOT EXISTS (SELECT 1 FROM Donors WHERE donor_id = p_donor_id AND user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45004' SET MESSAGE_TEXT = 'Donor does not belong to this user';
    END IF;
    
    -- Check tax deductibility
    SET v_tax_deductible = fn_is_tax_deductible(p_ngo_id);
    
    -- Process donation
    INSERT INTO Donations (user_id, ngo_id, donor_id, amount, payment_method, is_tax_deductible)
    VALUES (p_user_id, p_ngo_id, p_donor_id, p_amount, p_payment_method, v_tax_deductible);
    
    -- Return enhanced response
    SELECT 
        d.donation_id,
        n.name AS ngo_name,
        fn_format_donation_amount(d.amount) AS formatted_amount,
        d.payment_method,
        d.donation_date,
        IF(d.is_tax_deductible, 'Yes', 'No') AS tax_deductible,
        fn_get_ngo_avg_rating(p_ngo_id) AS ngo_rating,
        'Donation processed successfully' AS message
    FROM Donations d
    JOIN NGOs n ON d.ngo_id = n.ngo_id
    WHERE d.donation_id = LAST_INSERT_ID();
END //

-- 7. Enhanced Get Donation History
DROP PROCEDURE IF EXISTS get_donation_history //
CREATE PROCEDURE get_donation_history(
    IN p_user_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    -- Validate user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid user ID';
    ELSE
        -- Return enhanced donation history
        SELECT 
            d.donation_id,
            n.name AS ngo_name,
            fn_format_donation_amount(d.amount) AS amount,
            d.payment_method,
            d.donation_date,
            IF(d.is_tax_deductible, 'Yes', 'No') AS tax_deductible,
            fn_get_ngo_avg_rating(d.ngo_id) AS ngo_rating,
            fn_get_ngo_primary_category(d.ngo_id) AS primary_category
        FROM Donations d
        JOIN NGOs n ON d.ngo_id = n.ngo_id
        WHERE d.user_id = p_user_id
        ORDER BY d.donation_date DESC
        LIMIT p_limit OFFSET p_offset;
    END IF;
END //

-- 8. Enhanced Register NGO
DROP PROCEDURE IF EXISTS register_ngo //
CREATE PROCEDURE register_ngo(
    IN p_name VARCHAR(255),
    IN p_description TEXT,
    IN p_website VARCHAR(255),
    IN p_contact_email VARCHAR(100),
    IN p_contact_phone VARCHAR(20),
    IN p_location_id INT
)
BEGIN
    -- Validate using functions
    IF EXISTS (SELECT 1 FROM NGOs WHERE name = p_name) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NGO name already exists';
    ELSEIF fn_email_exists(p_contact_email) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Contact email already registered';
    ELSEIF p_location_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Locations WHERE location_id = p_location_id) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'Invalid location ID';
    END IF;
    
    -- Register NGO
    INSERT INTO NGOs (name, description, website, contact_email, contact_phone, location_id)
    VALUES (p_name, p_description, p_website, p_contact_email, p_contact_phone, p_location_id);
    
    -- Return enhanced response
    SELECT 
        ngo_id,
        name,
        description,
        fn_count_ngo_beneficiaries(LAST_INSERT_ID()) AS beneficiary_count,
        fn_count_upcoming_events(LAST_INSERT_ID()) AS upcoming_events,
        'NGO registered successfully' AS message
    FROM NGOs WHERE ngo_id = LAST_INSERT_ID();
END //

-- 10. Enhanced Search NGOs
DROP PROCEDURE IF EXISTS search_ngos //
CREATE PROCEDURE search_ngos(
    IN p_search_term VARCHAR(255),
    IN p_category_name VARCHAR(100),
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    -- Enhanced search with calculated fields
    SELECT 
        n.ngo_id,
        n.name,
        n.description,
        n.website,
        l.city,
        l.state,
        l.country,
        fn_get_ngo_avg_rating(n.ngo_id) AS avg_rating,
        fn_format_donation_amount(fn_get_ngo_total_donations(n.ngo_id)) AS total_donations,
        fn_count_ngo_beneficiaries(n.ngo_id) AS beneficiary_count,
        GROUP_CONCAT(DISTINCT nc.category_name) AS categories
    FROM NGOs n
    LEFT JOIN Locations l ON n.location_id = l.location_id
    LEFT JOIN NGO_Categories nc ON n.ngo_id = nc.ngo_id
    WHERE (p_search_term IS NULL OR 
           n.name LIKE CONCAT('%', p_search_term, '%') OR 
           n.description LIKE CONCAT('%', p_search_term, '%'))
    AND (p_category_name IS NULL OR nc.category_name = p_category_name)
    GROUP BY n.ngo_id
    ORDER BY avg_rating DESC
    LIMIT p_limit OFFSET p_offset;
END //

-- 11. Enhanced Add Beneficiary
DROP PROCEDURE IF EXISTS add_beneficiary //
CREATE PROCEDURE add_beneficiary(
    IN p_name VARCHAR(255),
    IN p_age INT,
    IN p_gender ENUM('Male', 'Female', 'Other'),
    IN p_ngo_id INT,
    IN p_received_support TEXT,
    IN p_birth_date DATE  -- Added for age calculation
)
BEGIN
    -- Validate NGO exists using function
    IF NOT EXISTS (SELECT 1 FROM NGOs WHERE ngo_id = p_ngo_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid NGO ID';
    ELSEIF p_age IS NULL AND p_birth_date IS NULL THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Either age or birth date must be provided';
    END IF;

    -- Calculate age if birth date is provided
    IF p_age IS NULL THEN
        SET p_age = fn_calculate_age(p_birth_date);
    END IF;

    -- Insert beneficiary
    INSERT INTO Beneficiaries (name, age, gender, ngo_id, received_support, birth_date)
    VALUES (p_name, p_age, p_gender, p_ngo_id, p_received_support, p_birth_date);
    
    -- Return enhanced response
    SELECT 
        b.beneficiary_id,
        b.name,
        b.age,
        b.gender,
        n.name AS ngo_name,
        fn_count_ngo_beneficiaries(p_ngo_id) AS total_beneficiaries,
        'Beneficiary added successfully' AS message
    FROM Beneficiaries b
    JOIN NGOs n ON b.ngo_id = n.ngo_id
    WHERE b.beneficiary_id = LAST_INSERT_ID();
END //

-- 12. Enhanced Process Adoption
DROP PROCEDURE IF EXISTS process_adoption //
CREATE PROCEDURE process_adoption(
    IN p_user_id INT,
    IN p_beneficiary_id INT,
    IN p_adoption_date DATE
)
BEGIN
    DECLARE v_adopter_id INT;
    DECLARE v_ngo_id INT;
    DECLARE v_beneficiary_name VARCHAR(255);
    
    -- Validate user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid user ID';
    END IF;
    
    -- Get or create adopter
    SELECT adopter_id INTO v_adopter_id FROM Adopters WHERE user_id = p_user_id;
    
    IF v_adopter_id IS NULL THEN
        INSERT INTO Adopters (user_id, name, email)
        SELECT user_id, username, email FROM Users WHERE user_id = p_user_id;
        SET v_adopter_id = LAST_INSERT_ID();
    END IF;
    
    -- Get beneficiary info
    SELECT ngo_id, name INTO v_ngo_id, v_beneficiary_name
    FROM Beneficiaries WHERE beneficiary_id = p_beneficiary_id;
    
    IF v_ngo_id IS NULL THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Invalid beneficiary ID';
    END IF;
    
    -- Process adoption
    INSERT INTO Adoptions (adopter_id, beneficiary_id, adoption_date)
    VALUES (v_adopter_id, p_beneficiary_id, p_adoption_date);
    
    -- Return enhanced response
    SELECT 
        a.adoption_id,
        v_beneficiary_name AS beneficiary_name,
        u.username AS adopter_name,
        n.name AS ngo_name,
        fn_calculate_age(b.birth_date) AS beneficiary_age,
        'Adoption processed successfully' AS message
    FROM Adoptions a
    JOIN Adopters ad ON a.adopter_id = ad.adopter_id
    JOIN Users u ON ad.user_id = u.user_id
    JOIN Beneficiaries b ON a.beneficiary_id = b.beneficiary_id
    JOIN NGOs n ON b.ngo_id = n.ngo_id
    WHERE a.adoption_id = LAST_INSERT_ID();
END //

-- 13. Enhanced Get Adoption History
DROP PROCEDURE IF EXISTS get_adoption_history //
CREATE PROCEDURE get_adoption_history(
    IN p_user_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    -- Validate user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid user ID';
    ELSE
        -- Return enhanced adoption history
        SELECT 
            a.adoption_id,
            b.name AS beneficiary_name,
            fn_calculate_age(b.birth_date) AS beneficiary_age,
            b.gender,
            n.name AS ngo_name,
            a.adoption_date,
            DATEDIFF(CURDATE(), a.adoption_date) AS days_since_adoption,
            fn_get_ngo_avg_rating(b.ngo_id) AS ngo_rating
        FROM Adoptions a
        JOIN Adopters ad ON a.adopter_id = ad.adopter_id
        JOIN Beneficiaries b ON a.beneficiary_id = b.beneficiary_id
        JOIN NGOs n ON b.ngo_id = n.ngo_id
        WHERE ad.user_id = p_user_id
        ORDER BY a.adoption_date DESC
        LIMIT p_limit OFFSET p_offset;
    END IF;
END //

-- 14. Enhanced Add Event
DROP PROCEDURE IF EXISTS add_event //
CREATE PROCEDURE add_event(
    IN p_name VARCHAR(255),
    IN p_description TEXT,
    IN p_ngo_id INT,
    IN p_event_date DATE,
    IN p_location TEXT
)
BEGIN
    -- Validate NGO exists
    IF NOT EXISTS (SELECT 1 FROM NGOs WHERE ngo_id = p_ngo_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid NGO ID';
    ELSEIF p_event_date < CURDATE() THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Event date cannot be in the past';
    END IF;
    
    -- Add event
    INSERT INTO Events (name, description, ngo_id, event_date, location)
    VALUES (p_name, p_description, p_ngo_id, p_event_date, p_location);
    
    -- Return enhanced response
    SELECT 
        e.event_id,
        e.name,
        e.description,
        n.name AS ngo_name,
        e.event_date,
        fn_days_until_next_event(p_ngo_id) AS days_until_event,
        fn_count_upcoming_events(p_ngo_id) AS total_upcoming_events,
        'Event added successfully' AS message
    FROM Events e
    JOIN NGOs n ON e.ngo_id = n.ngo_id
    WHERE e.event_id = LAST_INSERT_ID();
END //

-- 15. Enhanced Submit Review
DROP PROCEDURE IF EXISTS submit_review //
CREATE PROCEDURE submit_review(
    IN p_user_id INT,
    IN p_ngo_id INT,
    IN p_rating INT,
    IN p_review_text TEXT
)
BEGIN
    DECLARE v_existing_review_id INT;
    
    -- Validate inputs
    IF p_rating < 1 OR p_rating > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    ELSEIF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Invalid user ID';
    ELSEIF NOT EXISTS (SELECT 1 FROM NGOs WHERE ngo_id = p_ngo_id) THEN
        SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'Invalid NGO ID';
    END IF;
    
    -- Check for existing review
    SELECT review_id INTO v_existing_review_id 
    FROM Reviews 
    WHERE user_id = p_user_id AND ngo_id = p_ngo_id;
    
    IF v_existing_review_id IS NOT NULL THEN
        -- Update existing review
        UPDATE Reviews
        SET rating = p_rating,
            review_text = p_review_text,
            created_at = CURRENT_TIMESTAMP
        WHERE review_id = v_existing_review_id;
        
        -- Return enhanced response
        SELECT 
            r.review_id,
            u.username AS reviewer_name,
            n.name AS ngo_name,
            r.rating,
            r.review_text,
            fn_get_ngo_avg_rating(p_ngo_id) AS ngo_avg_rating,
            'Review updated successfully' AS message
        FROM Reviews r
        JOIN Users u ON r.user_id = u.user_id
        JOIN NGOs n ON r.ngo_id = n.ngo_id
        WHERE r.review_id = v_existing_review_id;
    ELSE
        -- Create new review
        INSERT INTO Reviews (user_id, ngo_id, rating, review_text)
        VALUES (p_user_id, p_ngo_id, p_rating, p_review_text);
        
        -- Return enhanced response
        SELECT 
            r.review_id,
            u.username AS reviewer_name,
            n.name AS ngo_name,
            r.rating,
            r.review_text,
            fn_get_ngo_avg_rating(p_ngo_id) AS ngo_avg_rating,
            'Review submitted successfully' AS message
        FROM Reviews r
        JOIN Users u ON r.user_id = u.user_id
        JOIN NGOs n ON r.ngo_id = n.ngo_id
        WHERE r.review_id = LAST_INSERT_ID();
    END IF;
END //
