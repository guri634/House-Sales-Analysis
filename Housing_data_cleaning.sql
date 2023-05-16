-- View the columns of data 
show columns from housedata;

-- See a sample of our data
select *
from housedata
limit 10;

-- Check if propertyaddress is null
select *
from housedata
where propertyaddress is null
order by parcelid; 

-- See the values with which we are replacing null values of propertyaddress column
select a.uniqueid, a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, ifnull(a.propertyaddress, b.propertyaddress) as replaced_null
from housedata a
join housedata b
	on a.parcelid = b.parcelid
    and a.uniqueid <> b.uniqueid
where a.propertyaddress is null;

-- Replace the null values of propertyaddress column based on parcel id
-- Because same parcel ids have same address
update housedata a
join housedata b
	on a.parcelid = b.parcelid
    and a.uniqueid <> b.uniqueid
set a.propertyaddress  = ifnull(a.propertyaddress, b.propertyaddress)
where a.propertyaddress is null;


-- Breaking out Property Address into Individual Columns (Address, City, State)
select propertyaddress 
from housedata;

select
substr(propertyaddress, 1, locate(';', propertyaddress)-1) as address,
substr(propertyaddress, locate(';', propertyaddress)+1) as state
from housedata;

alter table housedata
add propertysplitaddress varchar(255);

update housedata
set propertysplitaddress = substr(propertyaddress, 1, locate(';', propertyaddress)-1);

alter table housedata
add propertysplitcity varchar(255);

update housedata
set propertysplitcity = substr(propertyaddress, locate(';', propertyaddress)+1);

select *
from housedata
limit 10;



-- Breaking out Owner Address into Individual Columns (Address, City, State)

select OwnerAddress,
substring_index(owneraddress, ';', 1) ownersplitaddress,
substring_index(substring_index(owneraddress, ';', 2), ';', -1) ownersplitcity,
substring_index(owneraddress, ';', -1) ownersplitstate
from housedata;

alter table housedata
add ownersplitaddress varchar(100),
add ownersplitcity varchar(100),
add ownersplitstate varchar(100);

update housedata
set ownersplitaddress = substring_index(owneraddress, ';', 1);

update housedata
set ownersplitcity = substring_index(substring_index(owneraddress, ';', 2), ';', -1);

update housedata
set ownersplitstate = substring_index(owneraddress, ';', -1);

select *
from housedata
limit 10;

-- Change Y and N to Yes and No in "SoldAsVacant" column
select SoldAsVacant, count(SoldAsVacant)
from housedata
group by SoldAsVacant
order by 2;


update housedata
set SoldAsVacant = 
	case
		when SoldAsVacant = 'Y' then 'Yes'
        when SoldAsVacant = 'N' then 'No'
        else SoldAsVacant
	end;
    
select SoldAsVacant, count(SoldAsVacant)
from housedata
group by SoldAsVacant
order by 2;

-- Remove Duplicates
-- Usually one should not delete the duplicates from original table
-- so we will create a new table without duplicate values

with RowNumCTE as(
select *,
	row_number() over (
    partition by ParcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 order by 
					UniqueID
                    ) row_num
from housedata
)
select *
from RowNumCTE
where row_num > 1
order by PropertyAddress;

create table housedataupdated like housedata;

INSERT INTO housedataupdated
	with RowNumCTE as(
	select *,
		row_number() over (
		partition by ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 order by 
						UniqueID
						) row_num
	from housedata
	)
	select UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, LegalReference,
		   SoldAsVacant, OwnerName, OwnerAddress, Acreage, TaxDistrict, LandValue, BuildingValue,
		   TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath, propertysplitaddress, propertysplitcity,
		   ownersplitaddress, ownersplitcity, ownersplitstate
	from RowNumCTE
	where row_num = 1;
    
select * 
from housedataupdated;

drop table housedata;

rename table housedataupdated to housedata;

-- Delete Unused Columns

alter table housedata
drop column PropertyAddress,
drop column OwnerAddress,
drop column TaxDistrict;

select * from housedata;