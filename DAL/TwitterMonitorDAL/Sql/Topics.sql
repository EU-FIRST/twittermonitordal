﻿/*REM*/ DECLARE @filterFlag INT = 1
/*REM*/ DECLARE @dateTimeStart DATETIME = '2012-01-01T00:00:00'
/*REM*/ DECLARE @dateTimeEnd DATETIME = '2012-02-01T00:00:00' 
--ADD DECLARE @filterFlag INT = {0}
--ADD DECLARE @dateTimeStart DATETIME = {1} 
--ADD DECLARE @dateTimeEnd DATETIME = {2}

  SELECT Topic.TopicId,
         Topic.NumDocs,
         Terms.Term,
         Terms.Weight
    FROM  (    SELECT /*REM*/ TOP 10
                     --ADD    TOP /*#NumTopics*/
                      Topic TopicId,
                      Sum(NumDocs) NumDocs
                FROM [AAPL_D_Clusters] Clusters
                WHERE Clusters.StartTime >= @dateTimeStart AND
                      Clusters.EndTime <= @dateTimeEnd
                      and Clusters.RecordState = 0
             GROUP BY Topic
             ORDER BY Sum(NumDocs) DESC
             ) AS Topic
        CROSS APPLY (
            SELECT /*REM*/ TOP 100
                    --ADD    TOP /*#NumTermsPerTopic*/
                    Min(MostFrequentForm) Term,
                    Sum(TFIDF) Weight
                FROM [AAPL_D_Clusters] Clusters
                    INNER JOIN [AAPL_D_Terms] Terms
                        ON (Clusters.Id = Terms.ClusterId)
                WHERE Clusters.StartTime >= @dateTimeStart AND
                    Clusters.EndTime <= @dateTimeEnd AND
                    Clusters.Topic = Topic.TopicId AND
                    ( 0=1
                    /*REM TermUnigram*/    OR @filterFlag/1%2=1  AND Terms.Hashtag = 0 AND Terms.Stock = 0 AND Terms.[User] = 0 AND Terms.NGram=0  
                    /*REM TermBigram*/     OR @filterFlag/2%2=1  AND Terms.Hashtag = 0 AND Terms.Stock = 0 AND Terms.[User] = 0 AND Terms.NGram=1  
                    /*REM UserUnigram*/    OR @filterFlag/4%2=1  AND Terms.Hashtag = 0 AND Terms.Stock = 0 AND Terms.[User] = 1 AND Terms.NGram=0  
                    /*REM HashtagUnigram*/ OR @filterFlag/8%2=1  AND Terms.Hashtag = 1 AND Terms.Stock = 0 AND Terms.[User] = 0 AND Terms.NGram=0  
                    /*REM HashtagBigram*/  OR @filterFlag/16%2=1 AND Terms.Hashtag = 1 AND Terms.Stock = 0 AND Terms.[User] = 0 AND Terms.NGram=1 
                    /*REM StockUnigram*/   OR @filterFlag/32%2=1 AND Terms.Hashtag = 0 AND Terms.Stock = 1 AND Terms.[User] = 0 AND Terms.NGram=0 
                    /*REM StockBigram*/    OR @filterFlag/64%2=1 AND Terms.Hashtag = 0 AND Terms.Stock = 1 AND Terms.[User] = 0 AND Terms.NGram=1 
                    )
                    and Clusters.RecordState = 0 and Terms.RecordState = 0

            GROUP BY StemHash
            ORDER BY Sum(TFIDF) DESC
            ) AS Terms




