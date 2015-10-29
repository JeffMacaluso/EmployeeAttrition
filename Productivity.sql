DECLARE @StartDate date, @EndDate date, @PreStartDate date, @DayRange int
SET @StartDate = '2010-05-01'
SET @EndDate   = '2015-05-01'
SET @DayRange  = -150
SET @PreStartDate = DATEADD(dd, @DayRange, @StartDate)
;
IF OBJECT_ID('tempdb..#Hours') IS NOT NULL DROP TABLE #Hours
IF OBJECT_ID('tempdb..#Sales') IS NOT NULL DROP TABLE #Sales

--Populates #Hours and #Sales with data to be grouped into Service $/Hours for division, region, district, salon, and employee
SELECT
FDA.DimOperationalStructureEmployeeKey
, HomeSalon_DimOrganizationStructureSalonKey
, Division
, OrgRegionCode
, OrgSalonNumber
, OrgDistrictCode
, SUM(CASE WHEN DateAlternateKey BETWEEN @StartDate AND @EndDate THEN TotalHours ELSE 0 END) as TotalHours
, SUM(CASE WHEN (DateAlternateKey BETWEEN DATEADD(dd, @DayRange, (CASE WHEN OpsEmployeeTerminationDate IS NULL THEN CONVERT(date,@EndDate) ELSE OpsEmployeeTerminationDate END))
	                                         AND (CASE WHEN OpsEmployeeTerminationDate IS NULL THEN CONVERT(date,@EndDate) ELSE OpsEmployeeTerminationDate END))
    THEN TotalHours ELSE 0 END) AS STHours
INTO #Hours
FROM FactDailyAttendance FDA WITH (NOLOCK)
  JOIN DimDate WITH (NOLOCK) ON FDA.DimDateKey = DimDate.DateKey
  JOIN DimOperationalStructureEmployee Emp WITH(NOLOCK) ON FDA.DimOperationalStructureEmployeeKey = Emp.DimOperationalStructureEmployeeKey
  JOIN DimOrganizationStructureSalon Sal WITH (NOLOCK) ON Emp.HomeSalon_DimOrganizationStructureSalonKey = Sal.DimOrganizationStructureSalonKey
WHERE
 DateAlternateKey between @PreStartDate AND @EndDate
  AND (OpsEmployeeTerminationDate IS NULL OR OpsEmployeeTerminationDate > @StartDate )
  AND  OriginalHireDate != ''
  AND CASE WHEN OpsEmployeeTerminationDate IS NOT NULL THEN DateDiff(DD, OpsEmployeeHireDate, OpsEmployeeTerminationDate) 
           ELSE DateDiff(DD, OpsEmployeeHireDate, @EndDate) END >= 0
GROUP BY 
 FDA.DimOperationalStructureEmployeeKey
, HomeSalon_DimOrganizationStructureSalonKey
, Division
, OrgRegionCode
, OrgSalonNumber
, OrgDistrictCode
;

SELECT
DimOperationStructureEmployeeKey
, HomeSalon_DimOrganizationStructureSalonKey
, Division
, OrgRegionCode
, OrgSalonNumber
, OrgDistrictCode
, SUM(case when DimServiceKey > 0 AND DateAlternateKey BETWEEN @StartDate AND @EndDate THEN Amount ELSE 0 end) as ServiceSales
, SUM(CASE WHEN DimServiceKey > 0 
	    AND (DateAlternateKey BETWEEN DATEADD(dd, @DayRange, (CASE WHEN OpsEmployeeTerminationDate IS NULL THEN CONVERT(date,@EndDate) ELSE OpsEmployeeTerminationDate END))
	                                         AND (CASE WHEN OpsEmployeeTerminationDate IS NULL THEN CONVERT(date,@EndDate) ELSE OpsEmployeeTerminationDate END))
	  THEN Amount ELSE 0 END) AS STServiceSales
INTO #Sales
FROM FactTicketDetail WITH (NOLOCK)
  JOIN DimOperationalStructureEmployee Emp WITH (NOLOCK) ON FactTicketDetail.DimOperationStructureEmployeeKey = Emp.DimOperationalStructureEmployeeKey
  JOIN DimDate WITH (NOLOCK) ON FactTicketDetail.DimDateKey = DimDate.DateKey
  JOIN DimOrganizationStructureSalon Sal WITH (NOLOCK) ON Emp.HomeSalon_DimOrganizationStructureSalonKey = Sal.DimOrganizationStructureSalonKey
WHERE
 DateAlternateKey between @PreStartDate AND @EndDate
  AND (OpsEmployeeTerminationDate IS NULL OR OpsEmployeeTerminationDate > @StartDate )
GROUP BY
 DimOperationStructureEmployeeKey
, HomeSalon_DimOrganizationStructureSalonKey
, Division
, OrgRegionCode
, OrgSalonNumber
, OrgDistrictCode
;

SELECT
#Sales.Division AS Division
, SUM(ServiceSales) AS TotalServiceSales
, SUM(TotalHours) AS TotalHours
, SUM((ServiceSales)/(NULLIF(TotalHours,0))) AS TotalProductivity
, SUM(STServiceSales) AS STServiceSales
, SUM(STHours) AS STHours
, ISNULL(SUM((STServiceSales)/(NULLIF(STHours,0))),0) AS STProductivity
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 TotalHours IS NOT NULL
 AND TotalHours != 0
 AND #Sales.Division IS NOT NULL
GROUP BY 
 #Sales.Division 

SELECT
#Sales.OrgRegionCode AS Region
, SUM(ServiceSales) AS TotalServiceSales
, SUM(TotalHours) AS TotalHours
, SUM((ServiceSales)/(NULLIF(TotalHours,0))) AS TotalProductivity
, SUM(STServiceSales) AS STServiceSales
, SUM(STHours) AS STHours
, ISNULL(SUM((STServiceSales)/(NULLIF(STHours,0))),0) AS STProductivity
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 TotalHours IS NOT NULL
 AND TotalHours != 0
GROUP BY 
 #Sales.OrgRegionCode 

SELECT
#Sales.OrgDistrictCode AS District
, SUM(ServiceSales) AS TotalServiceSales
, SUM(TotalHours) AS TotalHours
, SUM((ServiceSales)/(NULLIF(TotalHours,0))) AS TotalProductivity
, SUM(STServiceSales) AS STServiceSales
, SUM(STHours) AS STHours
, ISNULL(SUM((STServiceSales)/(NULLIF(STHours,0))),0) AS STProductivity
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 TotalHours IS NOT NULL
 AND TotalHours != 0
GROUP BY 
 #Sales.OrgDistrictCode 

SELECT
#Sales.OrgSalonNumber AS Salon
, SUM(ServiceSales) AS TotalServiceSales
, SUM(TotalHours) AS TotalHours
, SUM((ServiceSales)/(NULLIF(TotalHours,0))) AS TotalProductivity
, SUM(STServiceSales) AS STServiceSales
, SUM(STHours) AS STHours
, ISNULL(SUM((STServiceSales)/(NULLIF(STHours,0))),0) AS STProductivity
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 TotalHours IS NOT NULL
 AND TotalHours != 0
GROUP BY 
 #Sales.OrgSalonNumber

SELECT
#Sales.DimOperationStructureEmployeeKey AS EmployeeKey
, SUM(ServiceSales) AS TotalServiceSales
, SUM(TotalHours) AS TotalHours
, SUM((ServiceSales)/(NULLIF(TotalHours,0))) AS TotalProductivity
, SUM(STServiceSales) AS STServiceSales
, SUM(STHours) AS STHours
, ISNULL(SUM((STServiceSales)/(NULLIF(STHours,0))),0) AS STProductivity
FROM #Sales
  JOIN #Hours ON #Sales.DimOperationStructureEmployeeKey = #Hours.DimOperationalStructureEmployeeKey
WHERE
 TotalHours IS NOT NULL
 AND TotalHours != 0
GROUP BY 
 #Sales.DimOperationStructureEmployeeKey
 
DROP TABLE #Sales
DROP TABLE #Hours
