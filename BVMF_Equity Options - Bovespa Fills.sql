
--WHAT ARE THE NEW PRODUCTS TRADED THIS MONTH ON BOVESPA (Market = 90) IN 7xASP
select distinct ProductName
  FROM [BIDW].[dbo].[Fills]
  where MarketId = 90 and year = 2018 and month = 4
  and IsBillable = 'Y'  
  and ProductName not in 
  (
  select distinct ProductName
  FROM [BIDW].[dbo].[Fills]
  where MarketId = 90 
  and IsBillable = 'Y'
  and year=2018 and month<=3
  --and month<>12
  UNION 
   select distinct ProductName
  FROM [BIDW].[dbo].[Fills]
  where MarketId = 90 
  and IsBillable = 'Y'
  and year<=2017
  )
  



  --FIND USERS WHO TRADED Equity Options
 SELECT DISTINCT
       UserName , accountid
FROM [BIDW].[dbo].[Fills]
WHERE MarketId = 90
      AND
      year = 2018
      AND
      month = 4
      AND
      IsBillable = 'Y'
      AND
      ProductName IN ( 'BBAS3' , 'BBDC3' , 'BBDC4' , 'BBSE3' , 'BRFS3' , 'BRML3' , 'BRPR3' , 'BVMF3' , 'CCRO3' , 'CIEL3' , 'CMIG4' , 'CRUZ3' , 'CSNA3' , 'EMBR3' , 'GGBR4' , 'HYPE3' , 'ITSA4' , 'ITUB3' , 'ITUB4' , 'JBSS3' , 'KLBN1' , 'KROT3' , 'LAME4' , 'MRFG3' , 'MRVE3' , 'PETR3' 
	 , 'SBSP3' , 'SUZB5' , 'TIMP3' , 'UGPA3' , 'USIM5' , 'VALE3' , 'VIVT4' , 'PETR4' , 'BOV11' , 'VALE5' , 'IDI' , 'ABEV3' , 'BBTG11' , 'BOVA11' , 'GGBR3' , 'GGBR4' , 'TIET11' , 'ALSC3' , 'BRSR6' , 'CPFE3' , 'CPLE6' , 'CYRE3' , 'ELET3' , 'ENBR3' , 'EQTL3' , 'EZTC3' , 'IGTA3' , 'RENT3'
	  , 'TRPL4' , 'CESP6' , 'EVEN3' , 'ALPA4' , 'BRAP3' , 'BRAP4' , 'BRKM3' , 'BRKM5' , 'CESP3' , 'CMIG3' , 'CPLE3' , 'ELET6' , 'GOAU3' , 'GOAU4' , 'ITSA3' , 'LAME3' , 'LAME4' , 'MULT3' , 'OIBR3' , 'OIBR4' , 'POMO3' , 'POMO4' , 'RAPT3' , 'RAPT4' , 'TBLE3' , 'VIVT3' , 'VIVT4' , 'SANB11' 
	  , 'SANB4' , 'XBOV11' , 'ALPA3' , 'CTIP3' , 'GRND3' , 'LIGT3' , 'LREN3' , 'MDIA3' , 'RADL3' , 'SBSP3' , 'TAEE11' , 'TIMP3' , 'SULA11' , 'ESTC3' , 'CVCB3' , 'TOTS3' , 'MYPK3' , 'DTEX3' , 'SMLE3' , 'CSMG3' , 'ITSA3F' , 'ITSA4F' , 'MPLU3' , 'NATU3F','CMIG4F','ELET3F','STBP3','VALE3F','VALE5F','BBDC4F',
       'JBSS3F','PETR4F','BEEF3F','BRAP4F','BRML3F','AMAR3','BVMF3F','NATU3','USIM5F','BBAS3F','GGBR4F','KROT3F','SANB11F','ABEV3F','BRFS3F','LAME4F','TIMP3F','CSMG3F','ELET6F','ESTC3F','FIBR3F','HYPE3F','ITUB4F'
       );




--FIND ALL FILLS FOR Users who traded EOs on Bovespa
SELECT Year,Month,UserName , AccountId , isEO , SUM(fills) AS Fills
FROM ( SELECT Year,Month,SUM(fills) AS fills , UserName , AccountId , [FillCategoryId]--,[DayofMonth]
       --,productname
,
CASE
    WHEN productname IN ( 'BBAS3' , 'BBDC3' , 'BBDC4' , 'BBSE3' , 'BRFS3' , 'BRML3' , 'BRPR3' , 'BVMF3' , 'CCRO3' , 'CIEL3' , 'CMIG4' , 'CRUZ3' , 'CSNA3' , 'EMBR3' , 'GGBR4' , 'HYPE3' , 'ITSA4' , 'ITUB3' , 'ITUB4' , 'JBSS3' , 'KLBN1' , 'KROT3' , 'LAME3' , 'LAME4' , 'MRFG3' , 'MRVE3' 
, 'PETR3' , 'SBSP3' , 'SUZB5' , 'TIMP3' , 'UGPA3' , 'USIM5' , 'VALE3' , 'VIVT3' , 'VIVT4' , 'PETR4' , 'BOV11' , 'VALE5' , 'IDI' , 'ABEV3' , 'BBTG11' , 'BOVA11' , 'GGBR3' , 'GGBR4' , 'TIET11' , 'ALSC3' , 'BRSR6' , 'CPFE3' , 'CPLE6' , 'CYRE3' , 'ELET3' , 'ENBR3' , 'EQTL3' , 'EZTC3' 
, 'IGTA3' , 'RENT3' , 'TRPL4' , 'CESP6' , 'EVEN3' , 'ALPA4' , 'BRAP3' , 'BRAP4' , 'BRKM3' , 'BRKM5' , 'CESP3' , 'CMIG3' , 'CPLE3' , 'ELET6' , 'GOAU3' , 'GOAU4' , 'ITSA3' , 'LAME3' , 'LAME4' , 'MULT3' , 'OIBR3' , 'OIBR4' , 'POMO3' , 'POMO4' , 'RAPT3' , 'RAPT4' , 'TBLE3' , 'VIVT3' 
, 'VIVT4' , 'SANB11' , 'SANB4' , 'XBOV11' , 'ALPA3' , 'CTIP3' , 'GRND3' , 'LIGT3' , 'LREN3' , 'MDIA3' , 'RADL3' , 'SBSP3' , 'TAEE11' , 'TIMP3' , 'SULA11' , 'ESTC3' , 'CVCB3' , 'TOTS3' , 'MYPK3' , 'DTEX3' , 'SMLE3' , 'CSMG3' , 'ITSA3F' , 'ITSA4F' , 'MPLU3' , 'NATU3F','CMIG4F','ELET3F','STBP3','VALE3F','VALE5F'
,'BEEF3F','BRAP4F','BRML3F','AMAR3','BVMF3F','NATU3','USIM5F','BBAS3F','GGBR4F','KROT3F','SANB11F','ABEV3F','BRFS3F','LAME4F','TIMP3F','CSMG3F','ELET6F','ESTC3F','FIBR3F','HYPE3F','ITUB4F'
                        )
    THEN 'EO'
    ELSE 'NotEO'
END AS 'isEO'
FROM [BIDW].[dbo].[Fills]
       WHERE year = 2018
             AND
             month = 4
             --and MarketId <> 90 
             AND
             IsBillable = 'Y'
             AND
             UserName IN ('ADOMICIANO','AYUJI', 'FELIPE' , 'RMENDES','LCOSSI'
                         )
       GROUP BY Year,Month,UserName , AccountId , [FillCategoryId] , productname--,[DayofMonth]
     ) AS Final
GROUP BY Year,Month,Username , accountid , isEO;



