--Cleaning Data in SQL Queries

SELECT *
FROM NashvilleHousing

--Standardize Date Format
ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate Date

SELECT SaleDate
FROM NashvilleHousing

--Populate Property Address Data
--Step #1 (Search for potential null data)
SELECT *
FROM NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

--Step #2 (Make sure the query is right and works)
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousing AS A
JOIN NashvilleHousing AS B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

--Step #3 (Update the original table with the tested query)
UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousing AS A
JOIN NashvilleHousing AS B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

--Step #4 (Make sure the previously null data have been updated)
SELECT *
FROM NashvilleHousing

--Breaking out address into individual columns (Address, City, State)
--PropertyAddress
--Step #1 (Look at the data that needs to separated into multiple columns)
SELECT PropertyAddress
FROM NashvilleHousing

--Step #2 (Make sure the query is right and works)
SELECT
--Substring parameters consist of string source, where to start, and where to stop
--CHARINDEX helps to find specific character in a string
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS PropertySplitAddress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS PropertySplitCity
--The -1 and +1 after the CHARINDEX moves the cursor of substring
FROM NashvilleHousing

--Step #3 (Create new columns for splitted data)
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255),
	PropertySplitCity nvarchar(255)

--Step #4 (Update the recently added columns with previously tested queries to insert the splitted data)
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

--Step #5 (Make sure the data have been updated)
SELECT PropertySplitAddress, PropertySplitCity
FROM NashvilleHousing

--OwnerAddress
--Step #1 (Look at the data that needs to separated into multiple columns)
SELECT OwnerAddress
FROM NashvilleHousing

--Step #2 (Make sure the query is right and works)
SELECT
--PARSENAME automatically seperates strings that contain '.' character into multiple columns
--In this case, the data has ',' character as a separator, so we need to replace it first with REPLACE method
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
--PARSENAME separates the data into columns backwards
--If there are 3 separated columns, that the number should start from 3 to 1
FROM NashvilleHousing

--Step #3 (Create new columns for splitted data)
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255),
	OwnerSplitCity nvarchar(255),
	OwnerSplitState nvarchar(255)

--Step #4 (Update the recently added columns with previously tested queries to insert the splitted data)
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--Step #5 (Make sure the data have been updated)
SELECT *
FROM NashvilleHousing

--Change Y and N to Yes and No in "Sold as Vacant" field
--Step #1 (Look at the data that needs to be changed)
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Step #2 (Make sure the query is right and works)
SELECT SoldAsVacant,
--CASE for conditional request
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleHousing

--Step #3 (Update the data using the tested query)
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

--Step #4 (Make sure the data has been updated)
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Remove Duplicates
--Step #1 (Create SELECT and PARTITION BY statement first
--If the row_nums came out right, cast it with CTE to make conditional requests
WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID
) AS row_num
FROM NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY [UniqueID ]

--Step #2 (Remove the duplicates)
WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID
) AS row_num
FROM NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--Step #3 (Run the step #1 again to make sure the duplicates have been removed)

--Delete Unused Columns
ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

SELECT *
FROM NashvilleHousing