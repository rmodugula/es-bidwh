USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetScreenActivityBaselineTarget_Trend]    Script Date: 7/16/2015 3:16:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetScreenActivityBaselineTarget_Trend] 
(@TargetYear int, @TargetMonth int)
	 
AS

-- **** Global Variables ***
declare @LastdayBaseMonth date , @LastdayCurrentMonth date , @BaseMonthNum int, @CurrentMonthNum int,@Baseyear int, @Basemonth int,@Currentyear int,@CurrentMonth Int,@CurrentQuarter int,
@EndYear int, @Endquarter int,@Runyear int,@Runmonth int,@RunQuarter int,@EndMonth int,@RunDate date,@Startdate Datetime, @Enddate datetime

SET @Currentyear=@TargetYear
SET @CurrentMonth=@TargetMonth
Set @CurrentQuarter = datepart(qq,getdate())
SET @Runyear = @Currentyear
SET @Runmonth = @CurrentMonth
Set @RunQuarter = @CurrentQuarter
SET @EndYear= 2014
SET @Endquarter = 1
SET @EndMonth = 6
Set @Startdate= CAST(CAST(@Runyear AS varchar) + '-' + CAST(@Runmonth AS varchar) + '-' + CAST(1 AS varchar) AS DATETIME)
Set @Enddate= CAST(CAST(@Endyear AS varchar) + '-' + CAST(@Endmonth AS varchar) + '-' + CAST(1 AS varchar) AS DATETIME)


Create table #LicenseImpact
(Year int,Month int,Quarter varchar(10), MasterAccountName nvarchar(200),AccountName nvarchar(200),AccountId nvarchar(200),Deliveryname nvarchar(200),ProductName nvarchar(200)
,Cancels int,Adds int,BaselineCount int,TargetCount int,NetCount int,Transfer int, NameChange int, Upgrade Int, Downgrade int, Migration int)


while (CAST(CAST(@Runyear AS varchar) + '-' + CAST(@Runmonth AS varchar) + '-' + CAST(1 AS varchar) AS DATETIME))>=@Enddate
--@Runyear >= @EndYear and @Runmonth>=@EndMonth
begin
--SET @Baseyear = Case when @Runmonth = 1 then @Runyear-1 else @Runyear End
--SET @Basemonth = case when @Runmonth=1 then 12 else @Runmonth-1 End
SET @Rundate=CAST(CAST(@Runyear AS VARCHAR(4)) + RIGHT('0' + CAST(@Runmonth AS VARCHAR(2)), 2) + RIGHT('0' + CAST(1 AS VARCHAR(2)), 2) AS DATE)
SET @LastdayBaseMonth = (select CAST(EndDate as date) from TimeInterval where YEAR=@Baseyear and Month=@Basemonth)
SET @LastdayCurrentMonth = (select CAST(EndDate as date) from TimeInterval where YEAR=@Runyear and Month=@Runmonth)
SET @BaseMonthNum = @Basemonth
SET @CurrentMonthNum = @Runmonth
-- **** end Global Variables ***

BEGIN
SET NOCOUNT ON;
------------------------------------------------------------Temp table for From Month------------------------------------------------------------------------
Create table #temp
(Accountid nvarchar(200),DELIVERYNAME nvarchar(200),productsku nvarchar(200),LineAmount float(50),BilledAmount float (50),LicenseCount int
,ttbillend datetime,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime,TTSalesCommissionException int )

insert into #temp
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE,
mbo.TTSalesCommissionException
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,a.LicenseCount,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE,a.TTSalesCommissionException
from 
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, SUM(BillableLicenseCount) as LicenseCount,TTSalesCommissionException
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
Join timeinterval T on m.year=t.year and m.month=t.month
where enddate>=dateadd(mm,-12,@Rundate) and enddate<=@Rundate
and screens='screens'
group by AccountId, DELIVERYNAME,TTSalesCommissionException
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, m.ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,m.productsku desc)as row	 
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
Join timeinterval T on m.year=t.year and m.month=t.month
where enddate>=dateadd(mm,-12,@Rundate) and enddate<=@Rundate
and screens='screens'
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
,ttbillend datetime,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime,TTSalesCommissionException int )

insert into #tempcurrent
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
,mbo.TTSalesCommissionException
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,a.LicenseCount,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE
,TTSalesCommissionException
from
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, SUM(BillableLicenseCount) as LicenseCount,TTSalesCommissionException
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
where YEAR =@Runyear 
and MONTH=@Runmonth
and screens='screens'
group by AccountId, DELIVERYNAME,TTSalesCommissionException
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, m.ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,m.productsku desc)as row	 
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
where YEAR =@Runyear 
and MONTH=@Runmonth
and screens='screens'
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

Insert Into #LicenseImpact
Select Year,Month,Quarter,MasterAccountName,AccountName,Accountid,DeliveryName,ProductName,Cancels, Adds
,BaselineCount as Baseline,TargetCount as Target,NetCount as Net,Transfer,NameChange,Upgrade,Downgrade,Migration from
(
select @Runyear as Year, @Runmonth as Month,case when @Runmonth in (1,2,3) then 'Q1' when @Runmonth in (4,5,6) then 'Q2' when @Runmonth in (7,8,9) then 'Q3' else 'Q4' End as Quarter
,MasterAccountName,Q.AccountName,A.Accountid,Deliveryname,ProductName,sum(Cancels) as Cancels,sum(Adds) as Adds, sum(BaselineCount) as BaselineCount,sum(TargetCount) as TargetCount
,sum(TargetCount)- sum(BaselineCount) as NetCount,
isnull(sum(case when TargetTTSalesCommissionException =1 then TargetTTSalesCommissionException End),0) as 'Transfer' ,
isnull(sum(Case when TargetTTSalesCommissionException=2 then TargetTTSalesCommissionException End),0) as 'NameChange' ,
isnull(sum(Case when TargetTTSalesCommissionException =3 then TargetTTSalesCommissionException End),0) as 'Upgrade',
isnull(sum(Case when TargetTTSalesCommissionException =4 then TargetTTSalesCommissionException End),0) as  'Downgrade' ,
isnull(sum(Case when TargetTTSalesCommissionException =5 then TargetTTSalesCommissionException End),0) as 'Migration' 
from
(
select j.AccountName,isnull(k.AccountId,j.accountid) as AccountId,isnull(j.Deliveryname,k.deliveryname) as DeliveryName,ProductName,
sum(j.Cancel) as Cancels,sum(j.Adds) as Adds,sum(isnull(k.BaselineCount,0)) as BaselineCount,sum(isnull(k.TargetCount,0)) as TargetCount,sum(j.TargetTTSalesCommissionException) as TargetTTSalesCommissionException
,sum(j.BaseTTSalesCommissionException) as BaseTTSalesCommissionException
 from
(
select f.AccountName,f.AccountId,f.Deliveryname,nullif(f.TTCONVERSIONDATE,'1900-01-01') as TTCONVERSIONDATE ,f.ChangeInPrice,f.Upgrade,f.Downgrade,f.Cancel,f.Adds,f.TotalChange,f.MayRevenue,f.CurrentMonthRevenue,f.PRICEGROUP,f.CUSTGROUP,f.PriceGroupDesc,f.SalesOffice,f.SalesRegion,p.ProductName
, f.TargetTTSalesCommissionException,f.BaseTTSalesCommissionException
from
(
select s.Accountname, r.* from
(
select z.Accountid,z.Deliveryname, isnull(SUM(z.Line),0) as ChangeInPrice, isnull(SUM(z.Upgrade),0) as Upgrade, ISNULL(sum(z.downgrade),0) as Downgrade
,ISNULL(sum(case when (z.upgrade =1 or z.Downgrade=1) then 0 else z.Cancel End),0) as Cancel,ISNULL(sum(z.Adds),0) as Adds
, isnull(SUM(z.Line),0)+isnull(SUM(z.Upgrade),0)+ ISNULL(sum(z.downgrade),0)+ISNULL(sum(z.Cancel),0)+ISNULL(sum(z.Adds),0) as TotalChange, isnull(SUM(b1),0) as MayRevenue, isnull(SUM(b2),0) as CurrentMonthRevenue,z.SalesOffice,z.SalesRegion
,z.PriceGroup,z.PriceGroupDesc,z.CustGroup,z.TTConversionDate,z.Productsku, sum(isnull(z.TargetTTSalesCommissionException,0)) as TargetTTSalesCommissionException
, sum(isnull(z.BaseTTSalesCommissionException,0)) as BaseTTSalesCommissionException
from
(
select 
case when d.accountid is null then c.accountid else d.accountid end as AccountId,
case when c.deliveryname is null then d.deliveryname else c.deliveryname end as Deliveryname,
case when c.productsku is null then d.productsku else c.productsku end as Productsku,
SUM(c.Billed) as B1, SUM(d.Billed) as B2
,case when c.SalesOffice is null then d.SalesOffice else c.SalesOffice end as SalesOffice
,case when c.SalesRegion is null then d.SalesRegion else c.SalesRegion end as SalesRegion
,case when c.PriceGroup is null then d.PriceGroup else c.PriceGroup end as PriceGroup
,case when c.PriceGroupDesc is null then d.PriceGroupDesc else c.PriceGroupDesc end as PriceGroupDesc
,case when c.CustGroup is null then d.CustGroup else c.CustGroup end as CustGroup
,case when c.TTConversionDate is null then d.TTConversionDate else c.TTConversionDate end as TTConversionDate
, 0 as Line
,case when d.TTSalesCommissionException=0 then  case when sum(c.licensecount)=sum(d.licensecount) then 0 else 
case when (c.productsku is null or SUM(c.licensecount)=0 
) and SUM(d.licensecount)>=1 then SUM(d.licensecount) else 
case when SUM(c.licensecount)>=1 and SUM(d.licensecount)>=1 
then 0 end end end else 0 end as Adds --<Ram 5/28/2014> Updated to fix a bug on Missing Screen Count

, case when sum(c.licensecount)>=1 and sum(d.licensecount)>=1 and c.productsku in (20000) and d.productsku in (20200) then 1 else 0 end as Upgrade

, case when sum(c.licensecount)>=1 and sum(d.licensecount)>=1 and c.productsku in (20200) and d.productsku in (20000) then 1 else 0 end as Downgrade

, case when sum(c.licensecount)=sum(d.licensecount) then 0 else case when SUM(c.licensecount)>=1 and (SUM(d.licensecount)=0  or d.productsku is null) then SUM(c.licensecount) else 
case when SUM(c.licensecount)>=1 and SUM(d.licensecount)>=1 and SUM(c.licensecount)>SUM(d.licensecount) then SUM(c.licensecount)-SUM(d.licensecount) else 0 end end end as Cancel --<Ram 5/28/2014> Updated to fix a bug on Missing Screen Count

,sum(d.TTSalesCommissionException) as TargetTTSalesCommissionException,sum(c.TTSalesCommissionException) as BaseTTSalesCommissionException
from
(
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE,mbo.TTSalesCommissionException
from
(
select AccountId, DELIVERYNAME,m.ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed,SUM(BillableLicenseCount)as LicenseCount, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,TTSalesCommissionException
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
Join timeinterval T on m.year=t.year and m.month=t.month
where enddate>=dateadd(mm,-12,@Rundate) and enddate<=@Rundate
and screens='screens'
and deliveryname  not in ( select deliveryname from #temp)
group by AccountId, DELIVERYNAME, m.ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE,TTSalesCommissionException
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
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.LicenseCount,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE,mbo.TTSalesCommissionException
from
(
select AccountId, DELIVERYNAME,m.ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed,SUM(BillableLicenseCount)as LicenseCount, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,TTSalesCommissionException
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
where YEAR =@Runyear 
and MONTH=@Runmonth
and screens='screens'
and deliveryname not in ( select deliveryname from #tempcurrent)
group by AccountId, DELIVERYNAME, m.ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE,TTSalesCommissionException
) mbo left Join
(
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on mbo.Country=rm.Country and isnull(nullif(mbo.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
union 
select * from #tempcurrent

)d 
on c.deliveryname=d.deliveryname
--c.AccountId=d.AccountId and
group by c.accountid,d.accountid,c.deliveryname,d.deliveryname,c.productsku,d.productsku,d.TTBillEnd,c.TTBillend,d.SalesOffice,d.SalesRegion,c.SalesOffice,c.SalesRegion,c.PriceGroup,d.PriceGroup,c.PriceGroupDesc,d.PriceGroupDesc,c.CustGroup,d.CustGroup,c.TTConversiondate,d.TTConversiondate
,d.TTSalesCommissionException
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
select AccountId,deliveryname,sum(case when year =@Baseyear and month=@BaseMonthNum then Billedamount end) as MayRevenue,
sum(case when year=@Runyear and month=@CurrentMonthNum then Billedamount end) as CurrentMonthRevenue,
sum(case when year =@Baseyear and month=@BaseMonthNum then BillableLicenseCount end) as BaselineCount,
sum(case when year=@Runyear and month=@CurrentMonthNum then BillableLicenseCount end) as TargetCount

 from 
dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
where screens='screens'
group by AccountId,deliveryname
)k
on j.AccountId=k.AccountId and j.Deliveryname=k.DELIVERYNAME
Group by  j.AccountName,j.AccountId,j.Deliveryname,ProductName,k.AccountId,k.DELIVERYNAME
)Q
Left Join Account A 
on Q.AccountId=A.Accountid
Group by MasterAccountName,Q.AccountName,A.Accountid,Deliveryname,ProductName
)Final


drop table #temp
drop table #tempcurrent

	SET @Runyear = case when @RunMonth = 1 then @Runyear-1 else @Runyear End
	SET @Runmonth=case when @RunMonth = 1 then 12 else @Runmonth-1 End
End

END
Select Year,Month,Quarter , MasterAccountName,AccountName,AccountId,Deliveryname,ProductName
,Cancels ,Adds ,BaselineCount,TargetCount,NetCount,Transfer,NameChange,Upgrade, Downgrade, Migration
from #LicenseImpact
















