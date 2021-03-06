USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetSalesCommissonReport]    Script Date: 7/24/2015 11:28:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetSalesCommissonReport]

 AS 

Begin 

Select * from BIDW.dbo.SalesCommission

End
 
 

 
/* AS

declare @year int;
declare @month int;
declare @Runyear int;
declare @Runmonth int;
declare @RunMonthName char(10);
declare @EndYear int;
declare @EndMonth int

declare @ppyear int
declare @ppmonth int;
declare @pyear int;
declare @pmonth int;

declare @Trnxnotindate datetime
declare @Subnotindate datetime

SET @year=Year(getdate())
SET @Month=Month(Getdate())+1
SET @Runyear = @Year
SET @Runmonth = @Month
SET @EndYear=  case when @month in (1,2) then @Year-1 else @Year end 
SET @EndMonth = Case when @month = 2 then 12 when @month=1 then 11 else @month-month(getdate()) end 

SET NOCOUNT ON;
Create table #Final
( Year int,Month char(10),accountid nvarchar(200),Masteraccountname nvarchar(200),AccountName nvarchar(200),NetworkShortName varchar(50),DeliveryName nvarchar(200),SalesOffice nvarchar(200),Region nvarchar(200),ProductName nvarchar(200)
,Productsku nvarchar(200),TTDescription varchar(100),TTChangeType varchar(50),TTSalesCommissionException varchar(50),Revenue float,TTNotes nvarchar(500),TypeOfData varchar(50),Screens int,SalesId varchar(50),City varchar(100)
,State varchar(50), Country varchar(50),CreatedDate Datetime,ModifiedDate Datetime)

while @Runyear >= @EndYear and @Runmonth>=@EndMonth
begin
	Set @ppyear = case when @runmonth in (1,2) then @runyear-1 else @runyear end
	Set @ppmonth = case when @runmonth=1 then 11 when @runmonth=2 then 12 else @runmonth-2 end 
	Set @pyear = case when @runmonth in (1) then @runyear-1 else @runyear end
	Set @pmonth = case when @runmonth=1 then 12 else @runmonth-1 end 
	Set @Trnxnotindate = dateadd(month,-2,(select DATEADD(month,@Runmonth-1,DATEADD(year,@RunYear-1900,0))))
	Set @Subnotindate = dateadd(month,0,(select DATEADD(month,@Runmonth-1,DATEADD(year,@RunYear-1900,0))))
	SET @RunMonthName = case @RunMonth
                         when 1 then '1-Jan'
						 when 2 then '2-Feb'
						 when 3 then '3-Mar'
						 when 4 then '4-Apr'
						 when 5 then '5-May'
						 when 6 then '6-Jun'
						 when 7 then '7-Jul'
						 when 8 then '8-Aug'
						 when 9 then '9-Sep'
						 when 10 then '10-Oct'
						 when 11 then '11-Nov'
						 when 12 then '12-Dec' End 


-------------------------------------------------------Transactions Calculations ----------------------------------------------------------------

Create table #Data
( Year int,Month int,accountid nvarchar(200),Masteraccountname nvarchar(200),AccountName nvarchar(200),Username nvarchar(200),City nvarchar(200),state nvarchar(200),Country nvarchar(200),Region nvarchar(200),Productsku nvarchar(200),
ProductName nvarchar(200),Revenue float,Count int,MasterUsername nvarchar(200),NeworkSortName varchar(50),DeliveryName nvarchar(200),TTDescription varchar(100),TTSalesCommissionException varchar(50),TTChangeType varchar(50)
,TTNotes nvarchar(500),SalesId varchar(50),CreatedDate Datetime,ModifiedDate Datetime)
Insert into #Data
select * from
(
select Year, Month, m.AccountId,MasterAccountName,a.AccountName,Username,isnull(nullif(City,''),'-') as City,State,Country,Region,m.Productsku,ProductName,sum(billedamount) as Revenue, sum(billablelicensecount) as Count 
,(masteraccountname+'-'+Username) as MasterUsername,NetworkShortName,DELIVERYNAME,TTDescription,TTSalesCommissionException,TTChangeType,TTNotes,SalesId
,CreatedDate,ModifiedDate
from MonthlyBillingData M
join account A on m.AccountId =a.Accountid
join product P on m.ProductSku=p.ProductSku
left join (select * from Network where billingmode='Transactional') N on M.CrmId=N.CrmId
where year=@RunYear and month=@RunMonth and productname like '%transaction%'
group by Year, Month, m.AccountId,MasterAccountName, a.AccountName,Username,City,State,Country,Region,ProductName,m.Productsku,DELIVERYNAME,TTDescription,TTSalesCommissionException,NetworkShortName,TTChangeType,TTNotes,SalesId
,CreatedDate,ModifiedDate
UNION
select Year, Month, m.AccountId,MasterAccountName,a.AccountName,Username,isnull(nullif(City,''),'-') as City,State,Country,Region,m.Productsku,ProductName,sum(billedamount) as Revenue, sum(billablelicensecount) as Count 
,(masteraccountname+'-'+Username) as MasterUsername,NetworkShortName,DELIVERYNAME,TTDescription,TTSalesCommissionException,TTChangeType,TTNotes,SalesId
,CreatedDate,ModifiedDate
from MonthlyBillingData M
join account A on m.AccountId =a.Accountid
join product P on m.ProductSku=p.ProductSku
left join (select * from Network where billingmode='Transactional') N on M.CrmId=N.CrmId
where year=@pyear and month=@pmonth and productname like '%transaction%'
group by Year, Month, m.AccountId,MasterAccountName, a.AccountName,Username,City,State,Country,Region,ProductName,m.Productsku,DELIVERYNAME,TTDescription,TTSalesCommissionException,NetworkShortName,TTChangeType,TTNotes,SalesId
,CreatedDate,ModifiedDate
UNION
select Year, Month, m.AccountId,MasterAccountName,a.AccountName,Username,isnull(nullif(City,''),'-') as City,State,Country,Region,m.Productsku,ProductName,sum(billedamount) as Revenue, sum(billablelicensecount) as Count 
,(masteraccountname+'-'+Username) as MasterUsername,NetworkShortName,DELIVERYNAME,TTDescription,TTSalesCommissionException,TTChangeType,TTNotes,SalesId
,CreatedDate,ModifiedDate
from MonthlyBillingData M
join account A on m.AccountId =a.Accountid
join product P on m.ProductSku=p.ProductSku
left join (select * from Network where billingmode='Transactional') N on M.CrmId=N.CrmId
where year=@ppyear and month=@ppmonth and productname like '%transaction%'
group by Year, Month, m.AccountId,MasterAccountName, a.AccountName,Username,City,State,Country,Region,ProductName,m.Productsku,DELIVERYNAME,TTDescription,TTSalesCommissionException,NetworkShortName,TTChangeType,TTNotes,SalesId
,CreatedDate,ModifiedDate
)Q
where MasterUsername in
(
select distinct (masteraccountname+'-'+Username)
from MonthlyBillingData M
join account A on m.AccountId =a.Accountid
join product P on m.ProductSku=p.ProductSku
where year=@ppyear and month=@ppmonth and productname like '%transaction%'
)

Update A
Set A.TTSalesCommissionException=B.TTSalesCommissionException
from #data A left join MonthlyBillingData B
on A.Username=b.username and a.TTDescription=b.TTDESCRIPTION and a.accountid=b.AccountId
where b.year=@ppyear and b.month=@ppmonth

Create Table #Notin
(MasterUsername varchar(200))
Insert into #Notin
select distinct masteraccountname+'-'+Username as MasterUsername from MonthlyBillingData M
join Account A on m.AccountId=a.Accountid
join TimeInterval T on m.Year=t.Year and m.Month=t.Month
join Product P on m.productsku=p.productsku
where enddate>=dateadd(month,-12,@Trnxnotindate) and enddate<@Trnxnotindate
and (screens='screens' or m.productsku =10106)


Create table #DistinctPriorUsername
( Year int,Month int,accountid nvarchar(200),Masteraccountname nvarchar(200),AccountName nvarchar(200),Username nvarchar(200),City nvarchar(200),state nvarchar(200),Country nvarchar(200),Region nvarchar(200),Productsku nvarchar(200),
ProductName nvarchar(200),Revenue float,Count int,MasterUsername nvarchar(200),NetworkShortName varchar(50),DeliveryName nvarchar(200),TTDescription varchar(100),TTSalesCommissionException varchar(50),TTChangeType varchar(50)
,TTNotes nvarchar(500),SalesId varchar(50),CreatedDate Datetime,ModifiedDate Datetime,row int)

Insert into #DistinctPriorUsername
select * from
(
select *, row_number() over (partition by masteraccountname+'-'+Username order by revenue desc) as Row from
(
select * from #Data
where MasterUsername
not in 
(
select * from #Notin
)
)q
)f
where row<=2 




Create table #CTE1
(Accountid varchar(100), Username varchar(200), Productname varchar(200),revenue float,DeliveryName nvarchar(200))
Insert into #CTE1
select Accountid,Username,Productname,sum(revenue)/2 as revenue,DeliveryName from #DistinctPriorUsername
group by Accountid,Username,Productname,DeliveryName




Insert into #Final

select @RunYear as Year,@RunMonthName as Month,A.AccountId,MasterAccountName,AccountName,NetworkShortName,A.DeliveryName,SalesOffice,Region,A.ProductName,Productsku,TTDescription,TTChangeType,
case when TTSalesCommissionException =1 then 'Transfer' 
     when TTSalesCommissionException=2 then 'NameChange' 
     when TTSalesCommissionException =3 then 'Upgrade'
	 when TTSalesCommissionException =4 then 'Downgrade' 
	 when TTSalesCommissionException =5 then 'Migration' 
	 when A.Accountid in ('C100349','C100353','C100278') then 'Special Deal' else 'Eligible' end as TTSalesCommissionException,sum(b.Revenue) as Revenue,TTNotes,'Transactional' as TypeOfData,count(distinct A.DeliveryName) as Screens,SalesId,City,A.State,A.Country
	 ,CreatedDate,ModifiedDate from
(
select * from #DistinctPriorUsername where row=1 
)A
left join
(select * from #cte1) B
on A.AccountId=b.AccountId and a.Username=b.Username and a.ProductName=b.ProductName
left join (
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on A.Country=rm.Country and isnull(nullif(A.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
--where A.productname like '%Transaction'
--and month=1 and year=2015
Group By A.AccountId,MasterAccountName,AccountName,NetworkShortName,A.DeliveryName,SalesOffice,Region,A.ProductName,Productsku,TTDescription,TTChangeType,
(case when TTSalesCommissionException =1 then 'Transfer' 
     when TTSalesCommissionException=2 then 'NameChange' 
     when TTSalesCommissionException =3 then 'Upgrade'
	 when TTSalesCommissionException =4 then 'Downgrade' 
	 when TTSalesCommissionException =5 then 'Migration' 
	 when A.Accountid in ('C100349','C100353','C100278') then 'Special Deal' else 'Eligible' end), TTNotes,SalesId,City,A.State,A.Country
	 ,CreatedDate,ModifiedDate




------------------------------------------------------Subscriptions Calculations ------------------------------------------------

Create table #DistinctSubNotInDeliveryName
( Deliveryname nvarchar(200))

Insert into #DistinctsubNotInDeliveryName
select distinct MasterAccountName+'-'+DeliveryName from MonthlyBillingData M
join Account A on m.AccountId=a.Accountid
join TimeInterval T on m.Year=t.Year and m.Month=t.Month
where ProductSku in (20000,20200)  and ttusage>=1 and enddate>=dateadd(month,-12,@Subnotindate) and enddate<@subnotindate

Insert Into #Final

select * from
(
select @RunYear as Year,@RunMonthName as Month, m.AccountId,Masteraccountname, AccountName,TTLicenseFileId as NetworkShortName,DeliveryName,SalesOffice,Region,ProductName,m.Productsku,TTdescription,TTChangeType, 
case when TTSalesCommissionException=1 then 'Transfer'
     when TTSalesCommissionException =2 then 'NameChange'
	  when TTSalesCommissionException =3 then 'Upgrade'
	   when TTSalesCommissionException =4 then 'Downgrade' 
	   when TTSalesCommissionException =5 then 'Migration' 
	   when (m.Accountid in ('C100066','C100180','C100166','C100092','C100288','C100185','C100114','C100157','C100083',
'C100195','C100077','C100082','C100267') or TTLicenseFileId ='Marex_7x') then 'Special Deal'
	 else 'Eligible'
	 End as TTSalesCommissionException
,sum(BilledAmount) as Revenue,TTNotes,'Subscriptions' as TypeOfData,count(distinct DeliveryName) as Screens,SalesId,City,M.State,M.Country
,CreatedDate,ModifiedDate from MonthlyBillingData M
join Account A
on M.AccountId=A.Accountid
join Product P on m.ProductSku=p.ProductSku
left join (
select distinct Country, State,SalesOffice from dbo.RegionMap
)rm
on m.Country=rm.Country and isnull(nullif(m.[State],''),'Unassigned')=isnull(nullif(rm.[State],''),'Unassigned')
where year=@Runyear and month=@Runmonth
and m.productsku in (20000,20200) and ttusage>=1.00 
--and TTSalesCommissionException<>1
--and (ttbillend >='2015-01-31 00:00:00.000' or TTBillEnd='1900-01-01 00:00:00.000') 
and MasterAccountName+'-'+DeliveryName not in 
(
select * from #DistinctSubNotInDeliveryName
)
group by Year, Month, m.AccountId,Masteraccountname, AccountName,DeliveryName,SalesOffice,Region,ProductName,m.Productsku,TTBillStart,TTBillEnd,
TTChangeType,TTNotes,TTSalesCommissionException,TTLicenseFileId,TTdescription,SalesId,City,M.State,M.Country
,CreatedDate,ModifiedDate
)F


-------------------------------------------------------------------------------------------------------


drop Table #Data
drop table #DistinctPriorUsername
Drop table #CTE1
drop table #Notin
drop table #DistinctSubNotInDeliveryName

	SET @Runyear = case when @RunMonth = 1 then @Runyear-1 else @Runyear End
	SET @Runmonth=case when @RunMonth = 1 then 12 else @Runmonth-1 End
end



Insert into #Final
(Year,Month,AccountId,MasterAccountName,AccountName,NetworkShortName,DeliveryName,SalesOffice,Region,ProductName,ProductSku,
TTDescription,TTChangeType,TTSalesCommissionException,Revenue,TTNotes,TypeOfData,Screens,SalesId,CreatedDate,ModifiedDate)
Values(2015,'1-Jan','','Special Deals','','','Special Deals','Special Deals','Special Deals','X_TRADER','','','','Eligible',4204,'','',0,0,'','')

Insert into #Final
(Year,Month,AccountId,MasterAccountName,AccountName,NetworkShortName,DeliveryName,SalesOffice,Region,ProductName,ProductSku,
TTDescription,TTChangeType,TTSalesCommissionException,Revenue,TTNotes,TypeOfData,Screens,SalesId,CreatedDate,ModifiedDate)
Values(2015,'2-Feb','','Special Deals','','','Special Deals','Special Deals','Special Deals','X_TRADER','','','','Eligible',4204,'','',0,0,'','')

Insert into #Final
(Year,Month,AccountId,MasterAccountName,AccountName,NetworkShortName,DeliveryName,SalesOffice,Region,ProductName,ProductSku,
TTDescription,TTChangeType,TTSalesCommissionException,Revenue,TTNotes,TypeOfData,Screens,SalesId,CreatedDate,ModifiedDate)
Values(2015,'3-Mar','','Special Deals','','','Special Deals','Special Deals','Special Deals','X_TRADER','','','','Eligible',4204,'','',0,0,'','')

Insert into #Final
(Year,Month,AccountId,MasterAccountName,AccountName,NetworkShortName,DeliveryName,SalesOffice,Region,ProductName,ProductSku,
TTDescription,TTChangeType,TTSalesCommissionException,Revenue,TTNotes,TypeOfData,Screens,SalesId,CreatedDate,ModifiedDate)
Values(2015,'4-Apr','','Special Deals','','','Special Deals','Special Deals','Special Deals','X_TRADER','','','','Eligible',2308,'','',0,0,'','')

Insert into #Final
(Year,Month,AccountId,MasterAccountName,AccountName,NetworkShortName,DeliveryName,SalesOffice,Region,ProductName,ProductSku,
TTDescription,TTChangeType,TTSalesCommissionException,Revenue,TTNotes,TypeOfData,Screens,SalesId,CreatedDate,ModifiedDate)
Values(2015,'5-May','','Special Deals','','','Special Deals','Special Deals','Special Deals','X_TRADER','','','','Eligible',2308,'','',0,0,'','')

Insert into #Final
(Year,Month,AccountId,MasterAccountName,AccountName,NetworkShortName,DeliveryName,SalesOffice,Region,ProductName,ProductSku,
TTDescription,TTChangeType,TTSalesCommissionException,Revenue,TTNotes,TypeOfData,Screens,SalesId,CreatedDate,ModifiedDate)
Values(2015,'6-Jun','','Special Deals','','','Special Deals','Special Deals','Special Deals','X_TRADER','','','','Eligible',2308,'','',0,0,'','')

Select * from #Final
where productname like 'X_TRADER%'



------------Commission paid but users cancelled licenses for current month------------------------
/*Select * from #Final
where productname like 'X_TRADER%' and TTSalesCommissionException='Eligible'
and year=2015 and month in ('1-Jan','2-Feb','3-Mar')
and DeliveryName+accountid in 
(
select DeliveryName+accountid
from
(
Select Year,Month,m.AccountId,MasterAccountName,AccountName,DeliveryName,Region,ProductName,m.ProductSku,
TTDescription,TTChangeType,TTSalesCommissionException,Billedamount as Revenue,TTNotes,SalesId from MonthlyBillingData M
join Product P on m.ProductSku=p.ProductSku
Join Account A on M.AccountId=A.Accountid
where productname like 'X_TRADER%'
and year=2015 and month =5 and billablelicensecount<>1
)Q
)
*/
--------------------------------------------------

*/