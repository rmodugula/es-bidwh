-----------------------Parameters used along the SP--------------------------------------------
Declare @DateEpoch bigint,@RowId int,@RunRecords int,@InstrumentId varchar(100),@DateEpochend bigint
Set @DateEpoch=cast(concat(DATEDIFF(s, '1970-01-01', cast('2019-06-01 00:00:00' as datetime)),'000000') as varchar(100))------ Adding training 6 zeros to match the unix format acccepted by the REST API-----
Set @DateEpochend=cast(concat(DATEDIFF(s, '1970-01-01', cast('2019-06-30 23:59:59' as datetime)),'000000') as varchar(100))
set @InstrumentId='6538322929932843268'


--DECLARE @TABLEVAR TABLE (responseXml VARCHAR(MAX))
--select @DateEpoch

Declare @url varchar(200)
DECLARE @Xml XML
Set @Url ='https://hds-int-dev-sim.trade.tt/api/1/bars?m='+'7'+'&instrId='+@InstrumentId+'&sem='+cast(@DateEpoch as varchar(100))+'&eem='+cast(@DateEpochend as varchar(100))+'&minstoroll=1440&sb=true&iv=false'

select @url,len(@url)

Declare @Object as Int;
Declare @ResponseText as table(Json_Table nvarchar(max));



Exec sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
Exec sp_OAMethod @Object, 'open', NULL, 'get',@Url, --Your Web Service Url (invoked)
                 'false'
Exec sp_OAMethod @Object, 'send'
Exec sp_OAMethod @Object, 'responseText', @ResponseText OUTPUT
INSERT into @Responsetext (Json_Table) exec sp_OAGetProperty @Object, 'responseText'


drop table #Data
select json_table as text1 
into #Data
from @Responsetext
Exec sp_OADestroy @Object



drop table #new
select replace(replace(replace(substring(text1,charindex('"pi":"',text1),80000),']","lp":1}}}',''),'"pi":"',''),'[','') as text1
Into #new
from #data

--select CHARINDEX('},',text1),* from #new
select substring(text1,charindex('{',text1,339*5),284) from #new

drop table #processedData
Select * 
into #processedData from
(
select substring(text1,charindex('{',text1,1),284) as text1 from #new
UNION
select substring(text1,charindex('{',text1,339),290) from #new
UNION
select substring(text1,charindex('{',text1,339*2),290) from #new
UNION
select substring(text1,charindex('{',text1,339*3),290) from #new
UNION
select substring(text1,charindex('{',text1,339*4),290) from #new
UNION
select substring(text1,charindex('{',text1,339*5),290) from #new
UNION
select substring(text1,charindex('{',text1,339*6),290) from #new
UNION
select substring(text1,charindex('{',text1,339*7),290) from #new
UNION
select substring(text1,charindex('{',text1,339*8),290) from #new
UNION
select substring(text1,charindex('{',text1,339*9),290) from #new
UNION
select substring(text1,charindex('{',text1,339*10),290) from #new
UNION
select substring(text1,charindex('{',text1,339*11),290) from #new
UNION
select substring(text1,charindex('{',text1,339*12),290) from #new
UNION
select substring(text1,charindex('{',text1,339*13),290) from #new
UNION
select substring(text1,charindex('{',text1,339*14),290) from #new
UNION
select substring(text1,charindex('{',text1,339*15),290) from #new
UNION
select substring(text1,charindex('{',text1,339*16),290) from #new
UNION
select substring(text1,charindex('{',text1,339*17),290) from #new
UNION
select substring(text1,charindex('{',text1,339*18),290) from #new
UNION
select substring(text1,charindex('{',text1,339*19),290) from #new
UNION
select substring(text1,charindex('{',text1,339*20),290) from #new
UNION
select substring(text1,charindex('{',text1,339*21),290) from #new
UNION
select substring(text1,charindex('{',text1,339*22),290) from #new
UNION
select substring(text1,charindex('{',text1,339*23),290) from #new
UNION
select substring(text1,charindex('{',text1,339*24),290) from #new
UNION
select substring(text1,charindex('{',text1,339*25),290) from #new
UNION
select substring(text1,charindex('{',text1,339*26),290) from #new
UNION
select substring(text1,charindex('{',text1,339*27),290) from #new
UNION
select substring(text1,charindex('{',text1,339*28),290) from #new
UNION
select substring(text1,charindex('{',text1,339*29),290) from #new
UNION
select substring(text1,charindex('{',text1,339*30),290) from #new
UNION
select substring(text1,charindex('{',text1,339*31),290) from #new
)t

select * from #processedData
where text1 <>'' and text1 like '%cts%'



Select *,getdate() as LastUpdatedDate from (
Select 
--cast(DATEADD(SECOND, cast(replace(substring(Text1,charindex('\"cts\":',text1),24),'\"cts\":','') as bigint)/1000000, '19700101 00:00') as date)
cast(DATEADD(SECOND, cast(replace(substring(Text1,charindex('\"cts\":',text1),24),'\"cts\":','') as bigint)/1000000, '19700101 00:00') as date) as TransactionDate
,7 as MarketId
--,@InstrumentId as InstrumentId
,replace(substring(text1,charindex('\"id\":',text1),charindex(',\"ts\"',text1)-charindex('\"id\":',text1)),'\"id\":','') as InstrumentId
,replace(replace(replace(replace(substring(Text1,charindex('"o\":',text1)+5,7),':',''),',',''),'\',''),'"','') as OpenNumber
,replace(replace(replace(replace(substring(Text1,charindex('"h\":',text1)+5,7),':',''),',',''),'\',''),'"','') as High
,replace(replace(replace(replace(substring(Text1,charindex('"c\":',text1)+5,7),':',''),',',''),'\',''),'"','') as Low
,replace(replace(replace(replace(substring(Text1,charindex('"o\":',text1)+5,7),':',''),',',''),'\',''),'"','') as CloseNumber
,replace(replace(replace(replace(substring(Text1,charindex('"bv\":',text1)+5,7),':',''),',',''),'\',''),'"','') as BuyVolume
,replace(replace(replace(replace(substring(Text1,charindex('"sv\":',text1)+5,7),':',''),',',''),'\',''),'"','') as SellVolume
,replace(substring(Text1,charindex('\"vol\":',text1),charindex(',\"t-ts\"',text1)-charindex('\"vol\":',text1)),'\"vol\":','') as GlobalVolume
from #processedData
where text1 <>'' 
)Q
--where TransactionDate is not null and TransactionDate not like '%status%' 
--and isnumeric(OpenNumber)=1 and isnumeric(High)=1
--and isnumeric(Low)=1 and isnumeric(CloseNumber)=1 and isnumeric(BuyVolume)=1 and isnumeric(SellVolume)=1
order by 1





