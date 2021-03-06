USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetLicenseCountsReconAX_FillHub]    Script Date: 1/7/2015 11:04:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetLicenseCountsReconAX_FillHub]
( @Year int, @Month int)
     
AS
BEGIN

 select isnull(x.Year,y.year) as Year, isnull(x.month,y.Month) as Month, isnull(x.AccountId,y.accountid) as AccountId
 ,isnull(x.MasterAccountName,y.masteraccountName) as MasterAccountName,isnull(x.AccountName,y.AccountName) as AccountName,
 isnull(x.DELIVERYNAME,y.DELIVERYNAME) as DeliveryName,isnull(x.UserName,y.TTDESCRIPTION) as UserName, isnull(x.AXCompany,y.AXCompany) as AXCompany,
 isnull(x.CustomerGroup,y.customergroup) as CustomerGroup,isnull(x.MetricName,y.MetricName) as MetricName,isnull(x.ProductName,y.ProductName) as ProductName,isnull(x.Metric,0) as FillHubLicenseCount,
 isnull(y.Metric,0) as AXLicenseCount from
 (
 select Q.YEAR,Q.Month,Q.Accountid,MasterAccountName,AccountName,DELIVERYNAME,UserName,AXCompany,CustomerGroup,
 case when AxProductId in (20999,20997,20993) then '#XTPros'
when AxProductId in (20005,20995,20992,10106)then '#XTs'
end as MetricName,
case when AxProductId in (20999) then 'XTProTransaction'
     when AxProductId in (20997) then 'XTProMBTransaction'
     when AxProductId in (20005) then 'XTTransaction'
     when AxProductId in (20995) then 'XTMBTransaction'
	 when AxProductId in (20993) then 'XTProINtMBTransaction'
	 when AxProductId in (20992) then 'XTINtMBTransaction'
     when AxProductId in (10106) then 'TTTrader' end as ProductName, COUNT(distinct username) as Metric
 from
 (
 select distinct F.YEAR,F.Month,F.Accountid,Username,Axproductid,DELIVERYNAME,AXCompany from Fills F
  left join 
 (select distinct YEAR,Month,Accountid,ProductSku,Deliveryname,DataAreaId as AXCompany,TTDESCRIPTION from BIDW.dbo.MonthlyBillingData 
 where YEAR=@Year and MONTH=@Month and ProductSku in (20005,20999,20997,20995,10106,20992,20993)
 ) M
 on F.Year=M.Year and F.Month=m.Month and F.AccountId=m.AccountId and F.UserName=m.TTDESCRIPTION and F.AxProductId=m.ProductSku
 where F.YEAR=@Year and F.MONTH=@Month
 and Axproductid in (20005,20999,20997,20995,10106,20992,20993)
 and IsBillable='Y'
 and NetworkId not in (577)
 )Q
 left join Account A
 on Q.AccountId=A.Accountid
 where MasterAccountName <>'TradeCo'
 group by Q.YEAR,Q.Month,Q.Accountid,Axproductid,MasterAccountName,AccountName,UserName,CustomerGroup,AXCompany,DELIVERYNAME
 )x
 full outer join 
( 
select YEAR,MONTH,AccountId,MasterAccountName,AccountName,DELIVERYNAME,TTDESCRIPTION,
 AXCompany,CustomerGroup,LicenseName as MetricName,ProductName,sum(LicenseCounts) as Metric from 
 (
select year,month,MasterAccountName,AccountName,M.AccountId,
DataAreaId as AXCompany,
CustGroup as CustomerGroup,deliveryname,ttdescription,
case when productsku in (20999,20997,20993) then '#XTPros'
when productsku in (20005,20995,10106,20992)then '#XTs'
end as LicenseName,case when productsku in (20999) then 'XTProTransaction'
     when productsku in (20997) then 'XTProMBTransaction'
     when productsku in (20005) then 'XTTransaction'
     when productsku in (20995) then 'XTMBTransaction'
	 when productsku in (20993) then 'XTProINtMBTransaction'
	 when productsku in (20992) then 'XTINtMBTransaction'
     when productsku in (10106) then 'TTTrader' end as ProductName,
SUM(BillableLicenseCount) as LicenseCounts
from BIDW.dbo.MonthlyBillingData M join Account A
on M.AccountId=A.Accountid
where ProductSku in (20005,20999,20997,20995,10106,20992,20993)
and YEAR=@Year and MONTH=@Month
and MasterAccountName <>'TradeCo'
group by MasterAccountName,AccountName,M.AccountId,YEAR,MONTH,ProductSku,DataAreaId,CustGroup,DELIVERYNAME,ttdescription
) K
group by YEAR,MONTH,AccountId,MasterAccountName,AccountName,DELIVERYNAME,TTDESCRIPTION,
 AXCompany,CustomerGroup,LicenseName,ProductName
 )y
 on x.Year=y.Year and x.Month=y.Month and x.AccountId=y.AccountId
 and x.UserName=y.TTDESCRIPTION and x.MetricName=y.MetricName and x.ProductName=y.ProductName

End

