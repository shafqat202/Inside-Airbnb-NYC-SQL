-- lets clean the data base before analysig
DESCRIBE listings;
-- finding null values for listing tables 
SELECT
    SUM(id IS NULL) AS id_null,
    SUM(host_id IS NULL OR TRIM(host_id) = '') AS host_id_missing,
    SUM(neighbourhood IS NULL OR TRIM(neighbourhood) = '') AS neighbourhood_missing,
    SUM(room_type IS NULL OR TRIM(room_type) = '') AS room_type_missing,
    SUM(property_type IS NULL OR TRIM(property_type) = '') AS property_type_missing,
    SUM(accommodates IS NULL) AS accommodates_null,
    SUM(price IS NULL) AS price_null,
    SUM(minimum_nights IS NULL) AS minimum_nights_null,
    SUM(maximum_nights IS NULL) AS maximum_nights_null,
    SUM(host_is_superhost IS NULL OR TRIM(host_is_superhost) = '') AS superhost_missing,
    SUM(review_scores_rating IS NULL) AS rating_null,
    SUM(review_scores_cleanliness IS NULL) AS cleanliness_null,
    SUM(number_of_reviews IS NULL) AS reviews_null,
    SUM(estimated_revenue_l365d IS NULL) AS revenue_null
FROM listings;

 -- price & estimated_revenue: 8,744 missing (28.90%)
-- review_scores_rating & cleanliness: 8,559 missing (28.29%)
-- host_is_superhost: 349 blank (1.15%)


-- and there was null only at neighbourhood column so we are willing to find if 
-- there exist actual neighbourhood values in the table or not

SELECT
    COUNT(*) AS total_rows,
    SUM(neighbourhood_cleansed IS NULL OR TRIM(neighbourhood_cleansed) = '') AS neighbourhood_cleansed_missing,
    COUNT(DISTINCT neighbourhood_cleansed) AS neighbourhood_count,
    SUM(neighbourhood_group_cleansed IS NULL OR TRIM(neighbourhood_group_cleansed) = '') AS neighbourhood_group_missing,
    COUNT(DISTINCT neighbourhood_group_cleansed) AS neighbourhood_group_count
FROM listings;
-- 223 distinct cleansed neighbourhoods
-- 5 distinct boroughs/groups
-- so we will replace the 100% missing neighbourhood column with neighbourhood_cleansed for all spatial analysis

-- now lets check if room types host status and neighbourhood_cleansed are clean enough for analysis 
SELECT 'room_type' AS column_name, room_type AS value, COUNT(*) AS 'rows'
FROM listings
GROUP BY room_type

UNION ALL

SELECT 'host_is_superhost', host_is_superhost, COUNT(*)
FROM listings
GROUP BY host_is_superhost

UNION ALL

SELECT 'neighbourhood_group_cleansed', neighbourhood_group_cleansed, COUNT(*)
FROM listings
GROUP BY neighbourhood_group_cleansed
ORDER BY column_name, 'rows' DESC;
-- Confirmed domain consistency across categorical dimensions without unexpected text variants.

-- lets check invalied values for rest of the columans which are numeric
SELECT
    SUM(price < 0) AS negative_price,
    SUM(price = 0) AS zero_price,
    SUM(accommodates <= 0) AS invalid_accommodates,
    SUM(minimum_nights <= 0) AS invalid_min_nights,
    SUM(maximum_nights <= 0) AS invalid_max_nights,
    SUM(minimum_nights > maximum_nights) AS min_gt_max,
    SUM(review_scores_rating < 0 OR review_scores_rating > 5) AS invalid_rating,
    SUM(review_scores_cleanliness < 0 OR review_scores_cleanliness > 5) AS invalid_cleanliness,
    SUM(availability_30 < 0 OR availability_30 > 30) AS invalid_availability_30,
    SUM(availability_365 < 0 OR availability_365 > 365) AS invalid_availability_365,
    SUM(estimated_occupancy_l365d < 0 OR estimated_occupancy_l365d > 365) AS invalid_occupancy,
    SUM(estimated_revenue_l365d < 0) AS negative_revenue
FROM listings;
-- Validated that all non-null numeric attributes obey business logic constraints.

-- now its time to check calendar table's integrity
SELECT
    COUNT(*) AS total_rows,
    SUM(listing_id IS NULL) AS listing_id_null,
    SUM(date IS NULL) AS date_null,
    SUM(available IS NULL OR TRIM(available) = '') AS available_missing,
    COUNT(DISTINCT listing_id) AS distinct_listings,
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date
FROM calendar;

-- 296 orphan listing IDs found, accounting for 108,040 calendar rows (0.97% of the 11,152,576 total rows) lets varify again

select count(*) as orphan_raws, count(distinct c.listing_id) as orphan_listing_id from calendar as c 
left join listings as l on c.listing_id=l.id where l.id is null;
-- cheeck same for review and we are doing this because listings is our main table for analysis
select count(*) as orphan_review_rows,count(distinct r.listing_id) as orphan_listing_ids from reviews as r left join listings as l 
on r.listing_id=l.id where l.id is null;

-- as I see less then 1% of orphan raw in calendar and 
-- reviews (239 orphan listing IDs found, accounting for 9,618 review rows (0.97% of 990,168 total reviews)
--  table so we delete them for a clean analysis
-- and as it is less than 10% so no analytical error will happen statistically

delete c from calendar c left join listings as l on  c.listing_id=l.id where l.id is null;

set sql_safe_updates=0; -- safe updates was preventing from deletation of mass amount of raws

delete r from reviews r left join listings as l 
on r.listing_id=l.id where l.id is null;

-- a new problems occur here as I converted tables after importation and didnt assign
-- primary key or foreign key so deleting raws with joining from listings were taking times more than 15 min
-- so i assign index below for ease

ALTER TABLE listings
ADD INDEX idx_listings_id (id);
select count(*) from reviews;
delete r from reviews as r left join listings as l on r.listing_id=l.id where l.id is null; -- now this works

SELECT 
    l.neighbourhood_cleansed,
    COUNT(*) AS listing_count
FROM listings l
LEFT JOIN neighbourhoods n
    ON l.neighbourhood_cleansed = n.neighbourhood
WHERE n.neighbourhood IS NULL
GROUP BY l.neighbourhood_cleansed; -- here i checked if neighbourhood_cleansed has any null values or not and no problem was found

SELECT
    COUNT(*) AS total_reviews,
    SUM(date IS NULL) AS null_dates,
    MIN(date) AS earliest_review,
    MAX(date) AS latest_review
FROM reviews; -- Confirmed review timestamps are continuous, correctly formatted, and free of null values.   

select count(*) as invalid_date from reviews where date is null;

select count(*) as unmatched_neighbourhood from (select distinct neighbourhood_cleansed from listings) as l 
left join neighbourhoods n on l.neighbourhood_cleansed=n.neighbourhood where n.neighbourhood is null;

-- listings.neighbourhood was 100% null
-- listings.neighbourhood_cleansed is 100% populated with 223 distinct neighbourhoods
-- these perfectly map to the neighbourhoods reference table


-- here the table inspection journey ends and now we move to final analysis