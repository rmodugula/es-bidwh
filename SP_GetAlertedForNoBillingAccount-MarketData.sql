USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForNoBillingAccount-MarketData]    Script Date: 4/25/2016 10:48:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForNoBillingAccount-MarketData]

AS

Begin

DECLARE @SnapshotDay INT;
DECLARE @CurrentDay INT;

SET @SnapshotDay = (SELECT TOP 1 Day FROM [MarketData].[dbo].[MarketDataUserEntitlement] WHERE year = YEAR(GETDATE()) AND month = MONTH(GETDATE()) ORDER BY Day DESC);
SET @CurrentDay = DAY(GETDATE());

IF (Select count(*) from
(
SELECT  Distinct [Year],[Month],[Day],[UserName],m.[CompanyId],m.CompanyName,BrokerId,case when C.CompanyName='Trading Technologies' then ' ' else 
C.CompanyName end as BrokerName,m.[NetworkId] 
FROM [MarketData].[dbo].[MarketDataUserEntitlement] M
Join Company C on m.BrokerId=c.CompanyId
where year=year(getdate()) and month=month(getdate()) and axproductid <>'<Unmapped>' and billingaccountid is null
--AND (ExchangeProvidedCode LIKE '%acc' OR waivered =1) 
and m.networkid<>'TNT' and m.companyname<>'Demo1' and m.CompanyName<>'Demo University'
and not (m.[CompanyId] =2 and m.NetworkId = 'TTWEB')
and username not like '%tradingtechnologies.com'
and Username not like '%trade.tt'
and University <> 1
and m.companyid<>183 and brokerid<>183
and NonBillable = 0)Q)<>0

--Only send email if the market data processor was run.
AND (@SnapshotDay = @CurrentDay)

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>No Billing Account Mapping in Current Month For Market Data</H1>' +
    N'<table border="1">' +
	N'<tr><th>Year</th><th>Month</th><th>UserName</th><th>CompanyId</th>' +
    N'<th>CompanyName</th><th>BrokerId</th><th>BrokerName</th><th>NetworkId</th>' +
    CAST ( ( SELECT td = Year,       '',
	                td = Month,       '',
	                td = UserName,       '',
                    td = CompanyId, '',
					td = CompanyName, '',
					td = BrokerId, '',
					td = BrokerName, '',
                    td = NetworkId, ''
               from (
SELECT  Distinct [Year],[Month],[Day],[UserName],m.[CompanyId],m.CompanyName,BrokerId,case when C.CompanyName='Trading Technologies' then ' ' else 
C.CompanyName end as BrokerName,m.[NetworkId] 
FROM [MarketData].[dbo].[MarketDataUserEntitlement] M
Join Company C on m.BrokerId=c.CompanyId
where year=year(getdate()) and month=month(getdate()) and axproductid <>'<Unmapped>' and billingaccountid is null
--AND (ExchangeProvidedCode LIKE '%acc' OR waivered =1) 
and m.networkid<>'TNT' and m.companyname<>'Demo1' and m.CompanyName<>'Demo University'
and not (m.[CompanyId] =2 and m.NetworkId = 'TTWEB')
and username not like '%tradingtechnologies.com'
and Username not like '%trade.tt'
and University <> 1
and m.companyid<>183 and brokerid<>183
and NonBillable = 0)Q
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;


  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL12DBMail Public Profile',
      @recipients='marketdata-alerts@tradingtechnologies.com;Melissa.Albertini@tradingtechnologies.com',
      @subject = 'Action Required: Billing Account Mapping Needed in Current Month For Market Data',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS





END

END



