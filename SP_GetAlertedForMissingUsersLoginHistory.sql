USE [MESS]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForMissingUsersLoginHistory]    Script Date: 5/17/2016 2:05:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForMissingUsersLoginHistory]
     
AS

Begin

IF (
    SELECT count(*)
  FROM [dbo].[UserLoginHistory]
  where ([year] = year(GETDATE()) and [month] = month(GETDATE()))
)=0

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<h1><b>No records present in “UserLoginHistory” table for Current Month</b></h1>' 
 

  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL20DBMail Public Profile',
	 @recipients='ax-support@tradingtechnologies.com',
	 --@recipients='ram.modugula@tradingtechnologies.com',
      @subject = 'Action Required: No records present in UserLoginHistory table for Current Month in MESS TT US load',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS



END

END



