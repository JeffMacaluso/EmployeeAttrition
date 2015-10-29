SELECT 
 Territory
, AVG(AvgWeeklyPaycheck) 
    AS '0 to 100'
, (AVG(CASE WHEN FlightRisk > 75 THEN AvgWeeklyPaycheck ELSE NULL END)) 
    AS '>75'
, (AVG(CASE WHEN FlightRisk < 75 AND FlightRisk > 50 THEN AvgWeeklyPaycheck ELSE NULL END))/(AVG(CASE WHEN FlightRisk > 75 THEN AvgWeeklyPaycheck ELSE NULL END))-1 
    AS '% Change'
, (AVG(CASE WHEN FlightRisk < 75 AND FlightRisk > 50 THEN AvgWeeklyPaycheck ELSE NULL END)) 
    AS '50 to 75'
, (AVG(CASE WHEN FlightRisk < 50 AND FlightRisk > 25 THEN AvgWeeklyPaycheck ELSE NULL END))/(AVG(CASE WHEN FlightRisk < 75 AND FlightRisk > 50 THEN AvgWeeklyPaycheck ELSE NULL END))-1 
    AS '% Change'
, (AVG(CASE WHEN FlightRisk < 50 AND FlightRisk > 25 THEN AvgWeeklyPaycheck ELSE NULL END)) 
    AS '25 to 50'
, (AVG(CASE WHEN FlightRisk < 25 THEN AvgWeeklyPaycheck ELSE NULL END))/(AVG(CASE WHEN FlightRisk < 50 AND FlightRisk > 25 THEN AvgWeeklyPaycheck ELSE NULL END))-1 
    AS '% Change'
, (AVG(CASE WHEN FlightRisk < 25 THEN AvgWeeklyPaycheck ELSE NULL END)) 
    AS '<25'
FROM finance.dbo.zFlightRisk
WHERE 
 FlightRisk IS NOT NULL
GROUP BY 
 Territory
ORDER BY Territory ASC
