libname project '~/HW/';
ods rtf file='~/HW/project.rtf' ;

/* cleaning raw data */
data storms_raw;
	infile '~/HW/StormEvents_details_2000.csv' DLM=',' 
         firstobs=2 dsd;
		input BEGIN_YEARMONTH BEGIN_DAY BEGIN_TIME END_YEARMONTH 
         END_DAY END_TIME EPISODE_ID EVENT_ID STATE :$14. STATE_FIPS   
         YEAR MONTH_NAME $ EVENT_TYPE :$23. CZ_TYPE $ CZ_FIPS 
         CZ_NAME :$30. WFO $ BEGIN_DATE_TIME :ANYDTDTM40. 
         CZ_TIMEZONE $ END_DATE_TIME :ANYDTDTM40. INJURIES_DIRECT 
                     INJURIES_INDIRECT DEATHS_DIRECT DEATHS_INDIRECT	 
         DAMAGE_PROPERTY $ DAMAGE_CROPS $ SOURCE :$17. MAGNITUDE 
         MAGNITUDE_TYPE $ FLOOD_CAUSE CATEGORY TOR_F_SCALE $   
         TOR_LENGTH TOR_WIDTH TOR_OTHER_WFO TOR_OTHER_CZ_STATE	
    	         TOR_OTHER_CZ_FIPS TOR_OTHER_CZ_NAME  BEGIN_RANGE 
                     BEGIN_AZIMUTH $ BEGIN_LOCATION :$9. END_RANGE END_AZIMUTH	 
         $ END_LOCATION :$9. BEGIN_LAT BEGIN_LON END_LAT END_LON	
         EPISODE_NARRATIVE :$1041. EVENT_NARRATIVE :$62. DATA_SOURCE 
         $;
	label CZ_TIMEZONE = 'Time Zone for the County/Parish, Zone or Marine Name' 
	         SOURCE = 'Source reporting the weather event';
run;


data fatalities_raw;
	infile '~/HW/StormEvents_fatalities_2000.csv' DLM=',' 
            firstobs=2 dsd;
	input FAT_YEARMONTH FAT_DAY FAT_TIME FATALITY_ID EVENT_ID 
         FATALITY_TYPE $ FATALITY_DATE :ANYDTDTM40. FATALITY_AGE 
         FATALITY_SEX $ FATALITY_LOCATION :$21. EVENT_YEARMONTH;
	label FATALITY_TYPE = 'Direct or indirect';
run;


/* creating new datasets with only variables we want to keep */
data storms;

	set storms_raw (keep=BEGIN_YEARMONTH BEGIN_DAY END_YEARMONTH 
      	END_DAY EVENT_ID STATE MONTH_NAME EVENT_TYPE 
CZ_TIMEZONE INJURIES_DIRECT INJURIES_INDIRECT 
DEATHS_DIRECT DEATHS_INDIRECT SOURCE);
run;

data fatalities;
	set fatalities_raw (keep=FAT_YEARMONTH FAT_DAY FATALITY_ID EVENT_ID 
   FATALITY_TYPE FATALITY_AGE FATALITY_SEX    
   FATALITY_LOCATION);
run;

data combined_storms_fatalities;
	set storms fatalities;
run;

Title1 "Table A";
/* Injury, Death, Event Statistics by Location */
proc sql;
	select STATE, 
		sum(INJURIES_DIRECT)+sum(INJURIES_INDIRECT) as ALL_INJURIES,
		sum(DEATHS_DIRECT)+sum(DEATHS_INDIRECT) as ALL_DEATHS,
		calculated ALL_DEATHS/(calculated ALL_INJURIES + calculated ALL_DEATHS) 
			as PERCENT_DEATHS format=percent8.2,
		count(distinct EVENT_TYPE) as NUM_STORMS,
		count(distinct EVENT_ID) as NUM_EVENTS
	from combined_storms_fatalities
	where STATE is not missing
	group by STATE;
quit;

Title1 "Table B";
/* Injury, Death, Number of Events by Month */
proc sql;
	select MONTH_NAME, 
		sum(INJURIES_DIRECT)+sum(INJURIES_INDIRECT) as ALL_INJURIES,
		sum(DEATHS_DIRECT)+sum(DEATHS_INDIRECT) as ALL_DEATHS,
		count(distinct EVENT_ID) as NUM_EVENTS
	from combined_storms_fatalities
	where MONTH_NAME is not missing
	group by MONTH_NAME;
quit;

Title1 "Table C";
/* Injury, Death, Source Statistics by Storm Event Type */
proc sql;
	select EVENT_TYPE, 
		sum(INJURIES_DIRECT)+sum(INJURIES_INDIRECT) as ALL_INJURIES,
		sum(DEATHS_DIRECT)+sum(DEATHS_INDIRECT) as ALL_DEATHS,
		count(distinct SOURCE) as NUM_SOURCES
	from combined_storms_fatalities
	where EVENT_TYPE is not missing
	group by EVENT_TYPE;
quit;

Title2 "Table D";

/* Heat: Highest Number of Deaths in 2000. 
Track months and locations of highest severity. */
proc sql;
	title 'Heat Statistics';
	select EVENT_ID, STATE, MONTH_NAME, INJURIES_DIRECT, 
		INJURIES_INDIRECT, DEATHS_DIRECT, DEATHS_INDIRECT 
	from combined_storms_fatalities
	where EVENT_TYPE = 'Heat'
		and (INJURIES_DIRECT or INJURIES_INDIRECT or 
		DEATHS_DIRECT or DEATHS_INDIRECT) <> 0
	order by STATE, MONTH_NAME;
quit;

Title2 "Table E";

/* Tornado: Highest Number of Injuries in 2000. 
Track months and locations of highest severity. */
proc sql;
	title 'Tornado Statistics';
	select EVENT_ID, STATE, MONTH_NAME, INJURIES_DIRECT, 
		INJURIES_INDIRECT, DEATHS_DIRECT, DEATHS_INDIRECT 
	from combined_storms_fatalities
	where EVENT_TYPE = 'Tornado'
		and (INJURIES_DIRECT or INJURIES_INDIRECT or 
		DEATHS_DIRECT or DEATHS_INDIRECT) <> 0
	order by STATE, MONTH_NAME;
quit;


Title2 "Table F";
/* Lightning: Significantly High Injuries and Deaths in 2000. 
Track months and locations of highest severity. */
proc sql;
	title 'Lightning Statistics';
	select EVENT_ID, STATE, MONTH_NAME, INJURIES_DIRECT, 
		INJURIES_INDIRECT, DEATHS_DIRECT, DEATHS_INDIRECT 
	from combined_storms_fatalities
	where EVENT_TYPE = 'Lightning'
		and (INJURIES_DIRECT or INJURIES_INDIRECT or 
		DEATHS_DIRECT or DEATHS_INDIRECT) <> 0
	order by STATE, MONTH_NAME;
Quit;

Title1 "Table G";
Title2 ‘Number of fatalities in 2000’;
proc sql;
select count(distinct(fatality_ID)) as Num_Fat
from combined_storms_fatalities
where FATALITY_type = 'D';
Quit;

ods text= "476 people died by the events in 2000";


Title "Table H";
title2 'Number of Fatal Events in 2000';
proc SQL;
select count(distinct EVENT_ID) as Num_Event
from combined_storms_fatalities
where FATALITY_type = 'D';
Quit;


title 'Table I';
title2 'Proportion of fatalities by sex';
proc freq data=combined_storms_fatalities;
table FATALITY_SEX;
where FATALITY_type = 'D';
run;

Title "Table J";
title2 'fatalities by age';
proc means data=combined_storms_fatalities mean median q1 q3 max min;
var FATALITY_AGE;
where FATALITY_type = 'D';
Run;


proc format;
	value age
	0-9='Child'
	10-19= 'Adolescence'
	20-29='Young Adult'
	30-59='Adult'
	59<-high='Senior'
	.='Missing';
run;

Title "Table K";
title2 'Fatality_ age by Fatility_location';
proc freq data=combined_storms_fatalities order=freq; 
	table Fatality_location*Fatality_age / norow nocol;
	format Fatality_age age.;
	where Fatality_location and Fatality_sex and Fatality_age is not missing; 
run;

ods text="More than half of Fatalities are Adults and Seniors. 
About 12% of Adults died outside or open area and about 21% of seniors died at a permanent home.
The locations that have high fatality percentage for Young adults, Adolescence, and Child are Outside/Open area and Vehicle/Towed Trailer.";


/*Joined Fatality and Storms data*/
title2 'New data of both fatalities and storms';
proc sql;
	create table fat_stor (drop=event_ID)as
	select *
	from fatalities, storms (rename=(event_ID=eventID))
	where fatalities.event_ID=storms.eventID;
quit;

Title "Table L";
title2 'The state has the most fatality';
proc sql outobs=5;
	select state,count(*) as num_fat
	from fat_stor
	group by state
	order by num_fat desc;
quit;

Title "Table M";
title2 'The state has the least fatality';
proc sql outobs=5;
	select state,count(*) as num_fat
	from fat_stor
	group by state
	order by num_fat asc;
quit;

ods text = "Texas has the most fatality and IDAHO, MASSACHUSETTS, VERMONT, MAINE SOUTH, and DAKOTA have the lowest fatality in the US.";
Title "Table N";
title2 'Which month has high fatalities'; 
proc sql;
	select month_name, count(distinct(fatality_ID)) as num_fat
	from fat_stor
	group by month_name
	order by num_fat desc;
quit;


Title "Table O";
title2 'Cause of Death and number of death in the state where has the most fatality';
proc sql ;
	Select distinct state, event_type, num_fat
	from (select state, event_type, count(distinct(fatality_ID)) as num_fat	from fat_stor where state="TEXAS"	group by event_type)
	having num_fat=max(num_fat);
quit;

ods text= "Heat is the main cause of death in Texas and 70 people died because of heat.";


ods text= "July and August are the period that people died a lot in the US. ";

Title "Table P";
title2 'What age group died the most by which event type';
proc freq data= fat_stor order=freq ;
	table fatality_age*event_type /nocum norow nocol nopercent;
	format fatality_age age.;
run;

ods text= "Adult is the age group that died the most by events. 
About one-third of people died because of Heat and it is the main cause of Senior's death. The second biggest cause is lightning.
Child is the age group that died the least by events";






