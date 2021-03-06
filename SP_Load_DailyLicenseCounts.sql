USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_DailyLicenseCounts]    Script Date: 5/31/2017 4:28:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
	
	DELETE [dbo].[DailyLicenseCountsReporting] WHERE Month = month(@Today) and Year = year(@Today) and Day = DATEPART(d, @Today)

	    

	Select case when State='00' or state='' then 'Unassigned' else state END  as State,Country,CountryName,SalesOffice,Region 
	into #SalesOfficeMapping
	from
	(
	SELECT Distinct isnull(nullif(state,''),'Unassigned') as [State],[Country],[CountryName],[SalesOffice],Region
	 , row_number() over (partition by isnull(nullif(state,''),'Unassigned'),country order by salesoffice,region) as row
     FROM [BIDW].[dbo].[MonthlyBillingDataAggregate]
     where year=@Year and SalesOffice like 'Office%' 
     )Q where row=1


	INSERT INTO [dbo].[DailyLicenseCountsReporting]

	Select Month, Year, Day, MasterAccountName, ProductName, LicenseCount, LastUpdatedDate, SalesOffice, Region from 
	(	
	select DATEPART(m, @Today) as Month, DATEPART(yyyy, @Today) as Year, DATEPART(d, @Today) as Day,MasterAccountName,
	'X_TRADER® Pro Transaction' as ProductName,Salesoffice,Region,COUNT(distinct AdditionalInfo+MasterAccountName) as LicenseCount,@Today as LastUpdatedDate from
	(
	select distinct AdditionalInfo,AccountId,f.state,f.Country,o.SalesOffice,o.Region from MonthlyBillingDataAggregateLiveTransactions F 
	left join #SalesOfficeMapping O 
	on isnull(nullif(f.state,''),'Unassigned')=o.state and f.Country=o.Country
	where Month=@month and Year=@year
	and Productsku in ('20999') 
	) Q left join Account A
	on Q.AccountId=A.Accountid
	group by MasterAccountName,Salesoffice,Region

	UNION ALL


		select DATEPART(m, @Today) as Month, DATEPART(yyyy, @Today) as Year, DATEPART(d, @Today) as Day,MasterAccountName,
	'X_TRADER® Transaction' as ProductName,Salesoffice,Region,COUNT(distinct AdditionalInfo+MasterAccountName) as LicenseCount,@Today as LastUpdatedDate from
	(
	select distinct AdditionalInfo,AccountId,f.state,f.Country,o.SalesOffice,o.Region from MonthlyBillingDataAggregateLiveTransactions F 
	left join #SalesOfficeMapping O 
	on isnull(nullif(f.state,''),'Unassigned')=o.state and f.Country=o.Country
	where Month=@month and Year=@year
	and Productsku in ('20005') 
	) Q left join Account A
	on Q.AccountId=A.Accountid
	group by MasterAccountName,Salesoffice,Region

	UNION ALL


		select DATEPART(m, @Today) as Month, DATEPART(yyyy, @Today) as Year, DATEPART(d, @Today) as Day,MasterAccountName,
	'X_TRADER® MultiBroker'  as ProductName,Salesoffice,Region,COUNT(distinct AdditionalInfo+MasterAccountName) as LicenseCount,@Today as LastUpdatedDate from
	(
	select distinct AdditionalInfo,AccountId,f.state,f.Country,o.SalesOffice,o.Region from MonthlyBillingDataAggregateLiveTransactions F 
	left join #SalesOfficeMapping O 
	on isnull(nullif(f.state,''),'Unassigned')=o.state and f.Country=o.Country
	where Month=@month and Year=@year
	and Productsku in ('20997','20995','20992','20993')
	) Q left join Account A
	on Q.AccountId=A.Accountid
	group by MasterAccountName,Salesoffice,Region

	UNION ALL

	select DATEPART(m, cast(@Today as date)) as Month, DATEPART(yyyy, cast(@Today as date)) as Year, DATEPART(d, cast(@Today as date)) as Day, MasterAccountName AS LegalName, 
	REPLACE(ProductName,'®', '') AS ProductName,Salesoffice,Region,SUM(licensecount) as LicenseCount,@Today -- <Ram 05/20/2014> Replace count(*) with BillableLicensecount
	from dbo.MonthlyBillingDataAggregate mbd 
	where (mbd.productsku = 20000 or mbd.productsku = 20200)
	and Month=@month and Year=@year
	group by MasterAccountName, ProductName,Salesoffice,Region


	UNION ALL


	select DATEPART(m, cast(getdate() as date)) as Month, DATEPART(yyyy, cast(getdate() as date)) as Year, DATEPART(d, cast(getdate() as date)) as day, MasterAccountName AS LegalName, 
	'TTWEB' AS ProductName,o.Salesoffice,o.Region,SUM(licensecount) as screens,@Today -- <Ram 05/20/2014> Replace count(*) with BillableLicensecount
	from dbo.MonthlyBillingDataAggregate mbd 
	left join #SalesOfficeMapping O 
	on (case when mbd.State='00' or mbd.state='' then 'Unassigned' else mbd.state END)=o.state and mbd.Country=o.Country
	where productsku in (80000,80001,80002,80003,81002,81003,80201,80005,80006,80007) 
	and Month=@month and Year=@year
	group by MasterAccountName, ProductName,o.Salesoffice,o.Region


	UNION ALL



	select DATEPART(m, cast(getdate() as date)) as Month, DATEPART(yyyy, cast(getdate() as date)) as Year, DATEPART(d, cast(getdate() as date)) as day, MasterAccountName AS LegalName, 
	'7x ASP User Access' AS ProductName,o.Salesoffice,o.Region,SUM(licensecount) as screens,@Today -- <Ram 05/20/2014> Replace count(*) with BillableLicensecount
	from dbo.MonthlyBillingDataAggregate mbd 
	left join #SalesOfficeMapping O 
	on (case when mbd.State='00' or mbd.state='' then 'Unassigned' else mbd.state END)=o.state and mbd.Country=o.Country
	where productsku in (20991,20994) 
	and Month=@month and Year=@year
	group by MasterAccountName, ProductName,o.Salesoffice,o.Region
	)Final
	where MasterAccountName is not null

	Drop table #SalesOfficeMapping
	
END
