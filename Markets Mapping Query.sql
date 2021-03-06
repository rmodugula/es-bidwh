Delete [BIDW_ODS].[dbo].[AllMarkets]
Insert into [BIDW_ODS].[dbo].[AllMarkets]

Select Distinct MarketId, 
case MarketName
when 'EurexPF' then 'Eurex'
when 'EurexUS' then 'Eurex'
when 'LIFFE' then 'NYSE_Liffe'
when 'eCBOT' then 'CBOT'
when 'ICE_IPE' then 'ICE'
when 'GETDirect' then 'EEX' 
when 'NYSE_LIFFE_US' then 'NYSE_Liffe'
when 'Eris_GovEx' then 'Eris'
else MarketName End as MarketName
,[Platform]
from
(
select distinct CoreMarketId as MarketId,rtrim(case when charindex('-',ExchangeShortName)=0 then ExchangeShortName
when ExchangeShortName like 'LIFFE-Equity Options%' then 'LIFFE-Equity Options'
else replace(SUBSTRING(ExchangeShortName,1,(charindex('-',ExchangeShortName))),'-','') end) as MarketName,'7xASP' as Platform from fillhub.[dbo].[Exchanges]
where coremarketid<>0
UNION ALL
select distinct CoreMarketId as MarketId,rtrim(case when charindex('-',ExchangeShortName)=0 then ExchangeShortName
when ExchangeShortName like 'LIFFE-Equity Options%' then 'LIFFE-Equity Options'
else replace(SUBSTRING(ExchangeShortName,1,(charindex('-',ExchangeShortName))),'-','') end) as MarketName,'7xUniBroker' as Platform from fillhub.[dbo].[Exchanges]
where coremarketid<>0
UNION ALL
SELECT [MarketId],[MarketName],'TTWEB' as Platform FROM chisql20.[MESS].[dbo].[Markets]
)Q
order by 1



