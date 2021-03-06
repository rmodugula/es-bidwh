USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetGetAllClientMnthlySummary]    Script Date: 03/14/2014 11:31:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create PROCEDURE [dbo].[GetAllClientsMnthlyTrnxSummary]
@Year Int,
@Month Int
     
AS
BEGIN

select ISNULL(x.year,y.year) as Year,ISNULL(x.month,y.month) as Month,ISNULL(x.AccountId,y.AccountId) as AccountId,
ISNULL(x.MasterAccountName,y.MasterAccountName) as MasterAccountName, ISNULL(x.AccountName,y.AccountName) as AccountName,
ISNULL(x.Region,y.Region) as Region,XTrader as XTraderLicenses, Change, FATrx,XTTrx 
from
(
select C.YEAR,c.MONTH,c.AccountId,c.MasterAccountName,c.AccountName,c.Region,
c.XTrader,c.XTrader-isnull(p.XTrader,0) as Change
from
(
 select YEAR,MONTH,AccountId,MasterAccountName,AccountName,Region,
sum(XTrader) as XTrader from 
 (
select year,month,MasterAccountName,AccountName,M.AccountId,ProductName,
deliveryname,ttdescription,Region,
SUM(BillableLicenseCount) as XTrader
from MonthlyBillingData M join Account A
on M.AccountId=A.Accountid
left join Product P
on M.ProductSku=P.ProductSku
where M.ProductSku in (20005,20999)
and YEAR=@Year and MONTH=@Month
group by MasterAccountName,AccountName,M.AccountId,YEAR,MONTH,ProductName,DataAreaId,
CustGroup,DELIVERYNAME,ttdescription,Region,ProductName
) K
group by YEAR,MONTH,AccountId,MasterAccountName,AccountName,Region
)C
left join
(
 select YEAR,MONTH,AccountId,MasterAccountName,AccountName,Region,
sum(XTrader) as XTrader from 
 (
select year,month,MasterAccountName,AccountName,M.AccountId,ProductName,
deliveryname,ttdescription,Region,
SUM(BillableLicenseCount) as XTrader
from MonthlyBillingData M join Account A
on M.AccountId=A.Accountid
left join Product P
on M.ProductSku=P.ProductSku
where M.ProductSku in (20005,20999)
and YEAR=case when @Month=1 then @Year-1 else @Year end 
and MONTH=case when @Month=1 then 12 else @Month-1 end
group by MasterAccountName,AccountName,M.AccountId,YEAR,MONTH,ProductName,DataAreaId,
CustGroup,DELIVERYNAME,ttdescription,Region,ProductName
) K
group by YEAR,MONTH,AccountId,MasterAccountName,AccountName,Region
)P
on c.AccountId=P.AccountId and c.Region=p.Region
)X 
full outer join 
(
select 
a.year as Year,
a.month as Month,
c.Accountid,
c.MasterAccountName,
c.AccountName,
Region,
Case when axproductid in ('20998') then SUM(fills) end as FATrx,
case when axproductid in ('20005','20999') then SUM(fills) end as XTTrx
--Case when axproductid in ('20998','20996') then SUM(fills) end as FATrx,
--case when axproductid in ('20005','20995','10106','20999','20997') then SUM(fills) end as XTTrx

from
	(
	select 	ExchangeId,sum(Fills) as Fills,P.ProductName,F.AccountId,DELIVERYNAME,F.UserName,F.Month,F.Year,TransactionDate,AxProductId
	,r.Region
	from dbo.fills F left join (select distinct year,month,accountid,deliveryname,TTDESCRIPTION,Region from MonthlyBillingData)M
	on F.Year=M.Year and F.Month=M.Month and F.AccountId=M.AccountId and f.UserName=m.TTDESCRIPTION
	left join Account A
	on F.AccountId=A.Accountid
	left join Product P
	on F.AxProductId=P.ProductSku
left join (select  distinct year, month,accountid,Username,Region from 
(select distinct year, month,accountid,username,countrycode from [USER]
 where YEAR=@Year and MONTH=@Month) U 
left join 
(select distinct region, country from RegionMap) R
on u.CountryCode=r.Country
)R
on F.Year=r.Year and f.Month=r.Month and f.AccountId=r.AccountId and f.UserName=r.UserName
	where IsBillable='Y' and 
	F.Year=@Year and F.Month=@Month
	and AxProductId in ('20998','20005','20999')
	--and AxProductId in ('20998','20005','20999','20996','20995','20997','10106')
	group by  ExchangeId,P.ProductName,F.AccountId,F.Month,F.Year,TransactionDate,
	AxProductId,f.UserName,DELIVERYNAME,r.Region
		)a
left join
	(
	select * from dbo.Exchange
	)b
on a.ExchangeId=b.ExchangeID
left join
	(
	select * from dbo.Account
	)c
on a.AccountId=c.AccountId
--where MasterAccountName<>'TradeCo'
 group by c.AccountName,b.ExchangeName,a.ProductName,a.month,a.year,a.AxProductId,
 c.Accountid,c.MasterAccountName,Region)Y
on x.Year=y.Month and x.Month=y.Month and x.AccountId=y.Accountid and x.Region=y.Region



end
--select C.YEAR,c.MONTH,c.AccountId,c.MasterAccountName,c.AccountName,c.Region,
--c.MetricName,c.Metric,c.Metric-isnull(p.Metric,0) as Change
--from
--(
-- select YEAR,MONTH,AccountId,MasterAccountName,AccountName,Region,
--LicenseName as MetricName,sum(LicenseCounts) as Metric from 
-- (
--select year,month,MasterAccountName,AccountName,M.AccountId,ProductName,
--deliveryname,ttdescription,Region,
--'X_Trader Licenses' as LicenseName,
--SUM(BillableLicenseCount) as LicenseCounts
--from MonthlyBillingData M join Account A
--on M.AccountId=A.Accountid
--left join Product P
--on M.ProductSku=P.ProductSku
--where M.ProductSku in (20005,20999,20997,20995,10106)
--and YEAR=@Year and MONTH=@Month
--group by MasterAccountName,AccountName,M.AccountId,YEAR,MONTH,ProductName,DataAreaId,
--CustGroup,DELIVERYNAME,ttdescription,Region,ProductName
--) K
--group by YEAR,MONTH,AccountId,MasterAccountName,AccountName,LicenseName,Region
--)C
--left join
--(
-- select YEAR,MONTH,AccountId,MasterAccountName,AccountName,Region,
--LicenseName as MetricName,sum(LicenseCounts) as Metric from 
-- (
--select year,month,MasterAccountName,AccountName,M.AccountId,ProductName,
--deliveryname,ttdescription,Region,
--'X_Trader Licenses' as LicenseName,
--SUM(BillableLicenseCount) as LicenseCounts
--from MonthlyBillingData M join Account A
--on M.AccountId=A.Accountid
--left join Product P
--on M.ProductSku=P.ProductSku
--where M.ProductSku in (20005,20999,20997,20995,10106)
--and YEAR=case when @Month=1 then @Year-1 else @Year end 
--and MONTH=case when @Month=1 then 12 else @Month-1 end
--group by MasterAccountName,AccountName,M.AccountId,YEAR,MONTH,ProductName,DataAreaId,
--CustGroup,DELIVERYNAME,ttdescription,Region,ProductName
--) K
--group by YEAR,MONTH,AccountId,MasterAccountName,AccountName,LicenseName,Region
--)P
--on c.AccountId=P.AccountId and c.Region=p.Region

--union all

--select 
--a.year as Year,
--a.month as Month,
--c.Accountid,
--c.MasterAccountName,
--c.AccountName,
--Region,
--Case 
--when axproductid in ('20998','20996') then 'FA Trx'
--      when axproductid in ('20005','20995','10106','20999','20997') then 'XT Trx'
--     End as MetricName
-- ,sum(a.Fills) as Metric, NUll as Change
--from
--	(
--	select 	ExchangeId,sum(Fills) as Fills,P.ProductName,F.AccountId,DELIVERYNAME,F.UserName,F.Month,F.Year,TransactionDate,AxProductId
--	,Region
--	from dbo.fills F left join (select distinct year,month,accountid,deliveryname,TTDESCRIPTION,Region from MonthlyBillingData)M
--	on F.Year=M.Year and F.Month=M.Month and F.AccountId=M.AccountId and f.UserName=m.TTDESCRIPTION
--	left join Account A
--	on F.AccountId=A.Accountid
--	left join Product P
--	on F.AxProductId=P.ProductSku
--	where IsBillable='Y' 
--	and F.Year=@Year and F.Month=@Month
--	and AxProductId in ('20998','20005','20999','20996','20995','20997','10106')
--	group by  ExchangeId,P.ProductName,F.AccountId,F.Month,F.Year,TransactionDate,
--	AxProductId,UserName,DELIVERYNAME,Region
--		)a
--left join
--	(
--	select * from dbo.Exchange
--	)b
--on a.ExchangeId=b.ExchangeID
--left join
--	(
--	select * from dbo.Account
--	)c
--on a.AccountId=c.AccountId
-- group by c.AccountName,b.ExchangeName,a.ProductName,a.month,a.year,a.AxProductId,
-- c.Accountid,c.MasterAccountName,Region
--end





