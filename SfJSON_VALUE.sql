SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
-- =============================================
-- Author:		Yawahang
-- Create date: 01/09/2021
-- JSON Support for SQL Server <= 2014
-- Description:	replacement for JSON_VALUE
-- =============================================
CREATE FUNCTION utl.SfJSON_VALUE
(   @Json NVARCHAR (MAX) ,
    @Key VARCHAR (MAX))
RETURNS NVARCHAR (MAX)
AS
    BEGIN
        DECLARE @Value NVARCHAR (MAX);

        IF ( LEN (@Json) > 0 )
            BEGIN
                DECLARE @tempJson TABLE
                (   Id INT NOT NULL ,
                    [valueJson] NVARCHAR (MAX) NOT NULL ,
                    [Key] VARCHAR (MAX) NOT NULL ,
                    [Value] NVARCHAR (MAX) NULL );

                IF @Json LIKE '[[]%' -- Json Array
                    BEGIN;
                        SELECT @Value = @Json;
                    END;
                ELSE
                    BEGIN; --- Split JSON Single Object index and value  
                        WITH jObj
                        AS ( SELECT 0 AS Id ,
                                    -1 AS i ,
                                    0 AS j
                             UNION ALL
                             SELECT Id + 1 ,
                                    j ,
                                    CHARINDEX (',', @Json, j + 1)
                             FROM   jObj
                             WHERE  j > i ) ,
                             jRow
                        AS ( SELECT Id ,
                                    SUBSTRING (@Json, i + 1, IIF(j > 0, j, LEN (@Json) + 1) - i - 1) AS [value]
                             FROM   jObj
                             WHERE  i >= 0 )
                        INSERT @tempJson ( Id ,
                                           [valueJson] )
                               SELECT jr.Id ,
                                      jr.value
                               FROM   jRow AS jr;

                        --- Json Key Value Pair
                        UPDATE tj
                        SET    tj.[Key] = REPLACE (
                                              REPLACE (
                                                  SUBSTRING (tj.valueJson, 0, CHARINDEX ('":"', tj.valueJson)), '"', '') ,
                                              '{' ,
                                              '') ,
                               tj.[Value] = REPLACE (
                                                REPLACE (
                                                    SUBSTRING (
                                                        tj.valueJson ,
                                                        CHARINDEX (':"', tj.valueJson) + 2,
                                                        LEN (tj.valueJson)) ,
                                                    '"' ,
                                                    '') ,
                                                '}' ,
                                                '')
                        FROM   @tempJson AS tj;

                    END;

                SELECT @Value = tj.Value
                FROM   @tempJson AS tj
                WHERE  tj.[Key] = @Key;
            END;

        RETURN @Value;
    END;