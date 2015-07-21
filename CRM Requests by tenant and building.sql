
/******** If not exist, then create this table tblTenantWorkOrderRequest **********/
IF NOT EXISTS (SELECT * FROM sys.objects 
				WHERE object_id = OBJECT_ID(N'[dbo].tblTenantWorkOrderRequest]') AND type in (N'U'))
CREATE TABLE [dbo].[tblTenantWorkOrderRequest](
	BuildingId char(6)
	,BuildingName varchar(250)
	,TenantId char(50)
	,ByMonth int
	,Name varchar(250)
	,IncidentNumber varchar(25)
)	

/******** Merge data: update existing record and insert new records into table tblTenantWorkOrderRequest **********/
DECLARE @Debug smallint = 0
DECLARE @TempTenantWorkOrderRequests table(
	BuildingId char(6)
	,BuildingName varchar(250)
	,TenantId char(50)
	,ByMonth int
	,Name varchar(250)
	,IncidentNumber varchar(25)
)	

INSERT INTO @TempTenantWorkOrderRequests(
	BuildingId
	,BuildingName
	,TenantId
	,ByMonth
	,Name
	,IncidentNumber	
)

SELECT 
	b.new_buildingId as BuildingId
    ,i.new_buildingidName As BuildingName
	,a.New_TenantID As TenantId
    ,Month(i.CreatedOn) as ByMonth
    ,a.Name
    ,i.New_incidentnumber as IncidentNumber
FROM [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].Incident i 
JOIN [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].Account a on i.AccountId = a.AccountId 
JOIN [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].New_buildingproperty b on b.New_buildingpropertyId=i.new_buildingid
WHERE year(i.CreatedOn) = DATEPART(year,getutcdate()) -- current year
    and i.SubjectIdName = 'Service Request'
    and Name != 'General Building Maintenance'
GROUP BY a.New_TenantID, b.new_buildingId, new_buildingidName, a.Name, Month(i.CreatedOn)
	,i.New_incidentnumber
	
/***** Debug ********/
IF @Debug > 0
BEGIN
	SELECT 	BuildingId
		,BuildingName
		,TenantId
		,ByMonth
		,Name
		,IncidentNumber	
	FROM @TempTenantWorkOrderRequests
END

/********** Performed merged here: update existing and insert new record based on BuildingId and TenantId ***********/
MERGE dbo.tblTenantWorkOrderRequest tb
USING
	(
		SELECT 	BuildingId
			,BuildingName
			,TenantId
			,ByMonth
			,Name
			,IncidentNumber	
		FROM @TempTenantWorkOrderRequests 
	) ds
ON (tb.BuildingId = ds.BuildingId AND tb.TenantId = ds.TenantId AND tb.IncidentNumber = ds.IncidentNumber)
WHEN NOT MATCHED THEN
INSERT ( BuildingId
		,BuildingName
		,TenantId
		,ByMonth
		,Name
		,IncidentNumber	)
VALUES(ds.BuildingId, ds.BuildingName, ds.TenantId, ds.ByMonth, ds.Name, ds.IncidentNumber);



/******** Stored procedures: Retrieve Tenants Overall Work order Request **********/

-- ============================================
-- Created By: Cecilia Carter & Eric Difrancesco
-- Create date: 7/21/2015
-- Description:	Retrieve Tenants Overall Work order Request
-- =============================================

/****
Use:
	EXECUTE dbo.spGetTenantBuildingOverallCrmRequest '00014158', '088504'
****/

CREATE PROCEDURE dbo.spGetTenantBuildingOverallCrmRequest
	@TenantId char(8),
	@BuildingId char(6)
AS
BEGIN
	SELECT BuildingName, ByMonth
		,Sum(WorkOrdersTenant) TenantWO
		,Sum(WorkOrdersBuilding) BuildingWO
	FROM (
		SELECT 
			BuildingName
			,Case When TenantID  = @TenantID Then Name Else BuildingName End as Grouper
			,ByMonth
			,SUM(CASE WHEN TenantID  = @TenantID THEN 1
									  ELSE 0 END) WorkOrdersTenant
			,count(incidentnumber) WorkOrdersBuilding 
		FROM dbo.tblTenantWorkOrderRequest
		WHERE 
			buildingId=@BuildingId
		GROUP BY buildingId, buildingName, Name, ByMonth , Case When TenantID  = @TenantID Then Name Else buildingName End
	) a
	GROUP BY BuildingName, ByMonth 
	ORDER BY ByMonth

END


------------------------------------------------------
/**** TESTING ONLY ******/

DECLARE @TenantID varchar(8)
DECLARE @BuildingId char(6)

SET @TenantID = '00014158' --'00014158'
SET @BuildingId='088504'

SELECT BuildingName, ByMonth
	,Sum(WorkOrdersTenant) TenantWO
	,Sum(WorkOrdersBuilding) BuildingWO
FROM (
	SELECT 
		BuildingName
		,Case When TenantID  = @TenantID Then Name Else BuildingName End as Grouper
		,ByMonth
		,SUM(CASE WHEN TenantID  = @TenantID THEN 1
								  ELSE 0 END) WorkOrdersTenant
		,count(incidentnumber) WorkOrdersBuilding 
	FROM dbo.tblTenantWorkOrderRequest
	WHERE 
		buildingId=@BuildingId
	GROUP BY buildingId, buildingName, Name, ByMonth , Case When TenantID  = @TenantID Then Name Else buildingName End
) a
GROUP BY BuildingName, ByMonth 
ORDER BY ByMonth

	
------------------------------------------------------------------------------------
/*
IF OBJECT_ID ('tempdb', '#tblTenantWorkOrderRequest') IS NULL
	DROP TABLE #tblTenantWorkOrderRequest 

SELECT 
	b.new_buildingId as BuildingId
    ,i.new_buildingidName As BuildingName
	,a.New_TenantID As TenantId
    ,Month(i.CreatedOn) as ByMonth
    ,a.Name
    ,i.New_incidentnumber as IncidentNumber
INTO #tblTenantWorkOrderRequest
FROM [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].Incident i 
JOIN [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].Account a on i.AccountId = a.AccountId 
JOIN [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].New_buildingproperty b on b.New_buildingpropertyId=i.new_buildingid
WHERE year(i.CreatedOn) = DATEPART(year,getutcdate()) -- current year
    and i.SubjectIdName = 'Service Request'
    and Name != 'General Building Maintenance'
    --and new_buildingidName = '8400 Normandale Lake'--Building Name example search
    --and @BuildingID=b.New_BuildingID --Parameter to use in code
GROUP BY a.New_TenantID, b.new_buildingId, new_buildingidName, a.Name, Month(i.CreatedOn)
	,i.New_incidentnumber

-----------------------------------------------------------------------
SELECT * FROM #tblTenantWorkOrderRequest WHERE TenantId='00014044'


DECLARE @TenantID varchar(8), @BuildingId char(6)
--SET @TenantID = '00014005'
SET @TenantID = '00014158' --'00014158'
SET @BuildingId='088504'


SELECT BuildingName, ByMonth
	,Sum(WorkOrdersTenant) TenantWO
	,Sum(WorkOrdersBuilding) BuildingWO
FROM (
	SELECT 
		BuildingName
		,Case When TenantID  = @TenantID Then Name Else BuildingName End as Grouper
		,ByMonth
		,SUM(CASE WHEN TenantID  = @TenantID THEN 1
								  ELSE 0 END) WorkOrdersTenant
		,count(incidentnumber) WorkOrdersBuilding 
	FROM #tblTenantWorkOrderRequest
	WHERE 
		buildingId=@BuildingId
	GROUP BY buildingId, buildingName, Name, ByMonth , Case When TenantID  = @TenantID Then Name Else buildingName End
) a
GROUP BY BuildingName, ByMonth 
ORDER BY ByMonth


-------------------------------------------------
/****** Original query from Difran *******/
-------------------------------------------------

DECLARE @TenantID varchar(8)
--SET @TenantID = '00014005'
SET @TenantID = '00014158' --'00014158'

;WITH TenantWorkOrders AS (
SELECT 
    i.new_buildingidName BuildingName
	--,a.New_TenantID As TenantId
    ,Case When A.New_TenantID  = @TenantID Then a.Name Else i.new_buildingidName End as Grouper
    ,Month(i.CreatedOn) as ByMonth
    ,SUM(CASE WHEN A.New_TenantID  = @TenantID THEN 1
                              ELSE 0 END) WorkOrdersTenant
    ,count(i.New_incidentnumber) WorkOrdersBuilding 
FROM [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].Incident i 
JOIN [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].Account a on i.AccountId = a.AccountId 
JOIN [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].New_buildingproperty b on b.New_buildingpropertyId=i.new_buildingid
WHERE year(i.CreatedOn) = DATEPART(year,getutcdate()) -- current year
    and i.SubjectIdName = 'Service Request'
    and Name != 'General Building Maintenance'
    and new_buildingidName = '8400 Normandale Lake'--Building Name example search
    --and @BuildingID=b.New_BuildingID --Parameter to use in code
GROUP BY new_buildingidName,a.Name, Month(i.CreatedOn), Case When A.New_TenantID  = @TenantID Then a.Name Else i.new_buildingidName End
--ORDER BY a.New_TenantID
)

SELECT  BuildingName,ByMonth
	,Sum(WorkOrdersTenant) a
	,Sum(WorkOrdersBuilding) b
FROM TenantWorkOrders
GROUP BY BuildingName, ByMonth 
ORDER BY ByMonth

*/
