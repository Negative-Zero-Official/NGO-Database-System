DELIMITER //

-- 1. After User Registration Trigger
-- Creates default user records in related tables based on user role selection
DROP TRIGGER IF EXISTS after_user_insert //
CREATE TRIGGER after_user_insert
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    -- Create default donor record for new users
    -- This allows all users to make donations by default
    INSERT INTO Donors (user_id, name, email, donor_type)
    VALUES (NEW.user_id, NEW.username, NEW.email, 'Individual');
    
    -- Log the user creation
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (NEW.user_id, 'USER_REGISTRATION', CONCAT('New user registered: ', NEW.username));
END //

-- 2. Before User Delete Trigger
-- Ensures proper cleanup when a user is deleted
DROP TRIGGER IF EXISTS before_user_delete //
CREATE TRIGGER before_user_delete
BEFORE DELETE ON Users
FOR EACH ROW
BEGIN
    -- Log the user deletion
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (OLD.user_id, 'USER_DELETION', CONCAT('User deleted: ', OLD.username));
END //

-- 3. After Donation Insert Trigger
-- Updates statistics and sends notifications when a donation is made
DROP TRIGGER IF EXISTS after_donation_insert //
CREATE TRIGGER after_donation_insert
AFTER INSERT ON Donations
FOR EACH ROW
BEGIN
    DECLARE v_donor_name VARCHAR(255);
    DECLARE v_ngo_name VARCHAR(255);
    
    -- Get donor and NGO names
    SELECT name INTO v_donor_name FROM Donors WHERE donor_id = NEW.donor_id;
    SELECT name INTO v_ngo_name FROM NGOs WHERE ngo_id = NEW.ngo_id;
    
    -- Update DonorStatistics table (needs to be created)
    INSERT INTO DonorStatistics (donor_id, total_donations, last_donation_date, last_donation_amount)
    VALUES (NEW.donor_id, NEW.amount, NEW.donation_date, NEW.amount)
    ON DUPLICATE KEY UPDATE
        total_donations = total_donations + NEW.amount,
        last_donation_date = NEW.donation_date,
        last_donation_amount = NEW.amount;
    
    -- Update NGOStatistics table (needs to be created)
    INSERT INTO NGOStatistics (ngo_id, total_donations, donor_count, last_donation_date)
    VALUES (NEW.ngo_id, NEW.amount, 1, NEW.donation_date)
    ON DUPLICATE KEY UPDATE
        total_donations = total_donations + NEW.amount,
        donor_count = (SELECT COUNT(DISTINCT donor_id) FROM Donations WHERE ngo_id = NEW.ngo_id),
        last_donation_date = NEW.donation_date;
    
    -- Log the donation activity
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (NEW.user_id, 'DONATION', 
            CONCAT(v_donor_name, ' donated ', FORMAT(NEW.amount, 2), ' to ', v_ngo_name));
    
    -- Create notification for NGO about new donation
    INSERT INTO Notifications (user_id, notification_type, message, is_read)
    SELECT 
        t.user_id, 
        'DONATION_RECEIVED', 
        CONCAT('New donation of ', FORMAT(NEW.amount, 2), ' received from ', v_donor_name), 
        0
    FROM Trustees t
    WHERE t.ngo_id = NEW.ngo_id;
END //

-- 4. Before Donation Delete Trigger
-- Updates statistics when a donation is deleted or refunded
DROP TRIGGER IF EXISTS before_donation_delete //
CREATE TRIGGER before_donation_delete
BEFORE DELETE ON Donations
FOR EACH ROW
BEGIN
    -- Update DonorStatistics
    UPDATE DonorStatistics
    SET total_donations = total_donations - OLD.amount
    WHERE donor_id = OLD.donor_id;
    
    -- Update NGOStatistics
    UPDATE NGOStatistics
    SET total_donations = total_donations - OLD.amount,
        donor_count = (SELECT COUNT(DISTINCT donor_id) FROM Donations WHERE ngo_id = OLD.ngo_id AND donation_id != OLD.donation_id)
    WHERE ngo_id = OLD.ngo_id;
    
    -- Log the donation deletion
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (OLD.user_id, 'DONATION_DELETED', 
            CONCAT('Donation #', OLD.donation_id, ' of amount ', FORMAT(OLD.amount, 2), ' deleted'));
END //

-- 5. After NGO Insert Trigger
-- Sets up default categories and statistics for new NGOs
DROP TRIGGER IF EXISTS after_ngo_insert //
CREATE TRIGGER after_ngo_insert
AFTER INSERT ON NGOs
FOR EACH ROW
BEGIN
    -- Initialize NGO statistics
    INSERT INTO NGOStatistics (ngo_id, total_donations, donor_count, last_donation_date)
    VALUES (NEW.ngo_id, 0, 0, NULL);
    
    -- Log the NGO creation
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (NULL, 'NGO_REGISTRATION', CONCAT('New NGO registered: ', NEW.name));
END //

-- 6. After Adoption Insert Trigger
-- Updates beneficiary status and creates notifications
DROP TRIGGER IF EXISTS after_adoption_insert //
CREATE TRIGGER after_adoption_insert
AFTER INSERT ON Adoptions
FOR EACH ROW
BEGIN
    DECLARE v_beneficiary_name VARCHAR(255);
    DECLARE v_adopter_name VARCHAR(255);
    DECLARE v_user_id INT;
    DECLARE v_ngo_id INT;
    
    -- Get beneficiary and adopter information
    SELECT b.name, b.ngo_id INTO v_beneficiary_name, v_ngo_id
    FROM Beneficiaries b
    WHERE b.beneficiary_id = NEW.beneficiary_id;
    
    SELECT a.name, a.user_id INTO v_adopter_name, v_user_id
    FROM Adopters a
    WHERE a.adopter_id = NEW.adopter_id;
    
    -- Update beneficiary status (assuming we add an is_adopted field)
    UPDATE Beneficiaries
    SET is_adopted = 1,
        adoption_date = NEW.adoption_date
    WHERE beneficiary_id = NEW.beneficiary_id;
    
    -- Log the adoption activity
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (v_user_id, 'ADOPTION', 
            CONCAT(v_adopter_name, ' adopted ', v_beneficiary_name, ' on ', DATE_FORMAT(NEW.adoption_date, '%Y-%m-%d')));
    
    -- Create notification for NGO about new adoption
    INSERT INTO Notifications (user_id, notification_type, message, is_read)
    SELECT 
        t.user_id, 
        'ADOPTION_COMPLETED', 
        CONCAT(v_beneficiary_name, ' was adopted by ', v_adopter_name, ' on ', DATE_FORMAT(NEW.adoption_date, '%Y-%m-%d')), 
        0
    FROM Trustees t
    WHERE t.ngo_id = v_ngo_id;
    
    -- Create confirmation notification for adopter
    INSERT INTO Notifications (user_id, notification_type, message, is_read)
    VALUES (v_user_id, 'ADOPTION_CONFIRMED', 
            CONCAT('Your adoption of ', v_beneficiary_name, ' is confirmed. Thank you for your compassion!'), 0);
END //

-- 7. After Review Insert Trigger
-- Updates NGO rating statistics and creates notifications
DROP TRIGGER IF EXISTS after_review_insert //
CREATE TRIGGER after_review_insert
AFTER INSERT ON Reviews
FOR EACH ROW
BEGIN
    DECLARE v_avg_rating DECIMAL(3,2);
    DECLARE v_ngo_name VARCHAR(255);
    DECLARE v_username VARCHAR(50);
    
    -- Get username and NGO name
    SELECT username INTO v_username FROM Users WHERE user_id = NEW.user_id;
    SELECT name INTO v_ngo_name FROM NGOs WHERE ngo_id = NEW.ngo_id;
    
    -- Calculate new average rating
    SELECT AVG(rating) INTO v_avg_rating 
    FROM Reviews
    WHERE ngo_id = NEW.ngo_id;
    
    -- Update NGO statistics with new rating
    UPDATE NGOStatistics
    SET avg_rating = v_avg_rating,
        review_count = (SELECT COUNT(*) FROM Reviews WHERE ngo_id = NEW.ngo_id)
    WHERE ngo_id = NEW.ngo_id;
    
    -- Log the review activity
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (NEW.user_id, 'REVIEW_SUBMITTED', 
            CONCAT(v_username, ' submitted a ', NEW.rating, '-star review for ', v_ngo_name));
    
    -- Create notification for NGO about new review
    INSERT INTO Notifications (user_id, notification_type, message, is_read)
    SELECT 
        t.user_id, 
        'REVIEW_RECEIVED', 
        CONCAT('New ', NEW.rating, '-star review received from ', v_username), 
        0
    FROM Trustees t
    WHERE t.ngo_id = NEW.ngo_id;
END //

-- 8. After Review Update Trigger
-- Updates NGO rating statistics when a review is modified
DROP TRIGGER IF EXISTS after_review_update //
CREATE TRIGGER after_review_update
AFTER UPDATE ON Reviews
FOR EACH ROW
BEGIN
    DECLARE v_avg_rating DECIMAL(3,2);
    
    -- Calculate new average rating
    SELECT AVG(rating) INTO v_avg_rating 
    FROM Reviews
    WHERE ngo_id = NEW.ngo_id;
    
    -- Update NGO statistics with new rating
    UPDATE NGOStatistics
    SET avg_rating = v_avg_rating
    WHERE ngo_id = NEW.ngo_id;
    
    -- Log the review update
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (NEW.user_id, 'REVIEW_UPDATED', 
            CONCAT('Review #', NEW.review_id, ' updated from ', OLD.rating, ' to ', NEW.rating, ' stars'));
END //

-- 9. After Event Insert Trigger
-- Creates notifications about new events
DROP TRIGGER IF EXISTS after_event_insert //
CREATE TRIGGER after_event_insert
AFTER INSERT ON Events
FOR EACH ROW
BEGIN
    DECLARE v_ngo_name VARCHAR(255);
    
    -- Get NGO name
    SELECT name INTO v_ngo_name FROM NGOs WHERE ngo_id = NEW.ngo_id;
    
    -- Log the event creation
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (NULL, 'EVENT_CREATED', 
            CONCAT('New event "', NEW.name, '" created for ', v_ngo_name, ' on ', DATE_FORMAT(NEW.event_date, '%Y-%m-%d')));
    
    -- Create notifications for users who donated to this NGO
    INSERT INTO Notifications (user_id, notification_type, message, is_read)
    SELECT DISTINCT 
        d.user_id, 
        'EVENT_ANNOUNCEMENT', 
        CONCAT(v_ngo_name, ' is hosting a new event: "', NEW.name, '" on ', DATE_FORMAT(NEW.event_date, '%Y-%m-%d')), 
        0
    FROM Donations d
    WHERE d.ngo_id = NEW.ngo_id;
END //

-- 10. Before Beneficiary Delete Trigger
-- Prevent deletion of adopted beneficiaries
DROP TRIGGER IF EXISTS before_beneficiary_delete //
CREATE TRIGGER before_beneficiary_delete
BEFORE DELETE ON Beneficiaries
FOR EACH ROW
BEGIN
    DECLARE v_is_adopted BOOLEAN;
    
    -- Check if beneficiary is adopted
    SELECT COUNT(*) > 0 INTO v_is_adopted 
    FROM Adoptions
    WHERE beneficiary_id = OLD.beneficiary_id;
    
    -- If adopted, prevent deletion
    IF v_is_adopted THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete a beneficiary who has been adopted';
    END IF;
    
    -- Log the beneficiary deletion
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (NULL, 'BENEFICIARY_DELETED', 
            CONCAT('Beneficiary #', OLD.beneficiary_id, ' (', OLD.name, ') deleted'));
END //

-- 11. Auto-Update Timestamps Trigger
-- Automatically updates timestamp fields when records are modified

-- FIXME: updated_at column isn't a thing in users table

DROP TRIGGER IF EXISTS before_user_update //
-- CREATE TRIGGER before_user_update
-- BEFORE UPDATE ON Users
-- FOR EACH ROW
-- BEGIN
--     SET NEW.updated_at = CURRENT_TIMESTAMP;
-- END //

-- 12. After Password Change Trigger
-- Logs password changes and sends notifications
DROP TRIGGER IF EXISTS after_password_change //
CREATE TRIGGER after_password_change
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
    -- Check if password was changed
    IF OLD.password_hash != NEW.password_hash THEN
        -- Log the password change
        INSERT INTO ActivityLog (user_id, activity_type, description)
        VALUES (NEW.user_id, 'PASSWORD_CHANGED', 
                CONCAT('Password changed for user: ', NEW.username));
        
        -- Create notification for the user
        INSERT INTO Notifications (user_id, notification_type, message, is_read)
        VALUES (NEW.user_id, 'SECURITY_ALERT', 
                'Your password was successfully changed. If you did not make this change, please contact support immediately.', 0);
    END IF;
END //

-- 13. After Trustee Assignment Trigger
-- Creates notifications when a user becomes a trustee
DROP TRIGGER IF EXISTS after_trustee_insert //
CREATE TRIGGER after_trustee_insert
AFTER INSERT ON Trustees
FOR EACH ROW
BEGIN
    DECLARE v_username VARCHAR(50);
    DECLARE v_ngo_name VARCHAR(255);
    
    -- Get username and NGO name
    SELECT username INTO v_username FROM Users WHERE user_id = NEW.user_id;
    SELECT name INTO v_ngo_name FROM NGOs WHERE ngo_id = NEW.ngo_id;
    
    -- Log the trustee assignment
    INSERT INTO ActivityLog (user_id, activity_type, description)
    VALUES (NEW.user_id, 'TRUSTEE_ASSIGNMENT', 
            CONCAT(v_username, ' assigned as trustee for ', v_ngo_name));
    
    -- Create notification for the user
    INSERT INTO Notifications (user_id, notification_type, message, is_read)
    VALUES (NEW.user_id, 'ROLE_ASSIGNMENT', 
            CONCAT('You have been assigned as a trustee for ', v_ngo_name), 0);
END //

-- 14. Auto-Calculate Age Trigger
-- Automatically updates age based on birth_date

-- FIXME: birth_date isn't a thing in beneficiaries table

DROP TRIGGER IF EXISTS before_beneficiary_insert //
-- CREATE TRIGGER before_beneficiary_insert
-- BEFORE INSERT ON Beneficiaries
-- FOR EACH ROW
-- BEGIN
--     -- Calculate age from birth_date if provided
--     IF NEW.birth_date IS NOT NULL AND NEW.age IS NULL THEN
--         SET NEW.age = TIMESTAMPDIFF(YEAR, NEW.birth_date, CURDATE());
--     END IF;
-- END //

-- DROP TRIGGER IF EXISTS before_beneficiary_update //
-- CREATE TRIGGER before_beneficiary_update
-- BEFORE UPDATE ON Beneficiaries
-- FOR EACH ROW
-- BEGIN
--     -- Update age when birth_date changes
--     IF NEW.birth_date != OLD.birth_date THEN
--         SET NEW.age = TIMESTAMPDIFF(YEAR, NEW.birth_date, CURDATE());
--     END IF;
-- END //

-- 15. NGO Verification Status Trigger
-- Updates NGO verification status based on review count and rating
DROP TRIGGER IF EXISTS after_review_for_verification //
CREATE TRIGGER after_review_for_verification
AFTER INSERT ON Reviews
FOR EACH ROW
BEGIN
    DECLARE v_review_count INT;
    DECLARE v_avg_rating DECIMAL(3,2);
    
    -- Calculate review count and average rating
    SELECT COUNT(*), AVG(rating) INTO v_review_count, v_avg_rating
    FROM Reviews
    WHERE ngo_id = NEW.ngo_id;
    
    -- Update verification status if criteria met
    IF v_review_count >= 5 AND v_avg_rating >= 4.0 THEN
        UPDATE NGOs
        SET is_verified = 1,
            verified_at = CURRENT_TIMESTAMP,
            verification_notes = CONCAT('Automatically verified based on ', v_review_count, ' reviews with average rating of ', v_avg_rating)
        WHERE ngo_id = NEW.ngo_id AND (is_verified = 0 OR is_verified IS NULL);
    END IF;
END //

DELIMITER ;