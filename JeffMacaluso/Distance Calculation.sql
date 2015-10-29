-- Determines the distance between an employee's address and primary salon in miles using geocodes

WITH Employee AS (
SELECT
 EmployeeKey
, HomeSalon_DimOrganizationStructureSalonKey
, Longitude
, Latitude
FROM Finance.dbo.zFlightRisk FR
  JOIN DimOperationalStructureEmployee Emp WITH (NOLOCK) ON FR.EmployeeKey = Emp.DimOperationalStructureEmployeeKey
WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL
)

, Salons AS (
SELECT
 DimOrganizationStructureSalonKey
, OrgSalonNumber
, Longitude
, Latitude
FROM DimOrganizationStructureSalon WITH (NOLOCK)
WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL
)

SELECT 
 EmployeeKey
, (Geography::Point(Employee.Latitude, Employee.Longitude, 4326).STDistance(Geography::Point(Salons.LATITUDE, Salons.LONGITUDE, 4326)))*(0.00062137) as Distance_Miles

FROM Employee
  JOIN Salons ON Employee.HomeSalon_DimOrganizationStructureSalonKey = Salons.DimOrganizationStructureSalonKey
WHERE 
(Geography::Point(Employee.Latitude, Employee.Longitude, 4326).STDistance(Geography::Point(Salons.LATITUDE, Salons.LONGITUDE, 4326)))*(0.00062137) < 100
