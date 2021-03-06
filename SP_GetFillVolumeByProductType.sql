USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetFillVolumeByProductType]    Script Date: 4/7/2016 10:46:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[GetFillVolumeByProductType]
@RunYear Int = Null,
@RunMonth Int = Null

AS

Declare @Year int, @Month char(10)
IF @RunMonth is Null and @RunMonth is Null
Begin 
Set @Year=YEAR(getdate()) 
Set @Month=Month(getdate())
END
else 
Begin
Set @Year=@RunYear
Set @Month=@RunMonth
End

    
BEGIN

select Year,Month,ExchangeName,FillProductType,ProductType,ProductClass,f.ProductName as FillProductName,AxProductName,sum(Fills) as BillableVolume, UserName
from 
(
select Year,Month,case when MarketName like '%cbot%' then 'CME' else MarketName end as ExchangeName,fills,username,f.ProductName,Description as FillProductType,P.Productname as AxProductName
from [bidw].[dbo].fills F 
left join  [bidw].[dbo].exchange e 
on f.ExchangeId=e.ExchangeId 
Left join [BIDW].[dbo].[Market] M
on f.MarketId=m.MarketID and f.platform=m.platform
join (SELECT [FillProductTypeId],[Description] FROM [dbo].[FillProductType]) FP
on f.producttype=fp.FillProductTypeId
join Product P on F.AxProductId=P.ProductSku
where isbillable='Y'and year=@Year and month=@Month
and NetworkId not in (577) 
) F 
left outer Join 
(
select * from
(
select *,row_number() over (partition by gateway,productsymbol order by activationdate desc) as row
from
(
select distinct ProductSymbol, ProductClass, ProductType, Exchange, 
case when Gateway='ICE' then 'ICE_IPE' 
when gateway ='BrokerTec' then 'BTec' else Gateway end as Gateway, ActivationDate from ExchangeProducts
)q
)z
where row=1
) EP on F.ProductName=ep.ProductSymbol and f.ExchangeName=ep.Gateway 
--where exchangename='tocom'
group by Year,Month,ProductClass,ExchangeName,ProductType,ProductName,FillProductType,UserName,AxProductName
end





