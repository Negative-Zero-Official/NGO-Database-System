CREATE VIEW vw_ngo_overview AS
SELECT 
    n.ngo_id,
    n.name,
    n.description,
    n.website,
    n.contact_email,
    n.contact_phone,
    l.city,
    l.state,
    l.country,
    fn_get_ngo_avg_rating(n.ngo_id) AS average_rating,
    fn_get_ngo_total_donations(n.ngo_id) AS total_donations,
    fn_count_ngo_beneficiaries(n.ngo_id) AS beneficiary_count,
    fn_count_upcoming_events(n.ngo_id) AS upcoming_events_count,
    GROUP_CONCAT(DISTINCT nc.category_name) AS categories
FROM NGOs n
LEFT JOIN Locations l ON n.location_id = l.location_id
LEFT JOIN NGO_Categories nc ON n.ngo_id = nc.ngo_id
GROUP BY n.ngo_id;


CREATE VIEW vw_active_donors AS
SELECT 
    d.donor_id,
    d.name AS donor_name,
    d.email,
    d.phone,
    d.donor_type,
    u.username,
    COUNT(dn.donation_id) AS donation_count,
    SUM(dn.amount) AS total_donation_amount,
    MAX(dn.donation_date) AS last_donation_date
FROM Donors d
JOIN Users u ON d.user_id = u.user_id
LEFT JOIN Donations dn ON d.donor_id = dn.donor_id
GROUP BY d.donor_id
ORDER BY total_donation_amount DESC;

CREATE VIEW vw_user_activity_summary AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    fn_get_user_role(u.user_id) AS role,
    (SELECT COUNT(*) FROM Donations WHERE user_id = u.user_id) AS donations_made,
    (SELECT COALESCE(SUM(amount), 0) FROM Donations WHERE user_id = u.user_id) AS total_donated,
    (SELECT COUNT(*) FROM Adoptions a JOIN Adopters ad ON a.adopter_id = ad.adopter_id WHERE ad.user_id = u.user_id) AS adoptions_made,
    (SELECT COUNT(*) FROM Reviews WHERE user_id = u.user_id) AS reviews_submitted,
    u.created_at AS member_since
FROM Users u;


CREATE VIEW vw_ngo_reviews AS
SELECT 
    r.review_id,
    r.ngo_id,
    n.name AS ngo_name,
    r.user_id,
    u.username AS reviewer_name,
    r.rating,
    r.review_text,
    r.created_at
FROM Reviews r
JOIN NGOs n ON r.ngo_id = n.ngo_id
JOIN Users u ON r.user_id = u.user_id
ORDER BY r.created_at DESC;


CREATE VIEW vw_upcoming_events AS
SELECT 
    e.event_id,
    e.name AS event_name,
    e.description,
    e.ngo_id,
    n.name AS ngo_name,
    e.event_date,
    e.location,
    DATEDIFF(e.event_date, CURDATE()) AS days_until_event
FROM Events e
JOIN NGOs n ON e.ngo_id = n.ngo_id
WHERE e.event_date >= CURDATE()
ORDER BY e.event_date;

CREATE VIEW vw_beneficiary_status AS
SELECT 
    b.beneficiary_id,
    b.name AS beneficiary_name,
    b.age,
    b.gender,
    b.ngo_id,
    n.name AS ngo_name,
    b.received_support,
    CASE 
        WHEN a.adoption_id IS NULL THEN 'Not Adopted'
        ELSE 'Adopted'
    END AS adoption_status,
    a.adoption_date,
    ad.name AS adopter_name
FROM Beneficiaries b
JOIN NGOs n ON b.ngo_id = n.ngo_id
LEFT JOIN Adoptions a ON b.beneficiary_id = a.beneficiary_id
LEFT JOIN Adopters ad ON a.adopter_id = ad.adopter_id;

CREATE VIEW vw_ngo_donation_summary AS
SELECT 
    n.ngo_id,
    n.name AS ngo_name,
    COUNT(d.donation_id) AS donation_count,
    SUM(d.amount) AS total_donations,
    AVG(d.amount) AS average_donation,
    MAX(d.amount) AS largest_donation,
    MIN(d.amount) AS smallest_donation,
    MAX(d.donation_date) AS last_donation_date,
    fn_get_ngo_primary_category(n.ngo_id) AS primary_category
FROM NGOs n
LEFT JOIN Donations d ON n.ngo_id = d.ngo_id
GROUP BY n.ngo_id
ORDER BY total_donations DESC;


CREATE VIEW vw_user_roles AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    CASE 
        WHEN t.trustee_id IS NOT NULL THEN 'Trustee'
        WHEN a.adopter_id IS NOT NULL THEN 'Adopter'
        WHEN d.donor_id IS NOT NULL THEN 'Donor'
        ELSE 'Regular User'
    END AS role
FROM Users u
LEFT JOIN Trustees t ON u.user_id = t.user_id
LEFT JOIN Adopters a ON u.user_id = a.user_id
LEFT JOIN Donors d ON u.user_id = d.user_id;

CREATE VIEW vw_category_distribution AS
SELECT 
    nc.category_name,
    COUNT(DISTINCT nc.ngo_id) AS ngo_count,
    SUM(fn_get_ngo_total_donations(nc.ngo_id)) AS total_donations_in_category,
    AVG(fn_get_ngo_avg_rating(nc.ngo_id)) AS avg_rating_in_category
FROM NGO_Categories nc
GROUP BY nc.category_name
ORDER BY ngo_count DESC;

CREATE VIEW vw_recent_activities AS
SELECT 
    'Donation' AS activity_type,
    d.donation_id AS activity_id,
    u.username AS user_name,
    n.name AS ngo_name,
    d.amount AS activity_detail,
    d.donation_date AS activity_date
FROM Donations d
JOIN Users u ON d.user_id = u.user_id
JOIN NGOs n ON d.ngo_id = n.ngo_id

UNION ALL

SELECT 
    'Adoption' AS activity_type,
    a.adoption_id AS activity_id,
    u.username AS user_name,
    n.name AS ngo_name,
    b.name AS activity_detail,
    a.adoption_date AS activity_date
FROM Adoptions a
JOIN Adopters ad ON a.adopter_id = ad.adopter_id
JOIN Users u ON ad.user_id = u.user_id
JOIN Beneficiaries b ON a.beneficiary_id = b.beneficiary_id
JOIN NGOs n ON b.ngo_id = n.ngo_id

UNION ALL

SELECT 
    'Review' AS activity_type,
    r.review_id AS activity_id,
    u.username AS user_name,
    n.name AS ngo_name,
    CONCAT(r.rating, ' stars') AS activity_detail,
    r.created_at AS activity_date
FROM Reviews r
JOIN Users u ON r.user_id = u.user_id
JOIN NGOs n ON r.ngo_id = n.ngo_id

UNION ALL

SELECT 
    'Event' AS activity_type,
    e.event_id AS activity_id,
    n.name AS user_name,
    e.name AS ngo_name,
    e.location AS activity_detail,
    e.event_date AS activity_date
FROM Events e
JOIN NGOs n ON e.ngo_id = n.ngo_id
WHERE e.event_date >= CURDATE()

ORDER BY activity_date DESC
LIMIT 100;

