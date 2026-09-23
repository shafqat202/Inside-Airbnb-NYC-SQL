-- we are checking that the main cleaned tables still contain the expected number of rows.
select
    (select count(*) from listings) as listings_rows,
    (select count(*) from calendar) as calendar_rows,
    (select count(*) from reviews) as reviews_rows,
    (select count(*) from neighbourhoods) as neighbourhoods_rows; -- update they contain each raws as begining just the orphan raws from reviews and calendar cancelled out

-- we are checking that each listing has a unique id and no duplicate listing records exist.
select
    count(*) as total_rows,
    count(distinct id) as unique_listing_ids,
    count(*) - count(distinct id) as duplicate_rows
from listings; -- no duplicates 

-- we are checking that every review is linked to a listing that exists in the listings table.
select
    count(*) as orphan_review_rows
from reviews r
left join listings l
    on r.listing_id = l.id
where l.id is null; 

-- we are checking that the calendar still contains the expected orphan records that are not in listings.
select
    count(*) as orphan_calendar_rows,
    count(distinct c.listing_id) as orphan_calendar_listings
from calendar c
left join listings l
    on c.listing_id = l.id
where l.id is null;

-- we are checking that every neighbourhood used by a listing exists in the neighbourhoods table.
select
    count(distinct l.neighbourhood_cleansed) as listing_neighbourhoods,
    count(distinct n.neighbourhood) as matched_neighbourhoods
from listings l
left join neighbourhoods n
    on l.neighbourhood_cleansed = n.neighbourhood;
    
-- we are checking that the calendar has no duplicate listing and date combinations.
select
    count(*) as total_rows,
    count(distinct concat(listing_id, '-', date)) as unique_listing_dates,
    count(*) - count(distinct concat(listing_id, '-', date)) as duplicate_rows
from calendar;

-- we are checking that important numeric fields do not contain impossible values.
select
    sum(case when accommodates <= 0 then 1 else 0 end) as invalid_accommodates,
    sum(case when price < 0 then 1 else 0 end) as invalid_price,
    sum(case when review_scores_rating < 0 or review_scores_rating > 5 then 1 else 0 end) as invalid_rating
from listings;