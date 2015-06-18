USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForNoBillingAccount-Fills]    Script Date: 5/14/2015 2:29:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForNoBillingAccount-Fills]
     
AS

Begin

IF (Select count(*) from
(
SELECT Year,Month,BrokerId,CompanyName,FillStatusDesc,sum(fills) as Fills FROM Fills F
join company C
on F.CompanyId=C.CompanyId
where year=year(getdate()) and month=month(getdate()) and fillstatus=4096
Group by Year,Month,BrokerId,CompanyName,FillStatusDesc
)A
join Company C
on A.BrokerId=c.CompanyId)<>0

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>No Billing Account in Current Month for Fills</H1>' +
    N'<table border="1">' +
	N'<tr><th>Year</th><th>Month</th><th>BrokerName</th><th>CompanyName</th>' +
    N'<th>FillStatusDesc</th><th>Fills</th>' +
    CAST ( ( SELECT td = Year,       '',
	                td = Month,       '',
	                td = C.CompanyName,       '',
                    td = A.CompanyName, '',
					td = FillStatusDesc, '',
                    td = Fills, ''
               from (
SELECT Year,Month,BrokerId,CompanyName,FillStatusDesc,sum(fills) as Fills FROM chisql12.bidw.dbo.Fills F
join chisql12.bidw.dbo.company C
on F.CompanyId=C.CompanyId
where year=year(getdate()) and month=Month(getdate()) and fillstatus=4096
Group by Year,Month,BrokerId,CompanyName,FillStatusDesc
)A
join chisql12.bidw.dbo.Company C
on A.BrokerId=c.CompanyId
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



