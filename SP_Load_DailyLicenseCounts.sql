USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_DailyLicenseCounts]    Script Date: 2/12/2016 3:10:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[SP_Load_DailyLicenseCounts]
	@RunDate datetime = null
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Today datetime
	DECLARE @Tomorrow datetime
	DECLARE @FirstDayOfMonth datetime
	DECLARE @LastDayOfLastMonth datetime
	DECLARE @Month int
	DECLARE @Year int
	DECLARE @PriorYear int   -- <Ram 1/10/2014 10:45 AM> To load Non-Invoiced Months Data Only - Jira BI-80
	DECLARE @PriorMonth int
	
	
	IF @RunDate is null
	BEGIN
		SET @RunDate = GETDATE()
	END
	
	SET @Today = CONVERT(date,@RunDate)
	SET @Tomorrow = CONVERT(date, DATEADD(d, 1, @Today)) 
	SET @FirstDayOfMonth = CONVERT(varchar,DATEPART(m, @Today)) + '/1/' + CONVERT(varchar,DATEPART(yyyy, @Today))
	SET @Month = DATEPART(m, @Today)
	SET @Year = DATEPART(yyyy, @Today)
	SET @PriorYear = (Case when Month(getdate()) =1 then YEAR(GETDATE())-1 else YEAR(getdate()) end)
	SET @PriorMonth = (Case when Month(getdate()) =1 then 12 else MONTH(getdate())-1 end)

	IF DATEPART(d,@Today) < 10 and 
(select COUNT(*) from chisql12.fillhub.dbo.invoicemonth
 where YEAR=@PriorYear AND MONTH =@PriorMonth) = 0    -- <Ram 1/10/2014 10:45 AM> To load Non-Invoiced Months Data Only - Jira BI-80
	
	BEGIN
		SET @LastDayOfLastMonth = CONVERT(date,DATEADD(d,-1,@FirstDayOfMonth))
		EXEC SP_Load_DailyLicenseCounts @LastDayOfLastMonth
	END
	
	DELETE DailyLicenseCountsReporting WHERE Month = DATEPART(m, @Today) and Year = DATEPART(yyyy, @Today) and Day = DATEPART(d, @Today)
/******************************************New Logic to load Transaction License Counts Ram<01/02/2014 14:50>***************************************/
	INSERT INTO DailyLicenseCountsReporting
	select DATEPART(m, @Today) as Month, DATEPART(yyyy, @Today) as Year, DATEPART(d, @Today) as Day,MasterAccountName,
	'X_TRADER® Pro Transaction' as ProductName,COUNT(*) as LicenseCount,GETDATE() as LastUpdatedDate from
	(
	select distinct networkid,username,AccountId from fills F 
	where Month=@Month and Year=@Year
	and isbillable='Y'
	and AxProductId in ('20999') and NetworkId not in (577)
	) Q join Account A
	on Q.AccountId=A.Accountid
	group by MasterAccountName
	union all
	select DATEPART(m, @Today) as Month, DATEPART(yyyy, @Today) as Year, DATEPART(d, @Today) as Day,MasterAccountName,
	'X_TRADER® Transaction' as ProductName,COUNT(*) as LicenseCount,GETDATE() as LastUpdatedDate from
	(
	select distinct networkid,username,AccountId from fills F 
	where Month=@Month and Year=@Year
	and isbillable='Y'
	and AxProductId in ('20005') and NetworkId not in (577)
	) Q join Account A
	on Q.AccountId=A.Accountid
	group by MasterAccountName
	union all
	Select Month,Year,Day,MasterAccountName,ProductName,sum(licensecount) as LicenseCount,GETDATE() as LastUpdatedDate
from(
select DATEPART(m, @Today) as Month, DATEPART(yyyy, @Today) as Year, DATEPART(d, @Today) as Day,MasterAccountName,
	'X_TRADER® MultiBroker' as ProductName,COUNT(*) as LicenseCount,GETDATE() as LastUpdatedDate from
	(
	select distinct username,AccountId from fills
	--select distinct username,BrokerId,AccountId from fills
	where Month=@Month and Year=@Year
	and IsBillable='Y'
	and axproductid=20997
	) Q join Account A
	on Q.AccountId=A.Accountid
	group by MasterAccountName	
	union all
	select DATEPART(m, @Today) as Month, DATEPART(yyyy, @Today) as Year, DATEPART(d, @Today) as Day,MasterAccountName,
	'X_TRADER® MultiBroker' as ProductName,COUNT(*) as LicenseCount,GETDATE() as LastUpdatedDate from
	(
	select distinct username,AccountId from fills
	--select distinct username,BrokerId,AccountId from fills
	where Month=@Month and Year=@Year
	and IsBillable='Y'
	and axproductid=20995
	) Q join Account A
	on Q.AccountId=A.Accountid
	group by MasterAccountName	
	union all
	select DATEPART(m, @Today) as Month, DATEPART(yyyy, @Today) as Year, DATEPART(d, @Today) as Day,MasterAccountName,
	'X_TRADER® MultiBroker' as ProductName,COUNT(*) as LicenseCount,GETDATE() as LastUpdatedDate from
	(
	select distinct username,AccountId from fills
	--select distinct username,BrokerId,AccountId from fills
	where Month=@Month and Year=@Year
	and IsBillable='Y'
	and axproductid=20992
	) Q join Account A
	on Q.AccountId=A.Accountid
	group by MasterAccountName	
	union all
	select DATEPART(m, @Today) as Month, DATEPART(yyyy, @Today) as Year, DATEPART(d, @Today) as Day,MasterAccountName,
	'X_TRADER® MultiBroker' as ProductName,COUNT(*) as LicenseCount,GETDATE() as LastUpdatedDate from
	(
	select distinct username,AccountId from fills
	--select distinct username,BrokerId,AccountId from fills
	where Month=@Month and Year=@Year
	and IsBillable='Y'
	and axproductid=20993
	) Q join Account A
	on Q.AccountId=A.Accountid
	group by MasterAccountName
	)Q
	Group By Month,Year,Day,MasterAccountName,ProductName
/***********************************************************************************/

	--SELECT DATEPART(m, @Today), DATEPART(yyyy, @Today), DATEPART(d, @Today), LegalName, Product, count(DISTINCT UserId),GETDATE()
	--FROM chisql20.licensing2.dbo.InvoiceFillDataCache ic inner join chisql20.licensing2.dbo.billingserver bs on bs.billingserverkey = ic.billingserverkey inner join chisql20.licensing2.dbo.account a on bs.slaid = a.id
	--WHERE month = DATEPART(m, @Today) and year = DATEPART(yyyy, @Today) and (productid = 270 OR productid = 285 or ProductId = 287) and DATEPART(d, @Today) > 2 and ic.Subtotal > 0
	--GROUP BY LegalName, Product
	
	INSERT INTO DailyLicenseCountsReporting
	select DATEPART(m, @Today), DATEPART(yyyy, @Today), DATEPART(d, @Today), a.MasterAccountName AS LegalName, 
	REPLACE(p.ProductName,'®', '') AS ProductName,SUM(billablelicensecount),getdate() -- <Ram 05/20/2014> Replace count(*) with BillableLicensecount
	from dbo.MonthlyBillingData mbd inner join dbo.account a on mbd.accountid = a.accountid
	inner join dbo.product p on mbd.productsku = p.productsku
	where TTBillStart <= @Today
	and (@Today between TTBillStart and TTBillEnd or ttbillend = '1/1/1900')
	and (mbd.productsku = 20000 or mbd.productsku = 20200)
	and billedamount > 0
	and MONTH = @Month and YEAR = @Year
	group by MasterAccountName, ProductName
	order by ProductName, MasterAccountName 

	
---------------------TTWEB User Counts---------------------------
    INSERT INTO DailyLicenseCountsReporting
	Select Month,Year,Day, LegalName,ProductName,sum(screens) as Screns,getdate()
from
(
	select DATEPART(m, cast(@Today as date)) as Month, DATEPART(yyyy, cast(@Today as date)) as Year, DATEPART(d, cast(@Today as date)) as day, a.MasterAccountName AS LegalName, 
	'TTWEB' AS ProductName,SUM(billablelicensecount) as screens -- <Ram 05/20/2014> Replace count(*) with BillableLicensecount
	from dbo.MonthlyBillingData mbd inner join dbo.account a on mbd.accountid = a.accountid
	inner join dbo.product p on mbd.productsku = p.productsku
	where TTBillStart <= cast(@Today as date)
	and (cast(@Today as date) between TTBillStart and TTBillEnd or ttbillend = '1/1/1900')
		and mbd.productsku in (80000,80001,80002,80003,80005,80006) 
	and billedamount > 0
	and MONTH = @Month and YEAR = @Year
	group by MasterAccountName, ProductName
)Q
group by Month,Year,Day, LegalName,ProductName
	order by ProductName, LegalName 

	--INSERT INTO reporting.DailyLicenseCount
	--SELECT DATEPART(m, @Today), DATEPART(yyyy, @Today), DATEPART(d, @Today), LegalName, ProductName, count(*)
	--FROM CHISQL01.TT_Internal.dbo.SLAProduct sp INNER JOIN CHISQL01.TT_Internal.dbo.Product p on sp.ProductID = p.ProductID
	--INNER JOIN CHISQL01.TT_Internal.dbo.SLA s on sp.SLAID = s.SLAID INNER JOIN CHISQL01.TT_Internal.dbo.Account a on s.AccountID = a.AccountID
	--WHERE sp.ProductID IN (1,2) and sp.SLAProductID in (
	--SELECT SLAProductID FROM CHISQL01.TT_Internal.dbo.SLAProductTerms WHERE StartDate < @Tomorrow and (EndDate is null or EndDate >= @Today) and BillableAmount > 0)
	--GROUP BY LegalName, ProductName
	
END
