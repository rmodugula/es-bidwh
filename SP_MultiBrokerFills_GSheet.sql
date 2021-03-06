USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_MultiBrokerFills_GSheet]    Script Date: 6/8/2016 12:51:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[SP_MultiBrokerFills_GSheet] 
@RunYear Int = Null,
@RunMonth char(10) = Null

AS

Declare @Year int, @Month char(10)
IF @RunMonth is Null and @RunMonth is Null
Begin 
set @Year = (select YEAR from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1)
set @Month = (SELECT rtrim(substring(DATENAME(month, cast(CONVERT(varchar,(select Month from(select *, ROW_NUMBER() over (order by id desc) as num from chisql12.fillhub.dbo.invoicemonth)Q where num=1)) + '/1/' + CONVERT(varchar,year(getdate())) as date)),1,3)))
--Set @Year=YEAR(getdate()) 
--Set @Month=(SELECT rtrim(substring(DATENAME(month, GETDATE()),1,3)))
END
else 
Begin
Set @Year=@RunYear
Set @Month=@RunMonth
End



BEGIN

Select Month,DayofMonth,Day,Brokername,MBMasterCustomerName,Brokerid,Companyname,CompanyId,case when Exchange='KCG' then 'LSE' end as Exchange,AxProductId,MDT,FunctionalityArea,IsBillable
,sum(fill) as Fill, sum(contracts) as Contracts from
(

SELECT
  z.Month
, z.DayofMonth
, z.Day
, z.UserName
, z.Brokername
, z.MBMasterCustomerName
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
, z.Contracts
FROM
(
    SELECT
      @Month AS Month
    , e.Username
    , e.DayofMonth
    , e.Day
    , f.companyname AS Brokername
    , e.MasterAccountName as MBMasterCustomerName
    , e.brokerid AS BrokerId
    , e.companyname AS CompanyName
    , e.companyid AS CompanyId
    , case when e.exchange like 'CBOT%' then 'CME' else e.exchange end as exchange
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
	, e.Contracts

    FROM
    (
        SELECT
          d.UserName
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
	   ,d.MasterAccountName
        , Isnull(d.fill, 0)AS Fill
		, Isnull(d.Contracts,0) as Contracts

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
              c.Username
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
			, c.Contracts
            , c.exchange
            , d.[description]
		  ,MasterAccountName

            FROM
            (
                SELECT
                  a.*
                , b.exchangeflavor AS exchange

                FROM
                (
                    SELECT
                      UserName
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
                    , [brokerid]
                    , [companyid]
                    , DayofMonth
                    , Day(TransactionDate) as Day
                    , Isbillable
				, MasterAccountName
                    , Fills AS Fill
					, Contracts

                    FROM [dbo].[fills] F
				left join (select * from Account where accountid not like 'LGCY%')A on F.AccountId=A.Accountid

                    WHERE networkid = 1104
                      and MarketId not in (84,85,88)
                     and year = @Year  and month =(case 
													when @month = 'Jan' then 1
													when @month = 'Feb' then 2
													when @month = 'Mar' then 3
													when @month = 'Apr' then 4
													when @month = 'May' then 5
													when @month = 'Jun' then 6
													when @month = 'Jul' then 7
													when @month = 'Aug' then 8
													when @month = 'Sep' then 9
													when @month = 'Oct' then 10
													when @month = 'Nov' then 11
													when @month = 'Dec' then 12
													end)
				                )
                 a

                JOIN exchange b
                 ON a.exchangeid = b.exchangeid

                --WHERE b.marketid not in (84,85,88)
            )
            c

            JOIN (select distinct ordersourcenumber,Description from ordersource) d
             ON c.lastordersource = d.ordersourcenumber --AND c.firstordersource = 
             --    d.ordersourcenumber
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
  y.Month
, y.DayofMonth
, y.Day
, y.UserName
, y.Brokername
, y.MBMasterCustomerName
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
, y.Contracts

FROM
(
    SELECT
      charindex('-',a1.exchangeflavor) AS iphen
    , a1.Month
    , a1.UserName
    , a1.DayofMonth
    , a1.Day
    , a1.Brokername
    , a1.MBMasterCustomerName
    , a1.brokerid
    , a1.AxProductId
    , a1.companyname
    , a1.companyid
    , case when a1.exchangeflavor like 'CBOT%' then 'CME' else a1.exchangeflavor end as exchangeflavor
    , a1.FirstOrderSource
    , a1.LastOrderSource
    , a1.OrderSourceHistory
    , a1.MDT
    , a1.FunctionalityArea
    , a2.[Description]
    , a1.Isbillable
     , a1.Fill
	, a1.Contracts

    FROM
    (
        SELECT
          a.*
        , b.exchangeflavor

        FROM
        (
            SELECT
              @Month AS Month
            , a.UserName
            , a.DayofMonth
            , a.Day
            , b.companyname AS Brokername
            , a.MasterAccountName as MBMasterCustomerName
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
		  ,a.MasterAccountName
            , a.fill
			, a.Contracts

            FROM
            (
                SELECT
                  UserName
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
                , [brokerid]
                , [companyid]
                , DayofMonth
                , Day(TransactionDate) as Day
                , Isbillable
			 ,MasterAccountName
                , Fills AS Fill
				, Contracts

                FROM [dbo].[fills] F
			 left join (select * from Account where accountid not like 'LGCY%')A on F.AccountId=A.Accountid

                WHERE networkid = 1104
                  and MarketId not in (84,85,88)
                AND [brokerid]=companyid
                and year = @Year 
                and month =(case 
							when @month = 'Jan' then 1
							when @month = 'Feb' then 2
							when @month = 'Mar' then 3
							when @month = 'Apr' then 4
							when @month = 'May' then 5
							when @month = 'Jun' then 6
							when @month = 'Jul' then 7
							when @month = 'Aug' then 8
							when @month = 'Sep' then 9
							when @month = 'Oct' then 10
							when @month = 'Nov' then 11
							when @month = 'Dec' then 12
							end)
                --AND transactiondatetime BETWEEN '2013-12-01'
                --AND '2013-12-31' --AND fillstatus = 2048
            )
            a

           FULL JOIN dbo.company b
             ON a.networkid = b.networkid
            AND a.[brokerid] = b.companyid
        )
         a

        JOIN dbo.exchange b
         ON a.exchangeid=b.exchangeid

        --WHERE b.marketid not in (84,85,88)
    )
     a1

    JOIN (select distinct ordersourcenumber,Description from ordersource) a2
     ON a1.LastOrderSource = a2.OrderSourceNumber --and a1.FirstOrderSource = a2.OrderSourceNumber
)
Y
)Z
Group BY Month,DayofMonth,Day,Brokername,MBMasterCustomerName,Brokerid,Companyname,CompanyId,Exchange,AxProductId,MDT,FunctionalityArea,IsBillable
END


