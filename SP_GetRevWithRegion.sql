USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetRevWithRegion]    Script Date: 09/19/2013 16:03:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- exec  GetRevWithRegion 7,2009 


ALTER PROCEDURE [dbo].[GetRevWithRegion] 
	-- Add the parameters for the stored procedure here
	@inputMonth int, -- = DatePart(month,GetDate()), 
	@inputYear int -- = DatePart(year,GetDate()), 
AS
BEGIN
	SET NOCOUNT ON;
declare @2MonthsAgoMonth int
declare @2MonthsAgoYear int
declare @4MonthsAgoMonth int
declare @4MonthsAgoYear int
select @2MonthsAgoMonth  =	case when ((@inputMonth - 2) < 1) then   12 + (@inputMonth - 2) 
								 else  @inputMonth - 2
							end    
select @2MonthsAgoYear   =	case when ((@inputMonth - 2) < 1) then  @inputYear - 1
								 else  @inputYear
							end    
select @4MonthsAgoMonth  =	case when ((@inputMonth - 4) < 1) then   12 + (@inputMonth - 4) 
								 else  @inputMonth - 4
							end    
select @4MonthsAgoYear   =	case when ((@inputMonth - 4) < 1) then  @inputYear - 1
								 else  @inputYear
							end    
print @2MonthsAgoYear
print @2MonthsAgoMonth
print @4MonthsAgoYear
print @4MonthsAgoMonth
select
      DataAreaId as AXCompany 	  
	  ,case when ([CustGroup] in ('Trnx SW','MultiBrokr')) then [AccountName]+ '(TX)' else [AccountName] end as AccountNameWithSource
	  ,case when ([CustGroup] in ('Trnx SW','MultiBrokr')) then '(TX)'+ [AccountName] else [AccountName] end as SourceWithAccountName
	  --,case when [source]= 1 then [AccountName]+ '(TX)' when [source]= 0 and [AccountName] = 'Newedge Financial, Inc.' then [AccountName]+ '(TX)' else [AccountName] end as AccountNameWithSource
	  --,case when [source]= 1 then '(TX)'+ [AccountName] when [source]= 0 and [AccountName] = 'Newedge Financial, Inc.' then '(TX)'+ [AccountName] else [AccountName] end as SourceWithAccountName
      ,[AccountName]
      ,[ProductName]
      ,[ProductCategoryName]
      ,[BilledAmount]
      ,rev.[BilledAmount] - rev.[BilledAmount2] as [BilledAmountDelta]
      ,[BilledAmount2]
      ,rev.[BilledAmount2] - rev.[BilledAmount4] as [BilledAmount2Delta]
      ,[BilledAmount4]
      ,rev.[Region] 
	  ,rev.[Country]
      ,rev.[State]
	  --,isnull(reg.SalesRegion,'Unmapped') as SalesRegion --case when [Country]= 'UNITED STATES' then [State] else [Country] end as CountryState
	  --,isnull(reg.SalesOffice,'Unmapped') as SalesOffice
	  ,isnull(rev.SalesOffice,'Unmapped') as SalesOffice
      ,rev.city
      ,AdditionalInfo
      ,[LicenseCount]
      ,[NGW]
      ,[NFA]
      ,[NTT]
      ,[NXT]
      ,[NXT Pro]
      , CustGroup as CustomerGroup, MasterAccountName
      , ActiveBillableToday, ActiveNonBillableToday
from (
		select			  
			   [AccountName]
			  ,[ProductName]
			  ,[ProductCategoryName]
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then isnull([BilledAmount],0) end,0))  AS [BilledAmount]
			  ,sum(isnull(case when (Month = @2MonthsAgoMonth and Year = @2MonthsAgoYear) then isnull([BilledAmount],0) end,0))  AS [BilledAmount2]
			  ,sum(isnull(case when (Month = @4MonthsAgoMonth and Year = @4MonthsAgoYear) then isnull([BilledAmount],0) end,0)) AS [BilledAmount4]
			  ,[Region]
			  ,[Country]
			  ,[State]
			  ,City
			  ,AdditionalInfo
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear) then isnull([LicenseCount],0) end,0))  AS [LicenseCount]
			  --,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear and ProductCategoryName in ('Gateway Products')) then isnull([LicenseCount],0) end,0))  AS [NGW]
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear and ProductCategoryName in ('Gateways')) then isnull([LicenseCount],0) end,0))  AS [NGW]
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear and ProductName in ('FIX Adapter','Fix Adapter Transaction')) then isnull([LicenseCount],0) end,0))  AS [NFA]
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear and ProductName in ('TT_TRADER®')) then isnull([LicenseCount],0) end,0))  AS [NTT]
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear and ProductName in ('X_TRADER®')) then isnull([LicenseCount],0) end,0))  AS [NXT]
			  ,sum(isnull(case when ([Month] = @inputMonth and [Year] = @inputYear and ProductName in ('X_TRADER® Pro','X_TRADER® Pro Transaction','X_TRADER® Transaction')) then isnull([LicenseCount],0) end,0))  AS [NXT Pro] -- <Ram:06/28/2013> Added the X_TRADER® Transaction Productname in the case statement
              ,CustGroup , Branch as SalesOffice, DataAreaId , MasterAccountName
              , ActiveBillableToday, ActiveNonBillableToday
		from MonthlyBillingDataAggregate
		where	
				-- jg 6 mar 2012 --remove below to allow adustments to enter reports
				-- jg 6 mar 2012 later try again --change below back to allow adustments to enter reports but not 0 based transactions
				--((isnull([BilledAmount],0) <> 0 and [source]=0) or [source]=1)
				( (isnull([LicenseCount],0) != 0)  or  isnull([NonBillableLicenseCount],0) >0  or ISNULL(BilledAmount, 0) >0  )
				and	
				((Month = @inputMonth and Year = @inputYear)
				or (Month = @2MonthsAgoMonth and Year = @2MonthsAgoYear)
				or (Month = @4MonthsAgoMonth and Year = @4MonthsAgoYear))
		group by 			  
			  [AccountName]
			  ,[ProductName]
			  ,[ProductCategoryName]
			  ,[Region]
			  ,[Country]
			  ,[State]
			  ,City
			  ,AdditionalInfo
			  , CustGroup, Branch, DataAreaId, MasterAccountName
			  , ActiveBillableToday, ActiveNonBillableToday
		) rev
		--inner join dbo.RegionMap reg on rev.Country = reg.Country and rev.State = reg.State
		--left join dbo.RegionMap reg on rev.Country = reg.Country and isnull(rev.State,'') = isnull(reg.State,'')
END


