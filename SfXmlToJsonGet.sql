USE [MBL]
GO
/****** Object:  UserDefinedFunction [dbo].[SfXmlToJsonGet]    Script Date: 26/03/2021 2:11:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Yawahang
-- Create date: 01/09/2021 
-- Description:	XML to JSON
-- =============================================
ALTER FUNCTION [dbo].SfXmlToJsonGet
( @XmlData XML )
RETURNS NVARCHAR (MAX)
AS
    BEGIN
        DECLARE @Json NVARCHAR (MAX);
        SELECT @Json = N'['
                       + STUFF (
        ( SELECT theLine
          FROM   ( SELECT ',' + ' {'
                          + STUFF (
        ( SELECT ',"' + COALESCE (b.c.value ('local-name(.)', 'NVARCHAR(255)'), '') + '":'
                 + CASE WHEN b.c.value ('count(*)', 'int') = 0 THEN
                            dbo.SfJsonEscape (b.c.value ('text()[1]', 'NVARCHAR(MAX)'))
                        ELSE dbo.SfXmlToJsonGet (b.c.query ('*'))
                   END
          FROM   x.a.nodes ('*') b(c)
        FOR XML PATH (''), TYPE ).value ('(./text())[1]', 'NVARCHAR(MAX)') ,
        1        ,
        1        ,
        ''       )      + '}'
                   FROM   @XmlData.nodes('/*') x(a) ) JSON(theLine)
        FOR XML PATH (''), TYPE ).value ('.', 'NVARCHAR(MAX)') ,
        1   ,
        1   ,
        ''  )          + N']';
        RETURN @Json;
    END;
