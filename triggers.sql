DELIMITER //

-- Drop Trigger: Prevent Duplicate Reviews
DROP TRIGGER IF EXISTS PreventDuplicateReviews //

-- 1. Prevent Duplicate Reviews (same user reviewing the same NGO multiple times)
CREATE TRIGGER PreventDuplicateReviews
BEFORE INSERT ON Reviews
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM Reviews 
        WHERE user_id = NEW.user_id AND ngo_id = NEW.ngo_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User has already reviewed this NGO';
    END IF;
END //

-- Drop Trigger: Validate Review Rating
DROP TRIGGER IF EXISTS ValidateReviewRating //

-- 2. Validate Review Rating (1-5)
CREATE TRIGGER ValidateReviewRating
BEFORE INSERT ON Reviews
FOR EACH ROW
BEGIN
    IF NEW.rating NOT BETWEEN 1 AND 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    END IF;
END //

-- Drop Trigger: Validate Beneficiary Age
DROP TRIGGER IF EXISTS ValidateBeneficiaryAge //

-- 3. Ensure Beneficiary Age is Positive
CREATE TRIGGER ValidateBeneficiaryAge
BEFORE INSERT ON Beneficiaries
FOR EACH ROW
BEGIN
    IF NEW.age <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Beneficiary age must be positive';
    END IF;
END //

-- Drop Trigger: Validate Donor Type
DROP TRIGGER IF EXISTS ValidateDonorType //

-- 4. Ensure Donor Type Consistency (Individual vs. Organization)
CREATE TRIGGER ValidateDonorType
BEFORE INSERT ON Donors
FOR EACH ROW
BEGIN
    IF NEW.donor_type NOT IN ('Individual', 'Organization') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid donor type';
    END IF;
END //

DELIMITER ;