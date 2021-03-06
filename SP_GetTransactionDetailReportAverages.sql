USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetTransactionDetailReportAverages]    Script Date: 1/7/2015 11:12:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetTransactionDetailReportAverages]
@RunYear Int = Null,
@RunMonth Int = Null
     
     
AS
BEGIN

Declare @Year int, @Month int
IF @RunMonth is Null and @RunMonth is Null
Begin 
Set @Year=YEAR(getdate()) 
Set @Month=MONTH(getdate())
end
else 
Begin
Set @Year=@RunYear
Set @Month=@RunMonth
End
 
 select Q.YEAR,Q.Month,MasterAccountName,AccountName,Q.AccountId,DeliveryName,UserName,AXCompany,CustomerGroup,
 isnull(case when AxProductId in (20999,20997,20993) then COUNT(distinct username) end,0) as '#XTPro',
isnull(case when AxProductId in (20005,20995,20992,10106)then COUNT(distinct username) end,0) as '#XT',
isnull(case when AxProductId in (20005,20995,20992,10106) then sum(BilledAmount) end,0) as XTBilledAmount,
isnull(case when AxProductId in (20999,20997,20993) then sum(BilledAmount) end,0) as XTProBilledAmount
 from
 (
 select distinct F.YEAR,F.Month,F.Accountid,Username,Axproductid,DELIVERYNAME,AXCompany,BilledAmount from Fills F
  left join 
 (select  YEAR,Month,Accountid,ProductSku,Deliveryname,DataAreaId as AXCompany,TTDESCRIPTION,Billedamount from bidw.dbo.MonthlyBillingData 
 where YEAR=@Year and MONTH=@Month and ProductSku in (20005,20999,20997,20993,20995,20992,10106)
 ) M
 on F.Year=M.Year and F.Month=m.Month and F.AccountId=m.AccountId and F.UserName=m.TTDESCRIPTION and F.AxProductId=m.ProductSku
 where F.YEAR=@Year and F.MONTH=@Month
 and Axproductid in (20005,20999,20997,20993,20995,20992,10106)
 and IsBillable='Y'
 and NetworkId not in (577)
 )Q
 left join Account A
 on Q.AccountId=A.Accountid
 where MasterAccountName <>'TradeCo'
 group by Q.YEAR,Q.Month,Q.Accountid,Axproductid,MasterAccountName,AccountName,UserName,CustomerGroup,AXCompany,DELIVERYNAME
end




