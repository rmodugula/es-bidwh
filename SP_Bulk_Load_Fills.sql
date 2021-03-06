USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Bulk_Load_Fills]    Script Date: 7/29/2014 2:32:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Ram>
-- Create date: <08/08/2013:1630>
-- Description:	<Load Aggregated FillHub Data to DWH>
-- =============================================
ALTER PROCEDURE [dbo].[SP_Bulk_Load_Fills]

AS


BEGIN

	SET NOCOUNT ON;
	
--truncate table dbo.Fills
insert into dbo.Fills
SELECT
  row_number() over (ORDER BY f.year) AS FillId
, f.[Year]
, f.[Month]
, U.UserId
, f.[broker] as [BrokerId]
, f.company as CompanyId
, f.ExchangeId
, f.NetworkId
, f.MarketId
, f.BillingAccountId as AccountId
, f.AxProductId
, f.ProductType
, f.ProductName
, f.FillType
, f.FillStatus
, sum((f.ShortQty+f.LongQty)*f.LotSize) as Fills
, f.FixAdapterName
, f.OpenClose
, f.OrderFlags
, f.LastOrderSource
, f.FirstOrderSource
, f.OrderSourceHistory
, f.FillCategoryId
, f.[Version]
, cast(f.TransactionDateTime AS date) as TransactionDate
, cast(f.BillingServerDateTime AS date) as BillingServerDate
, (case when f.fillstatus=2048 then 'Y' else 'N' end) as IsBillable
, count(f.fillid) as CountsPerFillId
, GETDATE() as lastupdatedate

FROM FillHubLink.fillhub.dbo.Fills F

LEFT JOIN FillHubLink.fillhub.dbo.[User] U
 ON F.Year=U.year
AND f.Month=u.month
AND f.username=u.username
AND f.BillingAccountId=u.BillingAccountId

WHERE f.[year] =2013
AND f.[month] in(7,8)
AND u.[year]=2013
AND u.[month]in(7,8)
--and username='DFELDMAN'
--and cast(TransactionDateTime as date) in (cast(getdate() as date))
--and cast(TransactionDateTime as date) in (cast(getdate() as date),cast(getdate()-1 as date))
GROUP BY f.[Year]
, f.[Month]
, u.userid
, f.[broker]
, f.company
, f.ExchangeId
, f.NetworkId
, f.MarketId
, f.BillingAccountId
, f.AxProductId
, f.ProductType
, f.ProductName
, f.FillType
, f.FillStatus
, f.FixAdapterName
, f.OpenClose
, f.OrderFlags
, f.LastOrderSource
, f.FirstOrderSource
, f.OrderSourceHistory
, f.FillCategoryId
, f.[Version]
, cast(f.TransactionDateTime AS date)
, cast(f.BillingServerDateTime AS date)
, (case when f.fillstatus=2048 then 'Y' else 'N' end)
ORDER BY cast(f.TransactionDateTime as date) 






--------------------------------------------Load Fills from TBS------------------------------------------------
insert into chisql12.bidw.dbo.Fills
select 
(select max(fillid) from chisql12.bidw.dbo.fills)+
row_number() over (ORDER BY Final.[TransactionDate]) AS FillId,Final.*
from
(
--select 
----M.FillId,
--M.[Year],M.[Month],(case when useridnum=0 then m.userid else right(m.userid,useridnum) end) as UserName,M.BrokerId,M.CompanyId,M.ExchangeId, M.NetworkId,M.MarketId
--,M.AccountId
--,M.AXProductId
--, M.ProductType,M.ProductName,M.FillType,M.FillStatus,M.Fills,M.FixAdapterName,M.OpenClose,M.OrderFlags,M.LastOrderSource,M.FirstOrderSource
--,M.OrderSourceHistory,M.FillCategoryId,M.[Version],M.TransactionDate,M.[BillingServerDate],M.IsBillable,M.FillsCountbydate,M.LastUpdatedDate
--from
--(
--SELECT 
--      --(select max(fillid) from dbo.fills)
--      --457172+row_number() over (ORDER BY cast([TransactionDateTime] as date)) AS FillId
--      DATEPART(yyyy,[TransactionDateTime]) as [Year]
--      ,DATEPART(MM,[TransactionDateTime]) as [Month]
--      , df.[UserId]
--      ,CASE WHEN charindex('/',REVERSE(df.UserId))=0 THEN 0 ELSE charindex('/',REVERSE(df.UserId))-1 END as UserIdnum
--      , 0 AS BrokerId
--      , 0 AS CompanyId
--      ,[ExchangeId] 
--      , '' as NetworkId
--      ,[MarketId]
--      ,I.companyid as AccountId
--      , '' as AXProductId
--      ,[ProductType]
--      ,df.[ProductName]
--      , '' as  FillType
--      , '' as FillStatus
--      ,sum([Quantity]*[LotSize]) as Fills
--      ,'' as FixAdapterName
--      , 0 as OpenClose
--      , 0 as OrderFlags
--      , [OrderSource] as LastOrderSource
--      , '' as FirstOrderSource
--      , '' as OrderSourceHistory
--      , '' as FillCategoryId
--      , 0 as [Version]
--      ,cast([TransactionDateTime] as date) as TransactionDate
--      ,cast([BillingServerDateTime] as DATE) as [BillingServerDate]
--      , 'Y' as IsBillable
--      , COUNT(TransactionDateTime) as FillsCountbydate
--      , GETDATE() as LastUpdatedDate
--   FROM chi101279.TransactionalBillingData.dbo.DetailedFills df
--  inner join chisql20.licensing2.dbo.BillingServer bs on df.BillingServerId=bs.BillingServerKey
--  left join chisql20.licensing2.dbo.InvoiceConfig I on bs.InvoiceConfigId=I.InvoiceConfigId

--   where 
--   --df.DetailFillId<=400000000 and 
--   df.DetailFillId>400000000
--   --CAST(TransactionDateTime as date) >='2013-05-01' and CAST(TransactionDateTime as date)<='2013-06-30'
--   --DATEPART(mm,TransactionDateTime) in (6)
--   --and DATEPART(yyyy,TransactionDateTime) = 2013
--   --cast([TransactionDateTime] as date)='2013-06-12'
--   --and df.userid='ABASU'
--  group by DATEPART(MM,[TransactionDateTime]),DATEPART(yyyy,[TransactionDateTime]),cast([TransactionDateTime] as date),cast([BillingServerDateTime] as DATE),df.UserId,ExchangeId,MarketId,ProductType,df.ProductName,OrderSource,I.companyid
--    --,fc.FillCategoryId
--  --,I.CompanyId
--  ) M

 
  --union all
  ------------------------------------------------------------------------------------------------------------------------------------
  
  
  -----------------------------------------------------Load MB Fills from FillHub-----------------------------------------------
    --insert into chisql12.bidw.dbo.Fills_F1
  SELECT
  --(select max(fillid) from dbo.fills)+row_number() over (ORDER BY f.year) AS FillId
 f.[Year]
, f.[Month]
, f.UserName
, f.[broker] as [BrokerId]
, f.company as CompanyId
, f.ExchangeId
, f.NetworkId
, f.MarketId
, f.BillingAccountId as AccountId
, f.AxProductId
, f.ProductType
, f.ProductName
, f.FillType
, f.FillStatus
, sum((f.ShortQty+f.LongQty)*f.LotSize) as Fills
, f.FixAdapterName
, f.OpenClose
, f.OrderFlags
, f.LastOrderSource
, f.FirstOrderSource
, f.OrderSourceHistory
, f.FillCategoryId
, f.[Version]
, cast(f.TransactionDateTime AS date) as TransactionDate
, cast(f.BillingServerDateTime AS date) as BillingServerDate
, (case when f.fillstatus=2048 then 'Y' else 'N' end) as IsBillable
, count(f.fillid) as CountsPerFillId
, GETDATE() as lastupdatedate

FROM FillHubLink.fillhub.dbo.Fills F

--LEFT JOIN FillHubLink.fillhub.dbo.[User] U
-- ON F.Year=U.year
--AND f.Month=u.month
--AND f.username=u.username
--AND f.BillingAccountId=u.BillingAccountId

WHERE f.[year] =2013
AND f.[month] in(1,2,3,4,5,6)
--AND u.[year]=2013
--AND u.[month]in(5,6)
and f.networkid=1104
--and username='DFELDMAN'
--and cast(TransactionDateTime as date) in (cast(getdate() as date))
--and cast(TransactionDateTime as date) in (cast(getdate() as date),cast(getdate()-1 as date))
GROUP BY f.[Year]
, f.[Month]
, f.userName
, f.[broker]
, f.company
, f.ExchangeId
, f.NetworkId
, f.MarketId
, f.BillingAccountId
, f.AxProductId
, f.ProductType
, f.ProductName
, f.FillType
, f.FillStatus
, f.FixAdapterName
, f.OpenClose
, f.OrderFlags
, f.LastOrderSource
, f.FirstOrderSource
, f.OrderSourceHistory
, f.FillCategoryId
, f.[Version]
, cast(f.TransactionDateTime AS date)
, cast(f.BillingServerDateTime AS date)
, (case when f.fillstatus=2048 then 'Y' else 'N' end)
--order by  cast(f.TransactionDateTime AS date)
) Final
  order by Final.[TransactionDate]
  ---------------------------------------------------------------------------------------------------------------------------------
END
