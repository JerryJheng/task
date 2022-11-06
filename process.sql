CREATE DATABASE  Processing;
USE Processing;

CREATE TABLE Test(
	Layer INT, ProcCode TEXT, SerialNum INT);
-- DROP TABLE Test;

SHOW VARIABLES LIKE "secure_file_priv";
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Process.csv' 
INTO TABLE Test 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY "\n"
IGNORE 1 ROWS;

SELECT * FROM Test
ORDER BY Layer DESC, SerialNum ASC;

CREATE TABLE Temp SELECT *, @tn :=@tn+1 AS TotalNum FROM Test,(SELECT @tn :=0) b
	 ORDER BY Layer DESC, SerialNum ASC;
-- DROP TABLE Temp;
SELECT * FROM Temp;
ALTER TABLE Temp ADD Selected INT;
SELECT * FROM Temp;

DELIMITER //
CREATE FUNCTION StateOfTotalNum(TotalNum INT, PreState INT) 
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE c INT;
    DECLARE pc TEXT;
	SELECT ProcCode From Temp WHERE Temp.TotalNum=TotalNum INTO pc;
    SELECT (CASE WHEN pc="CHGPTF" THEN 1 
					WHEN pc="CHGCLN" THEN 3 
                    WHEN (preState=1 OR prestate=2) THEN 2 
                    ELSE 0 END) INTO c;
    RETURN c;
END//

CREATE PROCEDURE forloop()
wholeblock:BEGIN
  DECLARE TotalNum INT;
  DECLARE PreState INT;
  SET TotalNum = 1;
  SET PreState =0;
  loop_label: LOOP
	IF TotalNum > (SELECT COUNT(*) FROM Temp) THEN LEAVE loop_label;
    END IF;
	SET PreState = (SELECT StateOfTotalNum(TotalNum, PreState));
    IF PreState=2 THEN
      UPDATE Temp SET Selected=1 WHERE Temp.TotalNum=TotalNum;
    END IF;
    SET TotalNum=TotalNum+1;
    ITERATE loop_label;
  END LOOP;
  SELECT * FROM Temp;
END//

CALL forloop()//
SELECT * FROM Temp WHERE Selected=1;//

WITH test1 AS (
SELECT *, @r:=@r+1 AS TotalNum FROM TEST,(SELECT @r:=0) b ORDER BY Layer DESC, SerialNum ASC)
SELECT * FROM test1 WHERE ProcCode="CHGPTF";
// DELIMITER ;


WITH A AS (SELECT *, @r:=@r+1 AS TotalNum, CASE WHEN ProcCode="CHGPTF" THEN 1 WHEN ProcCode="CHGCLN" THEN 3 END AS State FROM Test, (SELECT @r:=0) b ORDER BY Layer DESC, SerialNum ASC)
SELECT *,TotalNum+1 AS TotalNumOfPreState FROM A;

WITH E AS (
WITH C AS (
WITH A AS (SELECT *, @r:=@r+1 AS TotalNum, CASE WHEN ProcCode="CHGPTF" THEN 1 WHEN ProcCode="CHGCLN" THEN 3 END AS State, @rp:=@r+1 AS TotalNumOfPreState,@rpp:=@r-1 AS TotalNumOfPostState  FROM Test, (SELECT @r:=0) b ORDER BY Layer DESC, SerialNum ASC)
SELECT A.Layer,A.ProcCode,A.SerialNum,A.State, B.State AS PreState,A.TotalNum,A.TotalNumOfPostState FROM A LEFT JOIN A B ON A.TotalNum=B.TotalNumOfPreState
)
SELECT C.Layer,C.ProcCode,C.SerialNum,C.PreState, C.State, D.State AS PostState, C.TotalNum FROM C LEFT JOIN C D ON C.TotalNum=D.TotalNumOfPostState
)
SELECT * FROM E;

CREATE TEMPORARY TABLE TestData AS (
WITH C AS (
WITH A AS (SELECT *, @r:=@r+1 AS TotalNum, CASE WHEN ProcCode="CHGPTF" THEN 1 WHEN ProcCode="CHGCLN" THEN 3 END AS State, @rp:=@r+1 AS TotalNumOfPreState,@rpp:=@r-1 AS TotalNumOfPostState  FROM Test, (SELECT @r:=0) b ORDER BY Layer DESC, SerialNum ASC)
SELECT A.Layer,A.ProcCode,A.SerialNum,A.State, B.State AS PreState,A.TotalNum,A.TotalNumOfPostState FROM A LEFT JOIN A B ON A.TotalNum=B.TotalNumOfPreState
)
SELECT C.Layer,C.ProcCode,C.SerialNum,C.PreState, C.State, D.State AS PostState, C.TotalNum FROM C LEFT JOIN C D ON C.TotalNum=D.TotalNumOfPostState
);

DROP TABLE TestData;
SELECT * FROM TestData;

SELECT * FROM TestData WHERE FIND_IN_SET(State,'1,3')
