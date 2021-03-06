USE [MESS]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForUsersWithNullDemoJoiningDate]    Script Date: 5/17/2016 2:06:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForUsersWithNullDemoJoiningDate]
     
AS

Begin

IF (
    Select count(*) from
    (
	  SELECT [UserId],[DemoJoiningDate],[IsUserDemo]
       FROM [dbo].[Users]
       where DemoJoiningDate is null
       and isUserDemo = 1
    )Q
)<>0

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<h1><b>Users with Null DemoJoiningDate in Users Table</b></h1>' +
    '<br>'+
    N'<table border="1">' +
	N'<tr><th>UserId</th><th>DemoJoiningDate</th><th>IsUserDemo</th>' +
    CAST ( ( SELECT distinct 
                     td = UserId,       '',
				 td = DemoJoiningDate,       '',
                     td = IsUserDemo,       ''
 from (
       SELECT [UserId],[DemoJoiningDate],[IsUserDemo]
       FROM [dbo].[Users]
       where DemoJoiningDate is null
       and isUserDemo = 1
	   )Q
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>';
  


  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL20DBMail Public Profile',
	 @recipients='ax-support@tradingtechnologies.com',
	 --@recipients='ram.modugula@tradingtechnologies.com',
      @subject = 'Action Required: Users with Null DemoJoiningDate in Users Table in MESS TT US load',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS



END

END



