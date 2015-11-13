USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForNoBillingAccount-MarketData]    Script Date: 11/13/2015 9:55:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForNoBillingAccount-MarketData]
     
AS

Begin

IF (Select count(*) from
(
SELECT  Distinct [Year],[Month],[Day],[UserName],m.[CompanyId],m.CompanyName,BrokerId,C.CompanyName as BrokerName,m.[NetworkId] 
FROM [MarketData].[dbo].[MarketDataUserEntitlement] M
Join Company C on m.BrokerId=c.CompanyId
where year=year(getdate()) and month=month(getdate()) and axproductid <>'<Unmapped>' and billingaccountid is null
--AND (ExchangeProvidedCode LIKE '%acc' OR waivered =1) 
and m.networkid<>'TNT' and m.companyname<>'Demo1'
and not (m.[CompanyId] =2 and m.NetworkId = 'TTWEB')
and username not like '%tradingtechnologies.com'
and University <> 1
and m.companyid<>183 and brokerid<>183)Q)<>0

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
SELECT  Distinct [Year],[Month],[Day],[UserName],m.[CompanyId],m.CompanyName,BrokerId,C.CompanyName as BrokerName,m.[NetworkId] 
FROM [MarketData].[dbo].[MarketDataUserEntitlement] M
Join Company C on m.BrokerId=c.CompanyId
where year=year(getdate()) and month=month(getdate()) and axproductid <>'<Unmapped>' and billingaccountid is null
--AND (ExchangeProvidedCode LIKE '%acc' OR waivered =1) 
and m.networkid<>'TNT' and m.companyname<>'Demo1'
and not (m.[CompanyId] =2 and m.NetworkId = 'TTWEB')
and username not like '%tradingtechnologies.com'
and University <> 1
and m.companyid<>183 and brokerid<>183)Q
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



