USE [MESS]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForUsersWithLastLoginMismatches]    Script Date: 5/17/2016 2:06:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForUsersWithLastLoginMismatches]
     
AS

Begin

IF (
    Select count(*) from
    (
SELECT u.userid as UserId, u.lastLogin as LastLogin, ulh.LastLoginHistory, u.isActive, u.isDeleted
FROM (
      SELECT userid, MAX(LastLogin) as LastLoginHistory
      FROM UserLoginHistory
      GROUP BY userid
) ulh
INNER JOIN Users u
ON u.userid = ulh.userid
where u.lastLogin != ulh.LastLoginHistory
and u.isActive != 0 and u.isActive is not null
and u.isDeleted != 1
    )Q
)<>0

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<h1><b>Users with different LastLogin Dates in “Users” and “UserLoginHistory” table</b></h1>' +
    '<br>'+
    N'<table border="1">' +
	N'<tr><th>UserId</th><th>LastLogin</th><th>LastLoginHistory</th><th>IsActive</th><th>IsDeleted</th>' +
    CAST ( ( SELECT distinct 
                     td = UserId,       '',
				 td = LastLogin,       '',
                     td = LastLoginHistory, '',
				 td = IsActive, '',
				 td = IsDeleted, ''
 from (
SELECT u.userid as UserId, u.lastLogin as LastLogin, ulh.LastLoginHistory, u.IsActive, u.IsDeleted
FROM (
      SELECT userid, MAX(LastLogin) as LastLoginHistory
      FROM UserLoginHistory
      GROUP BY userid
) ulh
INNER JOIN Users u
ON u.userid = ulh.userid
where u.lastLogin != ulh.LastLoginHistory
and u.isActive != 0 and u.isActive is not null
and u.isDeleted != 1
	   )Q
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>';
  


  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL20DBMail Public Profile',
	 @recipients='ax-support@tradingtechnologies.com',
	 --@recipients='ram.modugula@tradingtechnologies.com',
      @subject = 'Action Required: At least one LastLogin has different values in Users and UserLoginHistory table in MESS TT US load',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS



END

END



