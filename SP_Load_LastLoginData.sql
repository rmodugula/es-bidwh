USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_LastLoginData]    Script Date: 11/3/2014 1:29:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Load_LastLoginData]
(@Year Int, @Month Int)
  
AS
BEGIN

Delete lastlogin
where year=@Year and month=@Month
Insert into lastlogin
select distinct Year(LastLoginDate) as Year, Month(LastLoginDate) as Month,*,getdate() as LastUpdatedDate
from
(
select tt_description as UserName,Delivery_name as DeliveryName,Customer,TT_product as TTProduct
,User_group as UserGroup,Email,Phone,Last_Login as LastLoginDate,IPAddress,[Version], [Status],[UserCreatedDate] from chisql15.ttus_logins.dbo.lastloginAll
where year(Last_Login)=@Year and month(Last_Login)=@Month
)Q

update LastLogin
set Customer='Daiwa Securities Co. Ltd'
where Customer='Daiwa Securities'

update LastLogin
set Customer='GH Financials'
where Customer='GH Financial'


update LastLogin
set Customer='Macquarie Group'
where Customer='Macquarie'

update LastLogin
set Customer='BAML'
where Customer='Merrill Lynch'

update LastLogin
set Customer='Mizuho Securities'
where Customer='Mizuho'

end



