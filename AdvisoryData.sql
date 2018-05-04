SELECT  A.[AdvisoryId]
      ,[AdvisoryTypeId]
      ,[AdvisoryStatusEnum]
      ,B.[Subject]
      ,[CreatedDate] as BroadcastCreatedDate
      ,A.[BroadcastDate] as EndBroadcastDate
	  ,B.BroadcastDate as StartBroadcastDate
      ,[BroadcastUser]
      ,[BroadcastAdvisoryNumber]
      ,[BroadcastAdvisoryId]
      ,[EmailPriorityEnum]
      ,[IsShelved]
      ,[IsFollowup]
      ,[FollowupAdvisoryId]
  FROM [AdvisorySystem].[dbo].[Advisory] A
  Left join
  (
    select Distinct AdvisoryId,Subject,BroadcastDate FROM [AdvisorySystem].[dbo].[Advisory]
   )B on A.FollowupAdvisoryId=B.AdvisoryId
  where IsFollowup=1 and AdvisoryTypeId in (19,13,18,12,15,28)
  and cast(A.BroadcastDate as date)>='2017-09-01'
