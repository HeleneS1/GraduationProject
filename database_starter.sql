-- STAGING AREA-- 
-- Create--

create table if not exists hospital_stage 
(hosp_id serial primary key, 
hosp_name varchar(255),
hosp_city varchar(255),
hosp_name_city varchar (255), 
hosp_lat numeric,
hosp_long numeric);

create table if not exists accident_stage
(acc_id serial primary key,
sv_acc_id integer not null, 
url varchar(255) DEFAULT 'Unknown',
weekday varchar(255) DEFAULT 'Unknown',
date varchar DEFAULT 00000000,
time varchar(255) DEFAULT 0, 
police_district varchar(255) DEFAULT 'Unknown',
accident_category varchar(255) DEFAULT 'Unknown',
killed_ct integer DEFAULT 0,
very_seriously_injured_ct integer DEFAULT 0, 
serious_injured_ct integer DEFAULT 0,
injured_ct integer DEFAULT 0,
severity varchar(255) DEFAULT 'Unknown', 
road_type varchar(255) DEFAULT 'Unknown',
area_type varchar(255) DEFAULT 'Unknown',
road_surface varchar(255) DEFAULT 'Unknown',
driving_condition varchar(255) DEFAULT 'Unknown', 
weather_condition varchar(255) DEFAULT 'Unknown',
lighting_condition varchar(255) DEFAULT 'Unknown',
lane_type varchar(255) DEFAULT 'Unknown',
lane_numbers integer DEFAULT 000,
speed_limit integer DEFAULT 000, 
temperature integer DEFAULT 000,
loc_lat numeric DEFAULT 000,
loc_long numeric DEFAULT 000, 
hosp_id integer default 000, 
distance_to_hospital numeric default 000); 


--change datatype on date
update accident_stage set date = replace(date, '-', '');
alter table accident_stage alter column date type int using(date::int);
--change datatype on time
update accident_stage set time = replace(time, ':', '');
alter table accident_stage alter column time type int using(time::int);
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BUILD DIMENTIONS--
-- Create & populate date dimention --

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

ALTER TABLE d_date ADD CONSTRAINT d_date_date_dim_id_pk PRIMARY KEY (date_dim_id);
CREATE INDEX d_date_date_actual_idx
  ON d_date(date_actual);
COMMIT;

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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Create & populate time dimention

CREATE TABLE d_time
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
COMMENT ON TABLE d_time IS 'Time Dimension';
COMMENT ON COLUMN d_time.time_key IS 'Time Dimension PK';

insert into  d_time
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

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create & populate hospital dimention 
create table if not exists d_hospital
(hosp_id serial primary key, 
hosp_name varchar(255),
hosp_city varchar(255), 
hosp_name_city varchar(255), 
hosp_lat numeric,
hosp_long numeric) ;

insert into d_hospital (hosp_name, hosp_city, hosp_name_city, hosp_lat, hosp_long)
select hosp_name, hosp_city, hosp_name_city, hosp_lat, hosp_long from hospital_stage;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create and populate weather condition dimention 
create table if not exists d_weather_conditions
(weather_id serial primary key,
driving_condition varchar,
weather_condition varchar, 
lighting_condition varchar);


WITH thistable AS (
    SELECT 
        driving_condition, 
        weather_condition, 
        lighting_condition, 
        ROW_NUMBER() OVER (
            PARTITION BY 
                driving_condition, 
        		weather_condition, 
        		lighting_condition
            ORDER BY 
                driving_condition, 
        		weather_condition, 
        		lighting_condition
        ) row_num
     FROM 
        accident_stage)
insert into d_weather_conditions (driving_condition, weather_condition,
lighting_condition)
select driving_condition, weather_condition, 
lighting_condition from thistable where row_num = 1; 

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create and populate road condition dimention 
create table if not exists d_road_conditions
(road_id serial primary key, 
road_type varchar(255),
area_type varchar(255),
road_surface varchar(255),
lane_type varchar(255),
lane_numbers integer);

WITH thistable2 as (
    SELECT 
        road_type, 
        area_type, 
        road_surface,
        lane_type, 
        lane_numbers,
        ROW_NUMBER() OVER (
            PARTITION BY 
                road_type, 
		        area_type, 
		        road_surface,
		        lane_type, 
		        lane_numbers
            ORDER BY 
                road_type, 
		        area_type, 
		        road_surface,
		        lane_type, 
		        lane_numbers
        ) row_num
     FROM 
        accident_stage) 
insert into d_road_conditions ( road_type,area_type, road_surface, lane_type, lane_numbers)         
select  road_type, area_type,  road_surface,lane_type,lane_numbers
from thistable2 where row_num = 1; 

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BUILD AND POPULATE FACT TABLE 

create table if not exists fact_accident(
acc_sid serial primary key,
date_sid integer references d_date(date_dim_id),
time_sid integer references d_time(time_key),
hosp_sid integer references d_hospital(hosp_id),
weather_sid integer references d_weather_conditions(weather_id),
road_sid integer references d_road_conditions(road_id),
killed_ct integer,
very_seriously_injured_ct integer, 
serious_injured_ct integer, 
injured_ct integer,
distance_to_hospital numeric,
sv_acc_id integer, 
temperature integer, 
loc_lat numeric, 
loc_long numeric, 
speed_limit integer); 

	with fact as (select *
		from accident_stage acs
			join hospital_stage hs using (hosp_id) 
			left join d_weather_conditions dcc using (driving_condition, weather_condition, lighting_condition) 
			left join d_road_conditions dpc using (road_type, area_type, road_surface, lane_type, lane_numbers)
		)
insert into fact_accident(date_sid, time_sid, hosp_sid, weather_sid, road_sid, killed_ct, 
			very_seriously_injured_ct , serious_injured_ct , injured_ct ,
			distance_to_hospital , sv_acc_id, temperature , loc_lat , loc_long, speed_limit) 
	select date, time, hosp_id, weather_id, road_id, killed_ct, very_seriously_injured_ct , 
		serious_injured_ct , injured_ct, distance_to_hospital , sv_acc_id, temperature , 
		loc_lat , loc_long, speed_limit
	from fact;


