USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateOrderSourceHistory]    Script Date: 3/2/2015 3:17:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[SP_UpdateOrderSourceHistory]
 @Year int,
 @Month int

  
AS
BEGIN
declare @S int;
declare @E int;
declare @I int;
declare @j char;
declare @k char;


SET @s = 0
SET @E = 9
SET @I = @s
--set @j = 
--case 
--when @s=0 then 00 
--when @s=1 then 01
--when @s=2 then 02
--when @s=3 then 03
--end


while 
@I <= @E
Begin
select @k=@I
select @j = (case 
				when @I=0 then '00'
				when @I=1 then 01
				when @I=2 then 02
				when @I=3 then 03
				when @I=4 then 04 
				when @I=5 then 05
				when @I=6 then 06
				when @I=7 then 07
				when @I=8 then 08 
				when @I=9 then 09
				end)

--select distinct @I,@k,@j from dbo.Fills_copy

--select * from dbo.Fills_copy
--where OrderSourceHistory like 
--case when @k=0 then '0,%'
--end
 update dbo.Fills
 set OrderSourceHistory='0'+ OrderSourceHistory
 where OrderSourceHistory <>''
	and OrderSourceHistory like 
								(case 
								when @k=0 then '0,%'
								when @k=1 then '1,%'
								when @k=2 then '2,%'
								when @k=3 then '3,%'
								when @k=4 then '4,%'
								when @k=5 then '5,%'
								when @k=6 then '6,%'
								when @k=7 then '7,%'
								when @k=8 then '8,%'
								when @k=9 then '9,%'
							end)
	
update dbo.Fills
 set OrderSourceHistory= 
 (case 
	when @k=0 and @j= 00 then REPLACE(OrderSourceHistory,',0,',',00,')
	when @k=1 and @j= 01  then REPLACE(OrderSourceHistory,',1,',',01,')
	when @k=2 and @j= 02 then REPLACE(OrderSourceHistory,',2,',',02,')
	when @k=3 and @j= 03 then REPLACE(OrderSourceHistory,',3,',',03,')
	when @k=4 and @j= 04 then REPLACE(OrderSourceHistory,',4,',',04,')
	when @k=5 and @j= 05 then REPLACE(OrderSourceHistory,',5,',',05,')
	when @k=6 and @j= 06 then REPLACE(OrderSourceHistory,',6,',',06,')
	when @k=7 and @j= 07 then REPLACE(OrderSourceHistory,',7,',',07,')
	when @k=8 and @j= 08 then REPLACE(OrderSourceHistory,',8,',',08,')
	when @k=9 and @j= 09 then REPLACE(OrderSourceHistory,',9,',',09,')
end)
 where OrderSourceHistory <>''
	and OrderSourceHistory like (case 
									when @k=0 then '%,0,%'
									when @k=1 then '%,1,%'
									when @k=2 then '%,2,%'
									when @k=3 then '%,3,%'
									when @k=4 then '%,4,%'
									when @k=5 then '%,5,%'
									when @k=6 then '%,6,%'
									when @k=7 then '%,7,%'
									when @k=8 then '%,8,%'
									when @k=9 then '%,9,%'
								end)
	
	SET @I = @I+1

end
 update dbo.Fills
	set OrderSourceHistory='0'+ OrderSourceHistory
	where OrderSourceHistory <>''
	and len(OrderSourceHistory)=1


/*******************************************Updated MDT and Functionality Area Columns***********************************************************************/
update dbo.Fills
set MDT=CASE WHEN [OrderSourceHistory] like '%15%' THEN 'MDT' ELSE 'non-MDT' END
where YEAR = @Year and Month=@Month


update dbo.fills
set FunctionalityArea=(
CASE 
            WHEN [FirstOrderSource] = 9 OR ([OrderSourceHistory] like '%09%' AND ([OrderSourceHistory] like '%11%' OR [OrderSourceHistory] like '%12%' OR [OrderSourceHistory] like '%19%' OR [OrderSourceHistory] like '%21%')) THEN 'Autospreader - ServerSide'
            WHEN [OrderSourceHistory] like '%01%' THEN 'Autospreader - Desktop' 
            WHEN [OrderSourceHistory] like '%22%' or ([OrderSourceHistory] like '%12%' and [OrderSourceHistory] not like '%09%') THEN 'AlgoSE' 
            WHEN [OrderSourceHistory] like '%02%' THEN 'Autotrader' 
            WHEN [FirstOrderSource] IN (6,23) THEN 'FIX Adapter'
            WHEN [OrderSourceHistory] like '%20%' OR [OrderSourceHistory] like '%24%' THEN 'SSE' 
            WHEN [FirstOrderSource] = 3 THEN 'XTAPI'
            WHEN [FirstOrderSource] IN (11,21) THEN 'TT API'
            WHEN OrderSourceHistory NOT LIKE '%24%'
            AND  OrderSourceHistory NOT LIKE '%23%'
            AND  OrderSourceHistory NOT LIKE '%22%'
            AND  OrderSourceHistory NOT LIKE '%21%'      
            AND  OrderSourceHistory NOT LIKE '%20%'
            AND  OrderSourceHistory NOT LIKE '%19%'
            AND  OrderSourceHistory NOT LIKE '%12%'
            AND  OrderSourceHistory NOT LIKE '%11%'                                    
            AND  OrderSourceHistory NOT LIKE '%09%'                                                                                   
            AND  OrderSourceHistory NOT LIKE '%01%'                                                                                                                                   
            AND  OrderSourceHistory NOT LIKE '%02%'                                     
            AND  OrderSourceHistory NOT LIKE '%06%'                           
			THEN 'Non-Automated' 
			When OrderSourceHistory LIKE '%23%' then 'FIX Adapter - Staged Orders'
			ELSE 'Needs a rule'
		END)
where YEAR = @Year and Month=@Month

/*************************************************************************************************************************************************************/
end

