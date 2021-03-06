USE [MESS]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForMissedUserEnvironmentAccess]    Script Date: 5/17/2016 2:04:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForMissedUserEnvironmentAccess]
     
AS

Begin

IF (
    Select count(*) from
    (
	   SELECT distinct ulg.Year,ulg.Month,ulg.[UserId],EnvironmentId,EnvironmentName,uea.CreatedDate
	   FROM [dbo].[UserLoginHistory] ulg
	   left join UserEnvironmentAccess uea   on ulg.userid = uea.userid
	   inner join Users u   on ulg.userid = u.userid
	   inner join Companies c   on u.companyId = c.CompanyId
	   where uea.userid is null and c.CompanyId != 63 and c.isTT != 1 and ulg.month = Month(GETDATE())
	   and ulg.year = Year(GETDATE()) and ((email not like '%@trade.tt') and (email not like '%@tradingtechnologies.com'))
    )Q
)<>0

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>UserEnvironmentAccess missing for Current Month</H1>' +
    N'<table border="1">' +
	N'<tr><th>Year</th><th>Month</th><th>UserId</th><th>EnvironmentId</th>' +
    N'<th>EnvironmentName</th><th>CreatedDate</th>' +
    CAST ( ( SELECT distinct 
                     td = Year,       '',
				 td = Month,       '',
                     td = UserId,       '',
	                td = EnvironmentId, '',
	                td = EnvironmentName, '',
			      td = CreatedDate, ''
 from (
   SELECT distinct ulg.Year,ulg.Month,ulg.[UserId],EnvironmentId,EnvironmentName,uea.CreatedDate
	   FROM [dbo].[UserLoginHistory] ulg
	   left join UserEnvironmentAccess uea   on ulg.userid = uea.userid
	   inner join Users u   on ulg.userid = u.userid
	   inner join Companies c   on u.companyId = c.CompanyId
	   where uea.userid is null and c.CompanyId != 63 and c.isTT != 1 and ulg.month = Month(GETDATE())
	   and ulg.year = Year(GETDATE()) and ((email not like '%@trade.tt') and (email not like '%@tradingtechnologies.com'))
	   )Q
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>';
  


  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL20DBMail Public Profile',
	 @recipients='ax-support@tradingtechnologies.com',
	 --@recipients='ram.modugula@tradingtechnologies.com',
      @subject = 'Action Required: Missing UserEnvironmentAccess for Current Month in MESS TT US load',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS



END

END



