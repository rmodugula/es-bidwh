USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetRevenueImpactSSO]    Script Date: 8/3/2015 4:22:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetRevenueImpactSSO] 
     @Baseyear int,
    @Currentyear int,
    @Basemonth char(10), 
	@CurrentMonth char(10)
	 
AS

-- **** Global Variables ***
declare @LastdayBaseMonth date , @LastdayCurrentMonth date , @BaseMonthNum int, @CurrentMonthNum int

SET @LastdayBaseMonth = (select CAST(EndDate as date) from TimeInterval where YEAR=@Baseyear and MonthName=@Basemonth)
SET @LastdayCurrentMonth = (select CAST(EndDate as date) from TimeInterval where YEAR=@Currentyear and MonthName=@Currentmonth)
SET @BaseMonthNum = case 
when @Basemonth = 'Jan' then 1
when @Basemonth = 'Feb' then 2
when @Basemonth = 'Mar' then 3
when @Basemonth = 'Apr' then 4
when @Basemonth = 'May' then 5
when @Basemonth = 'Jun' then 6
when @Basemonth = 'Jul' then 7
when @Basemonth = 'Aug' then 8
when @Basemonth = 'Sep' then 9
when @Basemonth = 'Oct' then 10
when @Basemonth = 'Nov' then 11
when @Basemonth = 'Dec' then 12
end
SET @CurrentMonthNum = case 
when @Currentmonth = 'Jan' then 1
when @Currentmonth = 'Feb' then 2
when @Currentmonth = 'Mar' then 3
when @Currentmonth = 'Apr' then 4
when @Currentmonth = 'May' then 5
when @Currentmonth = 'Jun' then 6
when @Currentmonth = 'Jul' then 7
when @Currentmonth = 'Aug' then 8
when @Currentmonth = 'Sep' then 9
when @Currentmonth = 'Oct' then 10
when @Currentmonth = 'Nov' then 11
when @Currentmonth = 'Dec' then 12
end

-- **** end Global Variables ***
BEGIN
SET NOCOUNT ON;
------------------------------------------------------------Temp table for From Month------------------------------------------------------------------------
Create table #temp
(Accountid nvarchar(200),DELIVERYNAME nvarchar(200),productsku nvarchar(200),LineAmount float(50),BilledAmount float (50)
,ttbillend datetime ,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime )

insert into #temp

select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE
from 
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed
from dbo.MonthlyBillingData  M
join Product P on m.ProductSku=p.ProductSku
where YEAR =@Baseyear
and MONTH=@BaseMonthNum
and screens='screens'
--and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993,80000,80001,80002,80003)
group by AccountId, DELIVERYNAME
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, m.ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,m.productsku desc)as row	 
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
where YEAR =@Baseyear 
and MONTH=@BaseMonthNum
and screens='screens'
--and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993,80000,80001,80002,80003)
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
(Accountid nvarchar(200),DELIVERYNAME nvarchar(200),productsku nvarchar(200),LineAmount float(50),BilledAmount float (50)
,ttbillend datetime,SalesOffice varchar(50),SalesRegion varchar(50),PriceGroup varchar(50),PriceGroupDesc varchar(100),CustGroup varchar(10),TTCONVERSIONDATE datetime )

insert into #tempcurrent
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE 
from
(
select a.accountid,a.deliveryname,b.productsku,a.line,a.billed,b.TTBillEnd,b.Region,b.Country,b.[State],b.PriceGroup,b.PriceGroupDesc,b.CustGroup,b.TTCONVERSIONDATE
from
(
select AccountId, DELIVERYNAME
,sum(LineAmount) as Line,sum(BilledAmount) as Billed
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
where YEAR =@Currentyear 
and MONTH=@CurrentMonthNum 
and screens='screens'
--and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993,80000,80001,80002,80003)
group by AccountId, DELIVERYNAME
)a join
(
select h.* from
(
select AccountId, DELIVERYNAME
, m.ProductSku, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
,ROW_NUMBER() Over (Partition by accountid,DeliveryName order by (case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end) desc,m.productsku desc)as row	 
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
where YEAR =@Currentyear 
and MONTH=@CurrentMonthNum
and screens='screens'
--and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993,80000,80001,80002,80003)
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

Create table #RevenueImpact
(AccountName nvarchar(200),AccountId nvarchar(200),Deliveryname nvarchar(200),TTCONVERSIONDATE datetime,ChangeInPrice numeric(28,2),Upgrade numeric(28,2)
,Downgrade numeric(28,2),Cancel numeric(28,2),Adds numeric(28,2),TotalChange numeric(28,2),
BaselineRevenue numeric(28,2),TargetRevenue numeric(28,2),PRICEGROUP nvarchar(200),PriceGroupDesc nvarchar(200),CustomerGroup nvarchar(100),SalesOffice nvarchar(50),SalesRegion nvarchar(50),Productname varchar(50)
)
insert into #RevenueImpact
select j.AccountName,j.AccountId,j.Deliveryname,j.TTCONVERSIONDATE,j.ChangeInPrice,j.Upgrade,j.Downgrade,j.Cancel,j.Adds,j.TotalChange,isnull(k.MayRevenue,0) as BaselineRevenue,isnull(k.CurrentMonthRevenue,0) as TargetRevenue,
j.PRICEGROUP as PriceGroup,j.PriceGroupDesc as PriceGroupDesc,j.CUSTGROUP as CustomerGroup,isnull(j.SalesOffice,'Unmapped') as SalesOffice,isnull(j.SalesRegion,'None') as SalesRegion,ProductName from
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
, case when  (c.productsku=d.productsku and SUM(c.billed)>0 and cast(c.ttbillend as date)>= @LastdayBaseMonth
)  and cast(d.ttbillend as date) >=(@LastdayCurrentMonth) then isnull(sum(d.Billed-c.Billed),0) end as Line
,case when (c.productsku is null and d.ProductSku is not null) or (sum(c.billed)=0  and d.productsku in (20000,20200,20005,20999,20995,20997,20992,20993,80000,80001,80002,80003,80005,80006)) or (SUM(c.billed)>0 and CAST(c.ttbillend as date) <@LastdayBaseMonth and SUM(d.billed)>0 and CAST(d.ttbillend as date)>=@LastdayBaseMonth)  then isnull(SUM(ISNULL(d.billed,0)-ISNULL(c.billed,0)),0) end as Adds
--or (SUM(c.billed)>0 and CAST(c.ttbillend as date) <@LastdayBaseMonth and SUM(d.billed)>0 and CAST(d.ttbillend as date)>=@LastdayBaseMonth) 
, case when c.ProductSku in (20000,20005,20992,20995,80000,80002,80005) and SUM(c.billed)>0 and cast(c.ttbillend as date) >= (@LastdayBaseMonth)  and d.ProductSku in (20200,20999,20997,20993,80001,80003,80006) and cast(d.ttbillend as date)>=(@LastdayCurrentMonth) then isnull(SUM(ISNULL(d.billed,0)-ISNULL(c.billed,0)),0) end as Upgrade
, case when c.ProductSku in (20200,20999,20997,20993,80001,80003,80006) and SUM(c.billed)>0  and cast(c.ttbillend as date) >= @LastdayBaseMonth  and (d.ProductSku in(20000,20005,20992,20995,80000,80002,80005) and cast(d.ttbillend as date)>=(@LastdayCurrentMonth)) then isnull(SUM(ISNULL(d.billed,0)-ISNULL(c.billed,0)),0) end as Downgrade
, case when (c.ProductSku in (20200,20000,20005,20999,20995,20997,20992,20993,80000,80001,80002,80003,80005,80006) and SUM(c.billed)>0 and cast(c.ttbillend as date) >= @LastdayBaseMonth  and (d.productsku is null or cast(d.ttbillend as date)<(@LastdayCurrentMonth))) or (SUM(c.billed)>0 and CAST(c.ttbillend as date) <@LastdayBaseMonth and d.productsku is null)  then isnull(SUM(ISNULL(d.billed,0)-ISNULL(c.billed,0)),0) end as Cancel
from
(
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE 
from
(
select AccountId, DELIVERYNAME,m.ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku 
where YEAR =@Baseyear 
and MONTH=@BaseMonthNum
and screens='screens'
--and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993,80000,80001,80002,80003)
and deliveryname  not in ( select deliveryname from #temp)
group by AccountId, DELIVERYNAME, m.ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
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
select mbo.accountid,mbo.deliveryname,mbo.productsku,mbo.line,mbo.billed,mbo.TTBillEnd,rm.SalesOffice,mbo.Region as SalesRegion,mbo.PriceGroup,mbo.PriceGroupDesc,mbo.CustGroup,mbo.TTCONVERSIONDATE 
from
(
select AccountId, DELIVERYNAME,m.ProductSku
,sum(LineAmount) as Line,sum(BilledAmount) as Billed, case when ttbillend='1900-01-01' then '2200-01-01' else TTBillEnd end as TTBillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
from dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku 
where YEAR =@Currentyear 
and MONTH=@CurrentMonthNum 
and screens='screens'
--and ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993,80000,80001,80002,80003)
and deliveryname not in ( select deliveryname from #tempcurrent)
group by AccountId, DELIVERYNAME, m.ProductSku,ttbillend,Region,Country,[State],PriceGroup,PriceGroupDesc,CustGroup,TTCONVERSIONDATE
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
select AccountId,deliveryname,sum(case when year =@Baseyear and month=@BaseMonthNum then Billedamount end) as MayRevenue,
sum(case when year=@Currentyear and month=@CurrentMonthNum then Billedamount end) as CurrentMonthRevenue
 from 
dbo.MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku 
and screens='screens'
--where ProductSku in (20000,20200,20005,20999,20995,20997,20992,20993,80000,80001,80002,80003) 
group by AccountId,deliveryname
)k
on j.AccountId=k.AccountId and j.Deliveryname=k.DELIVERYNAME


-------------------------------------- Show All Report's Data--------------------------------------------------------------
if (select rtrim(replace(suser_sname(),'INTAD\',''))) in 
(select username from Staff
where CostCenter in (210)
union all
select UserName from dbo.SecurityTable where DatabaseRole='SalesMDs'
union all
select username from SecurityTable
where DatabaseRole='BI-ES'
union all
select UserName from dbo.SecurityTable where DatabaseRole='Executive'
)
Begin
select * from #RevenueImpact
END
else
----------------------------------- Show Data BY Region-------------------------------------
if (select rtrim(replace(suser_sname(),'INTAD\',''))) in  (select username from Staff where IsActive='Y' and CostCenter in (600,610) and UserName not in (select UserName from dbo.SecurityTable where DatabaseRole='SalesMDs'))
BEGIN
select query.* from
(
select * from #RevenueImpact
)query join 
(select Region from staff
where username=(select replace(suser_sname(),'INTAD\',''))
)S
on query.SalesRegion=S.Region   ----<Ram 3/7/2014 14:30> Changed logic to filter by User Region as per Parker's Requirement
order by query.accountid,query.Deliveryname
end
-----------------------------------------------------------------Drop Temp Tables Created--------------------------------------------------------------------

drop table #temp
drop table #tempcurrent
END













