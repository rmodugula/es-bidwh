USE [BIDW]
GO

/****** Object:  View [dbo].[GetDucksBoardLast12MonthScreens]    Script Date: 9/18/2014 4:44:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


Alter VIEW [dbo].[GetDucksBoardLast12MonthScreens]
AS
select LastDayOfMonth,Screens,case when day(getdate())>25 then Screens else AdjustedScreens end as AdjustedScreens
from 
(
select *,'BeforeBill' as BillDesc
from
(
select Screen.LastDayOfMonth,Screens,case when day(getdate())<=10 or day(getdate())>25 then Screens else AdjustedScreens end as AdjustedScreens 
from (select cast(t.EndDate as date) as LastDayOfMonth,SUM(BillableLicenseCount) as Screens 
from [bidw].dbo.[MonthlyBillingData] M 
left join [bidw].dbo.[TimeInterval] T 
on m.Year=t.Year and m.Month=t.Month where DATEDIFF(mm,EndDate,GETDATE())<=12 
and DATEDIFF(mm,EndDate,GETDATE())>=2 and m.ProductSku in ('20005','20999','20997','20000','20200','20995','20993','20992') 
group by t.EndDate 

union 

select cast((SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()),0))) as date) as LastDayOfMonth,
SUM(BillableLicenseCount) as Screens from [bidw].dbo.[MonthlyBillingData] M 
left join [bidw].dbo.[TimeInterval] T 
on m.Year=t.Year and m.Month=t.Month where DATEDIFF(mm,EndDate,GETDATE())<=2  
and DATEDIFF(mm,EndDate,GETDATE())>=2 and m.ProductSku in ('20005','20999','20997','20000','20200','20995','20993','20992') 
group by t.EndDate 
 
union 

select cast((SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+1,0))) as date) as LastDayOfMonth, case when day(getdate())<=10 or day(getdate())>25 then Screens else AdjScreens end as AdjustedScreens 
from [bidw].dbo.GetDucksBoardScreenCounts 
where SalesOffice='Total')Screen 
left join (select cast(t.EndDate as date) as LastDayOfMonth,SUM(BillableLicenseCount) as AdjustedScreens 
from [bidw].dbo.[MonthlyBillingData] M 
left join [bidw].dbo.[TimeInterval] T 
on m.Year=t.Year and m.Month=t.Month where DATEDIFF(mm,EndDate,GETDATE())<=12 and DATEDIFF(mm,EndDate,GETDATE())>=1 
and m.ProductSku in ('20005','20999','20997','20000','20200','20995','20993','20992') group by t.EndDate)Adj on Screen.LastDayOfMonth=adj.LastDayOfMonth 
--order by 1
)Q

Union ALL

select *,'AfterBill' as BillDesc
from
(
select Screen.LastDayOfMonth,Screens,case when day(getdate())>25 then Screens else AdjustedScreens end as AdjustedScreens 
from (
select cast(t.EndDate as date) as LastDayOfMonth,SUM(BillableLicenseCount) as Screens 
from [bidw].dbo.[MonthlyBillingData] M 
left join [bidw].dbo.[TimeInterval] T 
on m.Year=t.Year and m.Month=t.Month where DATEDIFF(mm,EndDate,GETDATE())<=12 and DATEDIFF(mm,EndDate,GETDATE())>=1 
and m.ProductSku in ('20005','20999','20997','20000','20200','20995','20993','20992') 
group by t.EndDate 

union 

select cast((SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+1,0))) as date) as LastDayOfMonth,Screens 
from [bidw].dbo.GetDucksBoardScreenCounts 
where SalesOffice='Total'
)Screen 
left join (select cast(t.EndDate as date) as LastDayOfMonth,SUM(BillableLicenseCount) as AdjustedScreens 
from [bidw].dbo.[MonthlyBillingData] M 
left join [bidw].dbo.[TimeInterval] T 
on m.Year=t.Year and m.Month=t.Month where DATEDIFF(mm,EndDate,GETDATE())<=12 and DATEDIFF(mm,EndDate,GETDATE())>=0 
and m.ProductSku in ('20005','20999','20997','20000','20200','20995','20993','20992') 
group by t.EndDate)Adj 
on Screen.LastDayOfMonth=adj.LastDayOfMonth 
--order by 1
)X
)Final
where BillDesc = case when (case when month(getdate())=1 then 12 else MONTH(getdate())-1 end)=
(select Month from (select *,row_number() over (order by id desc) as row from fillhub.dbo.InvoiceMonth)Q where ROW=1) 
then 'AfterBill' else 'BeforeBill' end





GO


