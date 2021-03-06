USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetGetAllClientMnthlyTrx]    Script Date: 03/14/2014 11:32:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create PROCEDURE [dbo].[GetAllClientsMnthlyTrxDetails]
@Year Int,
@Month Int,
@AccountName varchar(50)
     
AS
BEGIN

select MasterAccountName,z.UserName,TraderName,ProductName,CountryCode,City,Region,FixAdapterName,XtraderLicenses,FATrx,XTTrx,cast(isnull(LastLogin,'1/1/1900')as DATE) as LastLoginDate from
(
select Year,Month, AccountId,MasterAccountName,AccountName,ProductName,TraderName,Username,Region,FixAdapterName,SUM(XtraderLicenses) as XtraderLicenses,
SUM(FATrx) as FATrx, SUM(XTTrx) as XTTrx from
(
select ISNULL(x.year,y.year) as Year, ISNULL(x.Month,Y.Month) as Month,ISNULL(x.AccountId,y.AccountId) as AccountId
, ISNULL(x.MasterAccountName,y.MasterAccountName) as MasterAccountName,ISNULL(x.AccountName,y.AccountName) as AccountName
, ISNULL(x.ProductName,y.ProductName) as ProductName,ISNULL(x.TraderName,y.TraderName) as TraderName,ISNULL(x.Username,y.Username) as Username
, ISNULL(x.region,y.region) as Region,FixAdapterName,XtraderLicenses,FATrx,XTTrx from
(
select YEAR,MONTH,AccountId,MasterAccountName,AccountName,ProductName,DELIVERYNAME as TraderName,TTDESCRIPTION as Username,Region,sum(Xtrader) as XtraderLicenses from 
 (
select year,month,MasterAccountName,AccountName,M.AccountId,ProductName,
deliveryname,ttdescription,Region,
SUM(BillableLicenseCount) as Xtrader
from MonthlyBillingData M join Account A
on M.AccountId=A.Accountid
left join Product P
on M.ProductSku=P.ProductSku
where 
M.ProductSku in (20005,20999)
--M.ProductSku in (20005,20999,20997,20995,10106)
and YEAR=@Year and MONTH=@Month
group by MasterAccountName,AccountName,M.AccountId,YEAR,MONTH,ProductName,DataAreaId,
CustGroup,DELIVERYNAME,ttdescription,Region,ProductName
) K
where MasterAccountName = @AccountName
group by YEAR,MONTH,AccountId,MasterAccountName,AccountName,DELIVERYNAME,TTDESCRIPTION,
Region,ProductName
)X 
full outer join
(
select 
a.year as Year,
a.month as Month,
c.Accountid,
c.MasterAccountName,
c.AccountName,
ProductName,
DELIVERYNAME as TraderName,
a.UserName,
Region,
nullif(FixAdapterName,'') as FixAdapterName,
Case when axproductid in ('20998') then sum(fills) end as FATrx,
case when axproductid in ('20005','20999') then sum(fills) end as XTTrx
--Case when axproductid in ('20998','20996') then sum(fills) end as FATrx,
--case when axproductid in ('20005','20995','10106','20999','20997') then sum(fills) end as XTTrx

from
	(
	select 	ExchangeId,sum(Fills) as Fills,P.ProductName,F.AccountId,DELIVERYNAME,F.UserName,F.Month,F.Year,TransactionDate,AxProductId
	,r.Region,FixAdapterName
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
	where IsBillable='Y' 
	and F.Year=@Year and F.Month=@Month
	and AxProductId in ('20998','20005','20999')
	--and AxProductId in ('20998','20005','20999','20996','20995','20997','10106')
	group by  ExchangeId,P.ProductName,F.AccountId,F.Month,F.Year,TransactionDate,
	AxProductId,f.UserName,DELIVERYNAME,r.Region,FixAdapterName
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
where MasterAccountName = @AccountName
group by a.year,a.month,c.Accountid,c.MasterAccountName,c.AccountName,ProductName,DELIVERYNAME,a.UserName,Region,FixAdapterName,a.AxProductId

) Y
on x.Year=y.Year and x.Month=y.Month and x.AccountId=y.Accountid and x.ProductName=y.ProductName and x.TraderName=y.TraderName and x.Username=y.UserName
and x.Region=y.Region
)G
group by Year,Month, AccountId,MasterAccountName,AccountName,ProductName,TraderName,Username,Region,FixAdapterName
 )Z Left Join 
 (
select Q.*,CountryCode, City from
(
select * from
(
select distinct ul.Year, ul.Month, ul.UserName, LastLogin,accountid,networkid,
ROW_NUMBER() over (partition by ul.year,ul.month,ul.Username order by lastlogin desc) as num from dbo.UserLogin UL
where ul.YEAR=@Year and ul.MONTH=@Month
)A
where num=1
)Q 
left outer join
(
select distinct year,month,accountid,networkid,username,countrycode,nullif(city,'') as City
from [user]
where YEAR=@Year and MONTH=@Month
) Q1
on q.Year=q1.Year and q.Month=q1.month and q.UserName=q1.UserName and q.AccountId=q1.AccountId and q.NetworkId=q1.NetworkId

 ) L
 on Z.year=L.year and Z.Month=L.month and z.Username=L.UserName 
 --where MasterAccountName = @AccountName


end
