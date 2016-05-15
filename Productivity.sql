DECLARE @StartDate date, @EndDate date, @PreStartDate date, @DayRange int
SET @StartDate = '2010-05-01'
SET @EndDate   = '2015-05-01'
SET @DayRange  = -180  -- 6 Months
SET @PreStartDate = DATEADD(dd, @DayRange, @StartDate)
;
IF OBJECT_ID('tempdb..#Hours') IS NOT NULL DROP TABLE #Hours
IF OBJECT_ID('tempdb..#Sales') IS NOT NULL DROP TABLE #Sales

--Populates #Hours and #Sales with data to be grouped into Service $/Hours for division, region, district, Store, and employee
SELECT
FDA.DimOperationalStructureEmployeeKey
, HomeStore_DimOrganizationStructureStoreKey
, Division
, OrgRegionCode
, OrgStoreNumber
, OrgDistrictCode
, SUM(CASE WHEN DateAlternateKey BETWEEN @StartDate AND @EndDate THEN HoursProductive ELSE 0 END) as HoursProductive
, SUM(CASE WHEN (DateAlternateKey BETWEEN DATEADD(dd, @DayRange, (CASE WHEN OpsEmployeeTerminationDate IS NULL THEN CONVERT(date,@EndDate) ELSE OpsEmployeeTerminationDate END))
	                                         AND (CASE WHEN OpsEmployeeTerminationDate IS NULL THEN CONVERT(date,@EndDate) ELSE OpsEmployeeTerminationDate END))
    THEN HoursProductive ELSE 0 END) AS Hours_6Mo
INTO #Hours
FROM dbo.FactDailyAttendance AS FDA 
  JOIN dbo.DimDate ON FDA.DimDateKey = DimDate.DateKey
  JOIN dbo.DimEmployees AS Emp ON FDA.DimOperationalStructureEmployeeKey = Emp.DimOperationalStructureEmployeeKey
  JOIN dbo.DimStores AS Stores  ON Emp.HomeStore_DimOrganizationStructureStoreKey = Stores.DimOrganizationStructureStoreKey
WHERE
 DateAlternateKey between @PreStartDate AND @EndDate
  AND (OpsEmployeeTerminationDate IS NULL OR OpsEmployeeTerminationDate > @StartDate )
  AND  OriginalHireDate != ''
  AND CASE WHEN OpsEmployeeTerminationDate IS NOT NULL THEN DateDiff(DD, OpsEmployeeHireDate, OpsEmployeeTerminationDate) 
           ELSE DateDiff(DD, OpsEmployeeHireDate, @EndDate) END >= 0
GROUP BY 
 FDA.DimOperationalStructureEmployeeKey
, HomeStore_DimOrganizationStructureStoreKey
, Division
, OrgRegionCode
, OrgStoreNumber
, OrgDistrictCode
;

SELECT
DimOperationStructureEmployeeKey
, HomeStore_DimOrganizationStructureStoreKey
, Division
, OrgRegionCode
, OrgStoreNumber
, OrgDistrictCode
, SUM(CASE WHEN DimServiceKey > 0 AND DateAlternateKey BETWEEN @StartDate AND @EndDate THEN Amount ELSE 0 end) as ServiceSales
, SUM(CASE WHEN DimServiceKey > 0 
	    AND (DateAlternateKey BETWEEN DATEADD(dd, @DayRange, (CASE WHEN OpsEmployeeTerminationDate IS NULL THEN CONVERT(date,@EndDate) ELSE OpsEmployeeTerminationDate END))
	                                         AND (CASE WHEN OpsEmployeeTerminationDate IS NULL THEN CONVERT(date,@EndDate) ELSE OpsEmployeeTerminationDate END))
	  THEN Amount ELSE 0 END) AS ServiceSales_6Mo
INTO #Sales
FROM dbo.FactSales AS Sales 
  JOIN dbo.Employees AS Emp ON Sales.DimOperationStructureEmployeeKey = Emp.DimOperationalStructureEmployeeKey
  JOIN dbo.DimDate ON Sales.DimDateKey = DimDate.DateKey
  JOIN dbo.Stores ON Emp.HomeStore_DimOrganizationStructureStoreKey = Stores.DimOrganizationStructureStoreKey
WHERE
  DateAlternateKey between @PreStartDate AND @EndDate
  AND (OpsEmployeeTerminationDate IS NULL OR OpsEmployeeTerminationDate > @StartDate )
  AND  OriginalHireDate != ''
  AND CASE WHEN OpsEmployeeTerminationDate IS NOT NULL THEN DateDiff(DD, OpsEmployeeHireDate, OpsEmployeeTerminationDate) 
           ELSE DateDiff(DD, OpsEmployeeHireDate, @EndDate) END >= 0
GROUP BY
 DimOperationStructureEmployeeKey
, HomeStore_DimOrganizationStructureStoreKey
, Division
, OrgRegionCode
, OrgStoreNumber
, OrgDistrictCode
;

-- By Division
SELECT
#Sales.Division AS Division
, SUM(ServiceSales) AS ServiceSales
, SUM(HoursProductive) AS HoursProductive
, SUM((ServiceSales)/(NULLIF(CEILING(SUM(HoursProductive)),0))) AS Productivity  -- Ceiling function to avoid dividing by a decimal
, SUM(ServiceSales_6Mo) AS ServiceSales_6Mo
, SUM(Hours_6Mo) AS Hours_6Mo
, ISNULL(SUM((ServiceSales_6Mo)/(NULLIF(CEILING(SUM(Hours_6Mo)),0))),0) AS Productivity_6Mo  -- Ceiling function to avoid dividing by a decimal
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 HoursProductive IS NOT NULL
 AND HoursProductive != 0
 AND #Sales.Division IS NOT NULL
GROUP BY 
 #Sales.Division 

-- By Region
SELECT
#Sales.OrgRegionCode AS Region
, SUM(ServiceSales) AS ServiceSales
, SUM(HoursProductive) AS HoursProductive
, SUM((ServiceSales)/(NULLIF(CEILING(SUM(HoursProductive)),0))) AS Productivity  -- Ceiling function to avoid dividing by a decimal
, SUM(ServiceSales_6Mo) AS ServiceSales_6Mo
, SUM(Hours_6Mo) AS Hours_6Mo
, ISNULL(SUM((ServiceSales_6Mo)/(NULLIF(CEILING(SUM(Hours_6Mo)),0))),0) AS Productivity_6Mo  -- Ceiling function to avoid dividing by a decimal
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 HoursProductive IS NOT NULL
 AND HoursProductive != 0
GROUP BY 
 #Sales.OrgRegionCode 

-- By District
SELECT
#Sales.OrgDistrictCode AS District
, SUM(ServiceSales) AS ServiceSales
, SUM(HoursProductive) AS HoursProductive
, SUM((ServiceSales)/(NULLIF(CEILING(SUM(HoursProductive)),0))) AS Productivity  -- Ceiling function to avoid dividing by a decimal
, SUM(ServiceSales_6Mo) AS ServiceSales_6Mo
, SUM(Hours_6Mo) AS Hours_6Mo
, ISNULL(SUM((ServiceSales_6Mo)/(NULLIF(CEILING(SUM(Hours_6Mo)),0))),0) AS Productivity_6Mo  -- Ceiling function to avoid dividing by a decimal
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 HoursProductive IS NOT NULL
 AND HoursProductive != 0
GROUP BY 
 #Sales.OrgDistrictCode 

-- By Store
SELECT
#Sales.OrgStoreNumber AS Store
, SUM(ServiceSales) AS ServiceSales
, SUM(HoursProductive) AS HoursProductive
, SUM((ServiceSales)/(NULLIF(CEILING(SUM(HoursProductive)),0))) AS Productivity  -- Ceiling function to avoid dividing by a decimal
, SUM(ServiceSales_6Mo) AS ServiceSales_6Mo
, SUM(Hours_6Mo) AS Hours_6Mo
, ISNULL(SUM((ServiceSales_6Mo)/(NULLIF(CEILING(SUM(Hours_6Mo)),0))),0) AS Productivity_6Mo  -- Ceiling function to avoid dividing by a decimal
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 HoursProductive IS NOT NULL
 AND HoursProductive != 0
GROUP BY 
 #Sales.OrgStoreNumber

-- By Employee
SELECT
#Sales.DimOperationStructureEmployeeKey AS EmployeeKey
, SUM(ServiceSales) AS ServiceSales
, SUM(HoursProductive) AS HoursProductive
, SUM((ServiceSales)/(NULLIF(CEILING(SUM(HoursProductive)),0))) AS Productivity  -- Ceiling function to avoid dividing by a decimal
, SUM(ServiceSales_6Mo) AS ServiceSales_6Mo
, SUM(Hours_6Mo) AS Hours_6Mo
, ISNULL(SUM((ServiceSales_6Mo)/(NULLIF(CEILING(SUM(Hours_6Mo)),0))),0) AS Productivity_6Mo  -- Ceiling function to avoid dividing by a decimal
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 HoursProductive IS NOT NULL
 AND HoursProductive != 0
GROUP BY 
 #Sales.DimOperationStructureEmployeeKey
 
DROP TABLE #Sales
DROP TABLE #Hours
