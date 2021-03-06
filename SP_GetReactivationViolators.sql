USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetReactivationViolators]    Script Date: 2/5/2015 2:35:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetReactivationViolators] 

AS
BEGIN

Declare @PriorYear int, @PriorMonth Int,@PriorPriorYear int,@PriorPriorMonth Int
Set @PriorYear= case when Month(getdate())=1 then year(getdate())-1 else year(getdate()) end
Set @PriorMonth = case when Month(getdate())=1 then 12 else month(getdate())-1 end
Set @PriorPrioryear = case when @PriorMonth=1 then @PriorYear-1 else @PriorYear end 
Set @PriorPriorMonth = case when @PriorMonth=1 then 12 else @PriorMonth-1 end

Create table #upgrade
(SALESID nvarchar(200),customer nvarchar(200),NAME nvarchar(200),ZipCode nvarchar(200),City nvarchar(200),State nvarchar(200),Country nvarchar(200),PriceGroupId nvarchar(200),DELIVERYNAME nvarchar(200),TTDESCRIPTION nvarchar(200),
SALESPRICE float(53),TTBILLSTART datetime,TTBILLEND datetime,TTCONVERSIONDATE datetime,TTNOTES nvarchar(640),LineRecId bigint,row int
)

insert into #upgrade
select z.SalesID,y.NAME as Customer,z.Name,z.DELIVERYZIPCODE as ZipCode,z.DELIVERYCITY as City,z.DELIVERYSTATE as State, z.DELIVERYCOUNTRYREGIONID as Country,z.PriceGroupID,z.DeliveryName,z.TTDescription,z.SalesPrice,z.TTBillStart,z.TTBILLEND,y.TTCONVERSIONDATE,z.TTNotes,z.LineRecId,z.Row
from
(
select a.SALESID
	   , a.NAME
	   , a.DELIVERYZIPCODE
	   ,a.DELIVERYCITY
	   ,a.DELIVERYSTATE
	   ,a.DELIVERYCOUNTRYREGIONID
	   ,st.CUSTACCOUNT
	   ,st.PriceGroupId
	   --, a.ITEMGROUPID
	   , a.DELIVERYNAME
	   , a.TTDESCRIPTION
	   --, a.SALESTYPE 
	   ,a.SALESPRICE
	   , a.TTBILLSTART
	   , a.TTBILLEND 	 
	   , a.TTNOTES
	   , a.recid as LineRecId
	   ,ROW_NUMBER() Over (Partition by a.DeliveryName order by ttbillstart desc,ttbillend desc)as row	   
	   from chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE a join chiaxsql01.TT_DYANX09_PRD.dbo.SALESTABLE st
	   on a.SALESID = st.SALESID
  where a.SALESTYPE = 2
	 	AND st.PRICEGROUPID = 'Stndrdized'
	 
	    AND a.ITEMID IN (20200) 
	   
	  	    )z 
	    join chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE y
	    on z.CUSTACCOUNT=y.ACCOUNTNUM 
	     
	
create table #tempupgrade
( salesid nvarchar(200),Customer nvarchar(200),deliveryname nvarchar(200),pricegroupid nvarchar(200), ttdescription nvarchar(200),name nvarchar(200),
salesprice float(53),previousstart datetime,previousend datetime,reactivationdate datetime,Zipcode nvarchar(200),City nvarchar(200),[State] nvarchar(200),Country nvarchar(200),TTCONVERSIONDATE datetime,ttnotes nvarchar(640),
LineRecId bigint,ttdiff int, Daysleft int, DaysinMnth int)


insert into #tempupgrade
 select R2.SALESID
,R2.Customer 
, R2.DELIVERYNAME
  , R2.PRICEGROUPID
  , R2.TTDESCRIPTION
  , R2.NAME
  , R1.SALESPRICE
  , R2.TTBILLSTART as PreviousStart
  , R2.TTBILLEND as PreviousEnd
  , R1.TTBILLSTART as Reactivationdate
  , R1.ZipCode
  ,R1.City
   ,R1.[State]
   ,R1.Country
  , R2.TTCONVERSIONDATE
   , R2.TTNOTES
   , R2.LineRecId
   , DATEDIFF(D,R2.TTBillEnd,R1.TTBillStart)-1 as ttdiff 
	  ,datediff(DAY,R2.TTBILLEND,R1.TTBILLSTART) as DaysLeft
	  , datediff(day, R2.TTBILLEND+1, dateadd(month, 1, R2.TTBILLEND+1)) as DaysinMnth   -- <Ram 1/10/2014 11:30AM> Updated Code to Handle February Leap/NonLeap Years - Jira BI-81
	--,CASE when MONTH(R2.TTBILLEND+1) In (1,3,5,7,8,10,12) then 31 else 30 end as DaysinMnth
  	    from #upgrade as R1
    Inner Join #upgrade as R2
on R1.DELIVERYNAME = R2.DELIVERYNAME 
and R1.row = R2.row-1
and DATEDIFF(D,R2.TTBillEnd,R1.TTBillStart) between 2 and 29
and DATEDIFF (DAY,R1.TTBILLSTART,GETDATE()) <= 40
where R2.TTBILLEND>=R2.TTCONVERSIONDATE-1
 Order By R1.TTBILLSTART desc

 

Create table #cancel
(SALESID nvarchar(200),customer nvarchar(200),NAME nvarchar(200),ZipCode nvarchar(200),City nvarchar(200),State nvarchar(200),Country nvarchar(200),PriceGroupId nvarchar(200),DELIVERYNAME nvarchar(200),TTDESCRIPTION nvarchar(200),
SALESPRICE float(53),TTBILLSTART datetime,TTBILLEND datetime,TTCONVERSIONDATE datetime, TTNOTES nvarchar(640),LineRecId Bigint,row int)

insert into #cancel
select z.SalesID,y.NAME as Customer,z.Name,z.DELIVERYZIPCODE as ZipCode,z.DELIVERYCITY as City,z.DELIVERYSTATE as State, z.DELIVERYCOUNTRYREGIONID as Country,z.PriceGroupID,z.DeliveryName,z.TTDescription,z.SalesPrice,z.TTBillStart,z.TTBILLEND,y.TTCONVERSIONDATE,z.TTNotes,z.LineRecId,z.Row
from
(
select a.SALESID
	   , a.NAME
	   , a.DELIVERYZIPCODE
	   ,a.DELIVERYCITY
	   ,a.DELIVERYSTATE
	   ,a.DELIVERYCOUNTRYREGIONID
	   ,st.CUSTACCOUNT
	   ,st.PriceGroupId
	   , a.DELIVERYNAME
	   , a.TTDESCRIPTION
	   --, a.SALESTYPE 
	   ,a.SALESPRICE
	   , a.TTBILLSTART
	   , a.TTBILLEND 	 
	   , a.TTNOTES
	   , a.recid as LineRecId
	   ,ROW_NUMBER() Over (Partition by a.DeliveryName order by ttbillstart desc,ttbillend desc)as row	   
	   from chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE a join chiaxsql01.TT_DYANX09_PRD.dbo.SALESTABLE st
	   on a.SALESID = st.SALESID
  where a.SALESTYPE = 2
	 	AND st.PRICEGROUPID = 'Stndrdized'
	    AND a.ITEMID IN (20000,20200)
	    	--and a.ITEMGROUPID in ('RevTrade','RevGW')
	    )z 
	    join chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE y
	    on z.CUSTACCOUNT=y.ACCOUNTNUM 
	

Create table #tempcancel
( salesid nvarchar(200),Customer nvarchar(200),deliveryname nvarchar(200),pricegroupid nvarchar(200), ttdescription nvarchar(200),name nvarchar(200),
salesprice float(53),previousstart datetime,previousend datetime, reactivationdate datetime,Zipcode nvarchar(200),City nvarchar(200),[State] nvarchar(200),Country nvarchar(200),TTCONVERSIONDATE datetime, ttnotes nvarchar(640),
LineRecId bigint,ttdiff int, daysleft int, daysinmnth int
)

insert into #tempcancel
 select R2.SALESID
,R2.Customer 
, R2.DELIVERYNAME
  , R2.PRICEGROUPID
  , R2.TTDESCRIPTION
  , R2.NAME
  , R1.SALESPRICE
  , R2.TTBILLSTART as PreviousStart
  , R2.TTBILLEND as PreviousEnd
  , R1.TTBILLSTART as Reactivationdate
  , R1.ZipCode
  ,R1.City
   ,R1.[State]
   ,R1.Country
  , R2.TTCONVERSIONDATE
  , R2.TTNOTES
  , R2.LineRecId
  , DATEDIFF(D,R2.TTBillEnd,R1.TTBillStart)-1 as ttdiff 
  ,datediff(DAY,R2.TTBILLEND,R1.TTBILLSTART) as DaysLeft
  , datediff(day, R2.TTBILLEND+1, dateadd(month, 1, R2.TTBILLEND+1)) as DaysinMnth  -- <Ram 1/10/2014 11:30AM> Updated Code to Handle February Leap/NonLeap Years - Jira BI-81
	--,CASE when MONTH(R2.TTBILLEND+1) In (1,3,5,7,8,10,12) then 31 else 30 end as DaysinMnth 
	   from #cancel as R1
 Inner Join #cancel as R2
on R1.DELIVERYNAME = R2.DELIVERYNAME 
and R1.row = R2.row-1
and DATEDIFF(D,R2.TTBillEnd,R1.TTBillStart) between 2 and 29
and DATEDIFF (DAY,R1.TTBILLSTART,GETDATE()) <= 40
where R2.TTBILLEND>=R2.TTCONVERSIONDATE-1
  Order By R1.TTBILLSTART desc

	
Create table #cancel_xtrader
(SALESID nvarchar(200),customer nvarchar(200),NAME nvarchar(200),ZipCode nvarchar(200),City nvarchar(200),State nvarchar(200),Country nvarchar(200),PriceGroupId nvarchar(200),DELIVERYNAME nvarchar(200),TTDESCRIPTION nvarchar(200),
SALESPRICE float(53),TTBILLSTART datetime,TTBILLEND datetime,TTCONVERSIONDATE datetime,TTNOTES nvarchar(640),LineRecId Bigint,row int)

insert into #cancel_xtrader
select z.SalesID,y.NAME as Customer,z.Name,z.DELIVERYZIPCODE as ZipCode,z.DELIVERYCITY as City,z.DELIVERYSTATE as State, z.DELIVERYCOUNTRYREGIONID as Country,z.PriceGroupID,z.DeliveryName,z.TTDescription,z.SalesPrice,z.TTBillStart,z.TTBILLEND,y.TTCONVERSIONDATE,z.TTNotes,z.LineRecId,z.Row
from
(
select a.SALESID
	   , a.NAME
	    , a.DELIVERYZIPCODE
	   ,a.DELIVERYCITY
	   ,a.DELIVERYSTATE
	   ,a.DELIVERYCOUNTRYREGIONID
	   ,st.CUSTACCOUNT
	   ,st.PriceGroupId
	   , a.DELIVERYNAME
	   , a.TTDESCRIPTION
	   --, a.SALESTYPE 
	   ,a.SALESPRICE
	   , a.TTBILLSTART
	   , a.TTBILLEND 	 
	   , a.TTNOTES
	   , a.recid as LineRecId
	   ,ROW_NUMBER() Over (Partition by a.DeliveryName order by ttbillstart desc,ttbillend desc)as row	   
	   from chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE a join chiaxsql01.TT_DYANX09_PRD.dbo.SALESTABLE st
	   on a.SALESID = st.SALESID
  where a.SALESTYPE = 2
	 	AND st.PRICEGROUPID = 'Stndrdized'
	    AND a.ITEMID IN (20000)
	    )z 
	    join chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE y
	    on z.CUSTACCOUNT=y.ACCOUNTNUM
	   
	
  

create table #tempcancel_xtrader
( salesid nvarchar(200),Customer nvarchar(200),deliveryname nvarchar(200),pricegroupid nvarchar(200), ttdescription nvarchar(200),name nvarchar(200),
salesprice float(53),previousstart datetime,previousend datetime, reactivationdate datetime,Zipcode nvarchar(200),City nvarchar(200),[State] nvarchar(200),Country nvarchar(200),TTCONVERSIONDATE datetime, ttnotes nvarchar(640),
LineRecid bigint,ttdiff int, daysleft int, daysinmnth int
)

insert into #tempcancel_xtrader
 select R2.SALESID
,R2.Customer 
, R2.DELIVERYNAME
  , R2.PRICEGROUPID
  , R2.TTDESCRIPTION
  , R2.NAME
  , R1.SALESPRICE
  , R2.TTBILLSTART as PreviousStart
  , R2.TTBILLEND as PreviousEnd
  , R1.TTBILLSTART as Reactivationdate
   , R1.ZipCode
  ,R1.City
   ,R1.[State]
   ,R1.Country
  , R2.TTCONVERSIONDATE
  , R2.TTNOTES
  , R2.LineRecId
  , DATEDIFF(D,R2.TTBillEnd,R1.TTBillStart)-1 as ttdiff
  ,datediff(DAY,R2.TTBILLEND,R1.TTBILLSTART) as DaysLeft
  ,datediff(day, R2.TTBILLEND+1, dateadd(month, 1, R2.TTBILLEND+1)) as DaysinMnth  -- <Ram 1/10/2014 11:30AM> Updated Code to Handle February Leap/NonLeap Years - Jira BI-81
  --,CASE when MONTH(R2.TTBILLEND+1) In (1,3,5,7,8,10,12) then 31 else 30 end as DaysinMnth 
  from #cancel_xtrader as R1
 Inner Join #cancel_xtrader as R2
on R1.DELIVERYNAME = R2.DELIVERYNAME 
and R1.row = R2.row-1
and DATEDIFF(D,R2.TTBillEnd,R1.TTBillStart) between 2 and 29
and DATEDIFF (DAY,R1.TTBILLSTART,GETDATE()) <= 40
where R2.TTBILLEND>=R2.TTCONVERSIONDATE-1
  Order By R1.TTBILLSTART desc



Create table #gateway
(SALESID nvarchar(200),customer nvarchar(200),NAME nvarchar(200),ZipCode nvarchar(200),City nvarchar(200),State nvarchar(200),Country nvarchar(200),PriceGroupId nvarchar(200),DELIVERYNAME nvarchar(200),TTDESCRIPTION nvarchar(200),
SALESPRICE float(53),TTBILLSTART datetime,TTBILLEND datetime,TTCONVERSIONDATE datetime, TTNOTES nvarchar(640),LineRecId Bigint,row int)

insert into #gateway
select z.SalesID,y.NAME as Customer,z.Name,z.DELIVERYZIPCODE as ZipCode,z.DELIVERYCITY as City,z.DELIVERYSTATE as State, z.DELIVERYCOUNTRYREGIONID as Country,z.PriceGroupID,z.DeliveryName,z.TTDescription,z.SalesPrice,z.TTBillStart,z.TTBILLEND,y.TTCONVERSIONDATE,z.TTNotes,LineRecId,z.Row
from
(
select a.SALESID
	   , a.NAME
	   , a.DELIVERYZIPCODE
	   ,a.DELIVERYCITY
	   ,a.DELIVERYSTATE
	   ,a.DELIVERYCOUNTRYREGIONID
	   ,st.CUSTACCOUNT
	   ,st.PriceGroupId
	   , a.DELIVERYNAME
	   , a.TTDESCRIPTION
	   --, a.SALESTYPE 
	   ,a.SALESPRICE
	   , a.TTBILLSTART
	   , a.TTBILLEND 	 
	   , a.TTNOTES
	   , a.recid as LineRecId
	   ,ROW_NUMBER() Over (Partition by a.DeliveryName,a.TTDescription order by ttbillstart desc,ttbillend desc)as row	   
	   from chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE a join chiaxsql01.TT_DYANX09_PRD.dbo.SALESTABLE st
	   on a.SALESID = st.SALESID
  where a.SALESTYPE = 2
	 	AND st.PRICEGROUPID = 'Stndrdized'
	    --AND a.ITEMID IN (20000,20200)
	    	and a.ITEMGROUPID ='RevGW'
	    )z 
	    join chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE y
	    on z.CUSTACCOUNT=y.ACCOUNTNUM 
	

Create table #tempgateway
( salesid nvarchar(200),Customer nvarchar(200),deliveryname nvarchar(200),pricegroupid nvarchar(200), ttdescription nvarchar(200),name nvarchar(200),
salesprice float(53),previousstart datetime,previousend datetime, reactivationdate datetime,Zipcode nvarchar(200),City nvarchar(200),[State] nvarchar(200),Country nvarchar(200),TTCONVERSIONDATE datetime, ttnotes nvarchar(640),
LineRecId Bigint,ttdiff int, daysleft int, daysinmnth int
)

insert into #tempgateway
 select R2.SALESID
,R2.Customer 
, R2.DELIVERYNAME
  , R2.PRICEGROUPID
  , R2.TTDESCRIPTION
  , R2.NAME
  , R1.SALESPRICE
  , R2.TTBILLSTART as PreviousStart
  , R2.TTBILLEND as PreviousEnd
  , R1.TTBILLSTART as Reactivationdate
  , R1.ZipCode
  ,R1.City
   ,R1.[State]
   ,R1.Country
  , R2.TTCONVERSIONDATE
  , R2.TTNOTES
  , R2.LineRecId
  , DATEDIFF(D,R2.TTBillEnd,R1.TTBillStart)-1 as ttdiff 
  ,datediff(DAY,R2.TTBILLEND,R1.TTBILLSTART) as DaysLeft
  ,datediff(day, R2.TTBILLEND+1, dateadd(month, 1, R2.TTBILLEND+1)) as DaysinMnth  -- <Ram 1/10/2014 11:30AM> Updated Code to Handle February Leap/NonLeap Years - Jira BI-81
  --,CASE when MONTH(R2.TTBILLEND+1) In (1,3,5,7,8,10,12) then 31 else 30 end as DaysinMnth 
	   from #gateway as R1
 Inner Join #gateway as R2
on R1.DELIVERYNAME = R2.DELIVERYNAME and R1.TTDESCRIPTION = R2.TTDESCRIPTION
and R1.row = R2.row-1
and DATEDIFF(D,R2.TTBillEnd,R1.TTBillStart) between 2 and 29
and DATEDIFF (DAY,R1.TTBILLSTART,GETDATE()) <= 40
where R2.TTBILLEND>=R2.TTCONVERSIONDATE-1
  Order By R1.TTBILLSTART desc


----------------------------------Final Query Code---------------------------------------------------


---------------------- For Prior Month New Start Date Non Upgrades ----------------------------------------------------------------
Select mon.Salesid ,mon.Customer ,mon.Deliveryname ,mon.pricegroupid , mon.ttdescription ,mon.ProductName ,
mon.salesprice, mon.ReactivationCharge+isnull(pmon.ReactivationCharge,0) as ReactivationCharge,mon.PreviousStartDate ,mon.PreviousEndDate , mon.NewStartDate ,
mon.Zipcode ,mon.City ,mon.[State] ,mon.Country ,mon.ViolationType , mon.GapinDays , mon.ttnotes from
(
Select x.Salesid ,Customer ,x.Deliveryname ,pricegroupid , x.ttdescription ,ProductName ,
salesprice, SalesPrice-Revenue as ReactivationCharge,PreviousStartDate ,PreviousEndDate , NewStartDate ,
Zipcode ,City ,[State] ,Country ,ViolationType , GapinDays , ttnotes
from
(
select c.SalesId,C.LineRecId,C.Customer,C.DeliveryName,c.PriceGroupID,c.TTDescription,c.Name as ProductName, c.SalesPrice,previousstart as PreviousStartDate, 
c.previousend as PreviousEndDate, c.Reactivationdate as NewStartDate,c.Zipcode,c.City,c.[State],c.Country,c.TTCONVERSIONDATE,c.TTNotes,case when flag=1 then 'Upgrade' else 'Cancellation' end as ViolationType,
c.ttdiff as GapinDays, case when month(c.previousend)=month(c.reactivationdate) then 0 else datediff(d,c.PreviousEnd,(SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.PreviousEnd)+1,0)))) end as GapPreviousMonth
,  datediff(d,(SELECT DATEADD(m,DATEDIFF(m,0,c.Reactivationdate),0)),c.Reactivationdate) as GapCurrentMonth
,c.DaysinMnth,(SELECT DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, c.PreviousEnd) + 1, 0))) as PrevEndate
,datediff(day, c.PreviousEnd+1, dateadd(month, 1, c.PreviousEnd+1)) as x
,case when cast(c.Reactivationdate as date)=(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))
then datepart(dd,(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))) else
datediff(day, c.Reactivationdate+1, dateadd(month, 1, c.Reactivationdate+1)) end as y
, (SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(c.Reactivationdate)-1),c.Reactivationdate),101)) as ReacStartDate
from
(
select a.*,1 as flag from
(
select * from #tempupgrade
except
select * from #tempcancel
)a
union
select b.*,0 as flag from
(
select * from #tempcancel 
intersect
select * from #tempupgrade
)b
union
select d.*,0 as flag from
(
select * from #tempcancel_xtrader
intersect
select * from #tempcancel

)d
union
select e.*,0 as flag from
(
select * from #tempgateway
)e
)C
where year(c.Reactivationdate)=@PriorYear and month(c.Reactivationdate)=@PriorMonth
)X 
join
(
select SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION,sum(billedamount) as Revenue  from MonthlyBillingData
where year=@PriorYear and month=@PriorMonth
--and DELIVERYNAME='FC - Cofsky, Kevin: 50078'
and productsku in (20000,20200)
group by SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION
) Y
on x.salesid=y.SalesId and x.deliveryname=y.DELIVERYNAME
where x.deliveryname not in 
(
select distinct deliveryname from MonthlyBillingData
where YEAR =@PriorYear
and MONTH = @PriorMonth
and ProductSku in (20006,20007)
)
)Mon
left join 
(

Select x.Salesid ,Customer ,x.Deliveryname ,pricegroupid , x.ttdescription ,ProductName ,
salesprice, case when violationtype='Upgrade' then (GapinDays/DaysinMnth)*1200 else
SalesPrice-Revenue end as ReactivationCharge, -- Added logic to handle Upgrade Violations when spanned between two months
PreviousStartDate ,PreviousEndDate , NewStartDate ,
Zipcode ,City ,[State] ,Country ,ViolationType , GapinDays , ttnotes
from
(
select c.SalesId,C.LineRecId,C.Customer,C.DeliveryName,c.PriceGroupID,c.TTDescription,c.Name as ProductName, c.SalesPrice,previousstart as PreviousStartDate, 
c.previousend as PreviousEndDate, c.Reactivationdate as NewStartDate,c.Zipcode,c.City,c.[State],c.Country,c.TTCONVERSIONDATE,c.TTNotes,case when flag=1 then 'Upgrade' else 'Cancellation' end as ViolationType,
c.ttdiff as GapinDays, case when month(c.previousend)=month(c.reactivationdate) then 0 else datediff(d,c.PreviousEnd,(SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.PreviousEnd)+1,0)))) end as GapPreviousMonth
,  datediff(d,(SELECT DATEADD(m,DATEDIFF(m,0,c.Reactivationdate),0)),c.Reactivationdate) as GapCurrentMonth
,c.DaysinMnth,(SELECT DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, c.PreviousEnd) + 1, 0))) as PrevEndate
,datediff(day, c.PreviousEnd+1, dateadd(month, 1, c.PreviousEnd+1)) as x
,case when cast(c.Reactivationdate as date)=(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))
then datepart(dd,(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))) else
datediff(day, c.Reactivationdate+1, dateadd(month, 1, c.Reactivationdate+1)) end as y
, (SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(c.Reactivationdate)-1),c.Reactivationdate),101)) as ReacStartDate
from
(
select a.*,1 as flag from
(
select * from #tempupgrade
except
select * from #tempcancel
)a
union
select b.*,0 as flag from
(
select * from #tempcancel 
intersect
select * from #tempupgrade
)b
union
select d.*,0 as flag from
(
select * from #tempcancel_xtrader
intersect
select * from #tempcancel

)d
union
select e.*,0 as flag from
(
select * from #tempgateway
)e
)C
where year(c.previousend)=@PriorPrioryear and month(c.previousend)=@PriorPriorMonth
)X 
join
(
select SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION,sum(billedamount) as Revenue  from MonthlyBillingData
where year=@PriorPrioryear and month=@PriorPriorMonth
--and DELIVERYNAME='FC - Cofsky, Kevin: 50078'
and productsku in (20000,20200)
group by SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION
) Y
on x.salesid=y.SalesId and x.deliveryname=y.DELIVERYNAME
where x.deliveryname not in 
(
select distinct deliveryname from MonthlyBillingData
where YEAR =@PriorPrioryear
and MONTH = @PriorPriorMonth
and ProductSku in (20006,20007)
)

)Pmon
on mon.deliveryname=Pmon.deliveryname
where mon.ViolationType='Cancellation'

UNION all

---------------------For Current Month New Start Date Non Upgrades --------------------------------------
Select x.Salesid ,Customer ,x.Deliveryname ,pricegroupid , x.ttdescription ,ProductName ,
salesprice, SalesPrice-Revenue as ReactivationCharge,PreviousStartDate ,PreviousEndDate , NewStartDate ,
Zipcode ,City ,[State] ,Country ,ViolationType , GapinDays , ttnotes
from
(
select c.SalesId,C.LineRecId,C.Customer,C.DeliveryName,c.PriceGroupID,c.TTDescription,c.Name as ProductName, c.SalesPrice,previousstart as PreviousStartDate, 
c.previousend as PreviousEndDate, c.Reactivationdate as NewStartDate,c.Zipcode,c.City,c.[State],c.Country,c.TTCONVERSIONDATE,c.TTNotes,case when flag=1 then 'Upgrade' else 'Cancellation' end as ViolationType,
c.ttdiff as GapinDays, case when month(c.previousend)=month(c.reactivationdate) then 0 else datediff(d,c.PreviousEnd,(SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.PreviousEnd)+1,0)))) end as GapPreviousMonth
,  datediff(d,(SELECT DATEADD(m,DATEDIFF(m,0,c.Reactivationdate),0)),c.Reactivationdate) as GapCurrentMonth
,c.DaysinMnth,(SELECT DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, c.PreviousEnd) + 1, 0))) as PrevEndate
,datediff(day, c.PreviousEnd+1, dateadd(month, 1, c.PreviousEnd+1)) as x
,case when cast(c.Reactivationdate as date)=(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))
then datepart(dd,(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))) else
datediff(day, c.Reactivationdate+1, dateadd(month, 1, c.Reactivationdate+1)) end as y
, (SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(c.Reactivationdate)-1),c.Reactivationdate),101)) as ReacStartDate
from
(
select a.*,1 as flag from
(
select * from #tempupgrade
except
select * from #tempcancel
)a
union
select b.*,0 as flag from
(
select * from #tempcancel 
intersect
select * from #tempupgrade
)b
union
select d.*,0 as flag from
(
select * from #tempcancel_xtrader
intersect
select * from #tempcancel

)d
union
select e.*,0 as flag from
(
select * from #tempgateway
)e
)C
where year(c.Reactivationdate)=year(getdate()) and month(c.Reactivationdate)=month(getdate())
)X 
join
(
select SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION,sum(billedamount) as Revenue  from MonthlyBillingData
where year=year(getdate()) and month=month(getdate())
--and DELIVERYNAME='FC - Cofsky, Kevin: 50078'
and productsku in (20000,20200)
group by SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION
) Y
on x.salesid=y.SalesId and x.deliveryname=y.DELIVERYNAME
where x.deliveryname not in 
(
select distinct deliveryname from MonthlyBillingData
where YEAR =year(getdate())
and MONTH = month(getdate())
and ProductSku in (20006,20007)
) and ViolationType='Cancellation'

UNION ALL
--------------------------------------------------------------For Upgrade Violation New Start Date--------------------------------

Select x.Salesid ,Customer ,x.Deliveryname ,pricegroupid , x.ttdescription ,ProductName ,
salesprice, Topay as ReactivationCharge,PreviousStartDate ,PreviousEndDate , NewStartDate ,
Zipcode ,City ,[State] ,Country ,ViolationType , GapinDays , ttnotes
from
(
select c.SalesId,C.LineRecId,C.Customer,C.DeliveryName,c.PriceGroupID,c.TTDescription,c.Name as ProductName, c.SalesPrice,previousstart as PreviousStartDate, 
c.previousend as PreviousEndDate, c.Reactivationdate as NewStartDate,c.Zipcode,c.City,c.[State],c.Country,c.TTCONVERSIONDATE,c.TTNotes,case when flag=1 then 'Upgrade' else 'Cancellation' end as ViolationType,
c.ttdiff as GapinDays, case when month(c.previousend)=month(c.reactivationdate) then 0 else datediff(d,c.PreviousEnd,(SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.PreviousEnd)+1,0)))) end as GapPreviousMonth
,  datediff(d,(SELECT DATEADD(m,DATEDIFF(m,0,c.Reactivationdate),0)),c.Reactivationdate) as GapCurrentMonth
,c.DaysinMnth,(SELECT DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, c.PreviousEnd) + 1, 0))) as PrevEndate
,datediff(day, c.PreviousEnd+1, dateadd(month, 1, c.PreviousEnd+1)) as x
,case when cast(c.Reactivationdate as date)=(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))
then datepart(dd,(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))) else
datediff(day, c.Reactivationdate+1, dateadd(month, 1, c.Reactivationdate+1)) end as y
, (SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(c.Reactivationdate)-1),c.Reactivationdate),101)) as ReacStartDate
from
(
select a.*,1 as flag from
(
select * from #tempupgrade
except
select * from #tempcancel
)a
union
select b.*,0 as flag from
(
select * from #tempcancel 
intersect
select * from #tempupgrade
)b
union
select d.*,0 as flag from
(
select * from #tempcancel_xtrader
intersect
select * from #tempcancel

)d
union
select e.*,0 as flag from
(
select * from #tempgateway
)e
)C
where year(c.Reactivationdate)=year(getdate()) and month(c.Reactivationdate)=month(getdate())
)X 
join
(
Select cur.SalesId,cur.Accountid, cur.DELIVERYNAME,cur.PriceGroupDesc,cur.TTDESCRIPTION,cur.Topay+pr.Topay as Topay from
(
select SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION,sum(billedamount) as Revenue,sum(ttusage) as TTusage,sum(ttusage)*1200-sum(billedamount) as Topay from MonthlyBillingData
where year=year(getdate()) and month=month(getdate())
--and DELIVERYNAME='FC - Kosson, Jason: PIOKOSS0'
and productsku in (20000)
group by SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION
)cur join
(
select SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION,sum(billedamount) as Revenue,sum(ttusage) as TTusage,sum(ttusage)*1200-sum(billedamount) as Topay from MonthlyBillingData
where year=@PriorYear and month=@PriorMonth
--and DELIVERYNAME='FC - Kosson, Jason: PIOKOSS0'
and productsku in (20000)
group by SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION
)pr
on cur.SalesId=pr.SalesId and cur.DELIVERYNAME=pr.DELIVERYNAME
) Y
on x.salesid=y.SalesId and x.deliveryname=y.DELIVERYNAME
where x.deliveryname not in 
(
select distinct deliveryname from MonthlyBillingData
where YEAR =year(getdate())
and MONTH = month(getdate())
and ProductSku in (20006,20007)
) and ViolationType='Upgrade'

UNION ALL
--------------------------------------------------------------For Upgrade Violation Prior Month Start Date--------------------------------

Select x.Salesid ,Customer ,x.Deliveryname ,pricegroupid , x.ttdescription ,ProductName ,
salesprice, Topay as ReactivationCharge,PreviousStartDate ,PreviousEndDate , NewStartDate ,
Zipcode ,City ,[State] ,Country ,ViolationType , GapinDays , ttnotes
from
(
select c.SalesId,C.LineRecId,C.Customer,C.DeliveryName,c.PriceGroupID,c.TTDescription,c.Name as ProductName, c.SalesPrice,previousstart as PreviousStartDate, 
c.previousend as PreviousEndDate, c.Reactivationdate as NewStartDate,c.Zipcode,c.City,c.[State],c.Country,c.TTCONVERSIONDATE,c.TTNotes,case when flag=1 then 'Upgrade' else 'Cancellation' end as ViolationType,
c.ttdiff as GapinDays, case when month(c.previousend)=month(c.reactivationdate) then 0 else datediff(d,c.PreviousEnd,(SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.PreviousEnd)+1,0)))) end as GapPreviousMonth
,  datediff(d,(SELECT DATEADD(m,DATEDIFF(m,0,c.Reactivationdate),0)),c.Reactivationdate) as GapCurrentMonth
,c.DaysinMnth,(SELECT DATEADD(d, -1, DATEADD(m, DATEDIFF(m, 0, c.PreviousEnd) + 1, 0))) as PrevEndate
,datediff(day, c.PreviousEnd+1, dateadd(month, 1, c.PreviousEnd+1)) as x
,case when cast(c.Reactivationdate as date)=(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))
then datepart(dd,(SELECT cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,c.Reactivationdate)+1,0)) as DATE))) else
datediff(day, c.Reactivationdate+1, dateadd(month, 1, c.Reactivationdate+1)) end as y
, (SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(c.Reactivationdate)-1),c.Reactivationdate),101)) as ReacStartDate
from
(
select a.*,1 as flag from
(
select * from #tempupgrade
except
select * from #tempcancel
)a
union
select b.*,0 as flag from
(
select * from #tempcancel 
intersect
select * from #tempupgrade
)b
union
select d.*,0 as flag from
(
select * from #tempcancel_xtrader
intersect
select * from #tempcancel

)d
union
select e.*,0 as flag from
(
select * from #tempgateway
)e
)C
where year(c.Reactivationdate)=@PriorYear and month(c.Reactivationdate)=@PriorMonth
)X 
join
(
Select cur.SalesId,cur.Accountid, cur.DELIVERYNAME,cur.PriceGroupDesc,cur.TTDESCRIPTION,cur.Topay+pr.Topay as Topay from
(
select SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION,sum(billedamount) as Revenue,sum(ttusage) as TTusage,sum(ttusage)*1200-sum(billedamount) as Topay from MonthlyBillingData
where year=year(getdate()) and month=month(getdate())
--and DELIVERYNAME='FC - Kosson, Jason: PIOKOSS0'
and productsku in (20000)
group by SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION
)cur join
(
select SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION,sum(billedamount) as Revenue,sum(ttusage) as TTusage,sum(ttusage)*1200-sum(billedamount) as Topay from MonthlyBillingData
where year=@PriorYear and month=@PriorMonth
--and DELIVERYNAME='FC - Kosson, Jason: PIOKOSS0'
and productsku in (20000)
group by SalesId,Accountid, DELIVERYNAME,PriceGroupDesc,TTDESCRIPTION
)pr
on cur.SalesId=pr.SalesId and cur.DELIVERYNAME=pr.DELIVERYNAME
) Y
on x.salesid=y.SalesId and x.deliveryname=y.DELIVERYNAME
where x.deliveryname not in 
(
select distinct deliveryname from MonthlyBillingData
where YEAR =year(getdate())
and MONTH = month(getdate())
and ProductSku in (20006,20007)
) and ViolationType='Upgrade'

drop table #upgrade
drop table #cancel
drop table #cancel_xtrader 
drop table #tempupgrade
drop table #tempcancel 
drop table #tempcancel_xtrader
drop table #gateway
drop table #tempgateway


END



















