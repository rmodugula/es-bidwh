USE [TTWebBillingProcessor]
GO
/****** Object:  StoredProcedure [dbo].[GetTTWEBNewUsersInfo]    Script Date: 7/19/2017 2:14:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetTTWEBNewUsersInfo]
@Year Int,
@Month Int

	
AS

DECLARE @FirstDayOfMonth smalldatetime
SET @FirstDayOfMonth = cast(CONVERT(varchar,@Month) + '/1/' + CONVERT(varchar,@Year) as date)
DECLARE @FirstDayOfBilling smalldatetime
SET @FirstDayOfBilling = cast(CONVERT(varchar,4) + '/1/' + CONVERT(varchar,2016) as date)


BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

select Year,Month, BillableCompany,billingaccount,UserCompany, FirstName,LastName,DeliveryName,ProductName,SalesPrice,PromoCode,CountryCode,[Quantity],[Discount],
       [Rate],[Description],UserCompanyId,UserId,City,ZipCode,StateCode,CustomerSuccessManager FROM 
(
SELECT Year,Month,[companyname] AS BillableCompany,billingaccount,l.UserCompany, u.FirstName,u.LastName,[DeliveryName],[ProductName],[SalesPrice],PromoCode,l.[CountryCode],[Quantity],[Discount],
       [Rate],[Description],l.UserCompanyId,l.UserId,l.City,l.ZipCode,case when l.StateCode='0' or l.statecode='' or l.statecode is null then 'Unassigned' else l.statecode end as StateCode,a.crmid
FROM chisql20.[TTWebBillingProcessor].[dbo].[BillableLines] l
     JOIN chisql20.MESS.dbo.Users u ON l.userid = u.userid
	left join chisql12.bidw.dbo.account a on l.billingaccount=a.accountid
WHERE year=@Year and month=@Month AND l.companyid NOT IN(10, 73, 1,2)
and (PromoCode is not null or salesPrice <> 0 )
and l.userid not in 
(
select distinct userid from chisql20.[TTWebBillingProcessor].[dbo].[BillableLines]
where companyid NOT IN(10, 73, 1,2) 
and not (PromoCode is null and salesPrice = 0)
and cast(CONVERT(varchar,month) + '/1/' + CONVERT(varchar,year) as date) <@FirstDayOfMonth
and cast(CONVERT(varchar,month) + '/1/' + CONVERT(varchar,year) as date)>='04/01/2016'
)
)Q
left join 
(
Select * from 
(
select Distinct Accountid,crmid,case when state='0' or state='' or state is null then 'Unassigned' else state end as State,Country,CustomerSuccessManager,row_number() over (partition by accountid,crmid,(case when state='0' or state='' or state is null then 'Unassigned' else state end),country order by customersuccessmanager) as row from chisql12.bidw.dbo.MonthlyBillingDataAggregate_Domo
where  date<=@FirstDayOfMonth and date>=DATEADD(m,-1,@FirstDayOfMonth) and screens='screens' and CustGroup='ttplatform' and customersuccessmanager is not null
)x where row=1
)t
on q.crmid=t.crmid and q.StateCode=t.State and q.countrycode=t.country
    
END
