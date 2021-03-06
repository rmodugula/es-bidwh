USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_ExpenseData_Updates]    Script Date: 8/7/2015 11:06:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Load_ExpenseData_Updates]

  
AS

BEGIN

Create Table #Temp
([ID] [int] NOT NULL, [Year] [int] NOT NULL,[Month] [int] NOT NULL,[FullName] [nvarchar](255) NULL,
[ReportName] [nvarchar](255) NULL,[SentforPaymentDate] [datetime] NULL,[TransactionDate] [datetime] NULL,
[ExpenseCategory] [nvarchar](255) NULL,[ExpenseType] [nvarchar](255) NULL,[Vendor] [nvarchar](255) NULL,
[Purpose] [nvarchar](255) NULL,[City] [nvarchar](255) NULL,[AMEXExpense] [nvarchar](255) NULL,
[MasterAccountName] [nvarchar](255) NULL,[Project] [nvarchar](255) NULL,
[ToLocation] [nvarchar](255) NULL,[HomeOffice] [nvarchar](255) NULL,[NumberofAttendees] [float] NULL,
[Currency] [nvarchar](255) NULL,[ApprovalStatus] [nvarchar](255) NULL,
[CostCenterType] [nvarchar](255) NULL,[Comment] [nvarchar](255) NULL,[Source] [nvarchar](255) NULL, [CrmId] [nvarchar](255) NULL )
  
Insert into #Temp

select Q.*,replace(AccountId,'-','') as CrmId from
(
select ID, Year, Month, FullName, ReportName, cast(SentforPaymentDate as date) as SentforPaymentDate, 
cast(TransactionDate as date) as TransactionDate, nullif(ExpenseCategory,'') as ExpenseCategory, ExpenseType, Vendor, nullif(Purpose,'') as Purpose, City,
nullif(AmexExpense,'') as AmexExpense, nullif(MasterAccountName,'') as MasterAccountName, nullif(Project,'') as Project, nullif(ToLocation,'') as ToLocation, nullif(HomeOffice,'') as HomeOffice, nullif(NumberofAttendees,'') as NumberofAttendees, 
Currency, nullif(ApprovalStatus,'') as ApprovalStatus, CostCenterType,
nullif(Comment,'') as Comment, Source from [BIDW_ODS].dbo.ExpenseData_ods 
where YEAR(sentforpaymentdate)=YEAR(GETDATE()) and MONTH(SentforPaymentDate)=MONTH(GETDATE())
  
Except 
  
select ID, Year, Month, FullName, ReportName, cast(SentforPaymentDate as date) as SentforPaymentDate, 
cast(TransactionDate as date) as TransactionDate, ExpenseCategory, ExpenseType, Vendor, Purpose, City,
AmexExpense, MasterAccountName, Project, ToLocation, HomeOffice, NumberofAttendees, 
Currency, ApprovalStatus, 
case when CostCenter like '6%' Then 'SalesDept' else 'NonSalesDept' end as CostCenterTypCostCenterType,
Comment, Source from [bidw].dbo.ExpenseData 
where YEAR(sentforpaymentdate)=YEAR(GETDATE()) and MONTH(SentforPaymentDate)=MONTH(GETDATE())
)Q
left join CRMOnlineBI.dbo.Account A
on Q.MasterAccountName collate database_default=A.Name collate database_default



Update A
Set A.Project=B.Project,A.ToLocation=B.ToLocation,
A.MasterAccountName=B.MasterAccountName, A.crmid=B.crmid
from chisql12.bidw.dbo.expensedata A
join #Temp B
on A.Id=B.ID

Drop Table #Temp

END