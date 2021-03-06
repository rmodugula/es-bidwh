USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetMarketDataVRXMLforCME_ByUser]    Script Date: 2/18/2015 1:34:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetMarketDataVRXMLforCME_ByUser]
@RunYear int =null, @RunMonth Int=null, @RunDay Int=null
     
AS

Declare @Year int, @Month int,@Day int, @inventoryEntry int, @subscriberNewEntry int, @vendorEntry int , @subscriberChangeEntry int 
IF @RunYear is Null and @RunMonth is Null and @RunDay is Null
Begin 
set @Year = Year(getdate())
set @Month = Month(getdate())
set @Day=day(getdate())
end
else 
Begin
Set @Year=@RunYear
Set @Month=@RunMonth
Set @Day=@RunDay
End


Set @inventoryEntry =   (select count(distinct username) FROM [BIDW_ODS].[dbo].[MarketDataUserEntitlements_ODS] where ExchangeId=7
                        and year=@Year and month=@Month and day=@Day and NetworkId in ('MB_ASP','TNT'))
						+
						(select count(distinct username) FROM [BIDW_ODS].[dbo].[MarketData7xEntitlements_ODS] where ExchangeId=7
                         and year=@Year and month=@Month and day=@Day and Networkshortname in ('TrdCoFM7'))
Set @subscriberNewEntry = (select count(distinct username) FROM [BIDW_ODS].[dbo].[MarketDataUserEntitlements_ODS] where ExchangeId=7
                        and year=@Year and month=@Month and day=@Day and NetworkId in ('MB_ASP','TNT'))
						+
						(select count(distinct username) FROM [BIDW_ODS].[dbo].[MarketData7xEntitlements_ODS] where ExchangeId=7
                         and year=@Year and month=@Month and day=@Day and Networkshortname in ('TrdCoFM7'))

Set @vendorEntry =   0
Set @subscriberChangeEntry =   0


Begin

;WITH XMLNAMESPACES 
(
'http://www.cmegroup.com/market-data/distributor/vrxml/X11/VRXML.xsd' as xsd,
'http://www.cmegroup.com/market-data/distributor/vrxml/1.1' as tns,
'http://www.cmegroup.com/market-data/distributor/vrxml/1.1 ' as xsi
)
SELECT
(
SELECT XmlData as [*] from
(
SELECT(

SELECT 89234 as '@tns:vendorId',
	 Getdate() as 'tns:dateFileCreated',
	 (
	 SELECT
	 'inventoryEntry' as 'tns:entryMetaData/@tns:entry',
	  @inventoryEntry as 'tns:entryMetaData/tns:count' 
	  for Xml path (''),Type),
	  (
	 SELECT
	 'subscriberNewEntry' as 'tns:entryMetaData/@tns:entry',
	 @subscriberNewEntry as 'tns:entryMetaData/tns:count' 
	 for Xml path (''),Type),
       (
	 SELECT
	 'vendorEntry' as 'tns:entryMetaData/@tns:entry',
	 @vendorEntry as 'tns:entryMetaData/tns:count' 
	 for Xml path (''),Type),
	   (
	 SELECT
	 'subscriberChangeEntry' as 'tns:entryMetaData/@tns:entry',
	 @subscriberChangeEntry as 'tns:entryMetaData/tns:count' 
	 for Xml path (''),Type)
	 for xml path ('tns:fileDescriptor'),type
	 )
union all
SELECT
(
SELECT Distinct
      isnull(BillingAccountId,'-') as '@tns:VAN',
	 --UserName as 'tns:username',
	 'ADD' as 'tns:product/@tns:actionCode',
	 'EXG' as 'tns:product/tns:productCode/@tns:codeOwner',
	 isnull(ExchangeProvidedCode,'-') as 'tns:product/tns:productCode/@tns:code',
	 cast(Getdate() as date) as 'tns:product/tns:inventory/tns:effectiveDate',
	 1 as 'tns:product/tns:inventory/tns:quantity'
	 --,cast(Getdate() as date) as 'tns:product/tns:effectiveDate'
	 FROM [BIDW_ODS].[dbo].[MarketDataUserEntitlements_ODS] Market
	  left join [fillhub].[dbo].[BillingAccountCompanyMap] BA
      on Market.CompanyId=BA.CompanyId
	 where year=@Year and month=@Month and Day=@Day and exchangeid=7 
	 and ExchangeProvidedCode is not null 
	 and ExchangeProvidedCode<>'<None>'
	 and NetworkId in ('MB_ASP','TNT','TTWEB')
	 and Market.companyname<>'' and market.companyname is not null and BillingAccountId is not null
	 FOR XML Path ('tns:inventoryEntry'),type
	)	


union all
SELECT
(

	SELECT Distinct
     CompanyName as 'tns:company/tns:name1',
     CompanyName as 'tns:company/tns:name2',
      AccountId as 'tns:locationNew/@tns:VAN',
     isnull(nullif(Address,''),'-') as 'tns:locationNew/tns:locals/tns:address/tns:address1',
     --'B' as 'tns:locationNew/tns:locals/tns:address/tns:address2',
     --'C' as 'tns:locationNew/tns:locals/tns:address/tns:address3',
     rtrim(isnull(nullif(City,'<None>'),'-')) as 'tns:locationNew/tns:locals/tns:address/tns:city',
     rtrim(isnull(nullif([State],'<None>'),'-')) as 'tns:locationNew/tns:locals/tns:address/tns:stateProvince',
     rtrim(isnull(nullif(PostalCode,'<None>'),'-')) as 'tns:locationNew/tns:locals/tns:address/tns:postalCode',
     rtrim(isnull(nullif(Country,'<None>'),'-')) as 'tns:locationNew/tns:locals/tns:address/tns:country',
     CompanyName as 'tns:locationNew/tns:locals/tns:company/tns:name1',
     CompanyName as 'tns:locationNew/tns:locals/tns:company/tns:name2',
     AccountId as 'tns:locationNew/tns:inventoryEntry/@tns:VAN',
	 'ADD' as 'tns:locationNew/tns:inventoryEntry/tns:product/@tns:actionCode',
	 'EXG' as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:productCode/@tns:codeOwner',
	 'CMDDSV' as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:productCode/@tns:code',
	 cast(Getdate() as date) as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:inventory/tns:effectiveDate',
	 1 as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:inventory/tns:quantity'
	 --,cast(Getdate() as date) as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:effectiveDate'
     FROM 
	 (
SELECT  Distinct Name as CompanyName,isnull(n.AccountId,'C100174') as AccountId,c.Address,c.City,c.State,zipcode as PostalCode,Country  from 
(Select distinct year,month,Day,exchangeid,networkshortname from [BIDW_ODS].[dbo].[MarketData7XEntitlements_ODS]) M
left join Network N
on m.NetworkshortName=n.NetworkShortName
 left join (select accountnum,Name,Street as address,city,[state],zipcode,countryregionid as Country from chiaxsql01.TT_DYANX09_PRD.dbo.CUSTTABLE) C
on isnull(n.AccountId,'C100174')=c.accountnum
 where year=@Year and month=@Month and day=@Day
and m.NetworkShortName not in ('MB_ASP','TNT')
and exchangeid=7

)Q
	
FOR XML Path ('tns:subscriberNewEntry'),type
)


union all
SELECT
(

	SELECT Distinct
     FirstName as 'tns:company/tns:name1',
     LastName as 'tns:company/tns:name2',
      isnull(BillingAccountId,'-') as 'tns:locationNew/@tns:VAN',
     isnull(nullif(StreetAddress,''),'-') as 'tns:locationNew/tns:locals/tns:address/tns:address1',
     --'B' as 'tns:locationNew/tns:locals/tns:address/tns:address2',
     --'C' as 'tns:locationNew/tns:locals/tns:address/tns:address3',
     rtrim(isnull(nullif(City,'<None>'),'-')) as 'tns:locationNew/tns:locals/tns:address/tns:city',
     rtrim(isnull(nullif([State],'<None>'),'-')) as 'tns:locationNew/tns:locals/tns:address/tns:stateProvince',
     rtrim(isnull(nullif(PostalCode,'<None>'),'-')) as 'tns:locationNew/tns:locals/tns:address/tns:postalCode',
     rtrim(isnull(nullif(Country,'<None>'),'-')) as 'tns:locationNew/tns:locals/tns:address/tns:country',
     FirstName as 'tns:locationNew/tns:locals/tns:company/tns:name1',
     LastName as 'tns:locationNew/tns:locals/tns:company/tns:name2',
     isnull(BillingAccountId,'-') as 'tns:locationNew/tns:inventoryEntry/@tns:VAN',
	 'ADD' as 'tns:locationNew/tns:inventoryEntry/tns:product/@tns:actionCode',
	 'EXG' as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:productCode/@tns:codeOwner',
	 isnull(ExchangeProvidedCode,'-') as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:productCode/@tns:code',
	 cast(Getdate() as date) as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:inventory/tns:effectiveDate',
	 1 as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:inventory/tns:quantity'
	 --,cast(Getdate() as date) as 'tns:locationNew/tns:inventoryEntry/tns:product/tns:effectiveDate'
     FROM bidw_ods.dbo.MarketDataUserEntitlements_ODS Market
	 left join [fillhub].[dbo].[BillingAccountCompanyMap] BA
      on Market.CompanyId=BA.CompanyId
     where year=@Year and month=@Month and Day=@Day and exchangeid=7 
	 and NetworkId in ('MB_ASP','TNT')
	 and ExchangeProvidedCode is not null 
	 and ExchangeProvidedCode<>'<None>'
	FOR XML Path ('tns:subscriberNewEntry'),type
	)
union all

SELECT
(	
	SELECT 
    'companyA' as '@tns:refVAN',
    'companyA' as 'tns:locationChange/@tns:VAN',
    'A' as 'tns:locationChange/tns:locals/tns:address/tns:address1',
     'B' as 'tns:locationChange/tns:locals/tns:address/tns:address2',
     'C' as 'tns:locationChange/tns:locals/tns:address/tns:address3',
     'D' as 'tns:locationChange/tns:locals/tns:address/tns:city',
     'E' as 'tns:locationChange/tns:locals/tns:address/tns:stateProvince',
     0 as 'tns:locationChange/tns:locals/tns:address/tns:postalCode',
     'US' as 'tns:locationChange/tns:locals/tns:address/tns:country'
     FROM bidw_ods.dbo.MarketDataUserEntitlements_ODS Market
    where year=@Year and month=@Month and Day=@Day and exchangeid=7 and NetworkId in ('MB_ASP','TNT')
	 and ExchangeProvidedCode is not null 
	 and ExchangeProvidedCode<>'<None>'
	and 1=0
	FOR XML Path ('tns:subscriberChangeEntry'),type
	) 
) as data(XmlData)

FOR XML Path (''), ROOT ('tns:vrxml'),type
) as FinalXml











end





