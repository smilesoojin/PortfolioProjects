-- Portfolio Project 2

-- Data Cleaning in SQL with Housing Data
-- Data from https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx
-- Data table saved as NashvilleHousing


-- Quick look at our data
SELECT *
FROM PortfolioProject1.dbo.NashvilleHousing


-- 1. Standardize Date Format
SELECT SaleDateConverted, CONVERT(DATE, SaleDate)
FROM PortfolioProject1.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)


-- 2. Populate Property Address Data
SELECT *
FROM PortfolioProject1.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- Two rows with same ParcelID but missing address on one of the rows
-- ISNULL(x,y): checks if x is NULL and if it is, replace with y
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject1.dbo.NashvilleHousing AS a
JOIN PortfolioProject1.dbo.NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject1.dbo.NashvilleHousing AS a
JOIN PortfolioProject1.dbo.NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


-- 3. Breaking out Address into Individual Columns (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject1.dbo.NashvilleHousing

-- SUBSTRING(string to look at, where to start, where to end)
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Street,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject1.dbo.NashvilleHousing

-- Add Street Address into a new column
ALTER TABLE NashvilleHousing
ADD PropertyStreet NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

-- Add City into a new column
ALTER TABLE NashvilleHousing
ADD PropertyCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- Check update
SELECT *
FROM PortfolioProject1.dbo.NashvilleHousing

-- Repeat for Owner Address (Street, City & State)
SELECT OwnerAddress
FROM PortfolioProject1.dbo.NashvilleHousing

-- PARSENAME parses using periods, gets substrings backwards
-- REPLACE(string, what to replace, what to replace it to)
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject1.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerStreet NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD OwnerCity NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD OwnerState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM PortfolioProject1.dbo.NashvilleHousing


-- 4. Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject1.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2						-- Yes & No more popular than Y & N

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
END
FROM PortfolioProject1.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
				   END


-- 5. Remove Duplicates (not common practice but good to know how to do it)
WITH RowNumCTE AS(
	SELECT *,
		   ROW_NUMBER() OVER (
						PARTITION BY ParcelID,
									 PropertyAddress,
									 SalePrice,
									 SaleDate,
									 LegalReference
						ORDER BY UniqueID ) AS row_num
	FROM PortfolioProject1.dbo.NashvilleHousing
)
DELETE
--SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress


-- 6. Remove Unused Columns (useful when displaying finalized clean data; don't do this on raw data)
SELECT *
FROM PortfolioProject1.dbo.NashvilleHousing

ALTER TABLE PortfolioProject1.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

