/*

Data Cleaning

Skills used: SUBSTRING,CHARINDEX, PARSENAME, ROWNUMBER, CTE, JOIN, CASE STATEMENT, DELETE

*/

--First, let's view the data we are working with
SELECT *
FROM dbo.NashvilleHousing

--Convert saledate formate to date instead of datetime

ALTER TABLE dbo.NashvilleHousing
ALTER COLUMN saledate date;


--Property address cleanup and updating nulls with the address
SELECT 
	*
FROM dbo.nashvillehousing
WHERE propertyaddress IS NULL
ORDER BY parcelid

SELECT 
	a.parcelid, 
	a.propertyaddress, 
	b.parcelid, 
	b.propertyaddress, 
	ISNULL(a.propertyaddress, b.propertyaddress) 
FROM dbo.nashvillehousing a
JOIN dbo.nashvillehousing b
	ON a.parcelid = b.parcelid
	AND a.[uniqueid ] <> b.[uniqueid ]
WHERE a.propertyaddress IS NULL
	
UPDATE A
SET propertyaddress = ISNULL(a.propertyaddress,b.propertyaddress)
FROM dbo.nashvillehousing a
JOIN dbo.nashvillehousing b
	ON a.parcelid = b.parcelid
	AND a.[uniqueid ] <> b.[uniqueid ]
WHERE a.propertyaddress IS NULL


--Separating address into address and city and owner address to address, city, state
SELECT propertyaddress
FROM dbo.nashvillehousing

--Using substring to remove things after the comma
SELECT SUBSTRING(propertyaddress, 1, CHARINDEX(',', propertyaddress) -1) as Address,
	SUBSTRING(propertyaddress, CHARINDEX(',', propertyaddress) +1, LEN(propertyaddress)) as City
FROM dbo.nashvillehousing


--Creating columns for the separated address and city
ALTER TABLE dbo.NashvilleHousing
ADD splitaddress nvarchar(255);

UPDATE dbo.nashvillehousing
SET splitaddress = SUBSTRING(propertyaddress, 1, CHARINDEX(',', propertyaddress) -1)


ALTER TABLE dbo.NashvilleHousing
ADD splitcity nvarchar(255);


UPDATE dbo.nashvillehousing
SET splitcity = SUBSTRING(propertyaddress, CHARINDEX(',', propertyaddress) +1, LEN(propertyaddress))


--Separating owner address to address, city, state
SELECT 
	PARSENAME(REPLACE(owneraddress, ',','.') ,3), --address
	PARSENAME(REPLACE(owneraddress, ',','.') ,2), --city
	PARSENAME(REPLACE(owneraddress, ',','.') ,1) --state
FROM dbo.nashvillehousing


--Create and update new owneraddressfields

ALTER TABLE dbo.NashvilleHousing
ADD ownersplitaddress nvarchar(255);

UPDATE dbo.nashvillehousing
SET ownersplitaddress = PARSENAME(REPLACE(owneraddress, ',','.') ,3)

ALTER TABLE dbo.NashvilleHousing
ADD ownersplitcity nvarchar(255);


UPDATE dbo.nashvillehousing
SET ownersplitcity = PARSENAME(REPLACE(owneraddress, ',','.') ,2)

ALTER TABLE dbo.NashvilleHousing
ADD ownersplitstate nvarchar(255);

UPDATE dbo.nashvillehousing
SET ownersplitstate = PARSENAME(REPLACE(owneraddress, ',','.') ,1)


--Viewing soldasvacant column and changing y/n to yes/no for uniformity.
SELECT DISTINCT(soldasvacant), COUNT(soldasvacant)
FROM dbo.nashvillehousing
GROUP BY soldasvacant
ORDER BY 2 DESC;



SELECT 
	soldasvacant,
	CASE WHEN soldasvacant = 'Y' THEN 'YES'
	WHEN soldasvacant = 'N' THEN 'NO'
	ELSE soldasvacant
	END
FROM dbo.nashvillehousing

UPDATE dbo.nashvillehousing
SET soldasvacant = 
	CASE WHEN soldasvacant = 'Y' THEN 'YES'
	WHEN soldasvacant = 'N' THEN 'NO'
	ELSE soldasvacant
	END


--Remove duplicates

WITH rownumcte AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY 
		parcelid,
		legalreference
	ORDER BY uniqueid) row_num

FROM dbo.nashvillehousing

)
DELETE
FROM rownumcte
WHERE row_num > 1 



--Removing unused columns

SELECT *
FROM dbo.nashvillehousing

ALTER TABLE dbo.nashvillehousing
DROP COLUMN owneraddress, taxdistrict, propertyaddress, saledate








