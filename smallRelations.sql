-- use NGO_Search_Engine;
SET SQL_SAFE_UPDATES = 0;

DELETE FROM Users;
DELETE FROM Locations;
DELETE FROM NGOs;
DELETE FROM NGO_Categories;
DELETE FROM Donors;
DELETE FROM Donations;
DELETE FROM Beneficiaries;
DELETE FROM Adopters;
DELETE FROM Adoptions;
DELETE FROM Trustees;
DELETE FROM Events;
DELETE FROM Reviews;

ALTER TABLE Users AUTO_INCREMENT = 1;

ALTER TABLE Locations AUTO_INCREMENT = 1;

ALTER TABLE NGOs AUTO_INCREMENT = 1;

ALTER TABLE Donors AUTO_INCREMENT = 1;

ALTER TABLE Donations AUTO_INCREMENT = 1;

ALTER TABLE Beneficiaries AUTO_INCREMENT = 1;

ALTER TABLE Adopters AUTO_INCREMENT = 1;

ALTER TABLE Adoptions AUTO_INCREMENT = 1;

ALTER TABLE Trustees AUTO_INCREMENT = 1;

ALTER TABLE Events AUTO_INCREMENT = 1;

ALTER TABLE Reviews AUTO_INCREMENT = 1;

INSERT INTO Users (username, email, password_hash) VALUES 
-- Donors (1-10)
('donor1', 'donor1@example.com', 'hashed_password_1'),
('donor2', 'donor2@example.com', 'hashed_password_2'),
('donor3', 'donor3@example.com', 'hashed_password_3'),
('donor4', 'donor4@example.com', 'hashed_password_4'),
('donor5', 'donor5@example.com', 'hashed_password_5'),
('donor6', 'donor6@example.com', 'hashed_password_6'),
('donor7', 'donor7@example.com', 'hashed_password_7'),
('donor8', 'donor8@example.com', 'hashed_password_8'),
('donor9', 'donor9@example.com', 'hashed_password_9'),
('donor10', 'donor10@example.com', 'hashed_password_10'),

-- Adopters (11-20)
('adopter1', 'adopter1@example.com', 'hashed_password_11'),
('adopter2', 'adopter2@example.com', 'hashed_password_12'),
('adopter3', 'adopter3@example.com', 'hashed_password_13'),
('adopter4', 'adopter4@example.com', 'hashed_password_14'),
('adopter5', 'adopter5@example.com', 'hashed_password_15'),
('adopter6', 'adopter6@example.com', 'hashed_password_16'),
('adopter7', 'adopter7@example.com', 'hashed_password_17'),
('adopter8', 'adopter8@example.com', 'hashed_password_18'),
('adopter9', 'adopter9@example.com', 'hashed_password_19'),
('adopter10', 'adopter10@example.com', 'hashed_password_20'),

-- Trustees (21-30)
('trustee1', 'trustee1@example.com', 'hashed_password_21'),
('trustee2', 'trustee2@example.com', 'hashed_password_22'),
('trustee3', 'trustee3@example.com', 'hashed_password_23'),
('trustee4', 'trustee4@example.com', 'hashed_password_24'),
('trustee5', 'trustee5@example.com', 'hashed_password_25'),
('trustee6', 'trustee6@example.com', 'hashed_password_26'),
('trustee7', 'trustee7@example.com', 'hashed_password_27'),
('trustee8', 'trustee8@example.com', 'hashed_password_28'),
('trustee9', 'trustee9@example.com', 'hashed_password_29'),
('trustee10', 'trustee10@example.com', 'hashed_password_30');

-- Insert unique data into Locations table
INSERT INTO Locations (city, state, country, latitude, longitude) VALUES 
('New York', 'NY', 'USA', 40.7128, -74.0060),
('Los Angeles', 'CA', 'USA', 34.0522, -118.2437),
('Chicago', 'IL', 'USA', 41.8781, -87.6298),
('Houston', 'TX', 'USA', 29.7604, -95.3698),
('Phoenix', 'AZ', 'USA', 33.4484, -112.0740),
('Philadelphia', 'PA', 'USA', 39.9526, -75.1652),
('San Antonio', 'TX', 'USA', 29.4241, -98.4936),
('San Diego', 'CA', 'USA', 32.7157, -117.1611),
('Dallas', 'TX', 'USA', 32.7767, -96.7970),
('Austin', 'TX', 'USA', 30.2672, -97.7431);

-- Insert unique data into NGOs table
INSERT INTO NGOs (name, description, website, contact_email, contact_phone, location_id) VALUES 
('Hope for Children', 'Education for underprivileged kids', 'www.hopeforchildren.org', 'contact@hopeforchildren.org', '1234567890', 1),
('Green Planet', 'Environmental conservation', 'www.greenplanet.org', 'info@greenplanet.org', '2345678901', 2),
('Paws Rescue', 'Animal rescue and rehabilitation', 'www.pawsrescue.org', 'help@pawsrescue.org', '3456789012', 3),
('Pure Water', 'Clean water initiatives', 'www.purewater.org', 'contact@purewater.org', '4567890123', 4),
('Feed the Future', 'Hunger relief programs', 'www.feedthefuture.org', 'info@feedthefuture.org', '5678901234', 5),
('Literacy for All', 'Promoting education worldwide', 'www.literacyforall.org', 'support@literacyforall.org', '6789012345', 6),
('Healthy Communities', 'Healthcare access initiatives', 'www.healthycommunities.org', 'contact@healthycommunities.org', '7890123456', 7),
('Safe Shelter', 'Housing for the homeless', 'www.safeshelter.org', 'info@safeshelter.org', '8901234567', 8),
('Women Rise', 'Empowering women through skills', 'www.womenrise.org', 'support@womenrise.org', '9012345678', 9),
('Digital for Good', 'Tech solutions for social issues', 'www.digitalforgood.org', 'contact@digitalforgood.org', '0123456789', 10);

-- Insert unique data into NGO_Categories table
INSERT INTO NGO_Categories (ngo_id, category_id, category_name) VALUES 
(1, 101, 'Child Education'),
(1, 102, 'Youth Development'),
(2, 201, 'Environmental Protection'),
(2, 202, 'Sustainability'),
(3, 301, 'Animal Rescue'),
(3, 302, 'Pet Adoption'),
(4, 401, 'Water Access'),
(4, 402, 'Sanitation'),
(5, 501, 'Food Security'),
(5, 502, 'Nutrition'),
(6, 601, 'Adult Literacy'),
(6, 602, 'School Support'),
(7, 701, 'Medical Care'),
(7, 702, 'Health Education'),
(8, 801, 'Housing'),
(8, 802, 'Homeless Support'),
(9, 901, 'Women Empowerment'),
(9, 902, 'Vocational Training'),
(10, 1001, 'Tech Education'),
(10, 1002, 'Digital Inclusion');

-- Insert unique data into Donors table
INSERT INTO Donors (user_id, name, email, phone, donor_type) VALUES 
(1, 'John Doe', 'john.doe@donor.com', '1112223333', 'Individual'),
(2, 'Jane Smith', 'jane.smith@donor.com', '2223334444', 'Individual'),
(3, 'Michael Johnson', 'michael.j@donor.com', '3334445555', 'Individual'),
(4, 'Sarah Williams', 'sarah.w@donor.com', '4445556666', 'Individual'),
(5, 'David Brown', 'david.b@donor.com', '5556667777', 'Individual'),
(6, 'ABC Corp', 'donate@abccorp.com', '6667778888', 'Organization'),
(7, 'XYZ Foundation', 'give@xyzfound.org', '7778889999', 'Organization'),
(8, 'Global Aid', 'support@globalaid.org', '8889990000', 'Organization'),
(9, 'Community First', 'info@communityfirst.org', '9990001111', 'Organization'),
(10, 'Future Fund', 'contact@futurefund.org', '0001112222', 'Organization');

-- Insert unique data into Donations table
INSERT INTO Donations (user_id, ngo_id, donor_id, amount, payment_method) VALUES 
(1, 1, 1, 100.00, 'Credit Card'),
(2, 2, 2, 250.50, 'PayPal'),
(3, 3, 3, 500.00, 'Bank Transfer'),
(4, 4, 4, 75.25, 'Credit Card'),
(5, 5, 5, 1000.00, 'PayPal'),
(6, 6, 6, 5000.00, 'Bank Transfer'),
(7, 7, 7, 1500.75, 'Credit Card'),
(8, 8, 8, 300.00, 'PayPal'),
(9, 9, 9, 750.50, 'Bank Transfer'),
(10, 10, 10, 2000.00, 'Credit Card');

-- Insert unique data into Beneficiaries table
INSERT INTO Beneficiaries (name, age, gender, ngo_id, received_support) VALUES 
('Rahul Sharma', 10, 'Male', 1, 'School supplies and tuition'),
('Priya Patel', 8, 'Female', 1, 'School uniform and books'),
('Amit Singh', 12, 'Male', 1, 'After-school tutoring'),
('Neha Gupta', 9, 'Female', 1, 'Medical checkup and vitamins'),
('Vijay Kumar', 11, 'Male', 1, 'School fees and transportation'),
('Buddy', 3, 'Male', 3, 'Vaccination and neutering'),
('Whiskers', 2, 'Female', 3, 'Rescue and rehabilitation'),
('Max', 5, 'Male', 3, 'Medical treatment and adoption'),
('Luna', 4, 'Female', 3, 'Foster care and training'),
('Rocky', 6, 'Male', 3, 'Senior dog care program');

-- Insert unique data into Adopters table
INSERT INTO Adopters (user_id, name, email, phone, address) VALUES 
(11, 'Alice Thompson', 'alice@family.com', '1112223333', '123 Main St, New York, NY'),
(12, 'Bob Wilson', 'bob@family.com', '2223334444', '456 Oak Ave, Los Angeles, CA'),
(13, 'Carol Martinez', 'carol@family.com', '3334445555', '789 Pine Rd, Chicago, IL'),
(14, 'David Miller', 'david@family.com', '4445556666', '321 Elm St, Houston, TX'),
(15, 'Eve Davis', 'eve@family.com', '5556667777', '654 Maple Dr, Phoenix, AZ'),
(16, 'Frank Moore', 'frank@family.com', '6667778888', '987 Cedar Ln, Philadelphia, PA'),
(17, 'Grace Taylor', 'grace@family.com', '7778889999', '159 Birch Blvd, San Antonio, TX'),
(18, 'Henry White', 'henry@family.com', '8889990000', '753 Spruce Way, San Diego, CA'),
(19, 'Ivy Clark', 'ivy@family.com', '9990001111', '456 Redwood Cir, Dallas, TX'),
(20, 'Jack Lewis', 'jack@family.com', '0001112222', '789 Sequoia Ct, Austin, TX');

-- Insert unique data into Adoptions table
INSERT INTO Adoptions (adopter_id, beneficiary_id, adoption_date) VALUES 
(1, 6, '2023-01-15'),
(2, 7, '2023-02-20'),
(3, 8, '2023-03-10'),
(4, 9, '2023-04-05'),
(5, 10, '2023-05-12'),
(6, 1, '2023-06-18'),
(7, 2, '2023-07-22'),
(8, 3, '2023-08-30'),
(9, 4, '2023-09-14'),
(10, 5, '2023-10-25');

-- Insert unique data into Trustees table
INSERT INTO Trustees (user_id, name, email, phone, position, ngo_id) VALUES 
(21, 'Olivia Green', 'olivia@trustee.org', '1112223333', 'Chairperson', 1),
(22, 'Peter King', 'peter@trustee.org', '2223334444', 'Secretary', 2),
(23, 'Quinn Scott', 'quinn@trustee.org', '3334445555', 'Treasurer', 3),
(24, 'Rachel Young', 'rachel@trustee.org', '4445556666', 'Director', 4),
(25, 'Samuel Hall', 'samuel@trustee.org', '5556667777', 'President', 5),
(26, 'Tina Adams', 'tina@trustee.org', '6667778888', 'Vice President', 6),
(27, 'Ulysses Reed', 'ulysses@trustee.org', '7778889999', 'Board Member', 7),
(28, 'Victoria Cook', 'victoria@trustee.org', '8889990000', 'Executive Director', 8),
(29, 'Walter Baker', 'walter@trustee.org', '9990001111', 'Program Manager', 9),
(30, 'Xena Carter', 'xena@trustee.org', '0001112222', 'Development Officer', 10);

-- Insert unique data into Events table
INSERT INTO Events (name, description, ngo_id, event_date, location) VALUES 
('Education Gala', 'Fundraiser for school programs', 1, '2023-11-15', 'Grand Ballroom, NY'),
('Earth Day Planting', 'Community tree planting', 2, '2023-04-22', 'Central Park, LA'),
('Adopt-a-Pet Day', 'Find homes for rescued animals', 3, '2023-05-20', 'City Shelter, Chicago'),
('Water Awareness Day', 'Educate about clean water', 4, '2023-06-05', 'Community Center, Houston'),
('Harvest Share', 'Food collection drive', 5, '2023-07-10', 'Various locations, Phoenix'),
('Reading Festival', 'Promote literacy skills', 6, '2023-08-12', 'Public Library, Philadelphia'),
('Health Fair', 'Free medical checkups', 7, '2023-09-18', 'Clinic, San Antonio'),
('Build Day', 'Construct homes for homeless', 8, '2023-10-05', 'Construction Site, San Diego'),
('Womens Expo', 'Showcase skills and products', 9, '2023-11-20', 'Convention Center, Dallas'),
('Tech Challenge', 'Develop solutions for NGOs', 10, '2023-12-10', 'Tech Campus, Austin');

-- Insert unique data into Reviews table
INSERT INTO Reviews (user_id, ngo_id, rating, review_text) VALUES 
(1, 1, 5, 'Transformative education programs for children'),
(2, 2, 4, 'Making real difference in environmental conservation'),
(3, 3, 5, 'Compassionate care for animals in need'),
(4, 4, 4, 'Critical work bringing clean water to communities'),
(5, 5, 5, 'Effective hunger relief programs with measurable impact'),
(6, 6, 4, 'Literacy programs are changing lives daily'),
(7, 7, 5, 'Healthcare services reach those who need it most'),
(8, 8, 4, 'Building more than houses - building hope'),
(9, 9, 5, 'Empowering women to transform their futures'),
(10, 10, 4, 'Innovative tech solutions for pressing social issues');

INSERT INTO Beneficiaries (name, age, gender, ngo_id, received_support) VALUES
('Anjali Mehta', 7, 'Female', 2, 'Tree plantation drive participation'),
('Rohan Desai', 14, 'Male', 2, 'Environmental awareness workshop'),
('Sneha Kapoor', 12, 'Female', 4, 'Access to clean drinking water'),
('Arjun Nair', 10, 'Male', 4, 'Sanitation facility improvement'),
('Kavya Iyer', 9, 'Female', 5, 'Nutritional meal support'),
('Manoj Verma', 13, 'Male', 5, 'Food distribution during crisis'),
('Simran Kaur', 8, 'Female', 6, 'Adult literacy program enrollment'),
('Rajesh Khanna', 11, 'Male', 6, 'Skill development training'),
('Meera Joshi', 10, 'Female', 7, 'Free medical checkup and medicines'),
('Vikram Singh', 14, 'Male', 7, 'Health awareness campaign participation');

INSERT INTO Events (name, description, ngo_id, event_date, location) VALUES
('Clean Energy Summit', 'Promote renewable energy solutions', 2, '2026-03-15', 'Green Conference Hall, LA'),
('Animal Welfare Workshop', 'Training on animal care and rescue', 3, '2026-04-10', 'Animal Shelter, Chicago'),
('Water Conservation Drive', 'Awareness on saving water', 4, '2026-05-22', 'Community Hall, Houston'),
('Food for All Campaign', 'Mass food distribution event', 5, '2026-06-18', 'City Square, Phoenix'),
('Global Literacy Day', 'Encouraging reading and education', 6, '2026-07-08', 'Central Library, Philadelphia'),
('Community Health Camp', 'Free health checkups and consultations', 7, '2026-08-14', 'Health Center, San Antonio'),
('Shelter Renovation Project', 'Improving facilities for the homeless', 8, '2026-09-25', 'Shelter Site, San Diego'),
('Women Empowerment Forum', 'Workshops and networking for women', 9, '2026-10-12', 'Civic Center, Dallas'),
('Tech for Change Hackathon', 'Innovative tech solutions for NGOs', 10, '2026-11-05', 'Innovation Hub, Austin'),
('Child Education Fair', 'Showcasing educational initiatives', 1, '2026-12-20', 'Exhibition Hall, NY');

SET SQL_SAFE_UPDATES = 1;
