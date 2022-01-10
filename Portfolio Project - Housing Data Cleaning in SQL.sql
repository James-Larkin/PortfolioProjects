-- Cleaning Data with SQL Queries
SELECT * FROM PortfolioProject..NashvilleHousing;

-------------------------------------------------------------------

--1.	Standardising the Date Format 
SELECT SaleDate
FROM PortfolioProject..NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

SELECT SaleDate, SaleDateConverted 
FROM PortfolioProject..NashvilleHousing;

-------------------------------------------------------------------

--2.	Populate Property Address Data
-- if PropertyAddress IS NULL, the value will be filled by matching ParcelID

-- Finding the blank PropertyAddresses and the duplicates which will populate the blanks
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Updating blank addresses with Addresses found above 
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID

-------------------------------------------------------------------

--3. Breaking PropertyAddress into Columns (Address, City)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

-- Making New Columns and Adding Split Address & City in
ALTER TABLE PortfolioProject..NashvilleHousing
ADD Address_Split nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET Address_Split = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD City_Split nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
SET City_Split = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));

SELECT * FROM PortfolioProject..NashvilleHousing

-------------------------------------------------------------------

--4. Breaking PropertyAddress into Multiple Columns (Address, City, State)
SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.'), 3) AS HouseAddress,
PARSENAME(REPLACE(OwnerAddress, ',','.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',','.'), 1) AS State
FROM PortfolioProject..NashvilleHousing

-- Making New Columns and Adding Parsed Address & City in
ALTER TABLE PortfolioProject..NashvilleHousing
ADD Owner_Address_Split nvarchar(255);
UPDATE PortfolioProject..NashvilleHousing
SET Owner_Address_Split = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD Owner_City_Split nvarchar(255);
UPDATE PortfolioProject..NashvilleHousing
SET Owner_City_Split = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD Owner_State_Split nvarchar(255);
UPDATE PortfolioProject..NashvilleHousing
SET Owner_State_Split = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1);

SELECT Owner_Address_Split, Owner_City_Split, Owner_State_Split
FROM PortfolioProject..NashvilleHousing

-------------------------------------------------------------------

--5. Changing Y and N to Yes and No in "Sold as Vacant" Field
-- Checking Fields
SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
Order BY 2;

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END;

-------------------------------------------------------------------

--6. Removing Duplicates
WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) row_num
				
FROM PortfolioProject..NashvilleHousing
)

DELETE FROM RowNumCTE
WHERE row_num > 1

-------------------------------------------------------------------

--7. Deleting Unused Columns
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


SELECT * FROM PortfolioProject..NashvilleHousing
