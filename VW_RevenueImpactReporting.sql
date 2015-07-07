USE [BIDW]
GO

/****** Object:  View [dbo].[VW_RevenueImpactReporting]    Script Date: 03/11/2014 10:51:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER VIEW [dbo].[VW_RevenueImpactReporting] 
as
select Year, Month, MonthName, Accountid, AccountName, DeliveryName, PriceGroup, 
 PriceGroupDesc, CusttomerGroup, TTConversionDate, SalesOffice, SalesRegion, BillingEndDate, isnull(case 
when ChangeInPrice <> 0 and  AddRevenue=0 and CancelRevenue=0 and UpgradeRevenue=0 and DownGradeRevenue=0 then ChangeInPrice

when ChangeInPrice = 0 and  AddRevenue<>0 and CancelRevenue=0 and UpgradeRevenue=0 and DownGradeRevenue=0 then AddRevenue

when ChangeInPrice = 0 and  AddRevenue=0 and CancelRevenue<>0 and UpgradeRevenue=0 and DownGradeRevenue=0 then CancelRevenue

when ChangeInPrice = 0 and  AddRevenue=0 and CancelRevenue=0 and UpgradeRevenue<>0 and DownGradeRevenue=0 then UpgradeRevenue

when ChangeInPrice = 0 and  AddRevenue=0 and CancelRevenue=0 and UpgradeRevenue=0 and DownGradeRevenue<>0 then DownGradeRevenue

end,0) as RevenueChange,
isnull(case 
when ChangeInPrice <> 0 and  AddRevenue=0 and CancelRevenue=0 and UpgradeRevenue=0 and DownGradeRevenue=0 then 'ChangeInPrice'

when ChangeInPrice = 0 and  AddRevenue<>0 and CancelRevenue=0 and UpgradeRevenue=0 and DownGradeRevenue=0 then 'AddRevenue'

when ChangeInPrice = 0 and  AddRevenue=0 and CancelRevenue<>0 and UpgradeRevenue=0 and DownGradeRevenue=0 then 'CancelRevenue'

when ChangeInPrice = 0 and  AddRevenue=0 and CancelRevenue=0 and UpgradeRevenue<>0 and DownGradeRevenue=0 then 'UpgradeRevenue'

when ChangeInPrice = 0 and  AddRevenue=0 and CancelRevenue=0 and UpgradeRevenue=0 and DownGradeRevenue<>0 then 'DownGradeRevenue'

end,'NoChange') as RevenueChangeType,NetRevenue, PriorMonthRevenue, CurrentRevenue,

isnull(case 
when  AddCount<>0 and CancelCount=0 and UpgradeCount=0 and DowngradeCount=0 then AddCount

when   AddCount=0 and CancelCount<>0 and UpgradeCount=0 and DowngradeCount=0 then -CancelCount

when   AddCount=0 and CancelCount=0 and UpgradeCount<>0 and DowngradeCount=0 then UpgradeCount

when  AddCount=0 and CancelCount=0 and UpgradeCount=0 and DowngradeCount<>0 then -DownGradeCount

end,0) as CountChange,
isnull(case 
when   AddCount<>0 and CancelCount=0 and UpgradeCount=0 and DowngradeCount=0 then 'AddCount'

when  AddCount=0 and CancelCount<>0 and UpgradeCount=0 and DowngradeCount=0 then 'CancelCount'

when   AddCount=0 and CancelCount=0 and UpgradeCount<>0 and DowngradeCount=0 then 'UpgradeCount'

when  AddCount=0 and CancelCount=0 and UpgradeCount=0 and DowngradeCount<>0 then 'DownGradeCount'

end,'NoChange') as CountsChangeType, NetCount, PriorMonthLicenseCount, CurrentLicenseCount
from dbo.RevenueImpactReporting
--where YEAR=2013 and MONTH=10




GO


