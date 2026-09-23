# Inside Airbnb NYC — SQL Analysis Project

A mini SQL practice project: load real Airbnb NYC data into MySQL, clean it, check it, ask 5 business questions, and verify the results. Results are visualized in Excel.

**Data source:** [insideairbnb.com](https://insideairbnb.com/get-the-data/) — New York City snapshot, 14 June 2026
**Tools:** MySQL, MySQL Workbench, Excel (pivot tables + charts)

---

## Workflow

```
01_ddl_dml.sql        → load & type the raw CSVs
02_data_quality.sql   → clean + validate
03_analysis.sql       → 5 business questions
04_verification.sql   → confirm the results hold up
```

| Table | Grain | Rows |
|---|---|---|
| `listings` | 1 row = 1 listing | 30,259 |
| `calendar` | 1 row = 1 listing × 1 date | 11,152,576 |
| `reviews` | 1 row = 1 review | 980,550 |
| `neighbourhoods` | 1 row = 1 neighbourhood | 230 |

---

## Data quality, in brief

- `listings.neighbourhood` was **100% null** → used `neighbourhood_cleansed` instead.
- `price` was missing on **~29%** of listings → every price query filters `where price is not null`.
- Calendar had **108,040 rows** for listings that don't exist in `listings` → kept, but joined carefully.
- Reviews had **9,618 orphan rows** (no matching listing) → removed during cleaning.

Biggest lesson: a query can be *correct* and still be *wrong* if you don't check the data first — and `calendar`/`reviews` are many-rows-per-listing, so joining them straight into `listings` without aggregating first inflates totals (fan-out).

---

## The 5 questions

1. How is inventory distributed across boroughs and room types?
2. How concentrated is the market among multi-listing hosts?
3. How does price vary by neighbourhood and room type?
4. Do superhosts price differently than non-superhosts?
5. How does availability move across the year vs. listed price?

Full tables + charts for all five are in **`Inside_Airbnb_NYC_Phase3_Analysis.xlsx`** (one sheet per question). Below is what they actually mean.

---

## Findings

**1. Manhattan isn't just bigger — it's a different kind of market.**
~30% of all listings, and two-thirds of those are entire homes, not rooms. The outer boroughs skew the opposite way (more private rooms than entire homes). Hotel-room listings barely exist outside Manhattan and Queens.

**2. 19% of hosts control 56% of listings.**
A small slice of "power hosts" running multiple properties account for over half the market — this isn't mostly individuals renting a spare room.

**3. Price gaps between boroughs are really an entire-home story.**
Manhattan entire-homes price roughly 2× Bronx entire-homes. Private rooms barely show this gap — a Manhattan private room and a Queens private room aren't that far apart.

**4. Superhost status barely affects entire-home price, but it does for rooms.**
Entire homes: superhost vs. non ≈ same price. Private rooms: superhosts charge ~$16 more. Shared rooms: ~$49 more. Trust seems to matter more when you're sharing a home with the host.

**5. Availability is seasonal. Price, in this data, can't be.**
Availability drops hardest in June–July (peak bookings) and recovers by November — a real pattern. The "flat" price across months isn't a finding — `calendar` has no daily price field, so it's just the same static listing price repeated 12 times. Worth knowing as a data limit, not a market insight.

---

## Verification

```
listings = 30,259   calendar = 11,152,576   reviews = 980,550   neighbourhoods = 230

duplicate listing ids       = 0
duplicate listing-date rows = 0
orphan calendar rows        = 108,040 (296 listing ids — expected, documented)
orphan review rows          = removed during cleaning
invalid price / rating / accommodates = 0
```

---

## Limitations

- No daily prices in `calendar` → seasonal price analysis isn't possible with this dataset.
- ~29% of listings had no price → excluded from price-based queries.
- Practice project, not a production market study — describes one dataset snapshot, not current NYC conditions.

---

## What I learned

Table grain, avoiding join fan-out, `load data infile`, handling missing/duplicate/orphan data, `case`, CTEs, window functions for percentages, and validating results after the fact.

> Before writing a query: know what one row in each table actually means. Everything else gets easier after that.

---

## Structure

```
Inside-Airbnb-NYC-SQL/
├── 01_ddl_dml.sql
├── 02_data_quality.sql
├── 03_analysis.sql
├── 04_verification.sql
├── Inside_Airbnb_NYC_Phase3_Analysis.xlsx
└── README.md
```
