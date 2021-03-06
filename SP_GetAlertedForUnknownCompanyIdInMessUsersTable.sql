USE [MESS]
GO
/****** Object:  StoredProcedure [dbo].[GetAlertedForUnknownCompanyIdInMessUsersTable]    Script Date: 5/17/2016 2:06:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetAlertedForUnknownCompanyIdInMessUsersTable]
     
AS

Begin

IF (
select   round((select (CAST((SELECT count([userid]) 
  FROM [dbo].[Users]
  where (companyid = -1 or companyid = 0 or companyid is null))*100 as float)/(
  select count([userid])
  from Users 
  ))),2) as '%OfUsers'
)>=1

Begin


DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<b>Total records with companyId=-1 or 0 or NULL is greater than 1% of total users and equals to' + ' '+
     cast((select   round((select (CAST((SELECT count([userid]) 
  FROM [dbo].[Users]
  where (companyid = -1 or companyid = 0 or companyid is null))*100 as float)/(
  select count([userid])
  from Users 
  ))),2) as '%OfUsers') as varchar)+'%'



  BEGIN
    EXEC msdb.dbo.SP_SEND_DBMAIL
      @profile_name='CHISQL20DBMail Public Profile',
	 @recipients='ax-support@tradingtechnologies.com',
	 --@recipients='ram.modugula@tradingtechnologies.com',
      @subject = 'Action Required: Users with companyId=-1 or 0 or null is greater than 1% of total users in MESS TT US load',
      @body = @tablehtml,
      @body_format = 'HTML'
	  --@attach_query_result_as_file = 1 ;
  END --IF EXISTS



END

END



