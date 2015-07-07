USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTransactionSummaryReport]    Script Date: 1/7/2015 11:17:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetTransactionSummaryReport]
@RunYear Int = Null,
@RunMonth Int = Null
     
     
AS

Declare @Year int, @Month int
IF @RunMonth is Null and @RunMonth is Null
Begin 
Set @Year=YEAR(getdate()) 
Set @Month=MONTH(getdate())
end
else 
Begin
Set @Year=@RunYear
Set @Month=@RunMonth
End

declare @FirstDayOfMonth smalldatetime , @LastDayOfMonth smalldatetime, @FirstDayOfNextMonth smalldatetime, @defaultdate smalldatetime

SET @FirstDayOfMonth = CONVERT(varchar,@Month) + '/1/' + CONVERT(varchar,@Year)
SET @FirstDayOfNextMonth = DATEADD(m,1,@FirstDayOfMonth)
SET @LastDayOfMonth = DATEADD(d,-1,@FirstDayOfNextMonth)

set @defaultdate = '1900-01-01 00:00:00.000'

BEGIN


select Year, Month,AccountId,MasterAccountName,AccountName,AXCompany,CustomerGroup,MetricName,SUM(metric) as Metric from
(
 select Q.YEAR,Q.Month,Q.Accountid,MasterAccountName,AccountName,DELIVERYNAME,UserName,AXCompany,CustomerGroup,
 case when AxProductId in (20999,20997,20993) then '##XTPro'
when AxProductId in (20005,20995,20992,10106)then '##XT'
end as MetricName, COUNT(distinct username) as Metric
 from
 (
 select distinct F.YEAR,F.Month,F.Accountid,Username,Axproductid,DELIVERYNAME,AXCompany from Fills F
  left join 
 (select distinct YEAR,Month,Accountid,ProductSku,Deliveryname,DataAreaId as AXCompany,TTDESCRIPTION from MonthlyBillingData 
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
 group by Q.YEAR,Q.Month,Q.Accountid,Axproductid,MasterAccountName,AccountName,CustomerGroup,AXCompany,DELIVERYNAME,UserName
 )z
 group by Year, Month,AccountId,MasterAccountName,AccountName,AXCompany,CustomerGroup,MetricName
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
--from MonthlyBillingData M join Account A
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
ct.DATAAREAID as AXCompany,CustGroup,
case when itemid in (20005,20995,20992,10106) then '##XTCap'
when itemid in (20999,20997,20993) then '##XTProCap'
end as LicenseName
,COUNT(TTDESCRIPTION) as LicenseCounts
FROM chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICETRANS] CT 
join chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICEJour] J
on ct.invoiceid=j.invoiceid and ct.dataareaid=j.dataareaid
join account A
on J.invoiceaccount=a.accountid
where TTLINEDISCOUNT <>0
and ITEMID in (20005,20999,20997,20993,20995,20992,10106)
and MasterAccountName <>'TradeCo'
and year(ct.invoicedate)=@Year and MONTH(ct.invoicedate)=@Month
group by [TTCUSTNAME],year(ct.INVOICEDATE),Month(ct.INVOICEDATE),substring(A.Accountid,1,7),itemid,CustGroup,
Masteraccountname,ct.DATAAREAID,ttdlvname,ttdescription

UNION ALL
 
select @Year as Year,@Month as Month,substring(A.custaccount,1,7) as Accountid,c.MasterAccountName,c.AccountName,A.dataareaid as AXCompany,A.custgroup,
case when itemid in (20005,20995,20992,10106) then '##XTCap'
when itemid in (20999,20997,20993) then '##XTProCap'
end as LicenseName,count(ttdescription) as LicenseCounts
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
group by substring(A.custaccount,1,7),A.custgroup,A.dataareaid,b.Deliveryname,MasterAccountName,AccountName,ttdescription,itemid

UNION ALL


SELECT year(ct.INVOICEDATE) as Year,Month(ct.INVOICEDATE) as Month,substring(A.Accountid,1,7) as Accountid,MasterAccountName,[TTCUSTNAME],ct.DATAAREAID as AXCompany,CustGroup,
 '#TotalCapped' LicenseName
,COUNT(TTDESCRIPTION) as LicenseCounts
  FROM chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICETRANS] CT 
  join chiaxsql01.[TT_DYANX09_PRD].[dbo].[CUSTINVOICEJour] J
  on ct.invoiceid=j.invoiceid and ct.dataareaid=j.dataareaid
  join account A
 on J.invoiceaccount=a.accountid
  where TTLINEDISCOUNT <>0
  and ITEMID in (20005,20999,20997,20993,20995,20992,10106)
  and MasterAccountName <>'TradeCo'
   and year(ct.invoicedate)=@Year and MONTH(ct.invoicedate)=@Month
  group by [TTCUSTNAME],year(ct.INVOICEDATE),Month(ct.INVOICEDATE),substring(A.Accountid,1,7),itemid,CustGroup,Masteraccountname,ct.DATAAREAID,ttdlvname,ttdescription

UNION
 

  select @Year as Year,@Month as Month,substring(A.custaccount,1,7) as Accountid,c.MasterAccountName,c.AccountName,A.dataareaid as AXCompany,A.custgroup,
  '#TotalCapped' as LicenseName,count(ttdescription) as LicenseCounts
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
 group by substring(A.custaccount,1,7),A.custgroup,A.dataareaid,b.Deliveryname,MasterAccountName,AccountName,ttdescription,itemid

UNION ALL

select 
a.year as Year,
a.month as Month,
c.Accountid,
c.MasterAccountName,
c.AccountName,
a.AXCompany,
a.CustomerGroup,
Case 
when axproductid in (20998,20996) then '#FATrx'
      when axproductid in (20005,20995,20992,10106) then '#XTTrx'
      when axproductid in (20999,20997,20993) then '#XTProTrx' 
  End as MetricName
 ,sum(a.Fills) as Metric
from
	(
	select 	ExchangeId,sum(Fills) as Fills,ProductName,F.AccountId,DELIVERYNAME,F.UserName,F.Month,F.Year,TransactionDate,AxProductId,DataAreaId as AXCompany,A.CustomerGroup as CustomerGroup
	from dbo.fills F left join (select distinct year,month,accountid,deliveryname,TTDESCRIPTION,dataareaid,custgroup,ProductSku from MonthlyBillingData)M
	on F.Year=M.Year and F.Month=M.Month and F.AccountId=M.AccountId and f.UserName=m.TTDESCRIPTION and f.AxProductId=m.ProductSku
	left join Account A
	on F.AccountId=A.Accountid
	where IsBillable='Y' 
	and F.Year=@Year and F.Month=@Month
	and AxProductId in (20998,20005,20999,20996,20995,20992,20997,20993,10106)
	group by  ExchangeId,ProductName,F.AccountId,F.Month,F.Year,TransactionDate,AxProductId,DataAreaId,A.CustomerGroup,UserName,DELIVERYNAME
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
where MasterAccountName<>'TradeCo'
 group by c.AccountName,b.ExchangeName,a.ProductName,a.month,a.year,a.AxProductId,c.Accountid,c.MasterAccountName,a.AXCompany,a.CustomerGroup
 

UNION ALL

select a.year as Year,a.month as Month,c.Accountid,c.MasterAccountName,c.AccountName,a.AXCompany,a.CustomerGroup,
case when b.ExchangeName ='CBOT' then 'CME' else b.Exchangename end as MetricName --- Added as per Melissa's Request 9/2/2014------------
 ,sum(a.Fills) as Metric
from
	(
	select 	ExchangeId,sum(Fills) as Fills,ProductName,F.AccountId,DELIVERYNAME,F.UserName,F.Month,F.Year,TransactionDate,AxProductId,DataAreaId as AXCompany,A.CustomerGroup as CustomerGroup
	from dbo.fills F left join (select distinct year,month,accountid,DELIVERYNAME,TTDESCRIPTION,dataareaid,custgroup,ProductSku from MonthlyBillingData)M
	on F.Year=M.Year and F.Month=M.Month and F.AccountId=M.AccountId and f.UserName=m.TTDESCRIPTION and f.AxProductId=m.ProductSku
	left join Account A
	on F.AccountId=A.Accountid
	where IsBillable='Y' 
	and F.Year=@Year and F.Month=@Month
	group by  ExchangeId,ProductName,F.AccountId,F.Month,F.Year,TransactionDate,AxProductId,DataAreaId,CustomerGroup,UserName,DELIVERYNAME
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
where MasterAccountName<>'TradeCo'
--and ExchangeName <>'CME'
 group by c.AccountName,b.ExchangeName,a.ProductName,a.month,a.year,a.AxProductId,c.Accountid,c.MasterAccountName,a.AXCompany,a.CustomerGroup

--------------------------------------------Removed as  per Melissa's Request 9/2/2014---------------------------------------------
--union all

--select 
--a.year as Year,a.month as Month,c.Accountid,c.MasterAccountName,c.AccountName,a.AXCompany,a.CustomerGroup,
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
--	select 	ExchangeId,sum(Fills) as Fills,ProductName,F.AccountId,DELIVERYNAME,F.UserName,F.Month,F.Year,TransactionDate,AxProductId,DataAreaId as AXCompany,A.CustomerGroup as CustomerGroup
--	from dbo.fills F left join (select distinct year,month,accountid,DELIVERYNAME,TTDESCRIPTION,dataareaid,custgroup,ProductSku from MonthlyBillingData)M
--	on F.Year=M.Year and F.Month=M.Month and F.AccountId=M.AccountId and f.UserName=m.TTDESCRIPTION and f.AxProductId=m.ProductSku
--	left join Account A
--	on F.AccountId=A.Accountid
--	where IsBillable='Y' 
--	and F.Year=@Year and F.Month=@Month
--	group by  ExchangeId,ProductName,F.AccountId,F.Month,F.Year,TransactionDate,AxProductId,DataAreaId,CustomerGroup,UserName,DELIVERYNAME
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
-- group by c.AccountName,b.ExchangeName,a.ProductName,a.month,a.year,a.AxProductId,c.Accountid,c.MasterAccountName,a.AXCompany,a.CustomerGroup

end




