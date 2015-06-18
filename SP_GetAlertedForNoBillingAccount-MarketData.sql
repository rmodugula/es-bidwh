USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForNoBillingAccount-MarketData]    Script Date: 5/15/2015 9:19:21 AM ******/
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
AND (ExchangeProvidedCode LIKE '%acc' OR waivered =1) and m.networkid<>'TNT')Q)<>0

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>No Billing Account in Current Month For Market Data</H1>' +
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
AND (ExchangeProvidedCode LIKE '%acc' OR waivered =1) and m.networkid<>'TNT')Q
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;


  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL12DBMail Public Profile',
      @recipients='ram.modugula@tradingtechnologies.com;Mark.mcclowry@tradingtechnologies.com;Melissa.Albertini@tradingtechnologies.com;Johanri.Gerber@tradingtechnologies.com',
      @subject = 'Action Required: Billing Account needed',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS





END

END



