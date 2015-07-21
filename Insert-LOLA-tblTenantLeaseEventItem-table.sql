
DECLARE @Debug smallint = 0

DECLARE @TenantLeaseEvents table(
	 BuildingId char(6)
	,TenantId char(50)
	,SuiteNo char(50)
	,EventType varchar(2)
	,LeaseActionId varchar(250)
	,LeaseActionDescription varchar(MAX)
	,InsertTimeStamp datetime
)

INSERT INTO @TenantLeaseEvents(BuildingId, TenantId, SuiteNo, EventType, LeaseActionId,LeaseActionDescription,InsertTimeStamp)
Select 
BLDG.BLDGID,
LEAS.MOCCPID AS TenantId,
SUIT.SUITENO As SuiteNo,
'LA' AS EventType,
Clause.BLDGID + Clause.LEASID AS LeaseActionId,
Clause.Detail As LeaseActionDesc
,getutcdate()
--ENTITY.ENTITYID,
--Entity.ENTTYPE,
--entity.proptype,
--BLDG.BLDGNAME,
--suit.FloorNo,
--LEAS.LEASID,
--LEAS.OCCPSTAT as 'Status',
--CLAUSE.DESCRPN as 'Clause',
--Clause.DETAIL as 'Clause Description',
--Leas.BEGINDATE as 'Lease Start',
--Leas.EXPIR as 'Lease End',
--suit.SUITENO,
--suit.SUITSQFT,
--Case When Leas.OCCPNAME IS Not Null Then Leas.OCCPNAME
--      Else 'Vacant' End as 'Tenant'
From suit (nolock)
left join entity (nolock) on suit.bldgid = entity.entityid
left join bldg (nolock) on suit.bldgid = bldg.bldgid
left join LEAS (nolock) on leas.BLDGID=suit.bldgid and suit.SUITID=LEAS.SUITID and
	(LEAS.EXPIR>GETDATE() or LEAS.MTM='Y')
left join CLAUSE (nolock) on Clause.BLDGID=bldg.bldgid and leas.LEASID=CLAUSE.LEASID
Where
--bldg.BLDGID='010401' and
----leas.LEASID='016414' or leas.LEASID='013887' and
--bldg.BLDGID=@BLDGIDPARAM and
Clause.CLAUSETYPEID='PEN'
and
suit.suitsqft > 0 and bldg.inactive <> 'Y'
and
LEAS.OCCPSTAT in ('C','N')
--and
--((LEAS.EXPIR =(select MAX(L.EXPIR) From LEAS L (nolock)  Where L.BLDGID=suit.bldgid and suit.SUITID=L.SUITID)) or LEAS.EXPIR is null)
--Order by
--Entity.ENTTYPE,BLDG.BLDGNAME,suit.FloorNo,suit.SUITENO

UNION ALL

Select  
BLDG.BLDGID,
LEAS.MOCCPID AS TenantId,
SUIT.SUITENO As SuiteNo,
'LO' AS EventType,
LEASOPTS.BLDGID + LEASOPTS.LEASID AS LeaseActionId,
LEASOPTS.Notes As LeaseActionDesc
,getutcdate()
--ENTITY.ENTITYID,
--Entity.ENTTYPE,
--entity.proptype,
--BLDG.BLDGNAME,
--suit.FloorNo,
--LEAS.LEASID,
--LEAS.OCCPSTAT as 'Status',
--CLAUSE.DESCRPN as 'Clause',
--Clause.DETAIL as 'Clause Description',
--Leas.BEGINDATE as 'Lease Start',
--Leas.EXPIR as 'Lease End',
--,suit.SUITENO,
--suit.SUITSQFT
--Case When Leas.OCCPNAME IS Not Null Then Leas.OCCPNAME
--      Else 'Vacant' End as 'Tenant'
From suit (nolock)
left join entity (nolock) on suit.bldgid = entity.entityid
left join bldg (nolock) on suit.bldgid = bldg.bldgid
left join LEAS (nolock) on leas.BLDGID=suit.bldgid and suit.SUITID=LEAS.SUITID and
	(LEAS.EXPIR>GETDATE() or LEAS.MTM='Y')
INNER join LEASOPTS (nolock) on LEASOPTS.BLDGID=bldg.bldgid and leas.LEASID=LEASOPTS.LEASID
Where
--bldg.BLDGID='010401' and
--leas.LEASID='016414' or leas.LEASID='013887' and
--bldg.BLDGID=@BLDGIDPARAM and
--LEASOPTS.OPTNTYPE='PEN'
--and
suit.suitsqft > 0 and bldg.inactive <> 'Y'
and
LEAS.OCCPSTAT in ('C','N')
--and
----((LEAS.EXPIR =(select MAX(L.EXPIR) From LEAS L (nolock)  Where L.BLDGID=suit.bldgid and suit.SUITID=L.SUITID)) or LEAS.EXPIR is null)
--Order by
--Entity.ENTTYPE,BLDG.BLDGNAME,suit.FloorNo,suit.SUITENO
if @Debug > 0
begin
	SELECT BuildingId, TenantId, SuiteNo, EventType, LeaseActionId,LeaseActionDescription 
	FROM @TenantLeaseEvents
end


/*Performed merge: update existing record and insert new ones*/
MERGE dbo.tblTenantLeaseEventItem tb
using (
	SELECT BuildingId, TenantId, SuiteNo, EventType, LeaseActionId,LeaseActionDescription, InsertTimeStamp 
	FROM @TenantLeaseEvents 
	WHERE SuiteNo IS NOT NULL
	) ds
on (tb.BuildingId = ds.BuildingId and tb.TenantId = ds.TenantId and tb.LeaseActionId = db.LeaseActionId)
when matched then update set
	 BuildingId = ds.BuildingId
	,TenantId = ds.TenantId
	,SuiteNo = ds.SuiteNo
	,EventType = ds.EventType
	,LeaseActionid = ds.LeaseActionId
	,LeaseActionDescription = ds.LeaseActionDescription
when not matched then 
insert (BuildingId, TenantId, SuiteNo, EventType, LeaseActionId,LeaseActionDescription,InsertTimeStamp)
values (ds.BuildingId, ds.TenantId, ds.SuiteNo, ds.EventType, ds.LeaseActionId, ds.LeaseActionDescription, ds.InsertTimeStamp);

