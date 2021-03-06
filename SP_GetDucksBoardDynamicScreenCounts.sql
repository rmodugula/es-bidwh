USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetDucksBoardDynamicScreenCounts_test]    Script Date: 1/13/2015 10:44:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[GetDucksBoardDynamicScreenCounts]
     
AS
BEGIN

Declare @PriorYear int,@PriorMonth int,@Billingmonthclosedflag int 

Set @PriorYear = (select Year from (select *,row_number() over (order by id desc) as row from fillhub.dbo.InvoiceMonth)Q where ROW=1)
Set @PriorMonth = (select Month from (select *,row_number() over (order by id desc) as row from fillhub.dbo.InvoiceMonth)Q where ROW=1)
Set @Billingmonthclosedflag = case when (select Year from (select *,row_number() over (order by id desc) as row from fillhub.dbo.InvoiceMonth)Q where ROW=1)=  case when month(getdate())=1 then year(getdate())-1 else year(getdate()) end
and (select Month from (select *,row_number() over (order by id desc) as row from fillhub.dbo.InvoiceMonth)Q where ROW=1)=case when month(getdate())=1 then 12 else month(getdate())-1 end
then 1 else 0 end

Begin

Select SalesOffice,Screens,Adds,Cancels,Upgrades,Downgrades
from
(
Select prefinal.SalesOffice,
case when @Billingmonthclosedflag=0 or day(getdate())>25 then Screens else AdjScreens End as Screens,
case when @Billingmonthclosedflag=0 or day(getdate())>25 then Adds else AdjAdds End as Adds,
case when @Billingmonthclosedflag=0 or day(getdate())>25 then Cancels else AdjCancels End as Cancels,
case when @Billingmonthclosedflag=0 or day(getdate())>25 then Upgrades else AdjUpgrades End as Upgrades,
case when @Billingmonthclosedflag=0 or day(getdate())>25 then Downgrades else AdjDowngrades End as Downgrades,
--case when day(getdate())<=8 or day(getdate())>25 then Screens else AdjScreens End as Screens,
--case when day(getdate())<=8 or day(getdate())>25 then Adds else AdjAdds End as Adds,
--case when day(getdate())<=8 or day(getdate())>25 then Cancels else AdjCancels End as Cancels,
--case when day(getdate())<=8 or day(getdate())>25 then Upgrades else AdjUpgrades End as Upgrades,
--case when day(getdate())<=8 or day(getdate())>25 then Downgrades else AdjDowngrades End as Downgrades,
case prefinal.SalesOffice
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
end as SalesOfficeSort,isnull(Region,'Unassigned') as SalesRegion
from
(
select isnull(screen.SalesOffice,trx.SalesOffice) as SalesOffice,SUM(isnull(Screen.Screens,0)+isnull(trx.Screens,0)) as Screens,
SUM(isnull(Screen.Adds,0)+isnull(trx.Adds,0)) as Adds,SUM(isnull(Screen.Cancels,0)+isnull(trx.Cancels,0)) as Cancels,
SUM(isnull(Screen.Upgrades,0)+isnull(trx.Upgrades,0)) as Upgrades,SUM(isnull(Screen.Downgrades,0)+isnull(trx.Downgrades,0)) as Downgrades,
SUM(isnull(AdjScreen.AdjScreens,0)) as AdjScreens,SUM(isnull(adjScreen.AdjAdds,0)) as AdjAdds,SUM(isnull(AdjScreen.AdjCancels,0)) as AdjCancels,
SUM(isnull(AdjScreen.AdjUpgrades,0)) as AdjUpgrades,SUM(isnull(AdjScreen.AdjDowngrades,0)) as AdjDowngrades
from
(
select SalesOffice,SUM(CurrentLicenseCount) as Screens,sum(AddCount) as Adds,sum(CancelCount) as Cancels, SUM(upgradecount) as Upgrades, SUM(downgradecount) as Downgrades
from [bidw].dbo.[RevenueImpactReporting] 
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
and ProductName in ('X_TRADER®','X_TRADER® Pro','TT - Subscription','TT Pro - Subscription','TT - Transaction','TT Pro - Transaction')
group by SalesOffice 
UNION 
select 'Total' as Total,SUM(CurrentLicenseCount) as Screens,sum(AddCount) as Adds,sum(CancelCount) as Cancels, SUM(upgradecount) as Upgrades, SUM(downgradecount) as Downgrades 
from [bidw].dbo.[RevenueImpactReporting] 
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
and ProductName in ('X_TRADER®','X_TRADER® Pro','TT - Subscription','TT Pro - Subscription','TT - Transaction','TT Pro - Transaction')
)Screen
full Outer join
(
select SalesOffice, sum(case when counts='Screens' then ScreenCounts end) as Screens,
sum(case when counts='Adds' then ScreenCounts end) as Adds,
sum(case when counts='Cancels' then ScreenCounts end) as Cancels,
sum(case when counts='Upgrades' then ScreenCounts end) as Upgrades,
sum(case when counts='Downgrades' then ScreenCounts end) as Downgrades
 from 
(
select isnull(SalesOffice,'Unassigned') as SalesOffice, 
Case when Counts='Screens' then COUNT(A.UserName) else COUNT(distinct A.username) end as ScreenCounts,Counts
 from 
(
    Select networkid,username,AccountId, 'Screens' as Counts
    from 
    (
	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20997'
	)e
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20995'
	)e
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20993'
	)e
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20992'
	)e	
	)Screens
	 
	 Union All
	 
	 select distinct networkid,username,AccountId,'Adds' as Counts from
(
	
select * from
(	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20997'
	)e
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20995'
	)e
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20993'
	)e
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20992'
	)e	
)r
except 
select * from
(
select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
and isbillable='Y'
and AxProductId in ('20999') and NetworkId not in (577)
union all
select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
and isbillable='Y'
and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20997'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20995'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20993'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20992'
	)e	
)t
)f
Union All
select distinct networkid,username,AccountId,'Cancels' as Counts  from
(
	select * from
(
	select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20997'
	)e	
	union all
	select distinct networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20995'
	)e
	union all
	select distinct networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20993'
	)e	
	union all
	select distinct networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20992'
	)e	
)t

except 
select * from
(	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20997'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20995'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20993'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20992'
	)e	
)r
)g
UNION ALL
select distinct networkid,username,AccountId,'Upgrades' as Counts  from
(
	select distinct networkid,username,AccountId from fills F 
where YEAR= case when MONTH(getdate())=12 then YEAR(getdate())+1 else @PriorYear end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
and isbillable='Y' and AxProductId in ('20999','20997','20993') and NetworkId not in (577)
INTERSECT
select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
and isbillable='Y' and AxProductId in ('20005','20995','20992') and NetworkId not in (577)
)g

UNION ALL

select distinct networkid,username,AccountId,'Downgrades' as Counts  from
(
select distinct networkid,username,AccountId from fills F 
where YEAR= case when MONTH(getdate())=12 then YEAR(getdate())+1 else @PriorYear end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
and isbillable='Y' and AxProductId in ('20005','20995','20992') and NetworkId not in (577)
INTERSECT
select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
and isbillable='Y' and AxProductId in ('20999','20997','20993') and NetworkId not in (577)
)g

)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end and CountryCode='US'
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end  and CountryCode<>'US' 
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by SalesOffice,Counts
)A1
Group By SalesOffice
union
select 'Total' as Total, sum(Screens) as Screens,sum(Adds) as Adds, sum(Cancels) as Cancels,sum(Upgrades) as Upgrades,sum(Downgrades) as Downgrades from
(
select COUNT(case when counts='Screens' then A.UserName end) as Screens,
case when counts='Adds' then count(distinct A.UserName) end as Adds,
case when counts='Cancels' then count(distinct A.UserName) end as Cancels ,
case when counts='Upgrades' then count(distinct A.UserName) end as Upgrades ,
case when counts='Downgrades' then count(distinct A.UserName) end as Downgrades 
from 
(
	Select networkid,username,AccountId, 'Screens' as Counts
    from 
    (
	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20997'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20995'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20993'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20992'
	)e	
	)Screens
	 
	 Union All
	 
	 select distinct networkid,username,AccountId,'Adds' as Counts from
(
	select * from
(	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20997'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20995'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20993'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20992'
	)e	
)r
except 
select * from
(
	select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20997'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20995'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20993'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20992'
	)e	
)t
)f
Union All
select distinct networkid,username,AccountId,'Cancels' as Counts  from
(
	select * from
(
	select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20997'
	)e	
	union all
	select distinct networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20995'
	)e
	union all
	select distinct networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20993'
	)e
	union all
	select distinct networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
	and IsBillable='Y'
	and axproductid='20992'
	)e
)t

except 
select * from
(	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	union all
	select distinct networkid,username,AccountId from fills F 
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20997'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20995'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20993'
	)e	
	union all
	select networkid,username,AccountId from
	(
	select distinct username,BrokerId,AccountId,networkid from fills
	where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
	and IsBillable='Y'
	and axproductid='20992'
	)e	
)r
)g
UNION ALL
select distinct networkid,username,AccountId,'Upgrades' as Counts  from
(
	select distinct networkid,username,AccountId from fills F 
where YEAR= case when MONTH(getdate())=12 then YEAR(getdate())+1 else @PriorYear end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
and isbillable='Y' and AxProductId in ('20999','20997','20993') and NetworkId not in (577)
INTERSECT
select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
and isbillable='Y' and AxProductId in ('20005','20995','20992') and NetworkId not in (577)
)g

UNION ALL

select distinct networkid,username,AccountId,'Downgrades' as Counts  from
(
select distinct networkid,username,AccountId from fills F 
where YEAR= case when MONTH(getdate())=12 then YEAR(getdate())+1 else @PriorYear end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
and isbillable='Y' and AxProductId in ('20005','20995','20992') and NetworkId not in (577)
INTERSECT
select distinct networkid,username,AccountId from fills F 
where YEAR=@PriorYear 
and MONTH=@PriorMonth 
and isbillable='Y' and AxProductId in ('20999','20997','20993') and NetworkId not in (577)
)g

)A
left join 
(
select distinct UserName,AccountId,NetworkId,u.State,CountryCode,SalesOffice from [User] U
left join (select distinct State,country,SalesOffice from  RegionMap) R
on u.CountryCode=r.Country and u.State=r.State
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end  and CountryCode='US'
union all
select distinct UserName,AccountId,NetworkId,u.state,CountryCode,SalesOffice from [User] U
left join (select distinct country,SalesOffice from  RegionMap where State='Unassigned') R
on u.CountryCode=r.Country
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end and CountryCode<>'US' 
)B
on A.UserName=b.UserName and a.AccountId=b.AccountId and a.NetworkId=b.NetworkId
group by Counts
)z
)Trx
on Screen.SalesOffice=trx.SalesOffice
Full Outer join 
(
select SalesOffice,SUM(CurrentLicenseCount) as AdjScreens,sum(AddCount) as AdjAdds,sum(CancelCount) as AdjCancels ,
sum(UpgradeCount) as AdjUpgrades,sum(DowngradeCount) as AdjDowngrades
from [bidw].dbo.[RevenueImpactReporting] 
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
group by SalesOffice 
UNION 
select 'Total' as Total,SUM(CurrentLicenseCount) as AdjScreens,sum(AddCount) as AdjAdds,sum(CancelCount) as AdjCancels,
sum(UpgradeCount) as AdjUpgrades,sum(DowngradeCount) as AdjDowngrades
from [bidw].dbo.[RevenueImpactReporting] 
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=@PriorYear then  year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end)  end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=@PriorMonth then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
)AdjScreen
on screen.SalesOffice=AdjScreen.SalesOffice
group by screen.SalesOffice,trx.SalesOffice,AdjScreen.SalesOffice
)PreFinal
left join
(SELECT  distinct [Region] ,[SalesOffice] FROM [BIDW].[dbo].[RegionMap]) Region
on PreFinal.SalesOffice=Region.SalesOffice
)Final
where SalesOffice<>case when DAY(getdate())>25 then '' else 'Unassigned' end
Order by SalesOfficeSort ASC
END

END





