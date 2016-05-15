-- Determines the distance between an employee's address and primary Store in miles using geocodes

WITH Employee AS (
SELECT
 EmployeeKey
, HomeStore_DimOrganizationStructureStoreKey
, Longitude
, Latitude
FROM FlightRisk
  JOIN Employee ON FlightRisk.EmployeeKey = Employee.DimOperationalStructureEmployeeKey
WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL
)

, Stores AS (
SELECT
 DimOrganizationStructureStoreKey
, OrgStoreNumber
, Longitude
, Latitude
FROM Store 
WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL
)

SELECT 
 EmployeeKey
, (Geography::Point(Employee.Latitude, Employee.Longitude, 4326).STDistance(Geography::Point(Stores.LATITUDE, Stores.LONGITUDE, 4326)))*(0.00062137) as Distance_Miles

FROM Employee
  JOIN Stores ON Employee.HomeStore_DimOrganizationStructureStoreKey = Stores.DimOrganizationStructureStoreKey
WHERE 
(Geography::Point(Employee.Latitude, Employee.Longitude, 4326).STDistance(Geography::Point(Stores.LATITUDE, Stores.LONGITUDE, 4326)))*(0.00062137) < 100
