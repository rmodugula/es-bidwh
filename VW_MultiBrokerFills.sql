USE [BIDW]
GO

/****** Object:  View [dbo].[VW_MultiBrokerFills]    Script Date: 10/30/2015 11:21:39 AM ******/
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
,[Platform]

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
	,[Platform]

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
		,[Platform]

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
			,[Platform]

            FROM
            (
                SELECT
                  a.*
                , b.MarketName AS exchange

                FROM
                (
                    SELECT
                    YEAR
                    ,MONTH
                    , UserName
                    , exchangeid
					, Marketid
                    , [networkid]
                    , [AxProductId]
                    , lastordersource
                    , firstordersource
                    , OrderSourceHistory
                      ,MDT
      ,FunctionalityArea
                    , [brokerid]
                    , [companyid]
                    , DayofMonth
                    , Day(TransactionDate) as Day
                    , Isbillable
					,[Platform]
                    , Fills AS Fill

                    FROM [dbo].[fills] 

                    WHERE networkid = 1104
                      and MarketId not in (84,85,88)
      
				                )
                 a

                LEFT JOIN Market b
                 ON a.Marketid = b.Marketid

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
, rtrim(case when y.iphen=0 then y.MarketName when y.iphen <>0 then replace(substring(y.MarketName,1,y.iphen),'-','') when y.MarketName='LIFFE-EO' then 'LIFFE-EO' end) as Exchange
, y.AxProductId
, Y.FirstOrderSource
,Y.LastOrderSource
, y.OrderSourceHistory
,y.MDT
,y.FunctionalityArea
, Y.[Description]
, y.Isbillable
, y.Fill
,[Platform]

FROM
(
    SELECT
      charindex('-',a1.MarketName) AS iphen
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
    , a1.MarketName
    , a1.FirstOrderSource
    , a1.LastOrderSource
    , a1.OrderSourceHistory
    , a1.MDT
    , a1.FunctionalityArea
    , a2.[Description]
    , a1.Isbillable
    , a1.Fill
	,[Platform]

    FROM
    (
        SELECT
          a.*
        , b.MarketName

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
			, a.Marketid
            , a.LastOrderSource
            , a.FirstOrderSource
            ,a.OrderSourceHistory
            ,a.MDT
            ,a.FunctionalityArea
            , a.Isbillable
            , a.fill
			,[Platform]

            FROM
            (
                SELECT
                Year
                ,Month
                , UserName
                , exchangeid
				, Marketid
                , [networkid]
                , AxProductId
                , LastOrderSource
                , FirstOrderSource
                , OrderSourceHistory
                  ,MDT
      ,FunctionalityArea
                , [brokerid]
                , [companyid]
                , DayofMonth
                , Day(TransactionDate) as Day
                , Isbillable
                , Fills AS Fill
				,[Platform]

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

        LEFT JOIN dbo.Market b
         ON a.Marketid=b.Marketid

            )
     a1

    JOIN dbo.OrderSource a2
     ON a1.LastOrderSource = a2.OrderSourceNumber )
Y








GO


