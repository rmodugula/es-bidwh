USE [BIDW]
GO

/****** Object:  View [dbo].[GetDucksBoardLogins]    Script Date: 9/18/2014 4:50:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[GetDucksBoardLogins]
AS

select Logins.*,isnull(Region,'Unassigned') as SalesRegion from
(
Select M.SalesOffice,M.TotalLogins,N.AvgForLast3Months as AvgofTotalLoginsForLast3Months,M.LoginsTraded as TradedLogins,O.AvgofTradedLoginsForLast3Months,
M.LastMonthTotalLogins,M.LastMonthLoginsTraded,
case M.SalesOffice
when 'Hong Kong' then 1
when 'Singapore' then 2
when 'Sydney' then 3
when 'Tokyo' then 4
when 'London' then 5
when 'Frankfurt' then 6
when 'Chicago' then 7
when 'Houston' then 8
when 'Sao Paulo' then 9
when 'New York' then 10
when 'Canada' then 11
when 'Geneva' then 12
when 'Unassigned' then 13
when 'Total' then 14
end as SalesOfficeSort

from
(
select t.SalesOffice,t.TotalLogins,tl.LoginsTraded,lmt.LastMonthTotalLogins,lmtl.LastMonthLoginsTraded from
(
select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as TotalLogins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
--where YEAR=year(getdate()) and MONTH=month(GETDATE()) and ProductName in ('X_TRADER_PRO','X_TRADER')
--------------------Added Code to get Prior Month logins until billing is closed-------------------
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=(select Year from (select *,row_number() over (order by id desc) as row 
from fillhub.dbo.InvoiceMonth)Q where ROW=1) then year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end) end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=(select Month from (select *,row_number() over (order by id desc) as row 
from fillhub.dbo.InvoiceMonth)Q where ROW=1) then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=year(getdate()) and MONTH=month(GETDATE()) and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=year(getdate()) and MONTH=month(GETDATE())  and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
union
select 'Total' as Total, SUM(logins) as Logins from
(
select COUNT(A.UserName) as Logins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
where YEAR=year(getdate()) and MONTH=month(GETDATE())  and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=year(getdate()) and MONTH=month(GETDATE())  and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=year(getdate()) and MONTH=month(GETDATE()) and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
--where SalesOffice is not null
group by SalesOffice
)z
)T
join
(
select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as LastMonthTotalLogins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
union
select 'Total' as Total, SUM(logins) as Logins from
(
select COUNT(A.UserName) as Logins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end  and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
--where SalesOffice is not null
group by SalesOffice
)z
)LMT
on t.SalesOffice=lmt.SalesOffice
join
(
select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as LoginsTraded from 
(
select distinct UserName,AccountId,NetworkId from Fills
--where YEAR=year(getdate()) and MONTH=month(GETDATE()) 
--------------------Added Code to get Prior Month logins until billing is closed-------------------
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=(select Year from (select *,row_number() over (order by id desc) as row 
from fillhub.dbo.InvoiceMonth)Q where ROW=1) then year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end) end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=(select Month from (select *,row_number() over (order by id desc) as row 
from fillhub.dbo.InvoiceMonth)Q where ROW=1) then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
and AxProductId in (20005,20997,20999)
and IsBillable='Y' and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=year(getdate()) and MONTH=month(GETDATE()) and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=year(getdate()) and MONTH=month(GETDATE())  and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
union
select 'Total' as Total, SUM(logins) as Logins from
(
select COUNT(A.UserName) as Logins from 
(
select distinct UserName,AccountId,NetworkId from Fills
where YEAR=year(getdate()) and MONTH=month(GETDATE()) and AxProductId in (20005,20997,20999)
and IsBillable='Y' and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=year(getdate()) and MONTH=month(GETDATE())  and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=year(getdate()) and MONTH=month(GETDATE()) and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
--where SalesOffice is not null
group by SalesOffice
)z
)TL
on t.SalesOffice=tl.SalesOffice
join
(
select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as LastMonthLoginsTraded from 
(
select distinct UserName,AccountId,NetworkId from Fills
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end  and AxProductId in (20005,20997,20999)
and IsBillable='Y' and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end  and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end   and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
union
select 'Total' as Total, SUM(logins) as Logins from
(
select COUNT(A.UserName) as Logins from 
(
select distinct UserName,AccountId,NetworkId from Fills
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end  and AxProductId in (20005,20997,20999)
and IsBillable='Y' and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end   and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=case when month(GETDATE())=1 then year(getdate())-1 else year(getdate()) end and MONTH=case when month(GETDATE())=1 then 12 else month(GETDATE())-1 end  and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
--where SalesOffice is not null
group by SalesOffice
)z
)LMTL
on t.SalesOffice=lmtl.SalesOffice
)M
join
(
-------------------------------------AVG of Total Logins-----------------------------
select p.SalesOffice,(PriorLogins+Prior1Logins+Prior2Logins)/3 as AvgForLast3Months from
(
select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as PriorLogins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
--union
--select 'Total' as Total, SUM(logins) as Logins from
--(
--select COUNT(A.UserName) as Logins from 
--(
--select distinct UserName,AccountId,NetworkId from UserLogin UL
--where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
--and ProductName in ('X_TRADER_PRO','X_TRADER')
--)A
--left join 
--(
--select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
--left join (select distinct State,country,SalesOffice from  RegionMap) R
--on u.CountryCode=r.Country and u.State=r.State
--where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
--and CountryCode='US'
--union all
--select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
--left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
--on u.CountryCode=r.Country
--where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
--and CountryCode<>'US' 
--)B
--on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
----where SalesOffice is not null
--group by SalesOffice
--)z
)p
join
(

select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as Prior1Logins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end  and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end  and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
--union
--select 'Total' as Total, SUM(logins) as Logins from
--(
--select COUNT(A.UserName) as Logins from 
--(
--select distinct UserName,AccountId,NetworkId from UserLogin UL
--where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 11 
--when month(getdate())=2 then 12
--else month(GETDATE())-2 end and ProductName in ('X_TRADER_PRO','X_TRADER')
--)A
--left join 
--(
--select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
--left join (select distinct State,country,SalesOffice from  RegionMap) R
--on u.CountryCode=r.Country and u.State=r.State
--where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 11 
--when month(getdate())=2 then 12
--else month(GETDATE())-2 end and CountryCode='US'
--union all
--select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
--left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
--on u.CountryCode=r.Country
--where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 11 
--when month(getdate())=2 then 12
--else month(GETDATE())-2 end and CountryCode<>'US' 
--)B
--on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
----where SalesOffice is not null
--group by SalesOffice
--)z
)p1
on p.SalesOffice=p1.SalesOffice
join
(

select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as Prior2Logins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
--union
--select 'Total' as Total, SUM(logins) as Logins from
--(
--select COUNT(A.UserName) as Logins from 
--(
--select distinct UserName,AccountId,NetworkId from UserLogin UL
--where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 10 
--when month(getdate())=2 then 11
--when month(getdate())=3 then 12
--else month(GETDATE())-3 end and ProductName in ('X_TRADER_PRO','X_TRADER')
--)A
--left join 
--(
--select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
--left join (select distinct State,country,SalesOffice from  RegionMap) R
--on u.CountryCode=r.Country and u.State=r.State
--where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 10 
--when month(getdate())=2 then 11
--when month(getdate())=3 then 12
--else month(GETDATE())-3 end and CountryCode='US'
--union all
--select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
--left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
--on u.CountryCode=r.Country
--where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 10 
--when month(getdate())=2 then 11
--when month(getdate())=3 then 12
--else month(GETDATE())-3 end and CountryCode<>'US' 
--)B
--on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
----where SalesOffice is not null
--group by SalesOffice
--)z
)p2
on p.SalesOffice=p2.SalesOffice

UNION ALL
-----------------------For Totals----------------

select 'Total' as Total, SUM(AvgForLast3Months)
from
(
select p.SalesOffice,(PriorLogins+Prior1Logins+Prior2Logins)/3 as AvgForLast3Months from
(
select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as PriorLogins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
)p
join
(

select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as Prior1Logins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end  and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end  and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice

)p1
on p.SalesOffice=p1.SalesOffice
join
(

select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as Prior2Logins from 
(
select distinct UserName,AccountId,NetworkId from UserLogin
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and ProductName in ('X_TRADER_PRO','X_TRADER')
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
)p2
on p.SalesOffice=p2.SalesOffice
)T
)N
on m.SalesOffice=n.SalesOffice
join
(
------------------------------AVG of Traded Logins---------------------------------
select p.SalesOffice,(PriorLogins+Prior1Logins+Prior2Logins)/3 as AvgofTradedLoginsForLast3Months from
(
select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as PriorLogins from 
(
select distinct UserName,AccountId,NetworkId from Fills
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and AxProductId in (20005,20997,20999)
and IsBillable='Y' and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and CountryCode='US' and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and CountryCode<>'US' and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
--union
--select 'Total' as Total, SUM(logins) as Logins from
--(
--select COUNT(A.UserName) as Logins from 
--(
--select distinct UserName,AccountId,NetworkId from Fills
--where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
--and AxProductId in (20005,20997,20999)
--)A
--left join 
--(
--select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
--left join (select distinct State,country,SalesOffice from  RegionMap) R
--on u.CountryCode=r.Country and u.State=r.State
--where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
--and CountryCode='US'
--union all
--select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
--left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
--on u.CountryCode=r.Country
--where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
--and CountryCode<>'US' 
--)B
--on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
----where SalesOffice is not null
--group by SalesOffice
--)z
)p
join
(

select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as Prior1Logins from 
(
select distinct UserName,AccountId,NetworkId from Fills
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end  and AxProductId in (20005,20997,20999)
and IsBillable='Y' and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end  and CountryCode='US' 
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
--union
--select 'Total' as Total, SUM(logins) as Logins from
--(
--select COUNT(A.UserName) as Logins from 
--(
--select distinct UserName,AccountId,NetworkId from Fills
--where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 11 
--when month(getdate())=2 then 12
--else month(GETDATE())-2 end  and AxProductId in (20005,20997,20999)
--)A
--left join 
--(
--select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
--left join (select distinct State,country,SalesOffice from  RegionMap) R
--on u.CountryCode=r.Country and u.State=r.State
--where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 11 
--when month(getdate())=2 then 12
--else month(GETDATE())-2 end and CountryCode='US'
--union all
--select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
--left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
--on u.CountryCode=r.Country
--where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 11 
--when month(getdate())=2 then 12
--else month(GETDATE())-2 end and CountryCode<>'US' 
--)B
--on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
----where SalesOffice is not null
--group by SalesOffice
--)z
)p1
on p.SalesOffice=p1.SalesOffice
join
(

select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as Prior2Logins from 
(
select distinct UserName,AccountId,NetworkId from Fills
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and AxProductId in (20005,20997,20999)
and IsBillable='Y' and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
--union
--select 'Total' as Total, SUM(logins) as Logins from
--(
--select COUNT(A.UserName) as Logins from 
--(
--select distinct UserName,AccountId,NetworkId from Fills
--where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 10 
--when month(getdate())=2 then 11
--when month(getdate())=3 then 12
--else month(GETDATE())-3 end and AxProductId in (20005,20997,20999)
--)A
--left join 
--(
--select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
--left join (select distinct State,country,SalesOffice from  RegionMap) R
--on u.CountryCode=r.Country and u.State=r.State
--where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 10 
--when month(getdate())=2 then 11
--when month(getdate())=3 then 12
--else month(GETDATE())-3 end and CountryCode='US'
--union all
--select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
--left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
--on u.CountryCode=r.Country
--where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
--and MONTH=case 
--when month(getdate())=1 then 10 
--when month(getdate())=2 then 11
--when month(getdate())=3 then 12
--else month(GETDATE())-3 end and CountryCode<>'US' 
--)B
--on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
----where SalesOffice is not null
--group by SalesOffice
--)z
)p2
on p.SalesOffice=p2.SalesOffice

UNION ALL
----------------------For ToTals------------------
select 'Total' as Total, SUM(AvgofTradedLoginsForLast3Months)
from
(
select p.SalesOffice,(PriorLogins+Prior1Logins+Prior2Logins)/3 as AvgofTradedLoginsForLast3Months from
(
select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as PriorLogins from 
(
select distinct UserName,AccountId,NetworkId from Fills
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and AxProductId in (20005,20997,20999)
and IsBillable='Y' and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and CountryCode='US' and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case when month(getdate())=1 then 12 else month(GETDATE())-1 end 
and CountryCode<>'US' and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
)p
join
(

select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as Prior1Logins from 
(
select distinct UserName,AccountId,NetworkId from Fills
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end  and AxProductId in (20005,20997,20999)
and IsBillable='Y' and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end  and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate()) in (1,2) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 11 
when month(getdate())=2 then 12
else month(GETDATE())-2 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
)p1
on p.SalesOffice=p1.SalesOffice
join
(

select isnull(SalesOffice,'Unassigned') as SalesOffice, COUNT(A.UserName) as Prior2Logins from 
(
select distinct UserName,AccountId,NetworkId from Fills
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and AxProductId in (20005,20997,20999)
and NetworkId not in (577, 624)
)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and CountryCode='US'
and NetworkId not in (577, 624)
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR= case when month(getdate()) in (1,2,3) then YEAR(getdate())-1 else year(getdate()) end
and MONTH=case 
when month(getdate())=1 then 10 
when month(getdate())=2 then 11
when month(getdate())=3 then 12
else month(GETDATE())-3 end and CountryCode<>'US' 
and NetworkId not in (577, 624)
)B 
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice
)p2
on p.SalesOffice=p2.SalesOffice
)T
)O
on m.SalesOffice=o.salesoffice
)Logins
left join
(SELECT  distinct [Region] ,[SalesOffice] FROM [BIDW].[dbo].[RegionMap]) Region
on Logins.SalesOffice=Region.SalesOffice
--order by isnull(Region,'Unassigned'),SalesOfficeSort ASC






GO


 