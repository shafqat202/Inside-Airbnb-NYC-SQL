select database();
-- Q1  we are looking at how the listings are distributed across boroughs and room types, along with guest capacity.
select
    neighbourhood_group_cleansed AS borough,
    room_type,
    COUNT(*) AS listing_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (PARTITION BY neighbourhood_group_cleansed),
        2
    ) AS pct_of_borough_inventory,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_total_inventory,

    SUM(accommodates) AS total_capacity,
    ROUND(AVG(accommodates), 2) AS avg_capacity

FROM listings
GROUP BY
    neighbourhood_group_cleansed,
    room_type
ORDER BY
    borough,
    listing_count desc;
    
    -- Q2 we are checking how many hosts manage one listing compared with hosts managing multiple listings.
    
    with host_portfolios AS (
    select
        host_id,
        COUNT(*) AS listing_count
    from listings
    GROUP BY host_id
)
select
    CASE
        WHEN listing_count = 1 THEN 'Single-property host'
        ELSE 'Multi-property host'
    END AS host_type,
    COUNT(*) AS host_count,
    SUM(listing_count) AS listing_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_hosts,
    ROUND(
        100.0 * SUM(listing_count) / SUM(SUM(listing_count)) OVER (),
        2
    ) AS pct_of_listings
FROM host_portfolios
GROUP BY
    CASE
        WHEN listing_count = 1 THEN 'Single-property host'
        ELSE 'Multi-property host'
    END
ORDER BY
    host_type; 
    
    -- Q3 we are comparing listed prices across neighbourhoods and room types to see how prices vary by location.
    select
    neighbourhood_group_cleansed as borough,
    neighbourhood_cleansed as neighbourhood,
    room_type,
    count(*) as priced_listing_count,
    round(avg(price), 2) as avg_price,
    min(price) as min_price,
    max(price) as max_price
from listings
where price is not null
group by
    neighbourhood_group_cleansed,
    neighbourhood_cleansed,
    room_type
order by
    room_type,
    borough,
    avg_price desc;
    
-- Q4 we are comparing the listed prices of superhosts and non-superhosts across different room types.
select
    room_type,
    case
        when host_is_superhost = 't' then 'superhost'
        when host_is_superhost = 'f' then 'non-superhost'
    end as host_status,
    count(*) as priced_listing_count,
    round(avg(price), 2) as avg_price,
    round(min(price), 2) as min_price,
    round(max(price), 2) as max_price
from listings
where price is not null
  and host_is_superhost in ('t', 'f')
group by
    room_type,
    case
        when host_is_superhost = 't' then 'superhost'
        when host_is_superhost = 'f' then 'non-superhost'
    end
order by
    room_type,
    host_status;

-- Q5 we are checking how availability and listed price change across the year by room type.
select
    month(c.date) as month_number,
    monthname(c.date) as month_name,
    l.room_type,
    count(*) as calendar_rows,
    round(
        100.0 * sum(case when c.available = 't' then 1 else 0 end) / count(*),
        2
    ) as availability_pct,
    round(avg(l.price), 2) as avg_listed_price
from calendar c
inner join listings l
    on c.listing_id = l.id
where l.price is not null
group by
    month(c.date),
    monthname(c.date),
    l.room_type
order by
    month_number,
    l.room_type;
    -- c here we end our analysis part  next and final part is verification which will be in verification.sql 