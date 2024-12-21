--Altering Table names
ALTER TABLE housing_dat_cleaning RENAME TO data_cleaning;

ALTER TABLE data_cleaning
RENAME COLUMN HalfBath TO half_bath;

--Changing date to standard format
SELECT sale_date
FROM data_cleaning;

UPDATE data_cleaning
SET sale_date = CAST(sale_date AS DATE);

ALTER TABLE data_cleaning
ADD sale_date_standard DATE;

UPDATE data_cleaning
SET sale_date_standard = CAST(sale_date AS DATE);

SELECT sale_date, sale_date_standard
FROM data_cleaning;

--Inserting data to property address data
SELECT *
FROM data_cleaning
ORDER BY parcel_id;

SELECT DISTINCT tab_1.unique_id, tab_1.parcel_id, tab_1.property_address, tab_2.parcel_id, tab_2.property_address
FROM data_cleaning tab_1
JOIN data_cleaning tab_2
    ON tab_1.unique_id <> tab_2.unique_id AND tab_1.parcel_id = tab_2.parcel_id 
WHERE tab_1.property_address IS NULL;

UPDATE data_cleaning 
SET property_address = (
    WITH cte_find_null_property_address AS
        (
            SELECT DISTINCT tab_1.unique_id AS tab_1_unique_id, 
                   tab_1.parcel_id AS tab_1_parcel_id,
                   tab_2.parcel_id AS tab_2_parcel_id
            FROM data_cleaning tab_1
            JOIN data_cleaning tab_2
                ON tab_1.unique_id <> tab_2.unique_id 
                AND tab_1.parcel_id = tab_2.parcel_id
            WHERE tab_1.property_address IS NULL
        )
    SELECT DISTINCT dc.property_address
    FROM data_cleaning dc
    JOIN cte_find_null_property_address cte
        ON cte.tab_2_parcel_id = dc.parcel_id 
        AND dc.property_address <> '2524 VAL MARIE  DR, MADISON'
    WHERE dc.property_address IS NOT NULL
    FETCH FIRST 1 ROWS ONLY --fetch only one at a time
)
WHERE property_address IS NULL;

--Separating the address into individual columns(atomicity) (Using Substring)
SELECT property_address
FROM data_cleaning;

SELECT SUBSTR(property_address, 1, INSTR(property_address, ',') - 1) AS first_address, --Before the comma happens
       SUBSTR(property_address, INSTR(property_address, ',') + 2, LENGTH(property_address)) AS second_address --After the comma happens
FROM data_cleaning;

ALTER TABLE data_cleaning
ADD property_split_address NVARCHAR2(50);

UPDATE data_cleaning
SET property_split_address = SUBSTR(property_address, 1, INSTR(property_address, ',') - 1);

ALTER TABLE data_cleaning
ADD property_split_city NVARCHAR2(50);

UPDATE data_cleaning
SET property_split_city = SUBSTR(property_address, INSTR(property_address, ',') + 2, LENGTH(property_address)) ;

--Separating the address into individual columns(atomicity) (Using Parsing)
SELECT * FROM data_cleaning;

SELECT REGEXP_SUBSTR(REPLACE(owner_address, ',', '.'), '[^\.]+', 1, 1) AS first_address,
       REGEXP_SUBSTR(REPLACE(owner_address, ',', '.'), '[^\.]+', 1, 2) AS second_address,
       REGEXP_SUBSTR(REPLACE(owner_address, ',', '.'), '[^\.]+', 1, 3) AS third_address
FROM data_cleaning;

ALTER TABLE data_cleaning
ADD owner_split_address NVARCHAR2(50);

UPDATE data_cleaning
SET owner_split_address = REGEXP_SUBSTR(REPLACE(owner_address, ',', '.'), '[^\.]+', 1, 1);

ALTER TABLE data_cleaning
ADD owner_split_city NVARCHAR2(50);

UPDATE data_cleaning
SET owner_split_city = REGEXP_SUBSTR(REPLACE(owner_address, ',', '.'), '[^\.]+', 1, 2);

ALTER TABLE data_cleaning
ADD owner_split_state NVARCHAR2(50);

UPDATE data_cleaning
SET owner_split_state = REGEXP_SUBSTR(REPLACE(owner_address, ',', '.'), '[^\.]+', 1, 3);

--Changing Y or N to Yes or No in sold_as_vacant column using CASE statement
SELECT sold_as_vacant, COUNT(sold_as_vacant)
FROM data_cleaning
GROUP BY sold_as_vacant
ORDER BY sold_as_vacant;
 
SELECT sold_as_vacant,
CASE 
    WHEN sold_as_vacant = 'Y' THEN 'Yes'
    WHEN sold_as_vacant = 'N' THEN 'No'
    ELSE sold_as_vacant
END
FROM data_cleaning;

UPDATE data_cleaning
SET sold_as_vacant =
CASE 
    WHEN sold_as_vacant = 'Y' THEN 'Yes'
    WHEN sold_as_vacant = 'N' THEN 'No'
    ELSE sold_as_vacant
END;

SELECT sold_as_vacant, COUNT(sold_as_vacant)
FROM data_cleaning
GROUP BY sold_as_vacant;

--Removing duplicates(Caution: only do these when necessary)
DELETE FROM data_cleaning
WHERE ROWID IN ( --ROWID stores reference for the rows in the table like a pointer
    SELECT rid
    FROM (
        SELECT ROWID AS rid,
               ROW_NUMBER() OVER (
                   PARTITION BY parcel_ID, property_address, sale_price, sale_date, legal_reference
                   ORDER BY unique_ID
               ) AS row_num
        FROM data_cleaning
    )
    WHERE row_num > 1
);

--Removing unused tables(Caution: only do these when necessary) MOST COMMON IN VIEWS
SELECT * 
FROM data_cleaning;

ALTER TABLE data_cleaning
DROP COLUMN owner_address;

ALTER TABLE data_cleaning
DROP COLUMN tax_district;

ALTER TABLE data_cleaning
DROP COLUMN property_address;

ALTER TABLE data_cleaning
DROP COLUMN sale_date;










