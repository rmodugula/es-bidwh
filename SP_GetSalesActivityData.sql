USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetSalesActivityData]    Script Date: 09/19/2013 16:04:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER Procedure [dbo].[GetSalesActivityData] (@StartDate datetime, @EndDate datetime)
as
Begin 


-- Replace the below section if we need data based on Created and Modified date. Cancellation data will be incorrect when using modified date.


select A.DATAAREAID as AXCompany, A.TTOPERATIONDATE as OperationDate, Branch.BranchName as SalesOffice, Account.AccountName, Product.ProductName
 , A.TTCHANGETYPE , A.DELIVERYNAME as UserName, A.TTDESCRIPTION as IPAddress
 , ISNULL(A.DELIVERYCITY, 'Unassigned') as City
 , ISNULL(A.DELIVERYSTATE, 'Unassigned') as State
 ,  isNULL(A.DELIVERYCOUNTRYREGIONID, 'Unassigned') as Country
 , A.DeliveryZipCode as Zip
 , Case when A.TTChangeType = 'Cancellation' or (A.TTCHANGETYPE = 'Downgrade' and A.TTBILLEND <> '')
       Then -1*(CAST(A.SALESPRICE as numeric(28,2)))
       Else CAST(A.SALESPRICE as numeric(28,2))
   End as BilledAmount
   -- updated 7/19/2013
 , Case when A.TTBillStart <> '' then A.TTBillStart
      ELSE NULL END AS TTBillStart
  , Case when A.TTBillEnd <> '' then A.TTBillEnd
      ELSE NULL END AS TTBillEnd
 
from
chiaxsql01.TT_DYANX09_PRD.dbo.SALESLINE A
left join Product on A.ITEMID = Product.ProductSku
left join Account on A.CUSTACCOUNT = Account.Accountid
left join Branch on  IsNULL(A.DIMENSION3_, 'Unassigned') =  Branch.BranchId

where A.SALESSTATUS = 1 -- 1 corresponds 'Open Order' Line status
and A.CREATEDBY != 'Admin'
and A.ITEMGROUPID != 'RevTelco'

and A.TTOPERATIONDATE between @StartDate and @EndDate  

and A.TTCHANGETYPE != 'MarketChange'

order by Account.AccountName, A.TTOPERATIONDATE, A.TTCHANGETYPE, A.DELIVERYNAME, Product.ProductName
  

End



/*

set @EndDate = DATEADD(d, 1, @EndDate) 


select A.DATAAREAID as AXCompany, A.CREATEDDATETIME as CreatedDate, Branch.BranchName as SalesOffice, Account.AccountName, Product.ProductName
 , A.TTCHANGETYPE , A.DELIVERYNAME as UserName, A.TTDESCRIPTION as IPAddress
 , ISNULL(A.DELIVERYCITY, 'Unassigned') as City
 , ISNULL(A.DELIVERYSTATE, 'Unassigned') as State
 ,  isNULL(A.DELIVERYCOUNTRYREGIONID, 'Unassigned') as Country
 , A.DeliveryZipCode as Zip
 , Case when A.TTChangeType = 'Cancellation' or (A.TTCHANGETYPE = 'Downgrade' and A.TTBILLEND <> '')
       Then -1*(CAST(A.SALESPRICE as numeric(28,2)))
       Else CAST(A.SALESPRICE as numeric(28,2))
   End as BilledAmount
 , A.TTBILLSTART, A.TTBILLEND
 
 
 
from
TT_DYANX09_PRD.dbo.SALESLINE A
left join Product on A.ITEMID = Product.ProductSku
left join Account on A.CUSTACCOUNT = Account.Accountid
left join Branch on  IsNULL(A.DIMENSION3_, 'Unassigned') =  Branch.BranchId

where A.SALESSTATUS = 1 -- 1 corresponds 'Open Order' Line status
and A.CREATEDBY != 'Admin'
and A.ITEMGROUPID != 'RevTelco'

and A.TTCHANGETYPE != 'MarketChange'

and A.TTCHANGETYPE<>'FreeTrial'
and A.TTCHANGETYPE <>'Cancellation'
and (DATEADD(minute, DATEDIFF(minute,getutcdate(),getdate()), A.CREATEDDATETIME)) between @StartDate and @EndDate 
or (
     A.TTCHANGETYPE ='FreeTrial' and A.TTBILLEND='' 
     AND (DATEADD(minute, DATEDIFF(minute,getutcdate(),getdate()), A.CREATEDDATETIME)) between @StartDate and @EndDate
     )
or (
     A.TTCHANGETYPE = 'Cancellation' 
     AND  (DATEADD(minute, DATEDIFF(minute,getutcdate(),getdate()), A.MODIFIEDDATETIME))  between @StartDate and @EndDate
     --AND A.TTBILLEND > A.MODIFIEDDATETIME
    )

 order by Account.AccountName, A.CREATEDDATETIME
  

End 

*/