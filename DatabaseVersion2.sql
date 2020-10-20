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
(num_acc_id serial primary key,
acc_id integer, 
url varchar(255),
weekday varchar(255),
date varchar,
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

--drop table database2.accident_stage ;
select * from database2.accident_stage ;

--change datatype on date in accident_stage (to match d_date)


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

CREATE TABLE database2.d_time
(
time_key integer NOT NULL,
time_value character(5) NOT NULL,
hours_24 character(2) NOT NULL,
hours_12 character(2) NOT NULL,
hour_minutes character (2)  NOT NULL,
day_minutes integer NOT NULL,
day_time_name character varying (20) NOT NULL,
day_night character varying (20) NOT NULL,
CONSTRAINT time_dim_pk PRIMARY KEY (time_key)
)
WITH (
OIDS=FALSE
);

COMMENT ON TABLE database2.d_time IS 'Time Dimension';
COMMENT ON COLUMN database2.d_time.time_key IS 'Time Dimension PK';

insert into  database2.d_time

SELECT  cast(to_char(minute, 'hh24mi') as numeric) time_key,
to_char(minute, 'hh24:mi') AS tume_value,
-- Hour of the day (0 - 23)
to_char(minute, 'hh24') AS hour_24,
-- Hour of the day (0 - 11)
to_char(minute, 'hh12') hour_12,
-- Hour minute (0 - 59)
to_char(minute, 'mi') hour_minutes,
-- Minute of the day (0 - 1439)
extract(hour FROM minute)*60 + extract(minute FROM minute) day_minutes,
-- Names of day periods
case when to_char(minute, 'hh24:mi') BETWEEN '06:00' AND '08:29'
then 'Morning'
when to_char(minute, 'hh24:mi') BETWEEN '08:30' AND '11:59'
then 'AM'
when to_char(minute, 'hh24:mi') BETWEEN '12:00' AND '17:59'
then 'PM'
when to_char(minute, 'hh24:mi') BETWEEN '18:00' AND '22:29'
then 'Evening'
else 'Night'
end AS day_time_name,
-- Indicator of day or night
case when to_char(minute, 'hh24:mi') BETWEEN '07:00' AND '19:59' then 'Day'
else 'Night'
end AS day_night
FROM (SELECT '0:00'::time + (sequence.minute || ' minutes')::interval AS minute
FROM generate_series(0,1439) AS sequence(minute)
GROUP BY sequence.minute
) DQ
ORDER BY 1 ;

--update database2.d_time set date = replace(date, '-', '');
--alter table database2.accident_stage alter column date type int using(date::int);


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
create table if not exists database2.d_changing_conditions
(change_id serial primary key,
driving_condition varchar,
weather_conditions varchar, 
lighting_condition varchar,
temperature integer);

--drop table database2.d_changing_conditions ;

create table if not exists database2.d_permanent_conditions
(permanent_id serial primary key, 
road_type varchar(255),
area_type varchar(255),
road_surface varchar(255),
lane_type varchar(255),
lane_numbers integer, 
speed_limit integer);

--drop table database2.d_permanent_conditions;


--Create fact-table 
create table if not exists database2.fact_accident(
acc_sid serial primary key,
date_sid integer references database2.d_date(date_dim_id),
time_sid integer references database2.d_time(time_key),
loc_sid integer references database2.d_location(loc_id),
hosp_sid integer references database2.d_hospital(hosp_id),
change_sid integer references database2.d_changing_conditions(change_id),
permanent_id integer references database2.d_permanent_conditions(permanent_id),
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

select * from database2.d_date dd ;

--change datatype on date
update database2.accident_stage set date = replace(date, '-', '');
alter table database2.accident_stage alter column date type int using(date::int);
select * from database2.accident_stage; 


--Insert into d_hospital
insert into database2.d_hospital (hosp_name, hosp_city, hosp_name_city, hosp_lat, hosp_long)
select hosp_name, hosp_city, hosp_name_city, hosp_lat, hosp_long from database2.hospital_stage ;
select * from database2.d_hospital;

--insert into changing conditions
insert into database2.d_changing_conditions (driving_condition, weather_conditions,
lighting_condition, temperature)
select driving_condition, weather_condition,
lighting_condition, speed_limit from database2.accident_stage; 

-- insert into permanent conditions
insert into database2.d_permanent_conditions (road_type, area_type, road_surface, lane_type,
lane_numbers, speed_limit)
select road_type, area_type, road_surface, lane_type, lane_numbers, speed_limit
from database2.accident_stage ;

select * from database2.accident_stage as2  ;

--change datatype on time
update database2.accident_stage set time = replace(time, ':', '');
alter table database2.accident_stage alter column time type int using(time::int);

--Insert into fact 
insert into database2.fact_accident (date_sid, time_sid, loc_sid, hosp_sid, change_sid,
permanent_id,
killed_ct, very_seriously_injured_ct, serious_injured_ct, injured_ct, distance, sv_acc_id)
select as2.date, t.time_key, dl.loc_id,  hs.hosp_id, cc.change_id, pc.permanent_id, 
as2.killed_ct, as2.very_seriously_injured_ct,
as2.serious_injured_ct, as2.injured_ct, ch.distance, as2.acc_id  
from database2.d_location dl
	join database2.accident_stage as2 on 
		dl.loc_id = as2.num_acc_id
	join database2.closest_hosp ch on 
		ch.acc_id = as2.acc_id
	join database2.hospital_stage hs on 
		hs.hosp_id = ch.hosp_id
	join database2.d_time t on
		t.time_key = as2.time 
	join database2.d_changing_conditions cc on 
		as2.num_acc_id = cc.change_id
	join database2.d_permanent_conditions pc on
		as2.num_acc_id = pc.permanent_id
	;


--Prøver på nytt
insert into database2.fact_accident (date_sid, time_sid, loc_sid, hosp_sid,
killed_ct, very_seriously_injured_ct, serious_injured_ct, injured_ct, distance, sv_acc_id
)
select a2.date, a2.time, dl.loc_id, hs.hosp_id,
killed_ct, very_seriously_injured_ct, serious_injured_ct, injured_ct, distance, a2.acc_id 
from database2.accident_stage a2
join database2.d_location dl on 
dl.loc_id = a2.num_acc_id
join database2.closest_hosp ch on 
		ch.acc_id = a2.acc_id
join database2.hospital_stage hs on 
		hs.hosp_id = ch.hosp_id
 ;


truncate database2.fact_accident ;

select count(*) from database2.d_changing_conditions dcc ; 
select * from database2.d_location as2 

select * from database2. as2; 





