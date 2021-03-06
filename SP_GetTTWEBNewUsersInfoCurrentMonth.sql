USE [TTWebBillingProcessor]
GO
/****** Object:  StoredProcedure [dbo].[GetTTWEBNewUsersInfoCurrentMonth]    Script Date: 5/3/2017 1:14:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetTTWEBNewUsersInfoCurrentMonth]

	
AS
Declare @Year Int
Declare @Month Int
Declare @PriorYear Int
Declare @PriorMonth Int
set @PriorYear= (case when MONTH(getdate())=1 then YEAR(getdate())-1 else YEAR(getdate()) end) 
set @PriorMonth = (case when MONTH(getdate())=1 then 12 else MONTH(getdate())-1 end)
Set @Year= case when (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth  where YEAR=year(getdate()) AND MONTH =Month(getdate())) = 0 then Year(getdate()) else @PriorYear END
Set @Month= case when (select COUNT(*) from chisql12.fillhub.dbo.invoicemonth  where YEAR=year(getdate()) AND MONTH =Month(getdate())) = 0 then  Month(getdate()) else @PriorMonth END

DECLARE @FirstDayOfMonth smalldatetime
SET @FirstDayOfMonth = cast(CONVERT(varchar,@Month) + '/1/' + CONVERT(varchar,@Year) as date)
DECLARE @FirstDayOfBilling smalldatetime
SET @FirstDayOfBilling = cast(CONVERT(varchar,4) + '/1/' + CONVERT(varchar,2016) as date)


BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Select Year,Month,BillableCompany,UserCompany,FirstName,LastName,[DeliveryName],[ProductName],[SalesPrice],PromoCode,[CountryCode],Sum(Quantity) as Quantity
,sum(Discount) as Discount,[Description],UserCompanyId,UserId,City,ZipCode,StateCode from
(
SELECT Year,Month,[companyname] AS BillableCompany,l.UserCompany, u.FirstName,u.LastName,[DeliveryName],[ProductName],[SalesPrice],PromoCode,l.[CountryCode],[Quantity],[Discount],
       [Rate],[Description],l.UserCompanyId,l.UserId,l.City,l.ZipCode,l.StateCode
FROM chisql20.[TTWebBillingProcessor].[dbo].[BillableLines] l
     JOIN chisql20.MESS.dbo.Users u ON l.userid = u.userid
WHERE year = @Year and month=@month AND l.companyid NOT IN(10, 73, 1,2)
---Excluded users who have $0 lines due to some reason other than a Promocode
and (PromoCode is not null or salesPrice <> 0 )
and l.userid not in 
(
select distinct userid from chisql20.[TTWebBillingProcessor].[dbo].[BillableLines]
where companyid NOT IN(10, 73, 1,2) 
--show users who have previously been $0 for a reason other than PromoCode
and not (PromoCode is null and salesPrice = 0)
and cast(CONVERT(varchar,month) + '/1/' + CONVERT(varchar,year) as date) <@FirstDayOfMonth 
and cast(CONVERT(varchar,month) + '/1/' + CONVERT(varchar,year) as date)>='04/01/2016'
--and 
--cast(CONVERT(varchar,month) + '/1/' + CONVERT(varchar,year) as date) >=@FirstDayOfBilling
)
)Q
Group by Year,Month,BillableCompany,UserCompany,FirstName,LastName,[DeliveryName],[ProductName],[SalesPrice],PromoCode,[CountryCode]
,[Description],UserCompanyId,UserId,City,ZipCode,StateCode 

    
END
