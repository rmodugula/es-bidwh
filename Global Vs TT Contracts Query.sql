----------------7x Contracts--------------
drop table #7xContracts
SELECT TransactionDate,MarketId,productname,sum(Contracts) as Contracts  
Into #7xContracts
FROM chisql12.[BIDW].[dbo].[Fills]
where year=2019 and Month=6
and isbillable='Y' and marketid=7 and platform<>'TTWEB'
Group by TransactionDate,MarketId,productname
order by 1

----------------TT Contracts--------------
SELECT cast(transacttime as date) as TransactionDate,MarketId,InstrumentId,sum(LastQty) as Contracts  
Into #TTContracts
FROM ttfills.[dbo].[Fills_BillableFlag]
where year(transacttime)=2019 and Month(transacttime)=6
and billable=1 and marketid=7
Group by cast(transacttime as date),MarketId,InstrumentId
order by 1,2


----------------Global Contracts----------------------------
drop table #GlobalContracts
SELECT TransactionDate,MarketId,InstrumentId,sum(cast(isnull(globalvolume,0) as float)) as GlobalContracts  
Into #GlobalContracts
FROM [CHISQL21\SQL2016].BABA.dbo.globaltransactions
where year(TransactionDate)=2019 and Month(TransactionDate)=6
Group by TransactionDate,MarketId,InstrumentId
order by 1,2

-----------------Instruments------------------------
SELECT I.[MarketId],[MarketName],I.[ProductId],[ProductType],[InstrumentId],[InstrumentName],[InstrumentAlias],[UniversalName]
,[LotSize],[LastTradingDate],ProductGroup,Symbol,MIC,AssetClass,SubAssetClass
Into #instruments
FROM [MESS].[dbo].[Instruments] I
left join [MESS].[dbo].[ExchangeProducts] EP on I.[ProductId]=EP.[ProductId] and I.marketid=EP.marketid


--select * from #7xContracts
--where TransactionDate='2019-06-28'

----------------------------TT Vs Global contracts Comparision with Instruments-----------------------------
drop table #FinalData
select isnull(ttc.TransactionDate,gc.TransactionDate) as TransactionDate,M.MarketName,isnull(ttc.marketid,gc.marketid) as MarketId,isnull(ttc.instrumentid,gc.instrumentid) as InstrumentId
,ProductType,InstrumentAlias,InstrumentName,ProductGroup,Symbol,MIC,AssetClass,SubAssetClass
,isnull(ttc.Contracts,0) as TTContracts,isnull(gc.GlobalContracts,0) as GlobalContracts
Into #FinalData
from  #TTContracts TTC
full outer  join #GlobalContracts GC on TTC.TransactionDate=GC.TransactionDate and TTC.MarketId=GC.marketid and ttc.InstrumentId=gc.instrumentid
Left join chisql20.Mess.dbo.Markets M on isnull(ttc.marketid,gc.marketid)=M.MarketId
Left join #instruments I on isnull(ttc.instrumentid,gc.instrumentid)=I.InstrumentId
where ProductType='Future'
--where isnull(gc.GlobalContracts,0)>isnull(ttc.Contracts,0)
order by 1


select * from #FinalData
where instrumentid='2393784402801154666'

----------------------------TT & 7x Vs Global contracts Comparision without Instruments-----------------------------
Select isnull(g.TransactionDate,xt.TransactionDate) as TransactionDate,M.MarketName,isnull(g.MarketId,xt.Marketid) as MarketId,ProductType
,ProductGroup,isnull(Symbol,productname) as ProductName,MIC,AssetClass,SubAssetClass,sum(isnull(xt.Contracts,0)) as XtContracts,sum(isnull(TTContracts,0)) as TTContracts
,sum(isnull(GlobalContracts,0)) as GlobalContracts,sum(isnull(xt.Contracts,0))+sum(isnull(TTContracts,0)) as TTOverallContracts
from (
select isnull(ttc.TransactionDate,gc.TransactionDate) as TransactionDate,M.MarketName,isnull(ttc.marketid,gc.marketid) as MarketId
,ProductType,InstrumentAlias,InstrumentName,ProductGroup,Symbol,MIC,AssetClass,SubAssetClass
,isnull(ttc.Contracts,0) as TTContracts,isnull(gc.GlobalContracts,0) as GlobalContracts
from  #TTContracts TTC
full outer  join #GlobalContracts GC on TTC.TransactionDate=GC.TransactionDate and TTC.MarketId=GC.marketid and ttc.InstrumentId=gc.instrumentid
Left join chisql20.Mess.dbo.Markets M on isnull(ttc.marketid,gc.marketid)=M.MarketId
Left join #instruments I on isnull(ttc.instrumentid,gc.instrumentid)=I.InstrumentId
)G
full outer join #7xContracts XT on g.TransactionDate=XT.TransactionDate and g.MarketId=xt.MarketId and g.Symbol=xt.productname
Left join chisql20.Mess.dbo.Markets M on isnull(g.MarketId,xt.Marketid)=M.MarketId
where ProductType='Future'
Group by g.TransactionDate,M.MarketName,g.MarketId,ProductType,ProductGroup,Symbol,MIC,AssetClass,SubAssetClass
,xt.TransactionDate,xt.Marketid,xt.productname
order by 1



