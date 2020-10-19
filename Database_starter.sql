
-- Create staging area hospitals
create table if not exists public.hospital_stage 
(hosp_id serial primary key, 
hosp_name varchar(255),
hosp_city varchar(255), 
hosp_lat numeric,
hosp_long numeric);

--drop table public.hospital_stage ;

--Create staging accident 
create table if not exists public.accident_stage
(acc_id integer primary key, 
url varchar(255),
loc_lat numeric,
loc_long numeric, 
death integer,
date varchar(255)); 
ALTER TABLE public.accident_stage
ALTER COLUMN date TYPE integer;


--drop table public.accident_stage;

-- Create staging: Closest hospital for each accident
create table if not exists public.closest_hosp
(id serial primary key,
acc_id integer,
hosp_id integer,
distance integer); 

-- drop table public.closest_hosp;

--Create starschema: dimension date

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

ALTER TABLE public.d_date ADD CONSTRAINT d_date_date_dim_id_pk PRIMARY KEY (date_dim_id);

CREATE INDEX d_date_date_actual_idx
  ON d_date(date_actual);

COMMIT;

-- Insert into d_date dimension

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

--drop table d_date; 

--Create dimension: hospital
create table if not exists public.d_hospital
(hosp_id serial primary key, 
hosp_name varchar(255),
hosp_city varchar(255), 
hosp_lat numeric,
hosp_long numeric) ;

--drop table public.d_hospital; 

--Create dimension location
create table if not exists public.d_location
(loc_id serial primary key, 
loc_lat numeric,
loc_long numeric) 
; 
--drop table public.d_location; 

-- Create fact-table
create table if not exists public.fact_accident(
acc_sid serial primary key,
date_sid integer references public.d_date(date_dim_id),
loc_sid integer references public.d_location(loc_id),
hosp_sid integer references public.d_hospital(hosp_id),
death integer,
distance numeric) ; 
alter table public.fact_accident add column sv_acc_id integer;

--drop table public.fact_accident;

-------------------------------------------------------------------------------------
-- Insert into d_location;
insert into public.d_location(loc_lat, loc_long) 
select loc_lat, loc_long from public.accident_stage;
--select * from d_location; 


--Insert into d_hospital
insert into public.d_hospital (hosp_name, hosp_city, hosp_lat, hosp_long)
select hosp_name, hosp_city, hosp_lat, hosp_long from public.hospital_stage ;
--select * from d_hospital; 


--change datatype on date in accident_stage (to match d_date)
update public.accident_stage set date = replace(date, '-', '');
alter table public.accident_stage alter column date type int using(date::int);


--Insert into fact
insert into public.fact_accident (date_sid, loc_sid, hosp_sid, death, distance, sv_acc_id)
select as2.date, dl.loc_id,  hs.hosp_id, as2.death, ch.distance, as2.acc_id  
from d_location dl
	join accident_stage as2 on 
		dl.loc_lat = as2.loc_lat and dl.loc_long = as2.loc_long
	join closest_hosp ch on 
		ch.acc_id = as2.acc_id
	join hospital_stage hs on 
		hs.hosp_id = ch.hosp_id;

select * from fact_accident; 
