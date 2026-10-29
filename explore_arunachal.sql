-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 29, 2026 at 01:47 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `explore_arunachal`
--

-- --------------------------------------------------------

--
-- Table structure for table `hotels`
--

CREATE TABLE `hotels` (
  `hotel_id` int(10) UNSIGNED NOT NULL,
  `hotel_name` varchar(150) NOT NULL,
  `location_id` int(10) UNSIGNED NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `price_per_night` decimal(10,2) DEFAULT NULL,
  `contact_number` varchar(30) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `altitude_m` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hotels`
--

INSERT INTO `hotels` (`hotel_id`, `hotel_name`, `location_id`, `address`, `price_per_night`, `contact_number`, `description`, `latitude`, `longitude`, `altitude_m`) VALUES
(1, 'Hotel Taktsang', 1, 'Temilow, Tawang', 4000.00, NULL, 'Sample hotel record for testing the tourism database.', NULL, NULL, NULL),
(2, 'Kasa Resort - Standard Room', 2, 'Ziro, Arunachal Pradesh', 4300.00, NULL, 'Sample accommodation record for testing the tourism database.', NULL, NULL, NULL),
(3, 'Example Lodge - Namsai', 22, 'Namsai, Arunachal Pradesh', NULL, NULL, 'Sample accommodation record for testing the tourism database.', NULL, NULL, NULL),
(4, 'Mountain View Hotel', 1, 'Tawang, Arunachal Pradesh', 2500.00, NULL, 'Fictional hotel and price for project demonstration.', NULL, NULL, NULL),
(5, 'Himalayan Comfort Inn', 1, 'Tawang, Arunachal Pradesh', 1800.00, NULL, 'Fictional hotel and price for project demonstration.', NULL, NULL, NULL),
(6, 'Pine Forest Resort', 2, 'Ziro, Arunachal Pradesh', 3200.00, NULL, 'Fictional hotel and price for project demonstration.', NULL, NULL, NULL),
(7, 'Green Valley Homestay', 2, 'Ziro, Arunachal Pradesh', 1500.00, NULL, 'Fictional hotel and price for project demonstration.', NULL, NULL, NULL),
(8, 'River View Lodge', 11, 'Pasighat, Arunachal Pradesh', 2000.00, NULL, 'Fictional hotel and price for project demonstration.', NULL, NULL, NULL),
(9, 'Golden Pagoda Stay', 22, 'Namsai, Arunachal Pradesh', 2200.00, NULL, 'Fictional hotel and price for project demonstration.', NULL, NULL, NULL),
(11, 'Namsai Lodge', 22, 'Namsai, Arunachal Pradesh', 1800.00, NULL, 'Fictional lodge record for the Explore Arunachal project. Sample price per night.', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `local_foods`
--

CREATE TABLE `local_foods` (
  `food_id` int(10) UNSIGNED NOT NULL,
  `location_id` int(10) UNSIGNED NOT NULL,
  `food_name` varchar(150) NOT NULL,
  `food_category` varchar(80) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `estimated_price` decimal(10,2) DEFAULT NULL,
  `where_to_try` varchar(180) DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `is_demo_data` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `local_foods`
--

INSERT INTO `local_foods` (`food_id`, `location_id`, `food_name`, `food_category`, `description`, `estimated_price`, `where_to_try`, `image_url`, `is_demo_data`) VALUES
(1, 1, 'Churpi', 'Traditional dairy food', 'Traditional cheese associated with Himalayan food culture; varieties can be soft or dried.', 120.00, 'Local market or demo food stall', '/static/images/churpi.jpg', 1),
(2, 1, 'Thukpa', 'Noodle soup', 'Warm noodle soup popular in Himalayan regions.', 180.00, 'Demo mountain cafe', '/static/images/thukpa.jpg', 1),
(3, 1, 'Momos', 'Dumplings', 'Steamed dumplings with vegetarian or meat fillings.', 150.00, 'Demo local eatery', '/static/images/momos.jpg', 1),
(4, 2, 'Bamboo Shoot Curry', 'Local-style dish', 'A regional-style dish made with bamboo shoots; preparation varies.', 180.00, 'Demo valley restaurant', '/static/images/ziro-bamboo-shoot.jpg', 1),
(5, 2, 'Pika Pila', 'Apatani-associated pickle', 'A traditional pickle associated with Apatani food culture.', 100.00, 'Demo local food stall', '/static/images/pika-pila.jpg', 1),
(6, 5, 'Momos', 'Dumplings', 'Steamed dumplings served with a dipping sauce.', 140.00, 'Demo highland cafe', '/static/images/bomdila-momos.jpg', 1),
(7, 5, 'Thukpa', 'Noodle soup', 'Noodle soup suitable for a cool-weather meal.', 170.00, 'Demo highland cafe', '/static/images/bomdila-thukpa.jpg', 1),
(8, 11, 'Smoked Fish', 'Regional-style dish', 'A smoked-fish dish inspired by food traditions of the Siang region.', 250.00, 'Demo riverside restaurant', '/static/images/smoked-fish.jpg', 1),
(9, 11, 'Rice with Local Greens', 'Rice meal', 'Rice served with seasonal greens in a regional-style meal.', 160.00, 'Demo local restaurant', '/static/images/local-greens.jpg', 1),
(10, 22, 'Bamboo Shoot Curry', 'Regional dish', 'A bamboo-shoot dish inspired by food traditions of the region.', 170.00, 'Demo Namsai food stall', '/static/images/namsai-bamboo-shoot.jpg', 1),
(11, 22, 'Sticky Rice', 'Rice dish', 'Sticky rice served as part of a regional-style meal.', 100.00, 'Demo local restaurant', '/static/images/sticky-rice.jpg', 1);

-- --------------------------------------------------------

--
-- Table structure for table `locations`
--

CREATE TABLE `locations` (
  `location_id` int(10) UNSIGNED NOT NULL,
  `location_name` varchar(120) NOT NULL,
  `district` varchar(100) NOT NULL,
  `state` varchar(100) NOT NULL DEFAULT 'Arunachal Pradesh',
  `description` text DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `altitude_m` int(11) DEFAULT NULL,
  `nearest_hospital` varchar(180) DEFAULT NULL,
  `hospital_phone` varchar(30) DEFAULT NULL,
  `nearest_police_station` varchar(180) DEFAULT NULL,
  `police_phone` varchar(30) DEFAULT NULL,
  `emergency_notes` text DEFAULT NULL,
  `estimated_daily_budget` decimal(10,2) DEFAULT NULL,
  `budget_notes` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `locations`
--

INSERT INTO `locations` (`location_id`, `location_name`, `district`, `state`, `description`, `latitude`, `longitude`, `altitude_m`, `nearest_hospital`, `hospital_phone`, `nearest_police_station`, `police_phone`, `emergency_notes`, `estimated_daily_budget`, `budget_notes`) VALUES
(1, 'Tawang Town', 'Tawang', 'Arunachal Pradesh', 'A town known for its Buddhist monastery and mountain scenery.', 27.5860000, 91.8590000, 3048, 'Tawang Demo Medical Centre', 'DEMO-HOSP-001', 'Tawang Demo Police Station', 'DEMO-POL-001', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(2, 'Ziro', 'Lower Subansiri', 'Arunachal Pradesh', 'A valley known for its landscapes and Apatani culture.', 27.5330000, 93.8300000, 1570, 'Ziro Demo Community Hospital', 'DEMO-HOSP-002', 'Ziro Demo Police Station', 'DEMO-POL-002', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(3, 'Itanagar', 'Papum Pare', 'Arunachal Pradesh', 'The capital city of Arunachal Pradesh.', 27.1000000, 93.6200000, 440, 'Itanagar Demo Medical Centre', 'DEMO-HOSP-013', 'Itanagar Demo Police Station', 'DEMO-POL-013', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(4, 'Changlang', 'Changlang', 'Arunachal Pradesh', 'A district with forests and natural attractions.', 27.1200000, 95.7100000, 200, 'Changlang Demo Hospital', 'DEMO-HOSP-009', 'Changlang Demo Police Station', 'DEMO-POL-009', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(5, 'Bomdila', 'West Kameng', 'Arunachal Pradesh', 'Town known for mountain scenery and monasteries.', 27.2500000, 92.4000000, 2217, 'Bomdila Demo Hospital', 'DEMO-HOSP-004', 'Bomdila Demo Police Station', 'DEMO-POL-004', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(6, 'Dirang', 'West Kameng', 'Arunachal Pradesh', 'Mountain valley known for natural scenery and hot springs.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(7, 'Sela Pass Area', 'Tawang', 'Arunachal Pradesh', 'High-altitude mountain pass area on the route to Tawang.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(8, 'Jang', 'Tawang', 'Arunachal Pradesh', 'Area associated with Nuranang Falls.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(9, 'Sangetsar Lake Area', 'Tawang', 'Arunachal Pradesh', 'Area around Sangetsar Lake, also known as Madhuri Lake.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(10, 'Mechuka', 'Shi Yomi', 'Arunachal Pradesh', 'Remote valley known for mountain landscapes.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(11, 'Pasighat', 'East Siang', 'Arunachal Pradesh', 'Town near the Siang River.', 28.0700000, 95.3300000, 155, 'Pasighat Demo Hospital', 'DEMO-HOSP-005', 'Pasighat Demo Police Station', 'DEMO-POL-005', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(12, 'Aalo', 'West Siang', 'Arunachal Pradesh', 'Town surrounded by hills and river valleys.', 28.1700000, 94.8000000, 300, 'Aalo Demo Hospital', 'DEMO-HOSP-010', 'Aalo Demo Police Station', 'DEMO-POL-010', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(13, 'Roing', 'Lower Dibang Valley', 'Arunachal Pradesh', 'Town serving as a gateway to nearby natural attractions.', 28.1400000, 95.8400000, 400, 'Roing Demo Medical Centre', 'DEMO-HOSP-008', 'Roing Demo Police Station', 'DEMO-POL-008', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(14, 'Tezu', 'Lohit', 'Arunachal Pradesh', 'Town in the Lohit region.', 27.4900000, 95.0200000, 185, 'Tezu Demo Medical Centre', 'DEMO-HOSP-006', 'Tezu Demo Police Station', 'DEMO-POL-006', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(15, 'Khonsa', 'Tirap', 'Arunachal Pradesh', 'Hill town in Tirap district.', 27.0200000, 95.5100000, 1200, 'Khonsa Demo Hospital', 'DEMO-HOSP-012', 'Khonsa Demo Police Station', 'DEMO-POL-012', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(16, 'Daporijo', 'Upper Subansiri', 'Arunachal Pradesh', 'Town near the Subansiri River.', 27.9900000, 94.2200000, 600, 'Daporijo Demo Hospital', 'DEMO-HOSP-007', 'Daporijo Demo Police Station', 'DEMO-POL-007', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(17, 'Anini', 'Dibang Valley', 'Arunachal Pradesh', 'Remote mountain town in Dibang Valley.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(18, 'Hayuliang', 'Anjaw', 'Arunachal Pradesh', 'Town in the Anjaw region.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(19, 'Seppa', 'East Kameng', 'Arunachal Pradesh', 'Town in East Kameng district.', 27.3600000, 93.0200000, 1000, 'Seppa Demo Hospital', 'DEMO-HOSP-011', 'Seppa Demo Police Station', 'DEMO-POL-011', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL),
(20, 'Yingkiong', 'Upper Siang', 'Arunachal Pradesh', 'Town in the Upper Siang region.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(21, 'Longding', 'Longding', 'Arunachal Pradesh', 'Town in Longding district.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(22, 'Namsai', 'Namsai', 'Arunachal Pradesh', 'A town in eastern Arunachal Pradesh known for its Buddhist heritage, including the Golden Pagoda at Tengapani.', 27.6700000, 95.8600000, 150, 'Namsai Demo Medical Centre', 'DEMO-HOSP-003', 'Namsai Demo Police Station', 'DEMO-POL-003', 'DEMO ONLY: fictional facilities and contacts.', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `medical_facilities`
--

CREATE TABLE `medical_facilities` (
  `medical_id` int(10) UNSIGNED NOT NULL,
  `facility_name` varchar(180) NOT NULL,
  `location_id` int(10) UNSIGNED NOT NULL,
  `facility_type` varchar(80) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `contact_number` varchar(30) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `altitude_m` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `medical_facilities`
--

INSERT INTO `medical_facilities` (`medical_id`, `facility_name`, `location_id`, `facility_type`, `address`, `contact_number`, `latitude`, `longitude`, `altitude_m`) VALUES
(1, 'Khando Drowa Sangmo District Hospital', 1, 'District Hospital', 'Tawang, Arunachal Pradesh 790104', '+91 3794 222221', 27.5860000, 91.8594000, 3000),
(2, 'General Hospital Ziro', 2, 'General Hospital', 'Ziro, Lower Subansiri, Arunachal Pradesh', 'Verify with Health Department', 27.8276000, 93.5202000, 1572),
(3, 'District Hospital Changlang', 4, 'District Hospital', 'Changlang, Arunachal Pradesh', 'Verify with Health Department', 27.7422000, 96.6424000, 580),
(4, 'General Hospital Bomdila', 5, 'General Hospital', 'Bomdila, West Kameng, Arunachal Pradesh', 'Verify with Health Department', 27.2606000, 92.4202000, 2430),
(5, 'Bakin Pertin General Hospital', 11, 'General Hospital', 'Pasighat, East Siang, Arunachal Pradesh', 'Verify with Health Department', 28.0619000, 95.3259000, 155),
(6, 'General Hospital Aalo', 12, 'General Hospital', 'Aalo, West Siang, Arunachal Pradesh', 'Verify with Health Department', 27.8451000, 95.2473000, 300),
(7, 'District Hospital Roing', 13, 'District Hospital', 'Roing, Lower Dibang Valley, Arunachal Pradesh', 'Verify with Health Department', 28.1429000, 95.9431000, 390),
(8, 'General Hospital Tezu', 14, 'General Hospital', 'Tezu, Lohit, Arunachal Pradesh', 'Verify with Health Department', 27.9339000, 96.1580000, 210),
(9, 'District Hospital Namsai', 22, 'District Hospital', 'Hospital Road, Namsai, Arunachal Pradesh 792103', 'Verify with Health Department', 27.6692000, 95.8644000, 150);

-- --------------------------------------------------------

--
-- Table structure for table `places`
--

CREATE TABLE `places` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `district` varchar(100) NOT NULL,
  `category` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `places`
--

INSERT INTO `places` (`id`, `name`, `district`, `category`, `description`) VALUES
(1, 'Tawang Monastery', 'Tawang', 'Cultural', 'A famous Buddhist monastery in Arunachal Pradesh.'),
(2, 'Ziro Valley', 'Lower Subansiri', 'Nature', 'A scenic valley known for its landscapes and Apatani culture.'),
(3, 'Namdapha National Park', 'Changlang', 'Wildlife', 'A national park known for its biodiversity and forests.'),
(4, 'Sela Pass', 'Tawang', 'Nature', 'High mountain pass with dramatic Himalayan scenery.'),
(5, 'Nuranang Falls', 'Tawang', 'Nature', 'Scenic waterfall near Jang, surrounded by forested mountains.'),
(6, 'Sangetsar Lake', 'Tawang', 'Nature', 'High-altitude lake known for mountain views.'),
(7, 'Bum La Pass', 'Tawang', 'Adventure', 'High-altitude border pass; check permit and access requirements.'),
(8, 'Tawang War Memorial', 'Tawang', 'Historical', 'Memorial honouring soldiers who served in the region.'),
(9, 'Talley Valley Wildlife Sanctuary', 'Lower Subansiri', 'Wildlife', 'Forest sanctuary with rich biodiversity.'),
(10, 'Meghna Cave Temple', 'Lower Subansiri', 'Religious', 'Cave temple set among scenic surroundings.'),
(11, 'Ita Fort', 'Papum Pare', 'Historical', 'Historic fort site in the Itanagar area.'),
(12, 'Ganga Lake (Gyakar Sinyi)', 'Papum Pare', 'Nature', 'Forest-fringed lake near Itanagar.'),
(13, 'Jawaharlal Nehru State Museum', 'Papum Pare', 'Cultural', 'Museum showcasing regional culture, crafts and history.'),
(14, 'Miao', 'Changlang', 'Nature', 'Town used as a gateway for exploring Namdapha National Park.'),
(15, 'Golden Pagoda (Kongmu Kham)', 'Namsai', 'Religious', 'Golden Buddhist pagoda near Namsai.'),
(16, 'Parshuram Kund', 'Lohit', 'Religious', 'Important pilgrimage site beside the Lohit River.'),
(17, 'Bhismaknagar Fort', 'Lower Dibang Valley', 'Historical', 'Archaeological fort site associated with regional history.'),
(18, 'Mayudia Pass', 'Lower Dibang Valley', 'Nature', 'Mountain destination known for misty views and cool weather.'),
(19, 'Daying Ering Wildlife Sanctuary', 'East Siang', 'Wildlife', 'River-island sanctuary with wetland and bird habitats.'),
(20, 'Bhalukpong', 'West Kameng', 'Nature', 'Gateway town near forested hills and the Kameng River.'),
(21, 'Bomdila Monastery', 'West Kameng', 'Religious', 'Buddhist monastery with views of the surrounding mountains.'),
(22, 'Dirang Dzong', 'West Kameng', 'Historical', 'Historic settlement and fortified village area in Dirang.'),
(23, 'Sangti Valley', 'West Kameng', 'Nature', 'Valley known for mountain scenery and seasonal birdlife.'),
(24, 'Malinithan Temple Ruins', 'Lower Siang', 'Historical', 'Archaeological temple ruins with carved stone remains.'),
(25, 'Akashiganga', 'Lower Dibang Valley', 'Religious', 'Pilgrimage destination associated with local legends.'),
(26, 'Kane Wildlife Sanctuary', 'West Siang', 'Wildlife', 'Protected forest area with regional biodiversity.'),
(27, 'D Ering Memorial Wildlife Sanctuary', 'East Siang', 'Wildlife', 'Wildlife sanctuary area near the Siang River.');

-- --------------------------------------------------------

--
-- Table structure for table `police_stations`
--

CREATE TABLE `police_stations` (
  `police_station_id` int(10) UNSIGNED NOT NULL,
  `station_name` varchar(180) NOT NULL,
  `location_id` int(10) UNSIGNED NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `contact_number` varchar(30) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `altitude_m` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `police_stations`
--

INSERT INTO `police_stations` (`police_station_id`, `station_name`, `location_id`, `address`, `contact_number`, `latitude`, `longitude`, `altitude_m`) VALUES
(1, 'Tawang Police Station', 1, 'Near District Hospital, Tawang, Arunachal Pradesh', 'Verify with Arunachal Pradesh ', 27.5860000, 91.8594000, 3000),
(2, 'Ziro Police Station', 2, 'Ziro, Lower Subansiri, Arunachal Pradesh', 'Verify with Arunachal Pradesh ', 27.8276000, 93.5202000, 1572),
(3, 'Itanagar Police Station', 3, 'C-Sector, Itanagar, Arunachal Pradesh 791111', '+91 360 2257220', 27.0844000, 93.6053000, 459),
(4, 'Bomdila Police Station', 5, 'Bomdila, West Kameng, Arunachal Pradesh', 'Verify with Arunachal Pradesh ', 27.2636000, 92.4229000, 2430),
(5, 'Dirang Police Station', 6, 'Dirang, West Kameng, Arunachal Pradesh', 'Verify with Arunachal Pradesh ', 27.3594700, 92.2456600, 1560),
(6, 'Pasighat Police Station', 11, 'Pasighat, East Siang, Arunachal Pradesh', 'Verify with Arunachal Pradesh ', 28.0619000, 95.3259000, 155),
(7, 'Namsai Police Station', 22, 'Tinali Road, Namsai, Arunachal Pradesh 792103', 'Verify with Arunachal Pradesh ', 27.6692000, 95.8644000, 150);

-- --------------------------------------------------------

--
-- Table structure for table `restaurants`
--

CREATE TABLE `restaurants` (
  `restaurant_id` int(10) UNSIGNED NOT NULL,
  `restaurant_name` varchar(150) NOT NULL,
  `location_id` int(10) UNSIGNED NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `cuisine_type` varchar(100) DEFAULT NULL,
  `average_price` decimal(10,2) DEFAULT NULL,
  `contact_number` varchar(30) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `altitude_m` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `restaurants`
--

INSERT INTO `restaurants` (`restaurant_id`, `restaurant_name`, `location_id`, `address`, `cuisine_type`, `average_price`, `contact_number`, `description`, `image_url`, `latitude`, `longitude`, `altitude_m`) VALUES
(1, 'Tawang Mountain Cafe', 1, 'Tawang Market', 'Indian and Tibetan', 350.00, 'DEMO-REST-001', 'Fictional restaurant for hackathon demo.', '/static/images/tawang-cafe.jpg', NULL, NULL, NULL),
(2, 'Ziro Valley Kitchen', 2, 'Ziro Market', 'Local and Indian', 250.00, 'DEMO-REST-002', 'Fictional restaurant for hackathon demo.', '/static/images/ziro.jpg', NULL, NULL, NULL),
(3, 'Bomdila Highland Kitchen', 5, 'Bomdila Market', 'Indian and local', 320.00, 'DEMO-REST-005', 'Fictional restaurant for hackathon demo.', '/static/images/bomdila.jpg', NULL, NULL, NULL),
(4, 'Pasighat Riverside Restaurant', 11, 'Pasighat Market', 'Indian and Chinese', 280.00, 'DEMO-REST-004', 'Fictional restaurant for hackathon demo.', '/static/images/pasighat.jpg', NULL, NULL, NULL),
(5, 'Namsai Golden Cafe', 22, 'Namsai Market', 'Indian and Asian', 300.00, 'DEMO-REST-003', 'Fictional restaurant for hackathon demo.', '/static/images/namsai.jpg', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tourist_destinations`
--

CREATE TABLE `tourist_destinations` (
  `destination_id` int(10) UNSIGNED NOT NULL,
  `destination_name` varchar(150) NOT NULL,
  `location_id` int(10) UNSIGNED NOT NULL,
  `destination_type` varchar(60) NOT NULL,
  `description` text DEFAULT NULL,
  `entry_fee` decimal(10,2) DEFAULT NULL,
  `opening_hours` varchar(120) DEFAULT NULL,
  `best_time_to_visit` varchar(150) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `estimated_entry_fee` decimal(10,2) DEFAULT NULL,
  `estimated_local_transport` decimal(10,2) DEFAULT NULL,
  `altitude_m` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tourist_destinations`
--

INSERT INTO `tourist_destinations` (`destination_id`, `destination_name`, `location_id`, `destination_type`, `description`, `entry_fee`, `opening_hours`, `best_time_to_visit`, `latitude`, `longitude`, `estimated_entry_fee`, `estimated_local_transport`, `altitude_m`) VALUES
(1, 'Tawang Monastery', 1, 'Monastery', 'Major Buddhist monastery and cultural landmark in Tawang.', NULL, NULL, 'Spring and autumn; check current conditions.', NULL, NULL, NULL, NULL, NULL),
(2, 'Sela Pass', 7, 'Mountain Pass', 'High-altitude pass on the route connecting the Tawang and West Kameng areas.', NULL, NULL, 'Subject to weather and road conditions.', NULL, NULL, NULL, NULL, NULL),
(3, 'Madhuri Lake (Sangetsar Lake)', 9, 'Lake', 'High-altitude lake in the Tawang region.', NULL, NULL, 'Check access requirements and local conditions.', NULL, NULL, NULL, NULL, NULL),
(4, 'Nuranang Falls (Jang Falls)', 8, 'Waterfall', 'Waterfall near Jang on the route towards Tawang.', NULL, NULL, 'Check weather and road conditions.', NULL, NULL, NULL, NULL, NULL),
(5, 'Bum La Pass', 1, 'Mountain Pass', 'High-altitude border-area destination; special permission may be required.', NULL, NULL, 'Only when access is officially permitted.', NULL, NULL, NULL, NULL, NULL),
(6, 'Golden Pagoda (Kongmu Kham)', 22, 'Pagoda', 'Buddhist pagoda at Tengapani in the Namsai region.', NULL, NULL, 'Check local visitor information before travelling.', NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `transport`
--

CREATE TABLE `transport` (
  `transport_id` int(10) UNSIGNED NOT NULL,
  `transport_name` varchar(150) NOT NULL,
  `transport_type` varchar(60) NOT NULL,
  `location_id` int(10) UNSIGNED NOT NULL,
  `starting_point` varchar(150) DEFAULT NULL,
  `destination` varchar(150) DEFAULT NULL,
  `estimated_distance_km` decimal(8,2) DEFAULT NULL,
  `estimated_duration` varchar(80) DEFAULT NULL,
  `estimated_fare` decimal(10,2) DEFAULT NULL,
  `fuel_cost` decimal(10,2) DEFAULT NULL,
  `contact_number` varchar(30) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transport`
--

INSERT INTO `transport` (`transport_id`, `transport_name`, `transport_type`, `location_id`, `starting_point`, `destination`, `estimated_distance_km`, `estimated_duration`, `estimated_fare`, `fuel_cost`, `contact_number`, `description`, `image_url`) VALUES
(1, 'Tawang Shared Taxi', 'Shared Taxi', 1, 'Tawang Town', 'Sela Pass', 80.00, '3 hours', 600.00, 0.00, 'DEMO-TRANS-001', 'Fictional shared taxi service for demo.', '/static/images/shared-taxi.jpg'),
(2, 'Tawang Private Cab', 'Private Taxi', 1, 'Tawang Town', 'Bomdila', 170.00, '6 hours', 3500.00, 0.00, 'DEMO-TRANS-002', 'Fictional private cab; sample fare per vehicle.', '/static/images/private-cab.jpg'),
(3, 'Ziro Local Taxi', 'Local Taxi', 2, 'Ziro', 'Ziro Tourist Circuit', 25.00, '2 hours', 900.00, 0.00, 'DEMO-TRANS-003', 'Fictional local sightseeing taxi.', '/static/images/ziro-taxi.jpg'),
(4, 'Itanagar to Tawang Cab', 'Private Taxi', 3, 'Itanagar', 'Tawang Town', 450.00, '12 hours', 6500.00, 0.00, 'DEMO-TRANS-005', 'Fictional intercity fare and route estimate.', '/static/images/intercity-cab.jpg'),
(5, 'Bomdila Tourist Cab', 'Private Taxi', 5, 'Bomdila', 'Dirang', 45.00, '2 hours', 1200.00, 0.00, 'DEMO-TRANS-007', 'Fictional cab fare for the demo.', '/static/images/bomdila-cab.jpg'),
(6, 'Pasighat City Taxi', 'Local Taxi', 11, 'Pasighat', 'Pasighat Sightseeing Area', 20.00, '1 hour', 600.00, 0.00, 'DEMO-TRANS-006', 'Fictional local sightseeing transport.', '/static/images/pasighat-taxi.jpg'),
(7, 'Aalo Local Taxi', 'Local Taxi', 12, 'Aalo', 'Aalo Sightseeing Area', 20.00, '1 hour', 600.00, 0.00, 'DEMO-TRANS-010', 'Fictional local sightseeing transport.', '/static/images/aalo-taxi.jpg'),
(8, 'Roing Local Cab', 'Local Taxi', 13, 'Roing', 'Mayudia Area', 35.00, '2 hours', 1000.00, 0.00, 'DEMO-TRANS-008', 'Fictional local transport option.', '/static/images/roing-cab.jpg'),
(9, 'Tezu Rental Car', 'Rental Car', 14, 'Tezu', 'Tezu Sightseeing Area', 30.00, '2 hours', 1800.00, 700.00, 'DEMO-TRANS-009', 'Fictional rental rate; fuel cost shown separately.', '/static/images/rental-car.jpg'),
(10, 'Namsai Town Cab', 'Local Taxi', 22, 'Namsai', 'Golden Pagoda', 15.00, '30 minutes', 400.00, 0.00, 'DEMO-TRANS-004', 'Fictional local transport option.', '/static/images/namsai-cab.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `travel_costs`
--

CREATE TABLE `travel_costs` (
  `travel_cost_id` int(10) UNSIGNED NOT NULL,
  `origin_location_id` int(10) UNSIGNED NOT NULL,
  `destination_location_id` int(10) UNSIGNED NOT NULL,
  `transport_type` varchar(50) NOT NULL,
  `distance_km` decimal(8,2) DEFAULT NULL,
  `estimated_fuel_cost` decimal(10,2) DEFAULT 0.00,
  `estimated_transport_fare` decimal(10,2) DEFAULT 0.00,
  `estimated_food_cost` decimal(10,2) DEFAULT 0.00,
  `estimated_hotel_cost` decimal(10,2) DEFAULT 0.00,
  `estimated_sightseeing_cost` decimal(10,2) DEFAULT 0.00,
  `estimated_miscellaneous_cost` decimal(10,2) DEFAULT 0.00,
  `estimated_total_cost` decimal(10,2) DEFAULT 0.00,
  `budget_notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `travel_costs`
--

INSERT INTO `travel_costs` (`travel_cost_id`, `origin_location_id`, `destination_location_id`, `transport_type`, `distance_km`, `estimated_fuel_cost`, `estimated_transport_fare`, `estimated_food_cost`, `estimated_hotel_cost`, `estimated_sightseeing_cost`, `estimated_miscellaneous_cost`, `estimated_total_cost`, `budget_notes`) VALUES
(1, 3, 1, 'Shared taxi', 180.00, 0.00, 1500.00, 600.00, 1800.00, 500.00, 300.00, 4700.00, 'Fictional one-person demo budget; confirm actual fares and conditions.');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `hotels`
--
ALTER TABLE `hotels`
  ADD PRIMARY KEY (`hotel_id`),
  ADD KEY `fk_hotel_location` (`location_id`),
  ADD KEY `idx_hotel_name` (`hotel_name`);

--
-- Indexes for table `local_foods`
--
ALTER TABLE `local_foods`
  ADD PRIMARY KEY (`food_id`),
  ADD KEY `idx_food_name` (`food_name`),
  ADD KEY `idx_food_location` (`location_id`);

--
-- Indexes for table `locations`
--
ALTER TABLE `locations`
  ADD PRIMARY KEY (`location_id`);

--
-- Indexes for table `medical_facilities`
--
ALTER TABLE `medical_facilities`
  ADD PRIMARY KEY (`medical_id`),
  ADD KEY `location_id` (`location_id`);

--
-- Indexes for table `places`
--
ALTER TABLE `places`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `police_stations`
--
ALTER TABLE `police_stations`
  ADD PRIMARY KEY (`police_station_id`),
  ADD KEY `location_id` (`location_id`);

--
-- Indexes for table `restaurants`
--
ALTER TABLE `restaurants`
  ADD PRIMARY KEY (`restaurant_id`),
  ADD KEY `fk_restaurant_location` (`location_id`),
  ADD KEY `idx_restaurant_name` (`restaurant_name`),
  ADD KEY `idx_restaurant_cuisine` (`cuisine_type`);

--
-- Indexes for table `tourist_destinations`
--
ALTER TABLE `tourist_destinations`
  ADD PRIMARY KEY (`destination_id`),
  ADD KEY `fk_destination_location` (`location_id`),
  ADD KEY `idx_destination_name` (`destination_name`),
  ADD KEY `idx_destination_type` (`destination_type`);

--
-- Indexes for table `transport`
--
ALTER TABLE `transport`
  ADD PRIMARY KEY (`transport_id`),
  ADD KEY `idx_transport_type` (`transport_type`),
  ADD KEY `idx_transport_location` (`location_id`);

--
-- Indexes for table `travel_costs`
--
ALTER TABLE `travel_costs`
  ADD PRIMARY KEY (`travel_cost_id`),
  ADD KEY `origin_location_id` (`origin_location_id`),
  ADD KEY `destination_location_id` (`destination_location_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `hotels`
--
ALTER TABLE `hotels`
  MODIFY `hotel_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `local_foods`
--
ALTER TABLE `local_foods`
  MODIFY `food_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `locations`
--
ALTER TABLE `locations`
  MODIFY `location_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `medical_facilities`
--
ALTER TABLE `medical_facilities`
  MODIFY `medical_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `places`
--
ALTER TABLE `places`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `police_stations`
--
ALTER TABLE `police_stations`
  MODIFY `police_station_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `restaurants`
--
ALTER TABLE `restaurants`
  MODIFY `restaurant_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `tourist_destinations`
--
ALTER TABLE `tourist_destinations`
  MODIFY `destination_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `transport`
--
ALTER TABLE `transport`
  MODIFY `transport_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `travel_costs`
--
ALTER TABLE `travel_costs`
  MODIFY `travel_cost_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `hotels`
--
ALTER TABLE `hotels`
  ADD CONSTRAINT `fk_hotel_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`) ON UPDATE CASCADE;

--
-- Constraints for table `local_foods`
--
ALTER TABLE `local_foods`
  ADD CONSTRAINT `fk_food_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`) ON UPDATE CASCADE;

--
-- Constraints for table `medical_facilities`
--
ALTER TABLE `medical_facilities`
  ADD CONSTRAINT `medical_facilities_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`) ON UPDATE CASCADE;

--
-- Constraints for table `police_stations`
--
ALTER TABLE `police_stations`
  ADD CONSTRAINT `police_stations_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`) ON UPDATE CASCADE;

--
-- Constraints for table `restaurants`
--
ALTER TABLE `restaurants`
  ADD CONSTRAINT `fk_restaurant_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`) ON UPDATE CASCADE;

--
-- Constraints for table `tourist_destinations`
--
ALTER TABLE `tourist_destinations`
  ADD CONSTRAINT `fk_destination_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`) ON UPDATE CASCADE;

--
-- Constraints for table `transport`
--
ALTER TABLE `transport`
  ADD CONSTRAINT `fk_transport_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`) ON UPDATE CASCADE;

--
-- Constraints for table `travel_costs`
--
ALTER TABLE `travel_costs`
  ADD CONSTRAINT `travel_costs_ibfk_1` FOREIGN KEY (`origin_location_id`) REFERENCES `locations` (`location_id`),
  ADD CONSTRAINT `travel_costs_ibfk_2` FOREIGN KEY (`destination_location_id`) REFERENCES `locations` (`location_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
