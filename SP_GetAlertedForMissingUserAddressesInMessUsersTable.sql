USE [MESS]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForMissingUserAddressesInMessUsersTable]    Script Date: 5/17/2016 2:05:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForMissingUserAddressesInMessUsersTable]
     
AS

Begin

IF (
    Select count(*) from
    (
	  SELECT [Userid],[FirstName] ,[LastName],[CountryCode] ,[StateCode],[ZipCode],[City]
FROM [MESS].[dbo].[Users] where countrycode = '' and isActive = 1 and isDeleted !=1 and isInternal = 0
    )Q
)<>0

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<h1><b>Users with missing addresses in Users Table</b></h1>' +
    '<br>'+
    N'<table border="1">' +
	N'<tr><th>UserId</th><th>FirstName</th><th>LastName</th><th>CountryCode</th>' +
    N'<th>StateCode</th><th>ZipCode</th><th>City</th>' +
    CAST ( ( SELECT distinct 
                     td = UserId,       '',
				 td = FirstName,       '',
                     td = LastName,       '',
	                td = CountryCode, '',
	                td = StateCode, '',
			      td = ZipCode, '',
				 td = City, ''
 from (
	  SELECT [UserId],[FirstName] ,[LastName],[CountryCode] ,[StateCode],[ZipCode],[City]
FROM [MESS].[dbo].[Users] where countrycode = '' and isActive = 1 and isDeleted !=1 and isInternal = 0
	   )Q
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>';
  


  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL20DBMail Public Profile',
	 @recipients='ax-support@tradingtechnologies.com',
	 --@recipients='ram.modugula@tradingtechnologies.com',
      @subject = 'Action Required: Users with missing addresses in Users Table in MESS TT US load',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS



END

END



