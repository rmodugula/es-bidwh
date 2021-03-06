USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_RevenueImpactData]    Script Date: 9/17/2014 4:29:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_RevenueImpactData] 
(@Month int,@Year int)
 
AS
declare @Currentyear int;
declare @CurrentMonth int;
declare @Baseyear int;
declare @Basemonth int

set @Currentyear=@Year
set @CurrentMonth=@Month
set @Baseyear = (case when @Month=1 then @Year-1 else @Year end)
set @Basemonth = (case when @Month=1 then 12 else 
case @month
when 2 then 1
when 3 then 2
when 4 then 3
when 5 then 4
when 6 then 5
when 7 then 6
when 8 then 7
when 9 then 8
when 10 then 9
when 11 then 10
when 12 then 11
end end)

-- **** Global Variables ***
declare @LastdayBaseMonth date , @LastdayCurrentMonth date 

SET @LastdayBaseMonth = (
select cast(enddate as DATE) from TimeInterval
where YEAR=@Baseyear and month=@Basemonth)


SET @LastdayCurrentMonth = (
select cast(enddate as DATE) from TimeInterval
where YEAR=@Currentyear and month=@Currentmonth)
-- **** end Global Variables ***
BEGIN
------------------------------------------------------------Temp table for From Month------------------------------------------------------------------------
Create table #temp
(Accountid nvarchar(200),DELIVERYNAME nvarchar(200),productsku nvarchar(200),LineAmount float(50),BilledAmount float (50),LicenseCount int
,ttbillend datetime,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime )

insert into #temp
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,a.LicenseCount,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE
from 
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, SUM(BillableLicenseCount) as LicenseCount
from dbo.MonthlyBillingData 
where YEAR =@Baseyear
and MONTH=@Basemonth
and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993)
group by AccountId, DELIVERYNAME
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,productsku desc)as row	 
from dbo.MonthlyBillingData
where YEAR =@Baseyear 
and MONTH=@Basemonth
and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993)
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


-----------------------------------------------------------------------------Temp Table for To Month-----------------------------------------------------
Create table #tempcurrent
(Accountid nvarchar(200),DELIVERYNAME nvarchar(200),productsku nvarchar(200),LineAmount float(50),BilledAmount float (50),LicenseCount int
,ttbillend datetime,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime )

insert into #tempcurrent
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,a.LicenseCount,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, SUM(BillableLicenseCount) as LicenseCount
from dbo.MonthlyBillingData
where YEAR =@Currentyear 
and MONTH=@Currentmonth
and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993)
group by AccountId, DELIVERYNAME
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,productsku desc)as row	 
from dbo.MonthlyBillingData
where YEAR =@Currentyear 
and MONTH=@Currentmonth
and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993)
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
delete RevenueImpactReporting
where YEAR=@Year and Month=@Month
Insert into RevenueImpactReporting
select @Currentyear as Year,@Currentmonth as Month,case @CurrentMonth
when 1 then 'Jan'
when 2 then 'Feb'
when 3 then 'Mar'
when 4 then 'Apr'
when 5 then 'May'
when 6 then 'Jun'
when 7 then 'Jul'
when 8 then 'Aug'
when 9 then 'Sep'
when 10 then 'Oct'
when 11 then 'Nov'
when 12 then 'Dec' end
 as MonthName,j.AccountId,j.AccountName,j.Deliveryname,j.ChangeInPriceRevenue,j.UpgradeRevenue,j.DowngradeRevenue,j.AddRevenue,j.CancelRevenue,(j.ChangeInPriceRevenue+j.UpgradeRevenue+j.DowngradeRevenue+j.AddRevenue+j.CancelRevenue) as NetRevenue,isnull(k.MayRevenue,0) as BaselineRevenue,isnull(k.CurrentMonthRevenue,0) as TargetRevenue,j.Upgrade,j.Downgrade,j.Adds,j.Cancel,(j.Upgrade+j.Downgrade+j.Adds+j.Cancel)as NetCount,isnull(k.BaselineCount,0) as BaselineCount,isnull(k.TargetCount,0) as TargetCount,j.PRICEGROUP as PriceGroup,j.PriceGroupDesc as PriceGroupDesc,j.CUSTGROUP as CustomerGroup,j.TTCONVERSIONDATE,isnull(j.SalesOffice,'Unmapped') as SalesOffice,isnull(j.SalesRegion,'None') as SalesRegion,
@LastdayCurrentMonth as BillingEndDate,ProductName,getdate() as LastUpdatedDate from
(
select f.AccountName,f.AccountId,f.Deliveryname,nullif(f.TTCONVERSIONDATE,'1900-01-01') as TTCONVERSIONDATE ,f.ChangeInPriceCount,f.ChangeInPriceRevenue,f.Upgrade,f.UpgradeRevenue,f.Downgrade,f.DowngradeRevenue,f.Cancel,f.CancelRevenue,f.Adds,f.AddRevenue,f.TotalChange as TotalChangeCount,f.MayRevenue,f.CurrentMonthRevenue,f.PRICEGROUP,f.CUSTGROUP,f.PriceGroupDesc,f.SalesOffice,f.SalesRegion,p.ProductName
from
(
select s.Accountname, r.* from
(
select z.Accountid,z.Deliveryname, isnull(SUM(z.Line),0) as ChangeInPriceCount,isnull(SUM(z.LineRevenue),0) as ChangeInPriceRevenue, isnull(SUM(z.Upgrade),0) as Upgrade,isnull(SUM(z.UpgradeRevenue),0) as UpgradeRevenue, ISNULL(sum(z.downgrade),0) as Downgrade
,ISNULL(sum(z.DowngradeRevenue),0) as DowngradeRevenue,ISNULL(sum(z.Cancel),0) as Cancel,ISNULL(sum(z.CancelRevenue),0) as CancelRevenue,ISNULL(sum(z.Adds),0) as Adds,ISNULL(sum(z.AddRevenue),0) as AddRevenue
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
, case when  (c.productsku=d.productsku and SUM(c.billed)>0 and cast(c.ttbillend as date)>= @LastdayBaseMonth
)  and cast(d.ttbillend as date) >=(@LastdayCurrentMonth) then 0 else 0 end as Line
, case when  (c.productsku=d.productsku and SUM(c.billed)>0 and cast(c.ttbillend as date)>= @LastdayBaseMonth
)  and cast(d.ttbillend as date) >=(@LastdayCurrentMonth) then isnull(sum(d.Billed-c.Billed),0) end as LineRevenue
,case when (c.productsku is null and d.ProductSku is not null) or (sum(c.billed)=0  and d.productsku in (20000,20200,20005,20999,20995,20997,20992,20993)) or (SUM(c.billed)>0 and CAST(c.ttbillend as date) <@LastdayBaseMonth and SUM(d.billed)>0 and CAST(d.ttbillend as date)>=@LastdayBaseMonth)  then isnull(SUM(ISNULL(d.billed,0)-ISNULL(c.billed,0)),0) end as AddRevenue
,case when sum(c.licensecount)=sum(d.licensecount) then 0 else case when (c.productsku is null or SUM(c.licensecount)=0 or cast(c.ttbillend as date)<@LastdayBaseMonth) and SUM(d.licensecount)>=1 then SUM(d.licensecount) else 
case when SUM(c.licensecount)>=1 and SUM(d.licensecount)>=1 and SUM(d.licensecount)>SUM(c.licensecount) then SUM(d.licensecount)-SUM(c.licensecount) else  0 end end end as Adds --<Ram 5/28/2014> Updated to fix a bug on Missing Screen Count
--,case when (c.productsku is null or SUM(c.licensecount)=0 or cast(c.ttbillend as date)<@LastdayBaseMonth) and SUM(d.licensecount)>=1 then 1 else 0 end as Adds
, case when c.ProductSku in (20000,20005,20992,20995) and SUM(c.billed)>0 and cast(c.ttbillend as date) >= (@LastdayBaseMonth)  and d.ProductSku in (20200,20999,20997,20993) and cast(d.ttbillend as date)>=(@LastdayCurrentMonth) then isnull(SUM(ISNULL(d.billed,0)-ISNULL(c.billed,0)),0) end as UpgradeRevenue
, case when sum(c.licensecount)>=1 and sum(d.licensecount)>=1 and c.productsku in (20000,20005,20992,20995) and d.productsku in (20200,20999,20997,20993) then 1 else 0 end as Upgrade
, case when c.ProductSku in (20200,20999,20997,20993) and SUM(c.billed)>0  and cast(c.ttbillend as date) >= @LastdayBaseMonth  and (d.ProductSku in(20000,20005,20992,20995) and cast(d.ttbillend as date)>=(@LastdayCurrentMonth)) then isnull(SUM(ISNULL(d.billed,0)-ISNULL(c.billed,0)),0) end as DowngradeRevenue
, case when sum(c.licensecount)>=1 and sum(d.licensecount)>=1 and c.productsku in (20200,20999,20997,20993) and d.productsku in (20000,20005,20992,20995) then 1 else 0 end as Downgrade
, case when (c.ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993) and SUM(c.billed)>0 and cast(c.ttbillend as date) >= @LastdayBaseMonth  and (d.productsku is null or cast(d.ttbillend as date)<(@LastdayCurrentMonth))) or (SUM(c.billed)>0 and CAST(c.ttbillend as date) <@LastdayBaseMonth and d.productsku is null)  then isnull(SUM(ISNULL(d.billed,0)-ISNULL(c.billed,0)),0) end as CancelRevenue
, case when sum(c.licensecount)=sum(d.licensecount) then 0 else case when SUM(c.licensecount)>=1 and (SUM(d.licensecount)=0  or d.productsku is null or cast(d.ttbillend as date)<@LastdayCurrentMonth) then SUM(c.licensecount) else 
case when SUM(c.licensecount)>=1 and SUM(d.licensecount)>=1 and SUM(c.licensecount)>SUM(d.licensecount) then SUM(c.licensecount)-SUM(d.licensecount) else 0 end end end as Cancel --<Ram 5/28/2014> Updated to fix a bug on Missing Screen Count
--, case when SUM(c.licensecount)>=1 and (SUM(d.licensecount)=0  or d.productsku is null or cast(d.ttbillend as date)<@LastdayCurrentMonth) then 1 else 0 end as Cancel
from
(
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME,ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed,SUM(BillableLicenseCount)as LicenseCount, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
from dbo.MonthlyBillingData
where YEAR =@Baseyear 
and MONTH=@Basemonth
and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993)
and deliveryname  not in ( select deliveryname from #temp)
group by AccountId, DELIVERYNAME, ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
)mbo left join 
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
union
select * from #temp
) c 

full outer join
(
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME,ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed,SUM(BillableLicenseCount)as LicenseCount, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
from dbo.MonthlyBillingData
where YEAR =@Currentyear 
and MONTH=@Currentmonth
and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993)
and deliveryname not in ( select deliveryname from #tempcurrent)
group by AccountId, DELIVERYNAME, ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
) mbo left Join
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
union 
select * from #tempcurrent

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
select AccountId,deliveryname,sum(case when year =@Baseyear and month=@Basemonth then Billedamount end) as MayRevenue,
sum(case when year=@Currentyear and month=@Currentmonth then Billedamount end) as CurrentMonthRevenue,
sum(case when year =@Baseyear and month=@Basemonth then BillableLicenseCount end) as BaselineCount,
sum(case when year=@Currentyear and month=@Currentmonth then BillableLicenseCount end) as TargetCount
 from 
dbo.MonthlyBillingData
where ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993) 
group by AccountId,deliveryname
)k
on j.AccountId=k.AccountId and j.Deliveryname=k.DELIVERYNAME
order by j.accountid,j.Deliveryname
-----------------------------------------------------------------Drop Temp Tables Created--------------------------------------------------------------------
drop table #temp
drop table #tempcurrent
END












