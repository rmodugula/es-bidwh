USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTransactionDetailReport]    Script Date: 5/4/2016 11:38:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetTransactionDetailReport]
(@Year Int, @Month int)
     
     
AS

declare @FirstDayOfMonth smalldatetime , @LastDayOfMonth smalldatetime, @FirstDayOfNextMonth smalldatetime, @defaultdate smalldatetime

SET @FirstDayOfMonth = CONVERT(varchar,@Month) + '/1/' + CONVERT(varchar,@Year)
SET @FirstDayOfNextMonth = DATEADD(m,1,@FirstDayOfMonth)
SET @LastDayOfMonth = DATEADD(d,-1,@FirstDayOfNextMonth)

set @defaultdate = '1900-01-01 00:00:00.000'

BEGIN

select Year, Month,AccountId,MasterAccountName,AccountName,DELIVERYNAME,UserName,AXCompany,CustomerGroup,MetricName,SUM(metric) as Metric from
(
 select Q.YEAR,Q.Month,Q.Accountid,MasterAccountName,AccountName,DELIVERYNAME,UserName,AXCompany,CustomerGroup,
 case when AxProductId in (20999,20997,20993) then '#XTPros'
when AxProductId in (20005,20995,20992,10106)then '#XTs'
end as MetricName, COUNT(distinct username) as Metric
 from
 (
 select distinct F.YEAR,F.Month,F.Accountid,Username,Axproductid,DELIVERYNAME,AXCompany from Fills F
  left join 
 (select distinct YEAR,Month,Accountid,ProductSku,Deliveryname,DataAreaId as AXCompany,TTDESCRIPTION from bidw.dbo.MonthlyBillingData 
 where YEAR=@Year and MONTH=@Month and ProductSku in (20005,20999,20997,20993,20995,20992,10106)
 ) M
 on F.Year=M.Year and F.Month=m.Month and F.AccountId=m.AccountId and F.UserName=m.TTDESCRIPTION and F.AxProductId=m.ProductSku
 where F.YEAR=@Year and F.MONTH=@Month
 and Axproductid in (20005,20999,20997,20993,20995,20992,10106)
 and IsBillable='Y'
 and NetworkId not in (577)
 )Q
 left join Account A
 on Q.AccountId=A.Accountid
 where MasterAccountName <>'TradeCo'
 group by Q.YEAR,Q.Month,Q.Accountid,Axproductid,MasterAccountName,AccountName,UserName,CustomerGroup,AXCompany,DELIVERYNAME
 )z
 group by Year, Month,AccountId,MasterAccountName,AccountName,DELIVERYNAME,UserName,AXCompany,CustomerGroup,MetricName
-- select YEAR,MONTH,AccountId,MasterAccountName,AccountName,DELIVERYNAME,TTDESCRIPTION,
-- AXCompany,CustomerGroup,LicenseName as MetricName,sum(LicenseCounts) as Metric from 
-- (
--select year,month,MasterAccountName,AccountName,M.AccountId,
--DataAreaId as AXCompany,
--CustGroup as CustomerGroup,deliveryname,ttdescription,
--case when productsku in (20999,20997,20993) then '#XTPros'
--when productsku in (20005,20995,20992,10106)then '#XTs'
--end as LicenseName,
--SUM(BillableLicenseCount) as LicenseCounts
--from bidw.dbo.MonthlyBillingData M join Account A
--on M.AccountId=A.Accountid
--where ProductSku in (20005,20999,20997,20993,20995,20992,10106)
--and YEAR=@Year and MONTH=@Month
--and MasterAccountName <>'TradeCo'
--group by MasterAccountName,AccountName,M.AccountId,YEAR,MONTH,ProductSku,DataAreaId,CustGroup,DELIVERYNAME,ttdescription
--) K
--group by YEAR,MONTH,AccountId,MasterAccountName,AccountName,DELIVERYNAME,TTDESCRIPTION,
-- AXCompany,CustomerGroup,LicenseName




UNION ALL

SELECT year(ct.INVOICEDATE) as Year,Month(ct.INVOICEDATE) as Month,substring(A.Accountid,1,7) as Accountid,MasterAccountName,[TTCUSTNAME],
ttdlvname,ttdescription,ct.DATAAREAID as AXCompany,A.customergroup as CustGroup,
case when itemid in (20005,20995,20992,10106) then '#XTsCap'
when itemid in (20999,20997,20993) then '#XTProsCap'
end as LicenseName
,COUNT(distinct TTDESCRIPTION) as LicenseCounts
FROM chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICETRANS] CT 
join chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICEJour] J
on ct.invoiceid=j.invoiceid and ct.dataareaid=j.dataareaid
join account A
on J.invoiceaccount=a.accountid
where TTLINEDISCOUNT <>0
and ITEMID in (20005,20999,20997,20993,20995,20992,10106)
and MasterAccountName <>'TradeCo'
and year(ct.invoicedate)=@Year and MONTH(ct.invoicedate)=@Month
group by [TTCUSTNAME],year(ct.INVOICEDATE),Month(ct.INVOICEDATE),substring(A.Accountid,1,7),itemid,A.customergroup,
Masteraccountname,ct.DATAAREAID,ttdlvname,ttdescription

UNION ALL
 
select @Year as Year,@Month as Month,substring(A.custaccount,1,7) as Accountid,c.MasterAccountName,c.AccountName,
b.Deliveryname,ttdescription,A.dataareaid as AXCompany,C.CustomerGroup as custgroup,
case when itemid in (20005,20995,20992,10106) then '#XTsCap'
when itemid in (20999,20997,20993) then '#XTProsCap'
end as LicenseName,count(distinct ttdescription) as LicenseCounts
from chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE A
inner join chiaxsql01.TT_DYANX09_PRD.dbo.SALESTABLE B
on  A.SALESID = B.SALESID and A.DATAAREAID = B.DATAAREAID
inner join Account C
on B.INVOICEACCOUNT = C.Accountid
where A.SALESSTATUS = 1 -- 1 corresponds 'Open Order' Line status
and (A.TTBILLSTART = @defaultdate  or A.TTBILLSTART <= @LastDayOfMonth)
and (A.TTBILLEND = @defaultdate or A.TTBILLEND >= @FirstDayOfMonth) 
and ITEMID in (20005,20999,20997,20993,20995,20992,10106)
and MasterAccountName <>'TradeCo'
and TTLINEDISCOUNT <>0
and A.salesid not in 
(select distinct salesid from  chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICEjour]
where YEAR(invoicedate)=@Year and MONTH(invoicedate)=@Month)
group by substring(A.custaccount,1,7),c.customergroup,A.dataareaid,b.Deliveryname,MasterAccountName,AccountName,ttdescription,itemid

UNION ALL


SELECT year(ct.INVOICEDATE) as Year,Month(ct.INVOICEDATE) as Month,substring(A.Accountid,1,7) as Accountid,MasterAccountName,[TTCUSTNAME],
ttdlvname,ttdescription,ct.DATAAREAID as AXCompany,A.CustomerGroup as custgroup,
 'TotalCapped' LicenseName
,COUNT(distinct TTDESCRIPTION) as LicenseCounts
  FROM chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICETRANS] CT 
  join chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICEJour] J
  on ct.invoiceid=j.invoiceid and ct.dataareaid=j.dataareaid
  join account A
 on J.invoiceaccount=a.accountid
  where TTLINEDISCOUNT <>0
  and ITEMID in (20005,20999,20997,20993,20995,20992,10106)
  and MasterAccountName <>'TradeCo'
   and year(ct.invoicedate)=@Year and MONTH(ct.invoicedate)=@Month
  group by [TTCUSTNAME],year(ct.INVOICEDATE),Month(ct.INVOICEDATE),substring(A.Accountid,1,7),itemid,A.CustomerGroup,Masteraccountname,ct.DATAAREAID,ttdlvname,ttdescription

UNION
 

  select @Year as Year,@Month as Month,substring(A.custaccount,1,7) as Accountid,c.MasterAccountName,c.AccountName,
  b.Deliveryname,ttdescription,A.dataareaid as AXCompany,C.CustomerGroup as custgroup,
  'TotalCapped' as LicenseName,count(distinct ttdescription) as LicenseCounts
 from chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE A
 inner join chiaxsql01.TT_DYANX09_PRD.dbo.SALESTABLE B
 on  A.SALESID = B.SALESID and A.DATAAREAID = B.DATAAREAID
 inner join Account C
 on B.INVOICEACCOUNT = C.Accountid
 where A.SALESSTATUS = 1 -- 1 corresponds 'Open Order' Line status
 and (A.TTBILLSTART = @defaultdate  or A.TTBILLSTART <= @LastDayOfMonth)
 and (A.TTBILLEND = @defaultdate or A.TTBILLEND >=@FirstDayOfMonth) 
 and ITEMID in (20005,20999,20997,20993,20995,20992,10106)
  and MasterAccountName <>'TradeCo'
  and TTLINEDISCOUNT <>0
  and A.salesid not in 
  (select distinct salesid from  chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICEjour]
  where YEAR(invoicedate)=@Year and MONTH(invoicedate)=@Month)
 group by substring(A.custaccount,1,7),C.CustomerGroup,A.dataareaid,b.Deliveryname,MasterAccountName,AccountName,ttdescription,itemid

UNION ALL

select 
a.year as Year,
a.month as Month,
c.Accountid,
c.MasterAccountName,
c.AccountName,
deliveryname,
a.UserName,
a.AXCompany,
a.CustomerGroup,
Case 
when axproductid in ('20998','20996') then '#FATrx'
      when axproductid in (20005,20995,20992,10106) then '#XTTrx'
      when axproductid in (20999,20997,20993) then '#XTProTrx' 
  End as MetricName
 ,sum(a.Fills) as Metric
from
	(
	select 	ExchangeId,sum(Fills) as Fills,F.AccountId,u.FullName as DELIVERYNAME,F.UserName,F.Month,F.Year,AxProductId,DataAreaId as AXCompany,A.CustomerGroup as CustomerGroup
	from 
	(
	Select Year,Month,ExchangeId,AccountId,Username,AxProductId,sum(fills) as Fills from dbo.fills 
	where year=@Year and month=@Month and IsBillable='Y' and AxProductId in (20998,20005,20999,20996,20995,20992,20997,20993,10106)
	group by Year,Month,ExchangeId,AccountId,Username,AxProductId
	) F 
	left join (select distinct year,month,accountid,deliveryname,TTDESCRIPTION,dataareaid,custgroup,ProductSku from bidw.dbo.MonthlyBillingData where year=@year and month=@Month)M
	on F.Year=M.Year and F.Month=M.Month and F.AccountId=M.AccountId and f.UserName=m.TTDESCRIPTION and f.AxProductId=m.ProductSku
	left join (select distinct YEAR,MONTH,accountid,username,fullname from [User] where year=@year and month=@Month) U
	on f.Year=u.Year and f.Month=u.Month and f.AccountId=u.AccountId and f.UserName=u.UserName	
	left join Account A
	on F.AccountId=A.Accountid
	group by  ExchangeId,F.AccountId,F.Month,F.Year,AxProductId,DataAreaId,A.CustomerGroup,f.UserName,u.FullName
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
    where MasterAccountName not like '%TRADECO Global%'
 group by c.AccountName,b.ExchangeName,a.month,a.year,a.AxProductId,c.Accountid,c.MasterAccountName,a.AXCompany,a.CustomerGroup,a.Username,DELIVERYNAME
 

UNION ALL

Select Year,Month,Accountid,MasterAccountName,AccountName,deliveryname,Username,AXCompany,CustomerGroup,
 MetricName,sum(Metric) as Metric from
(
select a.year as Year,a.month as Month,a.Accountid,isnull(c.MasterAccountName,tc.CompanyName) as MasterAccountName,isnull(c.AccountName,tc.companyname) as AccountName,deliveryname,a.Username,a.AXCompany,a.CustomerGroup,
Marketname as MetricName --- Added as per Melissa's Request 9/2/2014------------
 ,sum(a.Fills) as Metric
from
	(
	select 	NetworkId,MarketId,ExchangeId,CompanyId,sum(Fills) as Fills,F.AccountId,u.FullName as DELIVERYNAME,F.UserName,F.Month,F.Year,AxProductId,DataAreaId as AXCompany,A.CustomerGroup as CustomerGroup,platform
	from 
	(
	Select Year,Month,NetworkId,ExchangeId,MarketId,AccountId,Username,AxProductId,CompanyId,Platform,sum(fills) as Fills from dbo.fills where year=@Year and month=@Month and IsBillable='Y' 
	group by Year,Month,ExchangeId,AccountId,Username,AxProductId,MarketId,NetworkId,Platform,CompanyId
	) F 
	left join (select distinct year,month,accountid,DELIVERYNAME,TTDESCRIPTION,dataareaid,custgroup,ProductSku from bidw.dbo.MonthlyBillingData where year=@Year and month=@Month)M
	on F.Year=M.Year and F.Month=M.Month and F.AccountId=M.AccountId and f.UserName=m.TTDESCRIPTION and f.AxProductId=m.ProductSku
		left join (select distinct YEAR,MONTH,accountid,username,fullname from [User] where year=@Year and month=@Month) U
	on f.Year=u.Year and f.Month=u.Month and f.AccountId=u.AccountId and f.UserName=u.UserName	
	left join Account A
	on F.AccountId=A.Accountid
	group by  Networkid,MarketId,ExchangeId,F.AccountId,F.Month,F.Year,AxProductId,DataAreaId,CustomerGroup,f.UserName,u.FullName,platform,CompanyId
		)a
left join
	(
	select * from dbo.Exchange
	)b
on a.ExchangeId=b.ExchangeID
Left join [BIDW].[dbo].[Market] M
on a.MarketId=m.MarketID and a.platform=m.platform
left join
	(
	select * from dbo.Account
	)c
on a.AccountId=c.AccountId
left join ( select distinct companyId, companyname from dbo.ttcompanies) TC on a.CompanyId=tc.companyid
 group by c.AccountName,b.ExchangeName,a.month,a.year,a.AxProductId,a.Accountid,c.MasterAccountName,a.AXCompany,a.CustomerGroup,UserName,DELIVERYNAME,a.networkid,Marketname,tc.CompanyName
 )Q
    where MasterAccountName not like '%TRADECO Global%'
  group by AccountName,MetricName,month,year,Accountid,MasterAccountName,AXCompany,CustomerGroup,UserName,DELIVERYNAME

--------------------------------------------Removed as  per Melissa's Request 9/2/2014---------------------------------------------
--union all

--select 
--a.year as Year,a.month as Month,c.Accountid,c.MasterAccountName,c.AccountName,deliveryname,a.Username,a.AXCompany,a.CustomerGroup,
--Case 
--when b.ExchangeName like 'CME%' and a.ProductName in (select distinct ProductSymbol from ExchangeProducts
--where Exchange in ('NYMEX - New York Mercantile Exchange')) then 'NYMEX'
--when b.ExchangeName like 'CME%' and a.ProductName not in (select distinct ProductSymbol from ExchangeProducts
--where Exchange in ('NYMEX - New York Mercantile Exchange')) then 'CME (excl NYMEX)'
----('WWN','YPN','YQN','YRN','AX','QT','QR','BB','BZ','BZT','BBT','WF'
----,'WU','WY','CJ','CJT','KT','KTT','HXE','TT','TTT','CL','CAY','XKN'
----,'XKT','XCN','XCT','LO','CLBB','CLRE','CLT','LCE','LNE','OG','LR'
----,'LRT','LU','LUT','HO','GHY','OH','HCY','HOT','HOCL','QM','QH','QG'
----,'QU','NG','DGY','ON','NGT','QEN','PA','PL','PN','ZIY','RB','OB','RBT'
----,',ZXY','RE','RET','RNN','YIN','YJN','YKN','YMN','SO','HZ','RSN','YO'
----,'YOT','UX','HU','HUT') then 'NYMEX'	
--End as MetricName
--,sum(a.Fills) as Metric
--from
--	(
--	select 	ExchangeId,sum(Fills) as Fills,ProductName,F.AccountId,u.FullName as DELIVERYNAME,F.UserName,F.Month,F.Year,TransactionDate,AxProductId,DataAreaId as AXCompany,A.CustomerGroup as CustomerGroup
--	from dbo.fills F left join (select distinct year,month,accountid,DELIVERYNAME,TTDESCRIPTION,dataareaid,custgroup,ProductSku from bidw.dbo.MonthlyBillingData)M
--	on F.Year=M.Year and F.Month=M.Month and F.AccountId=M.AccountId and f.UserName=m.TTDESCRIPTION and f.AxProductId=m.ProductSku
--		left join (select distinct YEAR,MONTH,accountid,username,fullname from [User]) U
--	on f.Year=u.Year and f.Month=u.Month and f.AccountId=u.AccountId and f.UserName=u.UserName	
--	left join Account A
--	on F.AccountId=A.Accountid
--	where IsBillable='Y' 
--	and F.Year=@Year and F.Month=@Month
--	group by  ExchangeId,ProductName,F.AccountId,F.Month,F.Year,TransactionDate,AxProductId,DataAreaId,CustomerGroup,f.UserName,u.FullName
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
--where MasterAccountName<>'TradeCo'
--and ExchangeName ='CME'
-- group by c.AccountName,b.ExchangeName,a.ProductName,a.month,a.year,a.AxProductId,c.Accountid,c.MasterAccountName,a.AXCompany,a.CustomerGroup,UserName,DELIVERYNAME

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

end




