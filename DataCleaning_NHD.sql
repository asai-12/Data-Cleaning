use new_schema;
-- standardise Data format 

select SaleDate from NHD;
update NHD SET SaleDate = Convert(Date, SaleDate)

-- populate property address data-- when i imported the data i didnt chnage the emptry strings to null, hence its just empty now (cant use ifnull cus no null value)-- self join

SELECT a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress, CASE WHEN a.propertyAddress ='' THEN b.propertyAddress END as NEWP
From NHD AS a Join NHD as b 
on a.ParcelID = b.ParcelID 
AND a.ID <> b.ID
WHERE a.PropertyAddress = '';

UPDATE NHD AS a
JOIN NHD AS b ON a.ParcelID = b.ParcelID AND a.ID <> b.ID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress = '' AND b.PropertyAddress <> '';

-- since parcelid doesnt change for address, checks for other parcelid to populate missing address where the uniqueid isnt the same to remove duplicates

-- breaking up address into individual columns(Address, city ,state)


SELECT PropertyAddress, SUBSTRING(PropertyAddress,1, POSITION("," IN PropertyAddress) -1) AS PAddress, 
SUBSTRING(PropertyAddress, POSITION("," IN PropertyAddress) +1) AS PCity 
FROM NHD; 

ALTER TABLE  NHD
ADD PropertynewAddress VARCHAR(255);

UPDATE NHD 
SET PropertynewAddress = SUBSTRING(PropertyAddress,1, POSITION("," IN PropertyAddress) -1)

ALTER TABLE  NHD
ADD PropertynewCity VARCHAR(255);

UPDATE NHD 
SET PropertynewCity = SUBSTRING(PropertyAddress, POSITION("," IN PropertyAddress) +1)

SELECT OwnerAddress, 
SUBSTRING_INDEX(OwnerAddress, ',',1) as OwnernewAddress,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',2),',',-1) as OwnernewCity,
SUBSTRING_INDEX(OwnerAddress, ',',-1) as OwnernewState
FROM NHD; 

ALTER TABLE NHD 
ADD COLUMN OwnernewAddress VARCHAR(255), 
ADD COLUMN OwnernewCity VARCHAR(255), 
ADD COLUMN OwnernewState VARCHAR(255);

UPDATE NHD
SET OwnernewAddress = SUBSTRING_INDEX(OwnerAddress, ',',1),
OwnernewCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',',2),',',-1),
OwnernewState = SUBSTRING_INDEX(OwnerAddress, ',',-1); 

-- change Y and N to Yes and NO in 'Sold As Vacant' field


SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NHD
group by SoldAsVacant 
order by 2;

SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM NHD	

UPDATE NHD 
Set SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END


-- Remove Duplicates (not standard practice to delete duplicate, rather create a temp table without the duplicates)
-- finding duplicates using cte. In mysql cant directly delete from cte table, use subquery instead
with cte as (
	 SELECT *, ROW_NUMBER() over (PARTITION by  ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	 order by ID ) as rownum
	 FROM NHD) 
	 SELECT * FROM cte 
	 WHERE rownum >1
	
	-- MYSQL VERSION ( i joined the main table with my subquery and deleted where rownum =2 or more in the both tables.)
DELETE NHD
FROM NHD
JOIN (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                                  ORDER BY ID) AS rownum
    FROM NHD
) AS Sub
ON NHD.ID = Sub.ID
WHERE Sub.rownum > 1;



-- DELETE UNUSED COLUMNS (BEST PRACTICE IS NOT TO DO THIS TO RAW DATA, you'll lose data)

SELECT * FROM NHD;

ALTER TABLE NHD 
DROP COLUMN PropertyAddress,
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict 