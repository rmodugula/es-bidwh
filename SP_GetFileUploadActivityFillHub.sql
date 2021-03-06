USE [BIDW]
GO
/****** Object:  StoredProcedure [dbo].[GetFileUploadActivityFillHub]    Script Date: 05/28/2014 11:03:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetFileUploadActivityFillHub]
( @Year int, @Month int)
     
AS
BEGIN


select A.Year,A.Month,(case when len(A.day)=1 then '0'+cast(A.day as char(2)) else cast(A.day as char(2)) end+'('+substring(datename(dw,A.ForDateName),1,3)+')') as DayName,
A.NetworkId,A.NetworkName,A.FileUploadId,FileUploadStatus,IpAddress as BillingServer,NetworkBillingServer
,AddedFillRecords,BillableFillRecords,AddedUserRecords, 
DateReceived as FillHubReceivedDate,StartTime as TBSFileStartTime,EndTime as TBSFileEndTime from
(
select year(starttime) as Year, Month(starttime) as Month,day(starttime) as Day,CAST(starttime as DATE) as ForDateName,DateReceivedCST as DateReceived,StartTime,EndTime,
FileUploadId,FileUploadStatus,NetworkId,NetworkName,IpAddress, NetworkName+'-'+IpAddress as NetworkBillingServer,FileFillRecords,FileUserRecords,AddedFillRecords,BillableFillRecords
,AddedUserRecords  from
(
SELECT [FileUploadId]
      ,[FileUploadStatus]
      ,[NetworkId]
      ,Name as NetworkName
      ,Starttime as DateReceivedCST
      ,datereceived
      ,[FileURL]
      ,[IpAddress]
      ,[ManualUpload]
      ,[StartTime] as StartTime
      ,[EndTime] as EndTime
      ,[MacAddress]
      ,[ServerId]
      ,[Version]
      , FileFillRecords
      ,FileUserRecords
      ,AddedFillRecords
      , BillableFillRecords
      ,AddedUserRecords
  FROM chisql12.[fillhub].[dbo].[FileUploads] FU left join chisql12.fillhub.dbo.LicenseFile N
  on FU.networkid=N.Shortname
)Q
where year(starttime)=@Year and month(starttime)=@Month
)A

union all

select A.Year,A.Month,(case when len(A.day)=1 then '0'+cast(A.day as char(2)) else cast(A.day as char(2)) end+'('+substring(datename(dw,A.ForDateName),1,3)+')') as DayName,
A.NetworkId,A.NetworkName,A.FileUploadId,FileUploadStatus,IpAddress as BillingServer,NetworkBillingServer
,AddedFillRecords,BillableFillRecords,AddedUserRecords,
DateReceived as FillHubReceivedDate,StartTime as TBSFileStartTime,EndTime as TBSFileEndTime from
(
select year(datereceived) as Year, Month(datereceived) as Month,day(datereceived) as Day,CAST(DateReceived as DATE) as ForDateName,DateReceived,
StartTime,EndTime,FileUploadId,FileUploadStatus,NetworkId,NetworkName,IpAddress, 
NetworkName+'-'+IpAddress as NetworkBillingServer,FileFillRecords,FileUserRecords,AddedFillRecords,BillableFillRecords,AddedUserRecords  from
(
SELECT [FileUploadId]
      ,[FileUploadStatus]
      ,[NetworkId]
      ,Name as NetworkName
      ,datereceived as DateReceived
      ,[FileURL]
      ,[IpAddress]
      ,[ManualUpload]
      ,datereceived as StartTime
      ,[EndTime] as EndTime
      ,[MacAddress] 
      ,[ServerId]
      ,[Version]
       , FileFillRecords
      ,FileUserRecords
      ,AddedFillRecords
      , BillableFillRecords
      ,AddedUserRecords
  FROM chisql12.[fillhub].[dbo].[FileUploads] FU left join chisql12.fillhub.dbo.LicenseFile N
  on FU.networkid=N.Shortname
  where starttime is null and FileUploadStatus not in ('UploadSessionStarted')
)Q
where year(DateReceived)=@Year and month(DateReceived)=@Month
)A 

End

