SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================
-- Author:		Yawahang
-- Create date: 01/09/2021
-- JSON Support for SQL Server <= 2014
-- Description:	replacement for JSON_QUERY
-- =============================================
CREATE FUNCTION utl.SfJSON_QUERY
(   @Json NVARCHAR (MAX) ,
    @Key VARCHAR (MAX))
RETURNS NVARCHAR (MAX)
AS
    BEGIN
        DECLARE @Value NVARCHAR (MAX);

        IF ( LEN (@Json) > 0 )
            BEGIN
                DECLARE @tempJsonArr TABLE
                (   Id INT NOT NULL ,
                    [valueJson] NVARCHAR (MAX));

                DECLARE @tempJson TABLE
                (   Id INT NOT NULL ,
                    [valueJson] NVARCHAR (MAX) ,
                    [Key] VARCHAR (MAX) ,
                    [Value] NVARCHAR (MAX));

                IF @Json LIKE '[[]%' -- Json Array
                    BEGIN;
                        WITH a
                        AS ( SELECT 0 AS Id ,
                                    -1 AS i ,
                                    0 AS j
                             UNION ALL
                             SELECT Id + 1 ,
                                    j ,
                                    CHARINDEX ('},', @Json, j + 1)
                             FROM   a
                             WHERE  j > i ) ,
                             jRow
                        AS ( SELECT Id ,
                                    SUBSTRING (@Json, i + 1, IIF(j > 0, j, LEN (@Json) + 1) - i - 1) AS [value]
                             FROM   a
                             WHERE  i >= 0 )
                        INSERT @tempJsonArr ( Id ,
                                              valueJson )
                               SELECT jr.Id ,
                                      jr.[value]
                               FROM   jRow AS jr;

                        -- Update Invalid Json Objects 
                        UPDATE tja
                        SET    tja.valueJson = REPLACE (REPLACE (REPLACE (tja.valueJson, ',{', '{'), '[{', '{'), '}]', '}')
                        FROM   @tempJsonArr AS tja
                        WHERE  tja.valueJson NOT LIKE '%}';

                        UPDATE tja
                        SET    tja.valueJson = CONCAT (tja.valueJson, '}')
                        FROM   @tempJsonArr AS tja
                        WHERE  tja.valueJson NOT LIKE '%}';

                        -- Json Object for Json Array
                        UPDATE tja
                        SET    tja.valueJson = REPLACE (
                                                   REPLACE (REPLACE (tja.valueJson, ']', ''), '"}]', '"}'), '[{"', '{"')
                        FROM   @tempJsonArr AS tja;

                        SELECT *
                        FROM   @tempJsonArr AS tja;
                    END;
                ELSE
                    BEGIN
                        SELECT @Value = @Json;
                    END;

                --- Split JSON Single Object index and value 
                DECLARE @Id INT = 1 ,
                        @MaxId INT;;
                SELECT @MaxId = MAX (tja.Id)
                FROM   @tempJsonArr AS tja;

                WHILE @Id <= @MaxId
                    BEGIN;

                        SELECT @Json = tja.valueJson
                        FROM   @tempJsonArr AS tja
                        WHERE  tja.Id = @Id;

                        WITH a
                        AS ( SELECT 0 AS Id ,
                                    -1 AS i ,
                                    0 AS j
                             UNION ALL
                             SELECT Id + 1 ,
                                    j ,
                                    CHARINDEX ('","', @Json, j + 1)
                             FROM   a
                             WHERE  j > i ) ,
                             jRow
                        AS ( SELECT Id ,
                                    SUBSTRING (@Json, i + 1, IIF(j > 0, j, LEN (@Json) + 1) - i - 1) AS [value]
                             FROM   a
                             WHERE  i >= 0 )
                        INSERT @tempJson ( Id ,
                                           [valueJson] )
                               SELECT jr.Id ,
                                      jr.[value]
                               FROM   jRow AS jr;

                        SELECT @Id = @Id + 1;
                    END;


                --- Json Key Value Pair
                UPDATE tj
                SET    tj.[Key] = REPLACE (
                                      REPLACE (SUBSTRING (tj.valueJson, 0, CHARINDEX ('":"', tj.valueJson)), ',"', '') ,
                                      '{"' ,
                                      '') ,
                       tj.[Value] = REPLACE (
                                        SUBSTRING (tj.valueJson, CHARINDEX (':"', tj.valueJson) + 2, LEN (tj.valueJson)) ,
                                        '"}' ,
                                        '')
                FROM   @tempJson AS tj;


                SELECT @Value = tj.Value
                FROM   @tempJson AS tj
                WHERE  tj.[Key] = @Key;
            END;

        RETURN @Value;
    END;