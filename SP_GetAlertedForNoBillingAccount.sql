USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForNoBillingAccount]    Script Date: 4/15/2015 10:35:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForNoBillingAccount]
     
AS

Begin

IF EXISTS(Select C.companyname as BrokerName, A.CompanyName,FillStatusDesc,Fills from
(
SELECT BrokerId,CompanyName,FillStatusDesc,sum(fills) as Fills FROM Fills F
join company C
on F.CompanyId=C.CompanyId
where year=year(getdate()) and month=month(getdate()) and fillstatus=4096
Group by BrokerId,CompanyName,FillStatusDesc
)A
join Company C
on A.BrokerId=c.CompanyId)

DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>No Billing Account Fills in Current Month</H1>' +
    N'<table border="1">' +
    N'<tr><th>BrokerName</th><th>CompanyName</th>' +
    N'<th>FillStatusDesc</th><th>Fills</th>' +
    CAST ( ( SELECT td = C.CompanyName,       '',
                    td = A.CompanyName, '',
					td = FillStatusDesc, '',
                    td = Fills, ''
               from (
SELECT BrokerId,CompanyName,FillStatusDesc,sum(fills) as Fills FROM chisql12.bidw.dbo.Fills F
join chisql12.bidw.dbo.company C
on F.CompanyId=C.CompanyId
where year=year(getdate()) and month=Month(getdate()) and fillstatus=4096
Group by BrokerId,CompanyName,FillStatusDesc
)A
join chisql12.bidw.dbo.Company C
on A.BrokerId=c.CompanyId
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;


  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL12DBMail Public Profile',
      @recipients='ram.modugula@tradingtechnologies.com;Mark.mcclowry@tradingtechnologies.com;Melissa.Albertini@tradingtechnologies.com',
      @subject = 'Action Required: Billing Account needed',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS




END




