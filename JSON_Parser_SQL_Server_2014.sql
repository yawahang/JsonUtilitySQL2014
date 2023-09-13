-- JSON Single Object
DECLARE @Json NVARCHAR (4000) = N'{"Username":"admin@mr.com","Password":"admin@123", "OrgCode":"mr"}';
DECLARE @Key VARCHAR (MAX);
SELECT @Key = 'Username';
-----------------
DECLARE @tempJsonArr TABLE
(   Id INT NOT NULL ,
    [valueJson] NVARCHAR (MAX));

DECLARE @tempJson TABLE
(   Id INT NOT NULL ,
    [valueJson] NVARCHAR (MAX) ,
	[valueJsonMap] NVARCHAR (MAX) NULL,
    [Key] VARCHAR (MAX) ,
    [Value] NVARCHAR (MAX));

----------------------------------------
----------------------------------------
------- JSON_VALUE
----------------------------------------
---------------------------------------- 
SELECT '------- JSON_VALUE -------';
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
SET    tj.[Key] = REPLACE (REPLACE (SUBSTRING (tj.valueJson, 0, CHARINDEX ('":"', tj.valueJson)), '"', ''), '{', '') ,
       tj.[Value] = REPLACE (
                        REPLACE (SUBSTRING (tj.valueJson, CHARINDEX (':"', tj.valueJson) + 2, LEN (tj.valueJson)), '"', '') ,
                        '}' ,
                        '')
FROM   @tempJson AS tj;
 
SELECT tj.Value
FROM   @tempJson AS tj
WHERE  tj.[Key] = @Key;

----------------------------------------
----------------------------------------
------- JSON_QUERY
----------------------------------------
----------------------------------------
DELETE t
FROM   @tempJson t;
DELETE tja
FROM   @tempJsonArr AS tja;
SELECT '------- JSON_QUERY -------';
SELECT @Json = N'{"UserListDet":[{"Username":"admin@mr.com","Password":"admin@123"}],"User":{"Username":"admin@mr.com","Password":"admin@123"},"UserList":[{"Username":"admin@mr.com","Password":"admin@123"}]}';
SELECT @Key = 'User';
IF LEN (@Json) > 0 -- Json Object
    BEGIN;
        WITH jObj
        AS ( SELECT 0 AS Id ,
                    -1 AS i ,
                    0 AS j
             UNION ALL
             SELECT Id + 1 ,
                    j ,
                    CHARINDEX ('},', @Json, j + 1)
             FROM   jObj
             WHERE  j > i ) ,
             jRow
        AS ( SELECT Id ,
                    SUBSTRING (@Json, i + 1, IIF(j > 0, j, LEN (@Json) + 1) - i - 1) AS [value]
             FROM   jObj
             WHERE  i >= 0 )
        INSERT @tempJson ( Id ,
                           valueJson,
						   valueJsonMap)
               SELECT jr.Id ,
                      jr.[value],
                      jr.[value]
               FROM   jRow AS jr;

        -- Update Invalid Json Objects 
        UPDATE tja
        SET    tja.valueJsonMap = REPLACE (REPLACE (REPLACE (tja.valueJsonMap, ',"', '"'), ',{', '{'), '}}', '}')
        FROM   @tempJson AS tja
        WHERE  tja.valueJsonMap NOT LIKE '%}';

        UPDATE tja
        SET    tja.valueJsonMap = CONCAT (tja.valueJsonMap, '}')
        FROM   @tempJson AS tja
        WHERE  tja.valueJsonMap NOT LIKE '%}';

        UPDATE tja
        SET    tja.valueJsonMap = CONCAT ('{', tja.valueJsonMap)
        FROM   @tempJson AS tja
        WHERE  tja.valueJsonMap NOT LIKE '{%';

        -- Json Object for Json Array 
        UPDATE tja
        SET    tja.valueJson = tja.valueJsonMap
        FROM   @tempJson AS tja;

        UPDATE tja
        SET    tja.valueJsonMap = REPLACE (
                                   REPLACE (REPLACE (REPLACE (tja.valueJsonMap, '{,"', '{"'), ']', ''), '"}]', '"}') ,
                                   '[{"' ,
                                   '{"')
        FROM   @tempJson AS tja;	 
    END;
ELSE
    BEGIN
        SELECT 'Invalid JSON';
    END;

--- Json Key Value Pair
UPDATE tj
SET    tj.[Key] = REPLACE (REPLACE (SUBSTRING (tj.valueJsonMap, 0, CHARINDEX ('":{', tj.valueJsonMap)), '{"', ''), ',"', '') ,
       tj.[Value] = REPLACE (
                        REPLACE (
                            SUBSTRING (tj.valueJson, CHARINDEX ('{"', tj.valueJson), LEN (tj.valueJson)), '}}', '}') ,
                        ':{' ,
                        '{')
FROM   @tempJson AS tj;


SELECT *
FROM   @tempJson AS tja;

SELECT tj.Value
FROM   @tempJson AS tj
WHERE  tj.[Key] = @Key;

SELECT @Key = 'UserList';
SELECT tj.Value
FROM   @tempJson AS tj
WHERE  tj.[Key] = @Key;


----------------------------------------
----------------------------------------
------- OPENJSON
----------------------------------------
---------------------------------------- 
DELETE t
FROM   @tempJson t;
DELETE tja
FROM   @tempJsonArr AS tja;
SELECT '------- OPENJSON -------';
SELECT @Json = N'[{"Username":"admin@mr.com","Password":"admin@123", "OrgCode":"mr"},{"Username":"admin@mr.com","Password":"admin@123", "OrgCode":"mr"}]';
IF @Json LIKE '[[]%' -- Json Array
    BEGIN;
        WITH jObj
        AS ( SELECT 0 AS Id ,
                    -1 AS i ,
                    0 AS j
             UNION ALL
             SELECT Id + 1 ,
                    j ,
                    CHARINDEX ('},', @Json, j + 1)
             FROM   jObj
             WHERE  j > i ) ,
             jRow
        AS ( SELECT Id ,
                    SUBSTRING (@Json, i + 1, IIF(j > 0, j, LEN (@Json) + 1) - i - 1) AS [value]
             FROM   jObj
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
        SET    tja.valueJson = REPLACE (REPLACE (REPLACE (tja.valueJson, ']', ''), '"}]', '"}'), '[{"', '{"')
        FROM   @tempJsonArr AS tja;
    END;
ELSE
    BEGIN
        SELECT 'Invalid JSON';
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

        WITH jObj
        AS ( SELECT 0 AS Id ,
                    -1 AS i ,
                    0 AS j
             UNION ALL
             SELECT Id + 1 ,
                    j ,
                    CHARINDEX ('","', @Json, j + 1)
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
                      jr.[value]
               FROM   jRow AS jr;

        SELECT @Id = @Id + 1;
    END;


--- Json Key Value Pair
UPDATE tj
SET    tj.[Key] = REPLACE (REPLACE (SUBSTRING (tj.valueJson, 0, CHARINDEX ('":"', tj.valueJson)), ',"', ''), '{"', '') ,
       tj.[Value] = REPLACE (SUBSTRING (tj.valueJson, CHARINDEX (':"', tj.valueJson) + 2, LEN (tj.valueJson)), '"}', '')
FROM   @tempJson AS tj;

SELECT *
FROM   @tempJsonArr AS tja;
SELECT *
FROM   @tempJson AS tj;

----------------------------------------
----------------------------------------
------- FORJSON
----------------------------------------
---------------------------------------- 
DELETE t
FROM   @tempJson t;
DELETE tja
FROM   @tempJsonArr AS tja;
SELECT '------- FORJSON -------';
SELECT @Json = N'[{"Username":"admin@mr.com","Password":"admin@123", "OrgCode":"mr"},{"Username":"admin@mr.com","Password":"admin@123", "OrgCode":"mr"}]';
