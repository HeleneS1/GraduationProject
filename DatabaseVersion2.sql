-- Create staging area hospitals. DONE
create table if not exists database2.hospital_stage 
(hosp_id serial primary key, 
hosp_name varchar(255),
hosp_city varchar(255),
hosp_name_city varchar (255), 
hosp_lat numeric,
hosp_long numeric);

--drop table database2.hospital_stage ;

--Create staging accident NEARLY DONE
create table if not exists database2.accident_stage
(acc_id integer primary key, 
url varchar(255),
weekday varchar(255),
date varchar(255),
time varchar(255), 
police_district varchar(255),
accident_category varchar(255),
killed_ct integer,
very_seriously_injured_ct integer, 
serious_injured_ct integer,
injured_ct integer,
severity varchar(255), 
road_type varchar(255),
area_type varchar(255),
road_surface varchar(255),
driving_condition varchar(255), 
weather_condition varchar(255),
lighting_condition varchar(255),
lane_type varchar(255),
lane_numbers integer,
speed_limit integer, 
temperature integer,
loc_lat numeric,
loc_long numeric ); 

--change datatype on date in accident_stage (to match d_date)
update database2.accident_stage set date = replace(date, '-', '');
alter table database2.accident_stage alter column date type int using(date::int);

drop table database2.accident_stage;

-- Create staging: Closest hospital for each accident DONE
create table if not exists database2.closest_hosp
(id serial primary key,
acc_id integer,
hosp_id integer,
distance integer); 

-- drop table database2.closest_hosp;

--Create starschema: dimension date DONE

CREATE TABLE d_date
(
  date_dim_id              INT NOT NULL,
  date_actual              DATE NOT NULL,
  epoch                    BIGINT NOT NULL,
  day_suffix               VARCHAR(4) NOT NULL,
  day_name                 VARCHAR(9) NOT NULL,
  day_of_week              INT NOT NULL,
  day_of_month             INT NOT NULL,
  day_of_quarter           INT NOT NULL,
  day_of_year              INT NOT NULL,
  week_of_month            INT NOT NULL,
  week_of_year             INT NOT NULL,
  week_of_year_iso         CHAR(10) NOT NULL,
  month_actual             INT NOT NULL,
  month_name               VARCHAR(9) NOT NULL,
  month_name_abbreviated   CHAR(3) NOT NULL,
  quarter_actual           INT NOT NULL,
  quarter_name             VARCHAR(9) NOT NULL,
  year_actual              INT NOT NULL,
  first_day_of_week        DATE NOT NULL,
  last_day_of_week         DATE NOT NULL,
  first_day_of_month       DATE NOT NULL,
  last_day_of_month        DATE NOT NULL,
  first_day_of_quarter     DATE NOT NULL,
  last_day_of_quarter      DATE NOT NULL,
  first_day_of_year        DATE NOT NULL,
  last_day_of_year         DATE NOT NULL,
  mmyyyy                   CHAR(6) NOT NULL,
  mmddyyyy                 CHAR(10) NOT NULL,
  weekend_indr             BOOLEAN NOT NULL
);

ALTER TABLE database2.d_date ADD CONSTRAINT d_date_date_dim_id_pk PRIMARY KEY (date_dim_id);

CREATE INDEX d_date_date_actual_idx
  ON d_date(date_actual);

COMMIT;

-- Insert into d_date dimension DONE

INSERT INTO d_date
SELECT TO_CHAR(datum,'yyyymmdd')::INT AS date_dim_id,
       datum AS date_actual,
       EXTRACT(epoch FROM datum) AS epoch,
       TO_CHAR(datum,'fmDDth') AS day_suffix,
       TO_CHAR(datum,'Day') AS day_name,
       EXTRACT(isodow FROM datum) AS day_of_week,
       EXTRACT(DAY FROM datum) AS day_of_month,
       datum - DATE_TRUNC('quarter',datum)::DATE +1 AS day_of_quarter,
       EXTRACT(doy FROM datum) AS day_of_year,
       TO_CHAR(datum,'W')::INT AS week_of_month,
       EXTRACT(week FROM datum) AS week_of_year,
       TO_CHAR(datum,'YYYY"-W"IW-') || EXTRACT(isodow FROM datum) AS week_of_year_iso,
       EXTRACT(MONTH FROM datum) AS month_actual,
       TO_CHAR(datum,'Month') AS month_name,
       TO_CHAR(datum,'Mon') AS month_name_abbreviated,
       EXTRACT(quarter FROM datum) AS quarter_actual,
       CASE
         WHEN EXTRACT(quarter FROM datum) = 1 THEN 'First'
         WHEN EXTRACT(quarter FROM datum) = 2 THEN 'Second'
         WHEN EXTRACT(quarter FROM datum) = 3 THEN 'Third'
         WHEN EXTRACT(quarter FROM datum) = 4 THEN 'Fourth'
       END AS quarter_name,
       EXTRACT(isoyear FROM datum) AS year_actual,
       datum +(1 -EXTRACT(isodow FROM datum))::INT AS first_day_of_week,
       datum +(7 -EXTRACT(isodow FROM datum))::INT AS last_day_of_week,
       datum +(1 -EXTRACT(DAY FROM datum))::INT AS first_day_of_month,
       (DATE_TRUNC('MONTH',datum) +INTERVAL '1 MONTH - 1 day')::DATE AS last_day_of_month,
       DATE_TRUNC('quarter',datum)::DATE AS first_day_of_quarter,
       (DATE_TRUNC('quarter',datum) +INTERVAL '3 MONTH - 1 day')::DATE AS last_day_of_quarter,
       TO_DATE(EXTRACT(isoyear FROM datum) || '-01-01','YYYY-MM-DD') AS first_day_of_year,
       TO_DATE(EXTRACT(isoyear FROM datum) || '-12-31','YYYY-MM-DD') AS last_day_of_year,
       TO_CHAR(datum,'mmyyyy') AS mmyyyy,
       TO_CHAR(datum,'mmddyyyy') AS mmddyyyy,
       CASE
         WHEN EXTRACT(isodow FROM datum) IN (6,7) THEN TRUE
         ELSE FALSE
       END AS weekend_indr
FROM (SELECT '2010-01-01'::DATE+ SEQUENCE.DAY AS datum
      FROM GENERATE_SERIES (0,29219) AS SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;

select * from d_date;
--drop table d_date; 

--Create timedimesion  DONE

CREATE table database2.time (
    id int4 NOT NULL,
    time time,
    hour int2,
    military_hour int2,
    minute int4,
    second int4,
    minute_of_day int4,
    second_of_day int4,
    quarter_hour varchar,
    am_pm varchar,
    day_night varchar,
    day_night_abbrev varchar,
    time_period varchar,
    time_period_abbrev varchar
)
WITH (OIDS=FALSE);

--Populate time DONE

INSERT INTO database2.time
SELECT
  to_char(datum, 'HH24MISS')::integer AS id,
  datum::time AS time,
  to_char(datum, 'HH12')::integer AS hour,
  to_char(datum, 'HH24')::integer AS military_hour,
  extract(minute FROM datum)::integer AS minute,
  extract(second FROM datum) AS second,
  to_char(datum, 'SSSS')::integer / 60 AS minute_of_day,
  to_char(datum, 'SSSS')::integer AS second_of_day,
  to_char(datum - (extract(minute FROM datum)::integer % 15 || 'minutes')::interval, 'hh24:mi') ||
  ' � ' ||
  to_char(datum - (extract(minute FROM datum)::integer % 15 || 'minutes')::interval + '14 minutes'::interval, 'hh24:mi')
    AS quarter_hour,
  to_char(datum, 'AM') AS am_pm,
  CASE WHEN to_char(datum, 'hh24:mi') BETWEEN '08:00' AND '19:59' THEN 'Day (8AM-8PM)' ELSE 'Night (8PM-8AM)' END
  AS day_night,
  CASE WHEN to_char(datum, 'hh24:mi') BETWEEN '08:00' AND '19:59' THEN 'Day' ELSE 'Night' END
  AS day_night_abbrev,
  CASE
  WHEN to_char(datum, 'hh24:mi') BETWEEN '00:00' AND '03:59' THEN 'Late Night (Midnight-4AM)'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '04:00' AND '07:59' THEN 'Early Morning (4AM-8AM)'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '08:00' AND '11:59' THEN 'Morning (8AM-Noon)'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '12:00' AND '15:59' THEN 'Afternoon (Noon-4PM)'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '16:00' AND '19:59' THEN 'Evening (4PM-8PM)'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '20:00' AND '23:59' THEN 'Night (8PM-Midnight)'
  END AS time_period,
  CASE
  WHEN to_char(datum, 'hh24:mi') BETWEEN '00:00' AND '03:59' THEN 'Late Night'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '04:00' AND '07:59' THEN 'Early Morning'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '08:00' AND '11:59' THEN 'Morning'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '12:00' AND '15:59' THEN 'Afternoon'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '16:00' AND '19:59' THEN 'Evening'
  WHEN to_char(datum, 'hh24:mi') BETWEEN '20:00' AND '23:59' THEN 'Night'
  END AS time_period_abbrev
FROM generate_series('2000-01-01 00:00:00'::timestamp, '2000-01-01 23:59:59'::timestamp, '1 hour') datum;

select * from database2.time; 

--Create dimension: hospital
create table if not exists database2.d_hospital
(hosp_id serial primary key, 
hosp_name varchar(255),
hosp_city varchar(255), 
hosp_name_city varchar(255), 
hosp_lat numeric,
hosp_long numeric) ;

--drop table database2.d_hospital; 

--Create dimension location
create table if not exists database2.d_location
(loc_id serial primary key, 
loc_lat numeric,
loc_long numeric) 
; 
--drop table database2.d_location; 

--Create conditions_d 
create table if not exists database2.d_conditions
(con_id serial primary key,
driving_condition varchar,
weather_conditions varchar, 
lighting_condition varchar,
speed_limit integer,
temperature integer);

drop table database2.conditions ;

--Create fact-table 
create table if not exists database2.fact_accident(
acc_sid serial primary key,
date_sid integer references database2.d_date(date_dim_id),
loc_sid integer references database2.d_location(loc_id),
hosp_sid integer references database2.d_hospital(hosp_id),
con_sid integer references database2.conditions(con_id),
killed_ct integer,
very_seriously_injured_ct integer, 
serious_injured_ct integer, 
injured_ct integer,
distance numeric,
sv_acc_id integer) ; 

select * from database2."time" t;

--drop table database2.fact_accident;

-------------------------------------------------------------------------------------

-- Insert into d_location;
insert into database2.d_location(loc_lat, loc_long) 
select loc_lat, loc_long from database2.accident_stage;


--Insert into d_hospital
insert into database2.d_hospital (hosp_name, hosp_city, hosp_lat, hosp_long)
select hosp_name, hosp_city, hosp_lat, hosp_long from database2.hospital_stage ;

--insert into conditions
insert into database2.d_conditions (driving_condition, weather_conditions,
lighting_condition, speed_limit, temperature)
select driving_condition, weather_conditions,
lighting_condition, speed_limit, temperature from database2.accident_stage; 

--Insert into fact 
insert into database2.fact_accident (date_sid, loc_sid, hosp_sid, con_sid, 
killed_ct, very_seriously_injured_ct, serious_injured_ct, injured_ct, distance, sv_acc_id)
select as2.date, dl.loc_id,  hs.hosp_id, c.con_id, as2.killed_ct, as2.very_seriously_injured_ct,
as2.serious_injured_ct, as2.injured_ct, ch.distance, as2.acc_id  
from database2.d_location dl
	join database2.accident_stage as2 on 
		dl.loc_lat = as2.loc_lat and dl.loc_long = as2.loc_long
	join database2.closest_hosp ch on 
		ch.acc_id = as2.acc_id
	join database2.hospital_stage hs on 
		hs.hosp_id = ch.hosp_id
	join database2.d_conditions c on 
	as2.driving_condition = c.driving_condition and 
	as2.weather_condition = c.weather_conditions  and 
	as2.speed_limit = c.speed_limit and 
	as2.lighting_condition = c.lighting_condition and
	as2.temperature = c.temperature
	;

select * from database2.fact_accident; 




