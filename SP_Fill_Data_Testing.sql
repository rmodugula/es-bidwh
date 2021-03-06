USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Fill_Data_Testing]    Script Date: 04/09/2014 09:34:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Ram>
-- Create date: <08/08/2013:1630>
-- Description:	<Load Aggregated FillHub Data to DWH>
-- =============================================
ALTER PROCEDURE [dbo].[SP_Fill_Data_Testing]
@year int,
@Month int

AS


BEGIN

SET NOCOUNT ON;
select * from
(
select  Fill.Year,Fill.Month,Fill.MasterAccountName,Fill.Fills , LC.Licensecount,Fill.Fills-LC.licensecount as FillsDifference,lc.accountid as AxAccountid,fill.accountid as FillAccountid,lc.ttdescription,fill.username
from
(
select Year,Month,A.MasterAccountName,SUM(LicenseCount) as licensecount,left(mbd.accountid,7) AS accountid, case when LEN(mbd.ttdescription)>13 then rtrim(replace(right(mbd.ttdescription,CHARINDEX('†',reverse(mbd.ttdescription))),'†','')) else ttdescription end as ttdescription from chiaxsql01.apollo.dbo.MonthlyBillingData mbd
join chiaxsql01.apollo.dbo.Account A 
on mbd.AccountId=A.Accountid
join chiaxsql01.apollo.dbo.Product P 
on mbd.ProductSku=p.ProductSku
where YEAR=@year and MONTH=@Month
--and A.MasterAccountName = 'HSBC'
--and LEN(mbd.accountid)<8
--and P.ProductCategoryId in ('RevTrade', 'RevAPI')
and Mbd.ProductSku in ('10106','20999','20005','20997','20998')
--and mbd.ttdescription ='TTAEABSO4'
group by A.MasterAccountName,Year,Month,left(mbd.accountid,7),case when LEN(mbd.ttdescription)>13 then rtrim(replace(right(mbd.ttdescription,CHARINDEX('†',reverse(mbd.ttdescription))),'†','')) else ttdescription end 
--order by A.MasterAccountName
) LC
join 
(
select Year,Month,A.MasterAccountName,SUM(fills) as fills,mbd.accountid,mbd.username 
from dbo.Fills mbd
join chiaxsql01.apollo.dbo.Account A 
on mbd.AccountId=A.Accountid
where 
isbillable='Y'
and YEAR=@year and MONTH=@Month
--and mbd.username ='TTAEABSO4'

group by A.MasterAccountName,Year,Month,mbd.accountid,mbd.username
--order by A.MasterAccountName
) Fill
on LC.MasterAccountName=Fill.MasterAccountName and LC.Year=Fill.Year and LC.Month=Fill.Month
and lc.accountid=fill.accountid and lc.ttdescription=fill.username
--order by Fill.Year,Fill.Month,Fill.MasterAccountName,lc.accountid,fill.accountid,lc.ttdescription,fill.username
)Q
--where Q.FillsDifference>0
order by Q.Year,Q.Month,Q.MasterAccountName,Q.AxAccountid,Q.FillAccountid,Q.ttdescription,Q.username


END
