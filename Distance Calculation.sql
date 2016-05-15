-- Determines the distance between an employee's address and primary store in miles using geocodes

WITH Employees AS (
SELECT
 EmployeeKey
, HomeStore_DimOrganizationStructureStoreKey
, Longitude
, Latitude
FROM dbo.FlightRisk
  JOIN dbo.Employee ON FlightRisk.EmployeeKey = Employee.DimOperationalStructureEmployeeKey
WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL
)

, Stores AS (
SELECT
 DimOrganizationStructureStoreKey
, OrgStoreNumber
, Longitude
, Latitude
FROM dbo.Store 
WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL
)

SELECT 
 EmployeeKey
, (Geography::Point(Employees.Latitude, Employees.Longitude, 4326).STDistance(Geography::Point(Stores.LATITUDE, Stores.LONGITUDE, 4326)))*(0.00062137) as Distance_Miles

FROM Employees
  JOIN Stores ON Employees.HomeStore_DimOrganizationStructureStoreKey = Stores.DimOrganizationStructureStoreKey
WHERE 
(Geography::Point(Employees.Latitude, Employees.Longitude, 4326).STDistance(Geography::Point(Stores.LATITUDE, Stores.LONGITUDE, 4326)))*(0.00062137) < 100
