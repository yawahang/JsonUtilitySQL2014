USE [MBL]
GO
/****** Object:  UserDefinedFunction [dbo].[SfJsonEscape]    Script Date: 26/03/2021 2:10:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Yawahang
-- Create date: 01/09/2021 
-- Description:	JSON Escape
-- =============================================
ALTER FUNCTION [dbo].SfJsonEscape
( @Value NVARCHAR (MAX))
RETURNS NVARCHAR (MAX)
AS
    BEGIN 
        IF ( @Value IS NULL )
            BEGIN
                RETURN 'null';
            END;
        IF ( TRY_PARSE(@Value AS FLOAT) IS NOT NULL )
            BEGIN
                RETURN @Value;
            END;

        SET @Value = REPLACE (@Value, '\', '\\');
        SET @Value = REPLACE (@Value, '"', '\"');

        RETURN '"' + @Value + '"';
    END;