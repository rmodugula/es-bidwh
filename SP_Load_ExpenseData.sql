USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_Load_ExpenseData_test]    Script Date: 8/23/2016 1:56:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Load_ExpenseData]
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

Declare @PriorYear Int, @PriorMonth Int
Set @PriorYear = Case when @Month=1 then @Year-1 else @Year end
Set @PriorMonth = Case when @Month=1 then 12 else @Month-1 end

Create Table #ConcurExpense
([Year] [int] NOT NULL,	[Month] [int] NOT NULL,[StaffId] [nvarchar](255) NULL,[FullName] [nvarchar](255) NULL,[City] [nvarchar](255) NULL,[CrmId] [nvarchar](255) NULL,[MasterAccountName] [nvarchar](255) NULL,
[ReportName] [nvarchar](255) NULL,[ExpenseType] [nvarchar](255) NULL,[Vendor] [nvarchar](255) NULL,[Project] [nvarchar](255) NULL,[Purpose] [nvarchar](255) NULL,[CostCenter] [nvarchar](255) NULL,
[CostCenterName] [nvarchar](255) NULL,[ApprovalStatus] [nvarchar](255) NULL,[Currency] [nvarchar](255) NULL,[ApprovedAmount] [float] NULL,[FromLocation] [nvarchar](255) NULL,
[ToLocation] [nvarchar](255) NULL,[TransactionDate] [datetime] NULL,[SentforPaymentDate] [datetime] NULL,[NumberofAttendees] [float] NULL,[CostPerAttendee] [float] NULL,
[AMEXExpense] [nvarchar](255) NULL,[CommenterName] [nvarchar](255) NULL,[Comment] [nvarchar](255) NULL,[CommentDate] [datetime] NULL,[ExpenseCategory] [nvarchar](255) NULL,
[HomeOffice] [nvarchar](255) NULL,[CommentFor] [nvarchar](255) NULL,[EmployeeCountryCode] [nvarchar](255) NULL,[EntryApprovedAmount] [float] NULL,[Location] [nvarchar](255) NULL,
[Company] [nvarchar](255) NULL,[AccountCode] [nvarchar](255) NULL,[EmployeeCostCenter] [nvarchar](255) NULL,[ExpenseAmountReimbursement] [float] NULL,[CountryofEmployee] [nvarchar](255) NULL,
[Department] [nvarchar](50) NULL,[Source] [nvarchar](50) NULL,[ClientList1] [nvarchar](255) NULL,[ClientList2] [nvarchar](255) NULL,[PrimaryPurposeofTrip] [nvarchar](255) NULL,
[PurposeofTrip_SubPicklist][nvarchar](255) NULL,ReportExpenseKey [nvarchar](255) NULL,Posteddatetime datetime NULL,[LastUpdatedDate] [datetime] NULL)
  
Insert into #ConcurExpense
----------------------Loading Records having CrmId's <Ram 01/29/2014 12:00 PM>----------------------------------------------------------------------------------------------
select Year, Month, replace(E.employeeid,'-B','') as StaffId, Employee as FullName, E.City, clientid as CrmId, client as MasterAccountName, ReportName, ExpenseType, 
Vendor, Project, Purpose, E.CostCenter, CostCenterName, ApprovalStatus, Currency, ApprovedAmount, 
FromLocation, ToLocation, TransactionDate, SentforPaymentDate, NumberofAttendees, 
CostPerAttendee, AMEXExpense, CommenterName, Comment, CommentDate, rtrim(ltrim(substring(ExpenseCategory,CHARINDEX('.',ExpenseCategory)+1,100))) as ExpenseCategory, S.City as HomeOffice, CommentFor,
 EmployeeCountryCode, EntryApprovedAmount, Location, E.Company, AccountCode, EmployeeCostCenter, ExpenseAmountReimbursement,
  CountryofEmployee,'' as Department,'Concur' as Source, ClientList1,ClientList2,PrimaryPurposeofTrip,PurposeofTrip_SubPicklist,ReportExpenseKey,null as Posteddatetime, GETDATE() as LastUpdatedDate
from chisql12.bidw_ods.dbo.ConcurExpense E
left join Staff S
on replace(E.employeeid,'-B','')=S.StaffId
where YEAR(SentforPaymentDate)=@Year and Month(Sentforpaymentdate)=@Month and len(clientid)>10
--and Month=@Month 
----------------------Loading Records without CrmId's and not having CRM links as Comments------------------------------------------------------------------------------------
union all
select Year, Month, replace(replace(E.employeeid,'-B',''),'M','') as StaffId, Employee as FullName, E.City, case when clientid in (0,'other','N/A') then null else clientid end as CrmId, client as MasterAccountName, ReportName, ExpenseType, 
Vendor, Project, Purpose, E.CostCenter, CostCenterName, ApprovalStatus, Currency, ApprovedAmount, 
FromLocation, ToLocation, TransactionDate, SentforPaymentDate, NumberofAttendees, 
CostPerAttendee, AMEXExpense, CommenterName, Comment, CommentDate, rtrim(ltrim(substring(ExpenseCategory,CHARINDEX('.',ExpenseCategory)+1,100))) as ExpenseCategory, S.City as HomeOffice, CommentFor,
 EmployeeCountryCode, EntryApprovedAmount, Location, E.Company, AccountCode, EmployeeCostCenter, ExpenseAmountReimbursement,
  CountryofEmployee,'' as Department,'Concur' as Source,ClientList1,ClientList2,PrimaryPurposeofTrip,PurposeofTrip_SubPicklist,ReportExpenseKey,null as Posteddatetime,GETDATE() as LastUpdatedDate
from chisql12.bidw_ods.dbo.ConcurExpense E
left join Staff S
on replace(E.employeeid,'-B','')=S.StaffId
where YEAR(SentforPaymentDate)=@Year and Month(SentforPaymentDate)=@Month and len(clientid)<10 and (comment not like '%http://crm%' or comment is null)
--and Month=@Month
----------------------Loading Records without CrmId's and having CRM links as Comments and auto-mapping CrmId's using AppointmentId from CRM Prod --------------------------------------
union all
select Year, Month, StaffId, FullName,City,case when CRMid in(0,'other') then cast(RegardingObjectId as varchar(100)) else isnull(CrmId,RegardingObjectId) end as CrmId,
isnull(MasterAccountName,RegardingObjectIdName) as MasterAccountName,ReportName,ExpenseType,Vendor,Project,Purpose,CostCenter, CostCenterName, ApprovalStatus, Currency,
 ApprovedAmount,FromLocation, ToLocation,TransactionDate,SentforPaymentDate, NumberofAttendees, CostPerAttendee, AMEXExpense, CommenterName,
Comment, CommentDate,rtrim(ltrim(substring(ExpenseCategory,CHARINDEX('.',ExpenseCategory)+1,100))) as ExpenseCategory,SalesOffice as HomeOffice, CommentFor, EmployeeCountryCode, EntryApprovedAmount, Location, Company,
  AccountCode, EmployeeCostCenter, ExpenseAmountReimbursement, CountryofEmployee,'' as Department,'Concur' as Source,ClientList1,ClientList2,PrimaryPurposeofTrip,PurposeofTrip_SubPicklist,ReportExpenseKey,null as Posteddatetime,GETDATE() as LastUpdatedDate
from
(
select *,case when StartLength>0 then  
upper(rtrim(ltrim(replace(replace(replace(replace(substring(comment,StartLength,commentlength),'id=%7b',''),'>',''),'%7d',''),'id=','')))) 
else '00000000-0000-0000-0000-000000000000' end AS JoinId
--case when StartLength>0 then 
--case when substring(comment,StartLength,commentlength) like 'id={%' then substring(substring(comment,StartLength,commentlength),5,36)
--      when substring(comment,StartLength,commentlength) like 'id=%'  then substring(substring(comment,StartLength,commentlength),4,36)
--      else  substring(substring(comment,StartLength,commentlength),7,36) end
--else '00000000-0000-0000-0000-000000000000' end as JoinId
from
(
select Year, Month, replace(E.employeeid,'-B','') as StaffId, employee as FullName,E.City,
case when len(clientid)>20 then stuff(stuff(stuff(STUFF(replace(clientid,'-',''),9,0,'-'),14,0,'-'),19,0,'-'),24,0,'-') else clientid end as CrmId,
client as MasterAccountName, ReportName,ExpenseType,Vendor,Project,Purpose,E.CostCenter, CostCenterName, ApprovalStatus, Currency, ApprovedAmount,
FromLocation, ToLocation,TransactionDate,SentforPaymentDate, NumberofAttendees, CostPerAttendee, AMEXExpense, CommenterName,
Comment, CommentDate, charindex('id=',comment) as StartLength,len(comment) as CommentLength,ExpenseCategory, CommentFor, 
EmployeeCountryCode, EntryApprovedAmount, Location, E.Company,
  AccountCode, EmployeeCostCenter, ExpenseAmountReimbursement, CountryofEmployee, S.City as SalesOffice,ClientList1,ClientList2,PrimaryPurposeofTrip,PurposeofTrip_SubPicklist,ReportExpenseKey
from chisql12.bidw_ods.dbo.ConcurExpense E
left join Staff S
on replace(E.employeeid,'-B','')=S.StaffId
where YEAR(SentforPaymentDate)=@Year and Month(Sentforpaymentdate)=@Month
--and Month=@Month
and LEN(clientid)<10
and comment like '%http://crm%'
)Q
--where StartLength>0
) A
Left outer Join 
(
select distinct ActivityId,RegardingObjectId,RegardingObjectIdName from CRMOnlineBI.dbo.Appointment
--select ActivityId,RegardingObjectId,RegardingObjectIdName from chicrmsql01.Trading_Technologies_MSCRM.dbo.Appointment
--where ActivityId='9FD11795-4E8F-E311-9ED1-005056BE005E'
)B
on A.JoinId=B.ActivityId

------------------------------------------------------Load Prior Month 5280 Expenses Data from AX--------------------------------------------------------------------
Create Table #5280ExpensePriorMonth
([Year] [int] NOT NULL,[Month] [int] NOT NULL,[StaffId] [nvarchar](255) NULL,[FullName] [nvarchar](255) NULL,[City] [nvarchar](255) NULL,[CrmId] [nvarchar](255) NULL,[MasterAccountName] [nvarchar](255) NULL,
	[ReportName] [nvarchar](255) NULL,[ExpenseType] [nvarchar](255) NULL,[Vendor] [nvarchar](255) NULL,[Project] [nvarchar](255) NULL,[Purpose] [nvarchar](255) NULL,[CostCenter] [nvarchar](255) NULL,
	[CostCenterName] [nvarchar](255) NULL,[ApprovalStatus] [nvarchar](255) NULL,[Currency] [nvarchar](255) NULL,[ApprovedAmount] [float] NULL,[FromLocation] [nvarchar](255) NULL,
	[ToLocation] [nvarchar](255) NULL,[TransactionDate] [datetime] NULL,[SentforPaymentDate] [datetime] NULL,[NumberofAttendees] [float] NULL,[CostPerAttendee] [float] NULL,
	[AMEXExpense] [nvarchar](255) NULL,[CommenterName] [nvarchar](255) NULL,[Comment] [nvarchar](255) NULL,[CommentDate] [datetime] NULL,[ExpenseCategory] [nvarchar](255) NULL,
	[HomeOffice] [nvarchar](255) NULL,[CommentFor] [nvarchar](255) NULL,[EmployeeCountryCode] [nvarchar](255) NULL,[EntryApprovedAmount] [float] NULL,[Location] [nvarchar](255) NULL,
	[Company] [nvarchar](255) NULL,[AccountCode] [nvarchar](255) NULL,[EmployeeCostCenter] [nvarchar](255) NULL,[ExpenseAmountReimbursement] [float] NULL,[CountryofEmployee] [nvarchar](255) NULL,
	[Department] [nvarchar](50) NULL,[Source] [nvarchar](50) NULL,[ClientList1] [nvarchar](255) NULL,[ClientList2] [nvarchar](255) NULL,[PrimaryPurposeofTrip] [nvarchar](255) NULL,
[PurposeofTrip_SubPicklist][nvarchar](255) NULL,ReportExpenseKey [nvarchar](255) NULL,Posteddatetime datetime NULL,[LastUpdatedDate] [datetime] NULL)
	
Insert Into #5280ExpensePriorMonth
select  YEAR(x.TransactionDate) as Year, MONTH(x.TransactionDate) as Month,Null as StaffId,X.Employee as FullName,x.Location as City,Null as CrmId,Null as MasterAccountName,
y.ReportName,x.AccountName as ExpenseType,y.accountNameAlias as Vendor,Null as Project,x.Purpose,CostCenter,case when CostCenterName='Sales  Buyside' then 'Sales Buyside' else CostCenterName end as CostCenterName,Null as ApprovalStatus,
x.Currency,round(cast(x.ApprovedAmount as float),2) as ApprovedAmount,Null as FromLocation,Null as ToLocation,x.TransactionDate,x.SubmitDate as SentForPaymentDate,NUll as NumberOfAttendees,
Null as CostPerAttendee,NUll as AmexExpense,Null as CommenterName,Null as Comment,Null as CommentDate,Null as ExpenseCategory, Null as HomeOffice, Null as CommentFor,
Null as EmployeeCountryCode, Null as EntryApprovedAmount,x.Location,NUll as Company, x.AccountNum as AccountCode, Null as EmployeeCostCenter, Null as ExpenseAmountReimbursement,
Null as CountryofEmployee, x.Department,'5280' as Source,null as ClientList1,null as ClientList2,null as PrimaryPurposeofTrip,null as PurposeofTrip_SubPicklist,null as ReportExpenseKey,x.TransactionDate as Posteddatetime,GETDATE() as LastUpdatedDate from
(
select Employee,SubmitDate,TransactionDate,AccountName,Purpose,Currency,ApprovedAmount,ReportName,'' as JournalName,AccountNum,q2.Dataareaid,Voucher,
Department,CostCenter,CostCenterName,d2.Description as Location
from
(
select Employee,SubmitDate,TransactionDate,AccountName,Purpose,Currency,ApprovedAmount,ReportName,'' as JournalName,AccountNum,q1.Dataareaid,Voucher,
Department, Q1.CostCode as CostCenter,d1.Description as CostCenterName,LocationCode 
from
(
select Employee,SubmitDate,TransactionDate,AccountName,Purpose,Currency,ApprovedAmount,ReportName,'' as JournalName,AccountNum,q.Dataareaid,Voucher,
d.Description as Department, CostCode,LocationCode from
(
select YEAR(transdate) as Year, MONTH(transdate) as Month,Null as StaffId,lt.voucher as Employee,'' as City,Null as CrmId,Null as MasterAccountName,
'' as ReportName,AccountName as ExpenseType,accountNameAlias as Vendor,Null as Project,txt as Purpose,lt.dimension, lt.dimension2_ as CostCode, lt.dimension3_ as LocationCode,Null as ApprovalStatus,
lt.CurrencyCode as Currency,round(cast(amountmstsecond as float),2) as ApprovedAmount,Null as FromLocation,Null as ToLocation,transdate as TransactionDate,posteddatetime as SubmitDate,NUll as NumberOfAttendees,
Null as CostPerAttendee,NUll as AmexExpense,Null as CommenterName,Null as Comment,Null as CommentDate,Null as ExpenseCategory, Null as HomeOffice, Null as CommentFor,
Null as EmployeeCountryCode, Null as EntryApprovedAmount,'' as Location,NUll as Company, Null as AccountCode, Null as EmployeeCostCenter, Null as ExpenseAmountReimbursement,
Null as CountryofEmployee, '5280' as Source,GETDATE() as LastUpdatedDate, lt.dataareaid,AccountName,lt.AccountNum,Voucher
from chiaxsql01.TT_DYANX09_PRD.dbo.LEDGERTRANS LT
left join (select AccountNum,AccountName,AccountNamealias, dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.ledgertable) L
on lt.accountnum=l.accountnum and lt.dataareaid=L.dataareaid
left join chiaxsql01.TT_DYANX09_PRD.dbo.LedgerJournalTable ljt
on lt.JournalNum=ljt.JournalNum and lt.dataareaid=ljt.dataareaid
where year(transdate) =@PriorYear and Month(transdate)=@PriorMonth
)Q left join (select distinct description,num,dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.dimensions where dimensioncode=0) D
on q.dimension=d.num and q.dataareaid=d.dataareaid
)Q1 left join (select distinct description,num,dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.dimensions) D1
on q1.CostCode=d1.num and q1.dataareaid=d1.dataareaid
)Q2 left join (select distinct description,num,dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.dimensions where dimensioncode<>0) D2
on q2.LocationCode=d2.num and q2.dataareaid=d2.dataareaid
)x
left join 
(
select  distinct jt.voucher as Employee,posteddatetime as SubmitDate,transdate as TransactionDate,txt as Purpose,'USD' as Currency, 
case when jt.CURRENCYCODE='USD' then AMOUNTCURCREDIT else (case when (dbo.fnGetExchangeRt(jt.dataareaid,DocumentDate,'USD')) is null then 100/jt.Exchrate else (dbo.fnGetExchangeRt(jt.dataareaid,DocumentDate,'USD')) end)*AMOUNTCURCREDIT end as ApprovedAmount,
case when jt.CURRENCYCODE='USD' then AMOUNTCURCREDIT else (case when (dbo.fnGetExchangeRt(jt.dataareaid,DocumentDate,'USD')) is null then 100/jt.Exchrate else (dbo.fnGetExchangeRt(jt.dataareaid,DocumentDate,'USD')) end) *AMOUNTCURDEBIT end as ApprovedAmountD
,Invoice as ReportName, 
JOURNALNAME,JT.ACCOUNTNUM,jt.dataareaid,jt.dimension as DeptCode,jt.dimension2_ as CostCode,jt.dimension3_ as LocationCode,voucher,isnull(v.AccountName,v.Accountnamealias) as AccountName,v.Accountnamealias
from chiaxsql01.TT_DYANX09_PRD.dbo.LedgerJournalTable J join chiaxsql01.TT_DYANX09_PRD.dbo.LEDGERJOURNALTRANS JT 
on JT.JOURNALNUM = J.JOURNALNUM and jt.dataareaid=j.dataareaid join (select AccountNum,AccountName,AccountNamealias, dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.ledgertable
union
select  AccountNum,Name,Namealias, dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.VENDTABLE
where vendgroup not in ('EMP')) V 
on V.ACCOUNTNUM=JT.ACCOUNTNUM and v.dataareaid=jt.dataareaid
where 
J.JOURNALNAME in ('5280') and 
year(transdate) =@PriorYear and Month(transdate)=@PriorMonth
--and jt.JOURNALNUM in ('GLNb002191')  
and jt.accountnum like 'V%'
)Y
on x.Employee=y.Employee and x.SubmitDate=y.SubmitDate and x.TransactionDate=y.TransactionDate and x.voucher=y.voucher and x.dataareaid=y.dataareaid


------------------------------------------------------Load Current Month 5280 Expenses Data from AX--------------------------------------------------------------------
Create Table #5280ExpenseCurrentMonth
([Year] [int] NOT NULL,[Month] [int] NOT NULL,[StaffId] [nvarchar](255) NULL,[FullName] [nvarchar](255) NULL,[City] [nvarchar](255) NULL,[CrmId] [nvarchar](255) NULL,[MasterAccountName] [nvarchar](255) NULL,
	[ReportName] [nvarchar](255) NULL,[ExpenseType] [nvarchar](255) NULL,[Vendor] [nvarchar](255) NULL,[Project] [nvarchar](255) NULL,[Purpose] [nvarchar](255) NULL,[CostCenter] [nvarchar](255) NULL,
	[CostCenterName] [nvarchar](255) NULL,[ApprovalStatus] [nvarchar](255) NULL,[Currency] [nvarchar](255) NULL,[ApprovedAmount] [float] NULL,[FromLocation] [nvarchar](255) NULL,
	[ToLocation] [nvarchar](255) NULL,[TransactionDate] [datetime] NULL,[SentforPaymentDate] [datetime] NULL,[NumberofAttendees] [float] NULL,[CostPerAttendee] [float] NULL,
	[AMEXExpense] [nvarchar](255) NULL,[CommenterName] [nvarchar](255) NULL,[Comment] [nvarchar](255) NULL,[CommentDate] [datetime] NULL,[ExpenseCategory] [nvarchar](255) NULL,
	[HomeOffice] [nvarchar](255) NULL,[CommentFor] [nvarchar](255) NULL,[EmployeeCountryCode] [nvarchar](255) NULL,[EntryApprovedAmount] [float] NULL,[Location] [nvarchar](255) NULL,
	[Company] [nvarchar](255) NULL,[AccountCode] [nvarchar](255) NULL,[EmployeeCostCenter] [nvarchar](255) NULL,[ExpenseAmountReimbursement] [float] NULL,[CountryofEmployee] [nvarchar](255) NULL,
	[Department] [nvarchar](50) NULL,[Source] [nvarchar](50) NULL,[ClientList1] [nvarchar](255) NULL,[ClientList2] [nvarchar](255) NULL,[PrimaryPurposeofTrip] [nvarchar](255) NULL,
[PurposeofTrip_SubPicklist][nvarchar](255) NULL,ReportExpenseKey [nvarchar](255) NULL,Posteddatetime datetime NULL,[LastUpdatedDate] [datetime] NULL)
	
Insert Into #5280ExpenseCurrentMonth
select  YEAR(x.TransactionDate) as Year, MONTH(x.TransactionDate) as Month,Null as StaffId,X.Employee as FullName,x.Location as City,Null as CrmId,Null as MasterAccountName,
y.ReportName,x.AccountName as ExpenseType,y.accountNameAlias as Vendor,Null as Project,x.Purpose,CostCenter,case when CostCenterName='Sales  Buyside' then 'Sales Buyside' else CostCenterName end as CostCenterName,Null as ApprovalStatus,
x.Currency,round(cast(x.ApprovedAmount as float),2) as ApprovedAmount,Null as FromLocation,Null as ToLocation,x.TransactionDate,x.SubmitDate as SentForPaymentDate,NUll as NumberOfAttendees,
Null as CostPerAttendee,NUll as AmexExpense,Null as CommenterName,Null as Comment,Null as CommentDate,Null as ExpenseCategory, Null as HomeOffice, Null as CommentFor,
Null as EmployeeCountryCode, Null as EntryApprovedAmount,x.Location,NUll as Company, x.AccountNum as AccountCode, Null as EmployeeCostCenter, Null as ExpenseAmountReimbursement,
Null as CountryofEmployee, x.Department,'5280' as Source,null as ClientList1,null as ClientList2,null as PrimaryPurposeofTrip,null as PurposeofTrip_SubPicklist,null as ReportExpenseKey,x.TransactionDate as Posteddatetime,GETDATE() as LastUpdatedDate from
(
select Employee,SubmitDate,TransactionDate,AccountName,Purpose,Currency,ApprovedAmount,ReportName,'' as JournalName,AccountNum,q2.Dataareaid,Voucher,
Department,CostCenter,CostCenterName,d2.Description as Location
from
(
select Employee,SubmitDate,TransactionDate,AccountName,Purpose,Currency,ApprovedAmount,ReportName,'' as JournalName,AccountNum,q1.Dataareaid,Voucher,
Department, Q1.CostCode as CostCenter,d1.Description as CostCenterName,LocationCode 
from
(
select Employee,SubmitDate,TransactionDate,AccountName,Purpose,Currency,ApprovedAmount,ReportName,'' as JournalName,AccountNum,q.Dataareaid,Voucher,
d.Description as Department, CostCode,LocationCode from
(
select YEAR(transdate) as Year, MONTH(transdate) as Month,Null as StaffId,lt.voucher as Employee,'' as City,Null as CrmId,Null as MasterAccountName,
'' as ReportName,AccountName as ExpenseType,accountNameAlias as Vendor,Null as Project,txt as Purpose,lt.dimension, lt.dimension2_ as CostCode, lt.dimension3_ as LocationCode,Null as ApprovalStatus,
lt.CurrencyCode as Currency,round(cast(amountmstsecond as float),2) as ApprovedAmount,Null as FromLocation,Null as ToLocation,transdate as TransactionDate,posteddatetime as SubmitDate,NUll as NumberOfAttendees,
Null as CostPerAttendee,NUll as AmexExpense,Null as CommenterName,Null as Comment,Null as CommentDate,Null as ExpenseCategory, Null as HomeOffice, Null as CommentFor,
Null as EmployeeCountryCode, Null as EntryApprovedAmount,'' as Location,NUll as Company, Null as AccountCode, Null as EmployeeCostCenter, Null as ExpenseAmountReimbursement,
Null as CountryofEmployee, '5280' as Source,GETDATE() as LastUpdatedDate, lt.dataareaid,AccountName,lt.AccountNum,Voucher
from chiaxsql01.TT_DYANX09_PRD.dbo.LEDGERTRANS LT
left join (select AccountNum,AccountName,AccountNamealias, dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.ledgertable) L
on lt.accountnum=l.accountnum and lt.dataareaid=L.dataareaid
left join chiaxsql01.TT_DYANX09_PRD.dbo.LedgerJournalTable ljt
on lt.JournalNum=ljt.JournalNum and lt.dataareaid=ljt.dataareaid
where year(transdate) =@Year and Month(transdate)=@Month
)Q left join (select distinct description,num,dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.dimensions where dimensioncode=0) D
on q.dimension=d.num and q.dataareaid=d.dataareaid
)Q1 left join (select distinct description,num,dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.dimensions) D1
on q1.CostCode=d1.num and q1.dataareaid=d1.dataareaid
)Q2 left join (select distinct description,num,dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.dimensions where dimensioncode<>0) D2
on q2.LocationCode=d2.num and q2.dataareaid=d2.dataareaid
)x
left join 
(
select  distinct jt.voucher as Employee,posteddatetime as SubmitDate,transdate as TransactionDate,txt as Purpose,'USD' as Currency, 
case when jt.CURRENCYCODE='USD' then AMOUNTCURCREDIT else (case when (dbo.fnGetExchangeRt(jt.dataareaid,DocumentDate,'USD')) is null then 100/jt.Exchrate else (dbo.fnGetExchangeRt(jt.dataareaid,DocumentDate,'USD')) end)*AMOUNTCURCREDIT end as ApprovedAmount,
case when jt.CURRENCYCODE='USD' then AMOUNTCURCREDIT else (case when (dbo.fnGetExchangeRt(jt.dataareaid,DocumentDate,'USD')) is null then 100/jt.Exchrate else (dbo.fnGetExchangeRt(jt.dataareaid,DocumentDate,'USD')) end) *AMOUNTCURDEBIT end as ApprovedAmountD
,Invoice as ReportName, 
JOURNALNAME,JT.ACCOUNTNUM,jt.dataareaid,jt.dimension as DeptCode,jt.dimension2_ as CostCode,jt.dimension3_ as LocationCode,voucher,isnull(v.AccountName,v.Accountnamealias) as AccountName,v.Accountnamealias
from chiaxsql01.TT_DYANX09_PRD.dbo.LedgerJournalTable J join chiaxsql01.TT_DYANX09_PRD.dbo.LEDGERJOURNALTRANS JT 
on JT.JOURNALNUM = J.JOURNALNUM and jt.dataareaid=j.dataareaid join (select AccountNum,AccountName,AccountNamealias, dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.ledgertable
union
select  AccountNum,Name,Namealias, dataareaid from chiaxsql01.TT_DYANX09_PRD.dbo.VENDTABLE
where vendgroup not in ('EMP')) V 
on V.ACCOUNTNUM=JT.ACCOUNTNUM and v.dataareaid=jt.dataareaid
where 
J.JOURNALNAME in ('5280') and 
year(transdate) =@Year and Month(transdate)=@Month
and jt.accountnum like 'V%'
)Y
on x.Employee=y.Employee and x.SubmitDate=y.SubmitDate and x.TransactionDate=y.TransactionDate and x.voucher=y.voucher and x.dataareaid=y.dataareaid


DELETE ExpenseData
where YEAR=@PriorYear and Month=@PriorMonth and Source='5280'

DELETE ExpenseData
where YEAR=@Year and Month=@Month and Source='5280'

DELETE ExpenseData
where YEAR(SentforPaymentDate)=@Year and Month(SentforPaymentDate)=@Month and Source='Concur'

Insert INTO ExpenseData
select (select max(Id) from ExpenseData)+ROW_NUMBER() over (order by Sentforpaymentdate,Transactiondate asc),* from #5280ExpensePriorMonth

Insert INTO ExpenseData
Select (select max(Id) from ExpenseData)+ROW_NUMBER() over (order by Sentforpaymentdate,Transactiondate asc),* from #ConcurExpense

Insert INTO ExpenseData
select (select max(Id) from ExpenseData)+ROW_NUMBER() over (order by Sentforpaymentdate,Transactiondate asc),* from #5280ExpenseCurrentMonth

Drop Table #ConcurExpense
Drop Table #5280ExpensePriorMonth
Drop Table #5280ExpenseCurrentMonth


---------------------Update the table with the changes got from Google Sheets-----------------
Exec SP_Load_ExpenseData_Updates
-------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------Update Department Field------------------------------------------------------
update ExpenseData
set [Department]='Administration'
where costcenter like '2%' and Source='Concur'

update ExpenseData
set [Department]='Engineering'
where costcenter like '4%' and Source='Concur'

update ExpenseData
set [Department]='Global Support'
where costcenter like '8%' and Source='Concur'

update ExpenseData
set [Department]='IT'
where costcenter like '3%' and Source='Concur'

update ExpenseData
set [Department]='Operations'
where costcenter like '7%' and Source='Concur'

update ExpenseData
set [Department]='PMM'
where costcenter like '5%' and Source='Concur'

update ExpenseData
set [Department]='Sales'
where costcenter like '60%' and Source='Concur'


update ExpenseData
set [Department]='Sales Buyside'
where costcenter like '61%' and Source='Concur'

update ExpenseData
set [Department]='TradeCo' 
where costcenter like '1%' and Source='Concur'


Update E
Set E.CrmId=A.CrmId, E.MasterAccountName=E.ClientList1
from ExpenseData E Join Account A
on E.ClientList1=A.MasterAccountName
  where e.MasterAccountName is null and clientlist1 is not null
---------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------Code to Update PostedDateTime from AX and Map it with Concur Employee Name--------------------

Update E
Set E.Posteddatetime=A.Posteddatetime
from ExpenseData E 
left join
(
select  distinct u.name,oldvendaccountnum as staffid,posteddatetime,t.invoice from chiaxsql01.TT_DYANX09_PRD.dbo.LedgerJournalTrans T
left join chiaxsql01.TT_DYANX09_PRD.dbo.VENDTABLE U
on t.accountnum=u.accountnum and t.dataareaid=u.dataareaid
left join chiaxsql01.TT_DYANX09_PRD.dbo.LEDGERTRANS V
on t.journalnum=v.journalnum and t.dataareaid=v.dataareaid and t.journalnum=v.journalnum 
left join chiaxsql01.TT_DYANX09_PRD.dbo.LedgerJournalTable W
on t.journalnum=w.journalnum and t.dataareaid=w.dataareaid  
where 
t.voucher like 'EXP%' 
and  year(t.transdate)>2011 
and oldvendaccountnum is not null 
)A
on E.StaffId=a.staffid and E.ReportExpenseKey=A.invoice
where e.Source='Concur' and year=@RunYear and month=@RunMonth
--where year=2014 and month=9 and E.staffid=221

-------------------------------------------------------------------------------------

------------------------------------Delete FullName='' for Dataareaid=tti from AX for 5280----------------------------
Delete [dbo].[ExpenseData]
where fullname='' and source='5280'
and year=@RunYear and month=@RunMonth

-----------------------------------------------------------------------------------------------------

----------------------------------------Update HomeOffice and ToLocation to be the Same for 5280 data------------------------

Update BIDW.[dbo].[ExpenseData]
Set Homeoffice=Location
where source='5280' 
and year=@RunYear and month=@RunMonth

Update BIDW.[dbo].[ExpenseData]
Set ToLocation=Location
where source='5280'
and year=@RunYear and month=@RunMonth


End



/****************Unused Code************************/
--delete ExpenseData
--where YEAR in (2012,2013)
--insert into ExpenseData
--select Year, Month, EmployeeId As StaffId, Employee as FullName,E.City,
--case when len(clientid)>20 then stuff(stuff(stuff(STUFF(replace(clientid,'-',''),9,0,'-'),14,0,'-'),19,0,'-'),24,0,'-') else Clientid end as CrmId,
--Client as MasterAccountName, ReportName,E.ExpenseType,Vendor,Project,Purpose,E.CostCenter, CostCenterName, ApprovalStatus, Currency, ApprovedAmount,
--TotalApprovedAmount, FromLocation, ToLocation,TransactionDate,SentforPaymentDate, NumberofAttendees, CostPerAttendee, AMEXExpense, CommenterName,
--Comment, CommentDate, ET.ParentExpenseType as ExpenseCategory, SalesOffice as HomeOffice
--from chisql12.bidw_ods.dbo.ExpenseData_New E
--Left Join chisql12.bidw_ods.dbo.ExpenseType ET
--on E.expensetype=ET.Expensetype
--Left Join dbo.Staff S
--on E.Employeeid=S.StaffId
--where YEAR in (2012,2013)
--and Month=@Month


--update A
--set A.fromlocation=b.salesoffice
--from ExpenseData A join dbo.Staff B
--on A.StaffId=b.StaffId
--where YEAR=@Year and Month=@Month



