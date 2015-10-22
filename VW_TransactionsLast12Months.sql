USE [BIDW]
GO

/****** Object:  View [dbo].[VW_TransactionsLast12Months]    Script Date: 10/22/2015 10:44:59 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






ALTER VIEW [dbo].[VW_TransactionsLast12Months] 
as
select F.Year,F.Month,
cast(case f.Month 
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
when 12 then 'Dec' end as CHAR(3))+'-'+CAST(F.Year as CHAR(4)) as MonthYear,
cast((case when len(f.month)=2 then CONVERT(char(2),f.month) else CONVERT(char(1),f.month) end)+'/1/'+CONVERT(char(4),f.year) as date) as MonthDate,
MasterAccountName as CustomerName,Platform,sum(Fills) as Fills, SUM(fillscountbydate) as FillRecords
from dbo.fills F 	left join Account A
on F.AccountId=A.Accountid
left join TimeInterval T
on f.Year=t.Year and f.Month=t.Month
where IsBillable='Y' 
and DATEDIFF(mm,EndDate,GETDATE())<=12
and DATEDIFF(mm,EndDate,GETDATE())>=1
and AxProductId in ('20998','20005','20999','20996','20995','20997','10106','20992','20993')
and f.AccountId<>'C100271'
group by F.Month,F.Year,MasterAccountName,Platform

	





















GO


