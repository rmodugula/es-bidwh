USE [BIDW]
GO

/****** Object:  View [dbo].[VW_MultiBrokerFills]    Script Date: 04/15/2014 13:33:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






ALTER VIEW [dbo].[VW_MultiBrokerFills] 
as

	SELECT
  z.Year	
, case z.Month
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
       when 12 then 'Dec'
       end as Month
, z.DayofMonth
, z.Day
, z.UserName
, z.Brokername
, z.Brokerid
, case when z.CompanyName = 'TradeCo' then 'zzTradeCo' else z.Companyname end as Companyname
, z.Companyid
, rtrim(case when z.iphen=0 then z.exchange when z.iphen <>0 then replace(substring(z.exchange,1,z.iphen),'-','') when z.exchange='LIFFE-EO' then 'LIFFE-EO' end) as Exchange
 , z.AxProductId
, z.FirstOrderSource
,z.LastOrderSource
,z.OrderSourceHistory
,z.MDT
,z.FunctionalityArea
, z.Orderdescription
, z.Isbillable
, z.Fill

FROM
(
    SELECT
      e.Year
    , e.Month
    , e.Username
    , e.DayofMonth
    , e.Day
    , f.companyname AS Brokername
    , e.brokerid AS BrokerId
    , e.companyname AS CompanyName
    , e.companyid AS CompanyId
    , e.exchange as exchange
     , e.AxProductId
    , e.FirstOrderSource
    ,e.LastOrderSource
    ,e.OrderSourceHistory
    ,e.MDT
    ,e.FunctionalityArea
    , charindex('-',e.exchange)as iphen
    , e.[description] as Orderdescription
    , e.Isbillable
    , e.fill AS Fill

    FROM
    (
        SELECT
        d.YEAR
        , d.MONTH
        ,  d.UserName
        , d.DayofMonth
        , d.Day
        , c.brokerid
        , c.companyid
        , c.companyname
        , c.networkid
         , d.AxProductId
            , d.FirstOrderSource
            ,d.LastOrderSource
            ,d.OrderSourceHistory
            ,d.MDT
            ,d.FunctionalityArea
        , d.exchange
        , d.Isbillable
        , d.[Description]
        , Isnull(d.fill, 0)AS Fill

        FROM
        (
            SELECT
              a.brokerid
            , b.companyid
            , b.companyname
            , a.networkid

            FROM brokermap a

            JOIN company b
             ON a.networkid = b.networkid
            AND a.buysideid = b.companyid
        )
         c

        FULL JOIN
        (
            SELECT
             c.YEAR
             , c.MONTH
            , c.Username
            , c.networkid
            , c.[brokerid]
            , c.AxProductId
            , c.FirstOrderSource
            ,c.LastOrderSource
            ,c.OrderSourceHistory
            ,c.MDT
            ,c.FunctionalityArea
            , c.companyid
            , c.DayofMonth
            , c.Day
            , c.IsBillable
            , c.fill
            , c.exchange
            , d.[description]

            FROM
            (
                SELECT
                  a.*
                , b.exchangeflavor AS exchange

                FROM
                (
                    SELECT
                    YEAR
                    ,MONTH
                    , UserName
                    , exchangeid
                    , [networkid]
                    , [AxProductId]
                    , lastordersource
                    , firstordersource
                    , OrderSourceHistory
                      ,CASE WHEN [OrderSourceHistory] like '%15%' THEN 'MDT' ELSE 'non-MDT' END as MDT
      ,CASE 
            WHEN [FirstOrderSource] = 9 OR ([OrderSourceHistory] like '%09%' AND ([OrderSourceHistory] like '%11%' OR [OrderSourceHistory] like '%12%' OR [OrderSourceHistory] like '%19%' OR [OrderSourceHistory] like '%21%')) THEN 'Autospreader - ServerSide'
            WHEN [OrderSourceHistory] like '%01%' THEN 'Autospreader - Desktop' 
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
                    , [brokerid]
                    , [companyid]
                    , DayofMonth
                    , Day(TransactionDate) as Day
                    , Isbillable
                    , Fills AS Fill

                    FROM [dbo].[fills]

                    WHERE networkid = 1104
                      and MarketId not in (84,85,88)
      
				                )
                 a

                JOIN exchange b
                 ON a.exchangeid = b.exchangeid

            )
            c

            JOIN ordersource d
             ON c.lastordersource = d.ordersourcenumber  
            
        )
         d
         ON c.networkid = d.networkid
        AND c.brokerid = d.[brokerid]
        AND c.companyid = d.companyid
    )
    e

    JOIN dbo.company f
     ON e.networkid = f.networkid
    AND e.brokerid = f.companyid
)
z

    UNION ALL
SELECT
  y.Year
, case Y.Month
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
       when 12 then 'Dec'
       end as Month
, y.DayofMonth
, y.Day
, y.UserName
, y.Brokername
, y.Brokerid
, 'zInternal Broker' as Companyname
, y.Companyid
, rtrim(case when y.iphen=0 then y.exchangeflavor when y.iphen <>0 then replace(substring(y.exchangeflavor,1,y.iphen),'-','') when y.exchangeflavor='LIFFE-EO' then 'LIFFE-EO' end) as Exchange
, y.AxProductId
, Y.FirstOrderSource
,Y.LastOrderSource
, y.OrderSourceHistory
,y.MDT
,y.FunctionalityArea
, Y.[Description]
, y.Isbillable
, y.Fill

FROM
(
    SELECT
      charindex('-',a1.exchangeflavor) AS iphen
    , a1.Year
    , a1.Month
    , a1.UserName
    , a1.DayofMonth
    , a1.Day
    , a1.Brokername
    , a1.brokerid
    , a1.AxProductId
    , a1.companyname
    , a1.companyid
    , a1.exchangeflavor
    , a1.FirstOrderSource
    , a1.LastOrderSource
    , a1.OrderSourceHistory
    , a1.MDT
    , a1.FunctionalityArea
    , a2.[Description]
    , a1.Isbillable
    , a1.Fill

    FROM
    (
        SELECT
          a.*
        , b.exchangeflavor

        FROM
        (
            SELECT
              a.Year
            , a.month  
            , a.UserName
            , a.DayofMonth
            , a.Day
            , b.companyname AS Brokername
            , a.[brokerid] AS brokerid
             , a.AxProductId
            , b.companyname
            , b.companyid
            , a.exchangeid
            , a.LastOrderSource
            , a.FirstOrderSource
            ,a.OrderSourceHistory
            ,a.MDT
            ,a.FunctionalityArea
            , a.Isbillable
            , a.fill

            FROM
            (
                SELECT
                Year
                ,Month
                , UserName
                , exchangeid
                , [networkid]
                , AxProductId
                , LastOrderSource
                , FirstOrderSource
                , OrderSourceHistory
                  ,CASE WHEN [OrderSourceHistory] like '%15%' THEN 'MDT' ELSE 'non-MDT' END as MDT
      ,CASE 
            WHEN [FirstOrderSource] = 9 OR ([OrderSourceHistory] like '%09%' AND ([OrderSourceHistory] like '%11%' OR [OrderSourceHistory] like '%12%' OR [OrderSourceHistory] like '%19%' OR [OrderSourceHistory] like '%21%')) THEN 'Autospreader - ServerSide'
            WHEN [OrderSourceHistory] like '%01%' THEN 'Autospreader - Desktop' 
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
                , [brokerid]
                , [companyid]
                , DayofMonth
                , Day(TransactionDate) as Day
                , Isbillable
                , Fills AS Fill

                FROM [dbo].[fills]

                WHERE networkid = 1104
                  and MarketId not in (84,85,88)
                AND [brokerid]=companyid
                 )
            a

            JOIN dbo.company b
             ON a.networkid = b.networkid
            AND a.[brokerid] = b.companyid
        )
         a

        JOIN dbo.exchange b
         ON a.exchangeid=b.exchangeid

            )
     a1

    JOIN dbo.OrderSource a2
     ON a1.LastOrderSource = a2.OrderSourceNumber )
Y





GO


