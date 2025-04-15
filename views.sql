-- Drop NGO Ratings Summary View if it exists
DROP VIEW IF EXISTS NGO_Ratings_View;

-- NGO Ratings Summary
CREATE VIEW NGO_Ratings_View AS
SELECT 
    n.ngo_id, 
    n.name, 
    COALESCE(AVG(r.rating), 0) AS average_rating,
    COUNT(r.review_id) AS total_reviews
FROM NGOs n
LEFT JOIN Reviews r ON n.ngo_id = r.ngo_id
GROUP BY n.ngo_id;

-- Drop Available Beneficiaries View if it exists
DROP VIEW IF EXISTS Available_Beneficiaries_View;

-- Available Beneficiaries (Not Adopted)
CREATE VIEW Available_Beneficiaries_View AS
SELECT b.*
FROM Beneficiaries b
LEFT JOIN Adoptions a ON b.beneficiary_id = a.beneficiary_id
WHERE a.adoption_id IS NULL;

-- Drop Donation Summary View if it exists
DROP VIEW IF EXISTS Donation_Summary_View;

-- Donation Summary per NGO
CREATE VIEW Donation_Summary_View AS
SELECT 
    n.ngo_id, 
    n.name, 
    COALESCE(SUM(d.amount), 0) AS total_donations,
    COUNT(d.donation_id) AS donation_count
FROM NGOs n
LEFT JOIN Donations d ON n.ngo_id = d.ngo_id
GROUP BY n.ngo_id;

-- Drop Upcoming Events View if it exists
DROP VIEW IF EXISTS Upcoming_Events_View;

-- Upcoming Events
CREATE VIEW Upcoming_Events_View AS
SELECT *
FROM Events
WHERE event_date >= CURDATE();

-- Drop User Roles View if it exists
DROP VIEW IF EXISTS User_Roles_View;

-- User Roles
CREATE VIEW User_Roles_View AS
SELECT 
    u.user_id,
    u.username,
    GetUserRole(u.user_id) AS role
FROM Users u;