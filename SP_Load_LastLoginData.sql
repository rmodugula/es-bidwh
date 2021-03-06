USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_LastLoginData]    Script Date: 7/27/2015 11:36:58 AM ******/
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
select distinct Year(LastLoginDate) as Year, Month(LastLoginDate) as Month,*,'' as NetworkShortName,getdate() as LastUpdatedDate
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


Update L
Set NetworkShortName=
case customer
when  'ADM Investor Services' then 'TTNADM'
when 'Amp Global Clearing' then 'TTNAMP'
when 'BAML' then 'TTNMerLy'
when 'BNP Paribas' then 'TTNETBNP'
when 'Credit Suisse' then 'TTNCRS'
when 'Daiwa' then 'DW7'
when 'Daiwa Securities Co. Ltd' then 'DW7'
when 'Deutsche Bank' then 'TTNDB'
when 'ETRADE' then 'TM7'
when 'GH Financials' then 'TTNGHF'
when 'Goldman Sachs' then 'TTNGOLD'
when 'HSBC' then 'TTNHSBC'
when 'JP Morgan' then 'TTNETJPM'
when 'Macquarie Group' then 'TTNMACQ'
when 'Mizuho Securities' then 'TTNMIZ'
when 'Morgan Stanley' then 'TTNET MS'
when 'MultiBroker' then 'MB_ASP'
when 'Newedge' then 'TTNFIM7X'
when 'SEB' then 'SEB'
when 'TradeCo' then 'TrdCoFM7'
when 'UBS' then  'TTNETUBS'
END 
from [dbo].[LastLogin] L
where year=@Year and month=@Month




end



