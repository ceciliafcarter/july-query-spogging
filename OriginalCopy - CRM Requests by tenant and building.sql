
declare @TenantID varchar(8)
set @TenantID='00014158'

select BuildingName, [Month], 
	Sum(WorkOrdersTenant) a,
	Sum(WorkOrdersBuilding) b
FROM 
(select
    i.new_buildingidName BuildingName
--    ,a.New_TenantID
    ,Case When A.New_TenantID  = @TenantID Then a.Name Else i.new_buildingidName End as Grouper
    ,Month(i.CreatedOn) as Month
    ,SUM(CASE WHEN A.New_TenantID  = @TenantID THEN 1
                              ELSE 0 END) WorkOrdersTenant
    ,count(i.New_incidentnumber) WorkOrdersBuilding 
from [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].Incident i 
join [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].Account a on i.AccountId = a.AccountId 
join [MREGSQL2008].[Northmarqpm_MSCRM].[dbo].New_buildingproperty b on b.New_buildingpropertyId=i.new_buildingid
where year(i.CreatedOn) = '2015'
    and i.SubjectIdName = 'Service Request'
    and Name != 'General Building Maintenance'
    and new_buildingidName = '8400 Normandale Lake'--Building Name example search
    --and @BuildingID=b.New_BuildingID --Parameter to use in code
group by new_buildingidName,a.Name, Month(i.CreatedOn), Case When A.New_TenantID  = @TenantID Then a.Name Else i.new_buildingidName End
)a
GROUP BY BuildingName, [Month]
ORDER BY [Month]