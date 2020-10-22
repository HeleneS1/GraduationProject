-- POPULATE WEATHER CONDITIONS DIMENTION 
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
------------------------------------------------------------------------------------------------------------------------
-- POPULATE ROAD CONDITIONS DIMENTION 
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
-------------------------------------------------------------------------------------------------------------------
-- POPULATE FACT TABLE 	
with fact as (select *
		from accident_stage acs
			join hospital_stage hs using (hosp_id) 
			left join d_weather_conditions dcc using (driving_condition, weather_condition, lighting_condition) 
			left join d_road_conditions dpc using (road_type, area_type, road_surface, lane_type, lane_numbers)
			left join google_stage gs using (sv_acc_id)
		)
insert into fact_accident(date_sid, time_sid, hosp_sid, weather_sid, road_sid, killed_ct, 
			very_seriously_injured_ct , serious_injured_ct , injured_ct ,
			distance_to_hospital , sv_acc_id, temperature , loc_lat , loc_long, speed_limit, road_km, time_min) 
	select date, time, hosp_id, weather_id, road_id, killed_ct, very_seriously_injured_ct , 
		serious_injured_ct , injured_ct, distance_to_hospital , sv_acc_id, temperature , 
		loc_lat , loc_long, speed_limit, road_km, time_min
	from fact;
