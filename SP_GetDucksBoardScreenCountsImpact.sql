USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetDucksBoardScreenCountsImpact]    Script Date: 07/10/2014 09:31:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetDucksBoardScreenCountsImpact]
     
AS
BEGIN

---------------------------------------------------QTD Query------------------------------------------------------------------
------------------------------------------------------------Temp table for Prior Quarter------------------------------------------------------------------------

Create table #tempQTD
(Accountid nvarchar(200),DELIVERYNAME nvarchar(200),productsku nvarchar(200),LineAmount float(50),BilledAmount float (50),LicenseCount int
,ttbillend datetime,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime )

insert into #tempQTD
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,a.LicenseCount,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE
from 
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, SUM(BillableLicenseCount) as LicenseCount
from dbo.MonthlyBillingData 
where YEAR =case when MONTH(getdate()) in (1,2,3) then year(GETDATE())-1 else year(GETDATE()) end
and MONTH=case 
when MONTH(getdate()) in (1,2,3) then 12
when MONTH(getdate()) in (4,5,6) then 3
when MONTH(getdate()) in (7,8,9) then 6
when MONTH(getdate()) in (10,11,12) then 9 end
and ProductSku in (20000,20200)
group by AccountId, DELIVERYNAME
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,productsku desc)as row	 
from dbo.MonthlyBillingData
where YEAR =case when MONTH(getdate()) in (1,2,3) then year(GETDATE())-1 else year(GETDATE()) end
and MONTH=case 
when MONTH(getdate()) in (1,2,3) then 12
when MONTH(getdate()) in (4,5,6) then 3
when MONTH(getdate()) in (7,8,9) then 6
when MONTH(getdate()) in (10,11,12) then 9 end
and ProductSku in (20000,20200)
) h 
where h.row=1
)b on
a.AccountId=b.AccountId and a.DELIVERYNAME=b.DELIVERYNAME
)mbo left join
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------Temp Table for Present Quarter-----------------------------------------------------
Create table #tempQTDcurrent
(Accountid nvarchar(200),DELIVERYNAME nvarchar(200),productsku nvarchar(200),LineAmount float(50),BilledAmount float (50),LicenseCount int
,ttbillend datetime,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime )

insert into #tempQTDcurrent
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,a.LicenseCount,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, SUM(BillableLicenseCount) as LicenseCount
from dbo.MonthlyBillingData
where YEAR =YEAR(getdate())
and MONTH=MONTH(getdate())
and ProductSku in (20000,20200)
group by AccountId, DELIVERYNAME
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,productsku desc)as row	 
from dbo.MonthlyBillingData
where YEAR =YEAR(getdate())
and MONTH=MONTH(getdate())
and ProductSku in (20000,20200)
) h 
where h.row=1
)b on
a.AccountId=b.AccountId and a.DELIVERYNAME=b.DELIVERYNAME
)mbo left join
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')

-------------------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------Final Query---------------------------------------------------------------------------
Create table #QueryQTD
(AccountName nvarchar(200), Accountid nvarchar(200),Upgrade int,Downgrade int,Cancel int,Adds int,BaselineCount int
,TargetCount int,PriceGroup varchar(50),PriceGroupDesc varchar(100),CustomerGroup varchar(10),SalesOffice varchar(50),SalesRegion varchar(50),ProductName varchar(100) )

Insert into #QueryQTD
select j.AccountName,j.AccountId,sum(j.Upgrade) as Upgrade,sum(j.Downgrade) as Downgrade,sum(j.Cancel) as Cancel,sum(j.Adds) as Adds,
sum(k.BaselineCount) as BaselineCount,sum(k.TargetCount) as TargetCount,j.PRICEGROUP as PriceGroup,
j.PriceGroupDesc as PriceGroupDesc,j.CUSTGROUP as CustomerGroup,isnull(j.SalesOffice,'Unmapped') as SalesOffice,
isnull(j.SalesRegion,'None') as SalesRegion,ProductName from
(
select f.AccountName,f.AccountId,f.Deliveryname,nullif(f.TTCONVERSIONDATE,'1900-01-01') as TTCONVERSIONDATE ,f.ChangeInPrice,f.Upgrade,f.Downgrade,f.Cancel,f.Adds,f.TotalChange,f.MayRevenue,f.CurrentMonthRevenue,f.PRICEGROUP,f.CUSTGROUP,f.PriceGroupDesc,f.SalesOffice,f.SalesRegion,P.ProductName
from
(
select s.Accountname, r.* from
(
select z.Accountid,z.Deliveryname, isnull(SUM(z.Line),0) as ChangeInPrice, isnull(SUM(z.Upgrade),0) as Upgrade, ISNULL(sum(z.downgrade),0) as Downgrade
,ISNULL(sum(z.Cancel),0) as Cancel,ISNULL(sum(z.Adds),0) as Adds
, isnull(SUM(z.Line),0)+isnull(SUM(z.Upgrade),0)+ ISNULL(sum(z.downgrade),0)+ISNULL(sum(z.Cancel),0)+ISNULL(sum(z.Adds),0) as TotalChange, isnull(SUM(b1),0) as MayRevenue, isnull(SUM(b2),0) as CurrentMonthRevenue,z.SalesOffice,z.SalesRegion
,z.PriceGroup,z.PriceGroupDesc,z.CustGroup,z.TTConversionDate,z.Productsku
from
(
select 
case when c.accountid is null then d.accountid else c.accountid end as AccountId,
case when c.deliveryname is null then d.deliveryname else c.deliveryname end as Deliveryname,
case when c.productsku is null then d.productsku else c.productsku end as Productsku,
SUM(c.Billed) as B1, SUM(d.Billed) as B2
,case when c.SalesOffice is null then d.SalesOffice else c.SalesOffice end as SalesOffice
,case when c.SalesRegion is null then d.SalesRegion else c.SalesRegion end as SalesRegion
,case when c.PriceGroup is null then d.PriceGroup else c.PriceGroup end as PriceGroup
,case when c.PriceGroupDesc is null then d.PriceGroupDesc else c.PriceGroupDesc end as PriceGroupDesc
,case when c.CustGroup is null then d.CustGroup else c.CustGroup end as CustGroup
,case when c.TTConversionDate is null then d.TTConversionDate else c.TTConversionDate end as TTConversionDate
, case when  (c.productsku=d.productsku and SUM(c.billed)>0 and cast(c.ttbillend as date)>= '5/31/2014'
)  and cast(d.ttbillend as date) >=('6/30/2014') then 0 else 0 end as Line
,case when sum(c.licensecount)=sum(d.licensecount) then 0 else case when (c.productsku is null or SUM(c.licensecount)=0) and SUM(d.licensecount)>=1 then SUM(d.licensecount) else 
case when SUM(c.licensecount)>=1 and SUM(d.licensecount)>=1 and SUM(d.licensecount)>SUM(c.licensecount) then SUM(d.licensecount)-SUM(c.licensecount) else 0 end end end as Adds --<Ram 5/28/2014> Updated to fix a bug on Missing Screen Count
--,case when (c.productsku is null or SUM(c.licensecount)=0 or cast(c.ttbillend as date)<'5/31/2014') and SUM(d.licensecount)>=1 then 1 else 0 end as Adds
, case when sum(c.licensecount)>=1 and sum(d.licensecount)>=1 and c.productsku = 20000 and d.productsku = 20200 then 1 else 0 end as Upgrade
--c.ProductSku in (20000) and SUM(c.billed)>0 and cast(c.ttbillend as date) >= ('5/31/2014')  and d.ProductSku in (20200) and cast(d.ttbillend as date)>=('6/30/2014') then 1 else -1 end as Upgrade
, case when sum(c.licensecount)>=1 and sum(d.licensecount)>=1 and c.productsku = 20200 and d.productsku = 20000 then 1 else 0 end as Downgrade
--c.ProductSku in (20200) and SUM(c.billed)>0  and cast(c.ttbillend as date) >= '5/31/2014'  and (d.ProductSku in(20000) and cast(d.ttbillend as date)>=('6/30/2014')) then 1 else -1 end as Downgrade
, case when sum(c.licensecount)=sum(d.licensecount) then 0 else case when SUM(c.licensecount)>=1 and (SUM(d.licensecount)=0  or d.productsku is null) then SUM(c.licensecount) else 
case when SUM(c.licensecount)>=1 and SUM(d.licensecount)>=1 and SUM(c.licensecount)>SUM(d.licensecount) then SUM(c.licensecount)-SUM(d.licensecount) else 0 end end end as Cancel --<Ram 5/28/2014> Updated to fix a bug on Missing Screen Count
--, case when SUM(c.licensecount)>=1 and (SUM(d.licensecount)=0  or d.productsku is null or cast(d.ttbillend as date)<'6/30/2014') then 1 else 0 end as Cancel
from
(
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME,ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed,SUM(BillableLicenseCount)as LicenseCount, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
from dbo.MonthlyBillingData
where YEAR =case when MONTH(getdate()) in (1,2,3) then year(GETDATE())-1 else year(GETDATE()) end
and MONTH=case 
when MONTH(getdate()) in (1,2,3) then 12
when MONTH(getdate()) in (4,5,6) then 3
when MONTH(getdate()) in (7,8,9) then 6
when MONTH(getdate()) in (10,11,12) then 9 end
and ProductSku in (20000,20200)
and deliveryname  not in ( select deliveryname from #tempQTD)
group by AccountId, DELIVERYNAME, ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
)mbo left join 
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
union
select * from #tempQTD
) c 

full outer join
(
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME,ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed,SUM(BillableLicenseCount)as LicenseCount, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
from dbo.MonthlyBillingData
where YEAR =YEAR(getdate())
and MONTH=MONTH(getdate())
and ProductSku in (20000,20200)
and deliveryname not in ( select deliveryname from #tempQTDcurrent)
group by AccountId, DELIVERYNAME, ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
) mbo left Join
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
union 
select * from #tempQTDcurrent

)d 
on c.AccountId=d.AccountId and c.deliveryname=d.deliveryname
group by c.accountid,d.accountid,c.deliveryname,d.deliveryname,c.productsku,d.productsku,d.TTBillEnd,c.TTBillend,d.SalesOffice,d.SalesRegion,c.SalesOffice,c.SalesRegion,c.PriceGroup,d.PriceGroup,c.PriceGroupDesc,d.PriceGroupDesc,c.CustGroup,d.CustGroup,c.TTConversiondate,d.TTConversiondate
)z
group by z.accountid,z.Deliveryname,z.SalesOffice,z.SalesRegion,z.PriceGroup,z.PriceGroupDesc,z.CustGroup,z.TTConversionDate,z.Productsku

) r
join
( select * from dbo.Account) s
on r.AccountId=s.Accountid

) f 
left join Product P
on f.Productsku=p.ProductSku
)j 
left outer join
(
select AccountId,deliveryname,sum(case when  YEAR =year(GETDATE())
and MONTH=MONTH(getdate()) then Billedamount end) as CurrentMonthRevenue,
sum(case when YEAR =case when MONTH(getdate()) in (1,2,3) then year(GETDATE())-1 else year(GETDATE()) end
and MONTH=case 
when MONTH(getdate()) in (1,2,3) then 12
when MONTH(getdate()) in (4,5,6) then 3
when MONTH(getdate()) in (7,8,9) then 6
when MONTH(getdate()) in (10,11,12) then 9 end then Billedamount end) as  MayRevenue,
sum(case when  YEAR =year(GETDATE())
and MONTH=MONTH(getdate()) then BillableLicenseCount end) as TargetCount,
sum(case when  YEAR =case when MONTH(getdate()) in (1,2,3) then year(GETDATE())-1 else year(GETDATE()) end
and MONTH=case 
when MONTH(getdate()) in (1,2,3) then 12
when MONTH(getdate()) in (4,5,6) then 3
when MONTH(getdate()) in (7,8,9) then 6
when MONTH(getdate()) in (10,11,12) then 9 end then BillableLicenseCount end) as BaselineCount

 from 
dbo.MonthlyBillingData
where ProductSku in (20000,20200) 
group by AccountId,deliveryname
)k
on j.AccountId=k.AccountId and j.Deliveryname=k.DELIVERYNAME
group by j.AccountName,j.AccountId,j.PRICEGROUP,j.PriceGroupDesc,j.CUSTGROUP,j.SalesOffice,j.SalesRegion,j.ProductName

---------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------YTD Query----------------------------------------------------------------


------------------------------------------------------------Temp table Prior Year------------------------------------------------------------------------
Create table #tempYTD
(Accountid nvarchar(200),DELIVERYNAME nvarchar(200),productsku nvarchar(200),LineAmount float(50),BilledAmount float (50),LicenseCount int
,ttbillend datetime,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime )

insert into #tempYTD
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,a.LicenseCount,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE
from 
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, SUM(BillableLicenseCount) as LicenseCount
from dbo.MonthlyBillingData 
where YEAR =case when month(getdate())>3 then year(GETDATE()) else YEAR(getdate())-1 end and Month= 3
and ProductSku in (20000,20200)
group by AccountId, DELIVERYNAME
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,productsku desc)as row	 
from dbo.MonthlyBillingData
where YEAR =case when month(getdate())>3 then year(GETDATE()) else YEAR(getdate())-1 end and Month= 3
and ProductSku in (20000,20200)
) h 
where h.row=1
)b on
a.AccountId=b.AccountId and a.DELIVERYNAME=b.DELIVERYNAME
)mbo left join
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------Temp Table for Current Year-----------------------------------------------------
Create table #tempYTDcurrent
(Accountid nvarchar(200),DELIVERYNAME nvarchar(200),productsku nvarchar(200),LineAmount float(50),BilledAmount float (50),LicenseCount int
,ttbillend datetime,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime )

insert into #tempYTDcurrent
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,a.LicenseCount,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, SUM(BillableLicenseCount) as LicenseCount
from dbo.MonthlyBillingData
where YEAR = YEAR(getdate()) and MONTH=MONTH(getdate())
and ProductSku in (20000,20200)
group by AccountId, DELIVERYNAME
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,productsku desc)as row	 
from dbo.MonthlyBillingData
where YEAR =YEAR(getdate()) and MONTH=MONTH(getdate())
and ProductSku in (20000,20200)
) h 
where h.row=1
)b on
a.AccountId=b.AccountId and a.DELIVERYNAME=b.DELIVERYNAME
)mbo left join
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')

-------------------------------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------Final Query---------------------------------------------------------------------------

Create table #QueryYTD
(AccountName nvarchar(200), Accountid nvarchar(200),Upgrade int,Downgrade int,Cancel int,Adds int,BaselineCount int
,TargetCount int,PriceGroup varchar(50),PriceGroupDesc varchar(100),CustomerGroup varchar(10),SalesOffice varchar(50),SalesRegion varchar(50),ProductName varchar(100) )

Insert into #QueryYTD
select j.AccountName,j.AccountId,sum(j.Upgrade) as Upgrade,sum(j.Downgrade) as Downgrade,sum(j.Cancel) as Cancel,sum(j.Adds) as Adds,
sum(k.BaselineCount) as BaselineCount,sum(k.TargetCount) as TargetCount,j.PRICEGROUP as PriceGroup,
j.PriceGroupDesc as PriceGroupDesc,j.CUSTGROUP as CustomerGroup,isnull(j.SalesOffice,'Unmapped') as SalesOffice,
isnull(j.SalesRegion,'None') as SalesRegion,ProductName from
(
select f.AccountName,f.AccountId,f.Deliveryname,nullif(f.TTCONVERSIONDATE,'1900-01-01') as TTCONVERSIONDATE ,f.ChangeInPrice,f.Upgrade,f.Downgrade,f.Cancel,f.Adds,f.TotalChange,f.MayRevenue,f.CurrentMonthRevenue,f.PRICEGROUP,f.CUSTGROUP,f.PriceGroupDesc,f.SalesOffice,f.SalesRegion,P.ProductName
from
(
select s.Accountname, r.* from
(
select z.Accountid,z.Deliveryname, isnull(SUM(z.Line),0) as ChangeInPrice, isnull(SUM(z.Upgrade),0) as Upgrade, ISNULL(sum(z.downgrade),0) as Downgrade
,ISNULL(sum(z.Cancel),0) as Cancel,ISNULL(sum(z.Adds),0) as Adds
, isnull(SUM(z.Line),0)+isnull(SUM(z.Upgrade),0)+ ISNULL(sum(z.downgrade),0)+ISNULL(sum(z.Cancel),0)+ISNULL(sum(z.Adds),0) as TotalChange, isnull(SUM(b1),0) as MayRevenue, isnull(SUM(b2),0) as CurrentMonthRevenue,z.SalesOffice,z.SalesRegion
,z.PriceGroup,z.PriceGroupDesc,z.CustGroup,z.TTConversionDate,z.Productsku
from
(
select 
case when c.accountid is null then d.accountid else c.accountid end as AccountId,
case when c.deliveryname is null then d.deliveryname else c.deliveryname end as Deliveryname,
case when c.productsku is null then d.productsku else c.productsku end as Productsku,
SUM(c.Billed) as B1, SUM(d.Billed) as B2
,case when c.SalesOffice is null then d.SalesOffice else c.SalesOffice end as SalesOffice
,case when c.SalesRegion is null then d.SalesRegion else c.SalesRegion end as SalesRegion
,case when c.PriceGroup is null then d.PriceGroup else c.PriceGroup end as PriceGroup
,case when c.PriceGroupDesc is null then d.PriceGroupDesc else c.PriceGroupDesc end as PriceGroupDesc
,case when c.CustGroup is null then d.CustGroup else c.CustGroup end as CustGroup
,case when c.TTConversionDate is null then d.TTConversionDate else c.TTConversionDate end as TTConversionDate
, case when  (c.productsku=d.productsku and SUM(c.billed)>0 and cast(c.ttbillend as date)>= '5/31/2014'
)  and cast(d.ttbillend as date) >=('6/30/2014') then 0 else 0 end as Line
,case when sum(c.licensecount)=sum(d.licensecount) then 0 else case when (c.productsku is null or SUM(c.licensecount)=0) and SUM(d.licensecount)>=1 then SUM(d.licensecount) else 
case when SUM(c.licensecount)>=1 and SUM(d.licensecount)>=1 and SUM(d.licensecount)>SUM(c.licensecount) then SUM(d.licensecount)-SUM(c.licensecount) else 0 end end end as Adds --<Ram 5/28/2014> Updated to fix a bug on Missing Screen Count
, case when sum(c.licensecount)>=1 and sum(d.licensecount)>=1 and c.productsku = 20000 and d.productsku = 20200 then 1 else 0 end as Upgrade
--c.ProductSku in (20000) and SUM(c.billed)>0 and cast(c.ttbillend as date) >= ('5/31/2014')  and d.ProductSku in (20200) and cast(d.ttbillend as date)>=('6/30/2014') then 1 else -1 end as Upgrade
, case when sum(c.licensecount)>=1 and sum(d.licensecount)>=1 and c.productsku = 20200 and d.productsku = 20000 then 1 else 0 end as Downgrade
--c.ProductSku in (20200) and SUM(c.billed)>0  and cast(c.ttbillend as date) >= '5/31/2014'  and (d.ProductSku in(20000) and cast(d.ttbillend as date)>=('6/30/2014')) then 1 else -1 end as Downgrade
, case when sum(c.licensecount)=sum(d.licensecount) then 0 else case when SUM(c.licensecount)>=1 and (SUM(d.licensecount)=0  or d.productsku is null) then SUM(c.licensecount) else 
case when SUM(c.licensecount)>=1 and SUM(d.licensecount)>=1 and SUM(c.licensecount)>SUM(d.licensecount) then SUM(c.licensecount)-SUM(d.licensecount) else 0 end end end as Cancel --<Ram 5/28/2014> Updated to fix a bug on Missing Screen Count
--, case when SUM(c.licensecount)>=1 and (SUM(d.licensecount)=0  or d.productsku is null or cast(d.ttbillend as date)<'6/30/2014') then 1 else 0 end as Cancel
from
(
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME,ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed,SUM(BillableLicenseCount)as LicenseCount, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
from dbo.MonthlyBillingData
where YEAR =case when month(getdate())>3 then year(GETDATE()) else YEAR(getdate())-1 end and Month= 3
and ProductSku in (20000,20200)
and deliveryname  not in ( select deliveryname from #tempYTD)
group by AccountId, DELIVERYNAME, ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
)mbo left join 
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
union
select * from #tempYTD
) c 

full outer join
(
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME,ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed,SUM(BillableLicenseCount)as LicenseCount, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
from dbo.MonthlyBillingData
where YEAR =YEAR(getdate()) and MONTH=MONTH(getdate())
and ProductSku in (20000,20200)
and deliveryname not in ( select deliveryname from #tempYTDcurrent)
group by AccountId, DELIVERYNAME, ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
) mbo left Join
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
union 
select * from #tempYTDcurrent

)d 
on c.AccountId=d.AccountId and c.deliveryname=d.deliveryname
group by c.accountid,d.accountid,c.deliveryname,d.deliveryname,c.productsku,d.productsku,d.TTBillEnd,c.TTBillend,d.SalesOffice,d.SalesRegion,c.SalesOffice,c.SalesRegion,c.PriceGroup,d.PriceGroup,c.PriceGroupDesc,d.PriceGroupDesc,c.CustGroup,d.CustGroup,c.TTConversiondate,d.TTConversiondate
)z
group by z.accountid,z.Deliveryname,z.SalesOffice,z.SalesRegion,z.PriceGroup,z.PriceGroupDesc,z.CustGroup,z.TTConversionDate,z.Productsku

) r
join
( select * from dbo.Account) s
on r.AccountId=s.Accountid

) f 
left join Product P
on f.Productsku=p.ProductSku

)j 
left outer join
(
select AccountId,deliveryname,ISNULL(sum(case when YEAR =case when month(getdate())>3 then year(GETDATE()) else YEAR(getdate())-1 end and Month= 3 then Billedamount end),0) as MayRevenue,
ISNULL(sum(case when  YEAR =year(GETDATE()) and MONTH=MONTH(getdate()) THEN Billedamount end),0) as CurrentMonthRevenue,
ISNULL(sum(case when YEAR =case when month(getdate())>3 then year(GETDATE()) else YEAR(getdate())-1 end and Month= 3 then BillableLicenseCount end),0) as BaselineCount,
ISNULL(sum(case when  YEAR =year(GETDATE()) and MONTH=MONTH(getdate()) then BillableLicenseCount end),0) as TargetCount
from 
dbo.MonthlyBillingData
where ProductSku in (20000,20200) 
group by AccountId,deliveryname
)k
on j.AccountId=k.AccountId and j.Deliveryname=k.DELIVERYNAME
group by j.AccountName,j.AccountId,j.PRICEGROUP,j.PriceGroupDesc,j.CUSTGROUP,j.SalesOffice,j.SalesRegion,j.ProductName
order by j.accountid
---------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------Drop Temp Tables Created--------------------------------------------------------------------

drop table #tempQTD
drop table #tempQTDcurrent
--drop table #QueryQTD
drop table #tempYTD
drop table #tempYTDcurrent
--drop table #QueryYTD

Select qtd.ImpactType, MTD, QTD, YTD as FiscalYTD from
(
select 'Adds' as ImpactType, Sum(adds) as QTD from #QueryQTD
union
select 'Cancels' as ImpactType, Sum(Cancel) as QTD from #QueryQTD
union
select 'Downgrades' as ImpactType, Sum(Downgrade) as QTD from #QueryQTD
union
select 'Upgrades' as ImpactType, Sum(Upgrade) as QTD from #QueryQTD
)qtd
join
(
select 
case when countschangetype='AddCount' then 'Adds'
when countschangetype='CancelCount' then 'Cancels'
when countschangetype='DownGradeCount' then 'Downgrades'
when countschangetype='UpgradeCount' then 'Upgrades' end
 as ImpactType,SUM(netcount) as MTD from VW_RevenueImpactReporting
--where YEAR=YEAR(getdate()) and MONTH=MONTH(getdate())
---------------------Added code to get Prior Month Counts when the billing is not closed----------------
where YEAR=case when (case when month(getdate())=1 then YEAR(getdate())-1 else Year(getdate()) end)=(select Year from (select *,row_number() over (order by id desc) as row 
from fillhub.dbo.InvoiceMonth)Q where ROW=1) then year(getdate()) else (case when month(getdate())=1 then YEAR(getdate())-1 else year(getdate()) end) end
and MONTH=case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=(select Month from (select *,row_number() over (order by id desc) as row 
from fillhub.dbo.InvoiceMonth)Q where ROW=1) then MONTH(getdate()) else (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end) end
and ProductName in ('X_TRADER®','X_TRADER® Pro')
---------------------------------------------------
and countschangetype<>'NoChange'
group by countschangetype
)MTD on qtd.ImpactType=mtd.ImpactType
join
(
select 'Adds' as ImpactType, Sum(adds) as YTD from #QueryYTD
union
select 'Cancels' as ImpactType, Sum(Cancel) as YTD from #QueryYTD
union
select 'Downgrades' as ImpactType, Sum(Downgrade) as YTD from #QueryYTD
union
select 'Upgrades' as ImpactType, Sum(Upgrade) as YTD from #QueryYTD
)YTD on qtd.ImpactType=ytd.ImpactType
Order by 1
END