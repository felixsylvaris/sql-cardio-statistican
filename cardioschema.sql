
-this is schema creation file
--drop old table
DROP TABLE IF EXISTS cardiovi;

--create new table
CREATE TABLE cardiovi (
    patientid INT PRIMARY KEY,

    age INT,

    gender SMALLINT,
    chestpain SMALLINT,
    restingBP INT,

    serumcholestrol INT,

    fastingbloodsugar SMALLINT,
    restingrelectro SMALLINT,

    maxheartrate INT,

    exerciseangia SMALLINT,

    oldpeak DECIMAL(4,1),

    slope SMALLINT,
    noofmajorvessels SMALLINT,

    target SMALLINT
);



--cheking records count
select count(*) from cardiovi;
--looking at out db
select * from cardiovi;

--checking for nulls
SELECT *
FROM cardiovi
WHERE
    patientid IS NULL OR
    age IS NULL OR
    gender IS NULL OR
    chestpain IS NULL OR
    restingBP IS NULL OR
    serumcholestrol IS NULL OR
    fastingbloodsugar IS NULL OR
    restingrelectro IS NULL OR
    maxheartrate IS NULL OR
    exerciseangia IS NULL OR
    oldpeak IS NULL OR
    slope IS NULL OR
    noofmajorvessels IS NULL OR
    target IS NULL;
