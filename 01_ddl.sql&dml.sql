-- Fierst we optimize our workbench for the database with big data 
SET GLOBAL local_infile = 1;
SET GLOBAL net_read_timeout = 600;
SET GLOBAL net_write_timeout = 600;
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;
SET GLOBAL max_allowed_packet = 268435456;

SHOW VARIABLES WHERE Variable_name IN (
    'local_infile',
    'net_read_timeout',
    'net_write_timeout',
    'wait_timeout',
    'interactive_timeout',
    'max_allowed_packet',
    'secure_file_priv'
);


-- now we crate database and import tables as raw file for easy oeration
create database airbnb_nyc;
use airbnb_nyc;
create table listings_raw (id TEXT,
    listing_url TEXT,
    scrape_id TEXT,
    last_scraped TEXT,
    source TEXT,
    name TEXT,
    description TEXT,
    neighborhood_overview TEXT,
    picture_url TEXT,
    host_id TEXT,
    host_url TEXT,
    host_profile_id TEXT,
    host_profile_url TEXT,
    host_name TEXT,
    host_since TEXT,
    hosts_time_as_user_years TEXT,
    hosts_time_as_user_months TEXT,
    hosts_time_as_host_years TEXT,
    hosts_time_as_host_months TEXT,
    host_location TEXT,
    host_about TEXT,
    host_response_time TEXT,
    host_response_rate TEXT,
    host_acceptance_rate TEXT,
    host_is_superhost TEXT,
    host_thumbnail_url TEXT,
    host_picture_url TEXT,
    host_neighbourhood TEXT,
    host_listings_count TEXT,
    host_total_listings_count TEXT,
    host_verifications TEXT,
    host_has_profile_pic TEXT,
    host_identity_verified TEXT,
    neighbourhood TEXT,
    neighbourhood_cleansed TEXT,
    neighbourhood_group_cleansed TEXT,
    latitude TEXT,
    longitude TEXT,
    property_type TEXT,
    room_type TEXT,
    accommodates TEXT,
    bathrooms TEXT,
    bathrooms_text TEXT,
    bedrooms TEXT,
    beds TEXT,
    amenities TEXT,
    price TEXT,
    price_quote_checkin_date TEXT,
    price_quote_checkout_date TEXT,
    price_quote_total_price TEXT,
    price_quote_price_per_night TEXT,
    price_quote_raw TEXT,
    minimum_nights TEXT,
    maximum_nights TEXT,
    minimum_minimum_nights TEXT,
    maximum_minimum_nights TEXT,
    minimum_maximum_nights TEXT,
    maximum_maximum_nights TEXT,
    minimum_nights_avg_ntm TEXT,
    maximum_nights_avg_ntm TEXT,
    calendar_updated TEXT,
    has_availability TEXT,
    availability_30 TEXT,
    availability_60 TEXT,
    availability_90 TEXT,
    availability_365 TEXT,
    calendar_last_scraped TEXT,
    number_of_reviews TEXT,
    number_of_reviews_ltm TEXT,
    number_of_reviews_l30d TEXT,
    availability_eoy TEXT,
    number_of_reviews_ly TEXT,
    estimated_occupancy_l365d TEXT,
    estimated_revenue_l365d TEXT,
    first_review TEXT,
    last_review TEXT,
    review_scores_rating TEXT,
    review_scores_accuracy TEXT,
    review_scores_cleanliness TEXT,
    review_scores_checkin TEXT,
    review_scores_communication TEXT,
    review_scores_location TEXT,
    review_scores_value TEXT,
    license TEXT,
    instant_bookable TEXT,
    calculated_host_listings_count TEXT,
    calculated_host_listings_count_entire_homes TEXT,
    calculated_host_listings_count_private_rooms TEXT,
    calculated_host_listings_count_shared_rooms TEXT,
    reviews_per_month TEXT);

load data infile 'D:/SQL/MY SQL WorkBench/Data/Uploads/listings.csv'
into table  listings_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
select count(*) from listings_raw;

CREATE table calendar_raw (
    listing_id TEXT,
    date TEXT,
    available TEXT,
    minimum_nights TEXT,
    maximum_nights TEXT
);
load data infile 'D:/SQL/MY SQL WorkBench/Data/Uploads/calendar.csv'
into table  calendar_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

create table reviews_raw (
    listing_id TEXT,
    id TEXT,
    date TEXT,
    reviewer_id TEXT,
    reviewer_name TEXT,
    comments TEXT
);
load data infile 'D:/SQL/MY SQL WorkBench/Data/Uploads/reviews.csv'
into table  reviews_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE neighbourhoods_raw (
    neighbourhood_group TEXT,
    neighbourhood TEXT
);

LOAD DATA INFILE 'D:/SQL/MY SQL WorkBench/Data/Uploads/neighbourhoods.csv'
INTO TABLE neighbourhoods_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT
    (SELECT COUNT(*) FROM listings_raw) AS listings,
    (SELECT COUNT(*) FROM calendar_raw) AS calendar,
    (SELECT COUNT(*) FROM reviews_raw) AS reviews,
    (SELECT COUNT(*) FROM neighbourhoods_raw) AS neighbourhoods;
    
--     we imported all the tables successfully and DDL part is over

-- let's optimise the table according to their colums type as currently all are in txt format (DML) part

DROP TABLE IF EXISTS listings;

CREATE TABLE listings AS
SELECT
    CAST(NULLIF(id, '') AS UNSIGNED) AS id,
    host_id,
    name,
    neighbourhood,
    neighbourhood_cleansed,
    neighbourhood_group_cleansed,
    room_type,
    property_type,
    CAST(NULLIF(accommodates, '') AS UNSIGNED) AS accommodates,
    CAST(NULLIF(REPLACE(price, '$', ''), '') AS DECIMAL(10,2)) AS price,
    CAST(NULLIF(minimum_nights, '') AS UNSIGNED) AS minimum_nights,
    CAST(NULLIF(maximum_nights, '') AS UNSIGNED) AS maximum_nights,
    host_is_superhost,
    CAST(NULLIF(review_scores_rating, '') AS DECIMAL(3,2)) AS review_scores_rating,
    CAST(NULLIF(review_scores_cleanliness, '') AS DECIMAL(3,2)) AS review_scores_cleanliness,
    CAST(NULLIF(number_of_reviews, '') AS UNSIGNED) AS number_of_reviews,
    CAST(NULLIF(number_of_reviews_ltm, '') AS UNSIGNED) AS number_of_reviews_ltm,
    CAST(NULLIF(availability_30, '') AS UNSIGNED) AS availability_30,
    CAST(NULLIF(availability_365, '') AS UNSIGNED) AS availability_365,
    CAST(NULLIF(estimated_occupancy_l365d, '') AS UNSIGNED) AS estimated_occupancy_l365d,
    CAST(NULLIF(estimated_revenue_l365d, '') AS DECIMAL(12,2)) AS estimated_revenue_l365d

FROM listings_raw;
SELECT
    COUNT(*) AS 'rows',
    COUNT(id) AS non_null_ids,
    COUNT(price) AS non_null_prices,
    COUNT(review_scores_rating) AS non_null_ratings
FROM listings;

-- calendar table
CREATE TABLE calendar AS
SELECT
    CAST(listing_id AS UNSIGNED) AS listing_id,
    STR_TO_DATE(date, '%Y-%m-%d') AS date,
    available,
    CAST(NULLIF(minimum_nights, '') AS UNSIGNED) AS minimum_nights,
    CAST(NULLIF(maximum_nights, '') AS UNSIGNED) AS maximum_nights
FROM calendar_raw;



-- reviews
create table reviews as 
select cast(listing_id as unsigned) as listing_id,CAST(NULLIF(id, '') AS UNSIGNED) AS id,
str_to_date(date,'%Y-%m-%d') as date, cast(nullif(reviewer_id, " ") as unsigned) as reviewer_id, nullif(reviewer_name, " ") as revierer_name,
nullif(comments, " ") as comments from reviews_raw;
create table neighbourhoods as 
select nullif(neighbourhood_group, " ") as neighbourhood_group,nullif(neighbourhood, " ") as neighbourhood from neighbourhoods_raw;

 select count(*) as r from reviews union all
 select count(*) as x from neighbourhoods;
 SELECT COUNT(*) AS calendar_rows
FROM calendar;
SELECT COUNT(*) AS listings_rows
FROM listings;

-- basically what we did above was give the table's columns their actual type as loading a big data set with the actual column type was
-- too much of a hassle  . Thats how we and our ddl and dml
