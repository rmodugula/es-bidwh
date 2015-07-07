USE [BIDW]
GO

/****** Object:  View [dbo].[VW_OrderSourceRules]    Script Date: 10/29/2013 16:33:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[VW_OrderSourceRules] 
as
/******OrderSourceRules ******/
SELECT [Year]
      ,[Month]
       ,[NetworkId]
      ,[MarketId]
      ,a.MasterAccountName as Company
      ,[AxProductId]
      ,isBillable
      ,[Fills]
      ,[FirstOrderSource]
      ,[LastOrderSource]
      ,[OrderSourceHistory]
      ,CASE WHEN [OrderSourceHistory] like '%15%' THEN 'MDT' ELSE 'non-MDT' END as MDT
      ,CASE 
            WHEN [FirstOrderSource] = 9 OR ([OrderSourceHistory] like '%09%' AND ([OrderSourceHistory] like '%11%' OR [OrderSourceHistory] like '%12%' OR [OrderSourceHistory] like '%19%' OR [OrderSourceHistory] like '%21%')) THEN 'Autospreader - ServerSide'
            WHEN [OrderSourceHistory] like '%01%' THEN 'Autospreader - Desktop' 
--            WHEN [OrderSourceHistory] like '%,1,%' OR [FirstOrderSource] = 9 OR ([OrderSourceHistory] like '%,9,%' AND ([OrderSourceHistory] like '%11%' OR [OrderSourceHistory] like '%12%' OR [OrderSourceHistory] like '%19%' OR [OrderSourceHistory] like '%21%')) THEN 'Autospreader' 
            WHEN [OrderSourceHistory] like '%22%' or ([OrderSourceHistory] like '%12%' and [OrderSourceHistory] not like '%09%') THEN 'AlgoSE' 
            WHEN [OrderSourceHistory] like '%02%' THEN 'Autotrader' 
            WHEN [FirstOrderSource] IN (6,23) THEN 'FIX Adapter'
            WHEN [OrderSourceHistory] like '%20%' OR [OrderSourceHistory] like '%24%' THEN 'SSE' 
            WHEN [FirstOrderSource] = 3 THEN 'XTAPI'
            WHEN [FirstOrderSource] IN (11,21) THEN 'XTAPI XT Mode'
            WHEN OrderSourceHistory NOT LIKE '%24%'
            AND  OrderSourceHistory NOT LIKE '%23%'
            AND  OrderSourceHistory NOT LIKE '%22%'
            AND  OrderSourceHistory NOT LIKE '%21%'      
            AND  OrderSourceHistory NOT LIKE '%20%'
            AND  OrderSourceHistory NOT LIKE '%19%'
            AND  OrderSourceHistory NOT LIKE '%12%'
            AND  OrderSourceHistory NOT LIKE '%11%'                                    
            AND  OrderSourceHistory NOT LIKE '%09%'                                                                                   
            AND  OrderSourceHistory NOT LIKE '%01%'                                                                                                                                   
            AND  OrderSourceHistory NOT LIKE '%02%'                                     
            AND  OrderSourceHistory NOT LIKE '%06%'                           
			THEN 'Non-Automated' 
			ELSE 'Needs a rule'
		END as 'FunctionalityArea'   
  FROM [BIDW].[dbo].[Fills] f
  JOIN [BIDW].[dbo].[Account] a
  on f.AccountId = a.Accountid  
  where NetworkId = 1104--multibroker
 


GO


