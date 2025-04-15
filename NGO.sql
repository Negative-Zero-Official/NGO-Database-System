-- CREATE DATABASE NGO_Search_Engine;
USE NGO_Search_Engine;

-- Drop tables safely (to avoid errors if they don't exist)
DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS Events;
DROP TABLE IF EXISTS Adoptions;
DROP TABLE IF EXISTS Trustees;
DROP TABLE IF EXISTS Adopters;
DROP TABLE IF EXISTS Beneficiaries;
DROP TABLE IF EXISTS Donations;
DROP TABLE IF EXISTS Donors;
DROP TABLE IF EXISTS NGO_Categories;
DROP TABLE IF EXISTS NGOs;
DROP TABLE IF EXISTS Locations;
DROP TABLE IF EXISTS Users;

-- Users Table
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Locations Table
CREATE TABLE Locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

-- NGOs Table
CREATE TABLE NGOs (
    ngo_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    website VARCHAR(255),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    location_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (location_id) REFERENCES Locations(location_id) ON DELETE SET NULL
);

-- Categories Table (Optional: If using separate categories table)
-- CREATE TABLE Categories (
--     category_id INT AUTO_INCREMENT PRIMARY KEY,
--     category_name VARCHAR(100) UNIQUE NOT NULL
-- );

-- Many-to-Many Relationship: NGOs & Categories
CREATE TABLE NGO_Categories (
    ngo_id INT,
    category_id INT,
    category_name VARCHAR(100) UNIQUE NOT NULL,
    PRIMARY KEY (ngo_id, category_id),
    FOREIGN KEY (ngo_id) REFERENCES NGOs(ngo_id) ON DELETE CASCADE
    -- FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE CASCADE
);

-- Donors Table
CREATE TABLE Donors (
    donor_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    donor_type ENUM('Individual', 'Organization') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Donations Table
CREATE TABLE Donations (
    donation_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    ngo_id INT,
    donor_id INT, 
    amount DECIMAL(10,2) NOT NULL,
    donation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer') NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (ngo_id) REFERENCES NGOs(ngo_id) ON DELETE CASCADE,
    FOREIGN KEY (donor_id) REFERENCES Donors(donor_id) ON DELETE SET NULL
);

-- Beneficiaries Table
CREATE TABLE Beneficiaries (
    beneficiary_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    age INT,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    ngo_id INT,
    received_support TEXT,
    FOREIGN KEY (ngo_id) REFERENCES NGOs(ngo_id) ON DELETE CASCADE
);

-- Adopters Table (For Orphanages, Animal Shelters, etc.)
CREATE TABLE Adopters (
    adopter_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Adoption Table (Mapping Beneficiaries to Adopters)
CREATE TABLE Adoptions (
    adoption_id INT AUTO_INCREMENT PRIMARY KEY,
    adopter_id INT,
    beneficiary_id INT,
    adoption_date DATE,
    FOREIGN KEY (adopter_id) REFERENCES Adopters(adopter_id) ON DELETE CASCADE,
    FOREIGN KEY (beneficiary_id) REFERENCES Beneficiaries(beneficiary_id) ON DELETE CASCADE
);

-- Trustees Table (People who manage NGOs)
CREATE TABLE Trustees (
    trustee_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    position VARCHAR(100),
    ngo_id INT,
    FOREIGN KEY (ngo_id) REFERENCES NGOs(ngo_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Annual Events Table (NGOs organize events)
CREATE TABLE Events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    ngo_id INT,
    event_date DATE,
    location TEXT,
    FOREIGN KEY (ngo_id) REFERENCES NGOs(ngo_id) ON DELETE CASCADE
);

-- Reviews Table
CREATE TABLE Reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    ngo_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (ngo_id) REFERENCES NGOs(ngo_id) ON DELETE CASCADE
);

