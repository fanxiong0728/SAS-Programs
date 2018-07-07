*-------------------------------------------------------------------*
 *  Author:  Fan Xiong            <fanxiong0728@gmail.com>           *
*-------------------------------------------------------------------*

/*This SAS program uses a series of DATA and SQL procedures to compute morphine milligram equivalent flag metrics using PDMP data*/
/*The program uses a long-expansion of a time-series data to flag patients. SAS Views are used to more efficiently process a large data*/

options compress=yes threads cpucount=actual;

Libname KTRACS "C:\TEMP\KTRACS BACKUP\DATA";
LIBNAME PATIENT "C:\TEMP\KTRACS BACKUP\DATA\CDC APR YEAR 2";

%LET permlib = KTRACS;
%LET Data = NEWKTRACS16;

/*************kansas added reporting macro variables*/


%LET YEAR1=2016;  /*reporting year of interest is year1*/
%LET start_date=01JAN2016; 

%LET YEAR2=2017; /*start of next year of data is year2*/
%LET end_date=01JAN2017; /*adjusted to the start of the next year to avoid Dec 31 becoming Dec 30.*/

/*number of days in the observed period of interest*/
%let N = %SYSFUNC(DATDIF("&start_date."d,"&end_date."d, "act/act"));

/*Create Qtr Column Stop period*/
%let COLQTR1=%sysfunc(DATDIF("&start_date."d,"01APR&YEAR1."d, "act/act")); 
%let COLQTR2=%sysfunc(DATDIF("&start_date."d,"01JUL&YEAR1."d, "act/act")); 
%let COLQTR3=%sysfunc(DATDIF("&start_date."d,"01OCT&YEAR1."d, "act/act")); 
%let COLQTR4=%sysfunc(DATDIF("&start_date."d,"&end_date."d, "act/act")); 

/*Variables need*/

/*unique patient id*/
%LET PatientId = patient_identifier;
/*prescription filled date*/
%LET filldate = filled_date_c;
/*days of supply*/
%LET days_supply=dayssupply_dispensed;
/*name of drug to exclude Buprenorphine*/
%LET DRUG = drug;
/*MME per day variable at the prescription transaction level*/
%LET MME = mme_dd;
/*patient year of birth*/
%LET birthyear = birthyear;
/*patient city of residence reported*/
%LET citypt= citypt;
/*patient state of residence reported*/
%LET statept=statept;
/*Schedule II to IV prescription indicator*/
%LET CSIIIV=CSIIIV;
/*Opioid prescription indicator*/
%LET Opioid=Opioid;

/*******  PDMP indicator  *******/

/*  23. Percent of patients receiving more than an average daily dose of >90 morphine milligram equivalents  */

/*  CDC_OPIS */

/* First, read prescriptions */

	/*a sas view is created in the permanent library for reporting purposes. this negates the need to build a table and speeds up the read/write operation*/

data  &permlib..opioids ;
set &permlib..&data 

/*the keep and where clause may need to be modified based on your data*/
(keep=&PatientId &filldate &days_supply &DRUG &MME &birthyear &citypt &statept &CSIIIV &opioid
WHERE=(&PatientId NE "   " AND &citypt NE "   " and &statept = "KS" AND 
1899<=&birthyear <= 20&year1 and &DRUG NE "Buprenorphine" and &CSIIIV  = "1" And &opioid="1"));

/*the drop clause may need to be modified based on your data*/
	/*these are variables only needed to subset the data*/
DROP &birthyear &citypt &statept &CSIIIV &DRUG;

/***********
	    Revised and added other metrics for start date and two look-up variables indicating when in the reporting period the prescription starts and ends
	    The use of the ROW and COL indicator is a colmunar database technique to more efficiently retrieve data. It is used here for the purpose of calculating
	    prescriptions that fall on the same reporting days (e.g., overlapping days, 2+ opioids, overlapping MMEs, etc). 
***************/
	    

	/*THE REPORTING START DATE IS CONSIDERED FIRST. THIS ENSURES YOU ARE COUNTING THE RIGHT QUARTERS.*/
	/*USE A DOUBLE AMPERSAND SIGN FOR MORE EFFICIENT CALLING OF A 'NESTED' MACRO VARIABLE*/
	startdate="&&start_date"d;

	/*REPORTING END DATE IS FILLED DATE + DAYS OF SUPPLY WITH A -1 CORRECTION SO THAT THE FIRST PRESCRIPTION DATE IS THE SAME AS THE FILLED DATE */
	/*USE A DOUBLE AMPERSAND SIGN FOR MORE EFFICIENT CALLING OF A 'NESTED' MACRO VARIABLE*/
	enddate=sum(&filldate , &days_supply)-1; /* find end date of prescription based on fill date and days of supply */
	
	/*ENUMERATE THE PRESCRIPTION END DATE*/
	if (&year1 <=year(enddate)<&year2) then
		enddate=enddate;

	/*IF THE YEAR OF ENDDATE IS WITHIN THE INTERVALS OF INTEREST*/
	/*OTHWERWISE, SET IT TO THE REPORTING END DATE: DEC 31*/
	else if year(enddate)>=&year2 then
		enddate="&&end_date"d - 1;

	/*ROW is an indicator indicating where in the reportng date interval where a prescribed drug history begins for that prescription*/
	ROW=(&filldate -startdate) + 1;

	/*COL is the COLUMN indicating where in the reportng date interval where a prescribed drug history ends for that prescription*/
	COL=(enddate-startdate) + 1;

	format startdate enddate MMDDYY10.;

run;

/*same filled date with end date could be duplicates*/
proc sort data=&permlib..opioids THREADS nodup;
By &PatientId ROW COL;
RUN;

/*************
	Removed the proc sort and transpose since they are not needed and takes up a lot of space and resources
	Be careful about potentially duplicated records that must be removed in the initial PDMP data prep steps
************/


/* Set opioid data sets*/

data &permlib..persontot1;
Set &permlib..opioids (keep=&PatientId &MME ROW COL);

/*This creates a variable for each reporting days for each daily mme observed: this ensures the mme on the same days are aligned in the same column together*/

Array mmeindicator (*) mmedays1-mmedays&N; 

	/*create your mme days variable*/
	/*REMEMBER WE CREATED TWO VARIABLES TO SPECIFY WHEN TO BEGIN AND END THE ENUMERATION. THIS MAKES THE ENUMERATION RUN FASTER.*/
	DO K=ROW TO COL;
	mmeindicator[K] = &MME;
	END;

RUN;


/*Use a PROC SUMMARY TO ADD UP ALL MME REPORTING VARIABLES BY PATIENT*/
	/*an autoname is used to add up all numeric variables, which means the variables will be written as: mmedays1_sum*/
	/*this creates one record per patient with an opioid prescriptions with columns being the days with any opioid(s)*/

PROC SUMMARY DATA=&permlib..persontot1 (KEEP=&PatientId &MME mmedays1-mmedays&N) noprint threads chartype;
CLASS &PatientId / groupinternal;
TYPES &PatientId;
VAR  mmedays1-mmedays&N;
OUTPUT OUT=&permlib..personoth1_sum (DROP=_TYPE_ RENAME=_FREQ_=ANNUALOPIOIDRX) 
SUM= / autoname;
RUN;


/* Prescription days and mean MME for each person */

	/*a sas view is created in the permanent library for reporting purposes. this negates the need to build a table and speeds up the read/write operation*/

DATA &permlib..personoth1_sum2 (DROP=mmedays1_sum --  mmedays&N._sum mmedays1-mmedays&N);
SET &permlib..personoth1_sum;

	
	/*Rename the mme per day variables back into its original*/
	array summme (*)  mmedays1_sum --  mmedays&N._sum;
	array mmeday (*) mmedays1-mmedays&N;

	/*create reporting metrics by calander quarter period of observation*/
	array qtrindicators (4,4) TOTALMMEQTR1- TotalMMEQTR4
				  OpioidDaysQTR1 - OpioidDaysQTR4
				  MeanMMEqtr1-MeanMMEQtr4
				  HighMME90Qtr1 - Highmme90Qtr4;

	array ptindicators (*) HighMMEPatientQtr1-HighMMEPatientQtr4;

	/*Set reporting indicators to 0*/
	do c = 1 to 4;
	qtrindicators[1,c]=0; qtrindicators[2,c]=0; qtrindicators[3,c]=0; qtrindicators[4,c]=0;ptindicators[c]=0;
	End;
	drop c;

	do I = 1 to &N;
		if summme[i] NE . THEN mmeday[i]=summme[i]; /*Rename the mme per day variables back into its original*/
		ELSE if summme[i] = .  THEN mmeday[i]=0;

		/*start a j loop for quarterly reporting period indicator columns*/
   
		/*report year first quarter total mme: jan &year1 to march &year1*/
		if I <=&COLQTR1 then j = 1;

		/*report year second quarter total mme: apr &year1 to jul &year1*/
		else if &COLQTR1 < I <=&COLQTR2 then
			j = 2;

		/*report year third quarter total mme: aug &year1 to sept &year1*/
		ELSE IF &COLQTR2 < I <=&COLQTR3 then
			j=3;

		/*report year fourth quarter total mme: oct &year1 to dec &year1*/
		else if &COLQTR3 < I <=&COLQTR4 THEN
			j=4;

		IF mmeday[i] > 0 THEN qtrindicators[1,j]=mmeday[i]+qtrindicators[1,j]; /*total mme for reporting indicators*/
		IF mmeday[i] > 0 THEN qtrindicators[2,j]+1; /*total days with opioids for reporting indicators*/
		if mmeday[i]>=90 then qtrindicators[4,j]+1; /*total days with 90+ mme per day*/
		END;


	do Z = 1 to 4;
	/*mean mme per opioid day during observed quarter period*/
	IF qtrindicators[1,z] > 0 THEN qtrindicators[3,z]=(qtrindicators[1,z] / qtrindicators[2,z]); 
	ELSE qtrindicators[3,z]=0;

	/*patients with 90+ MME per Day on Average during observed quarter period*/
	if qtrindicators[3,z] GE 90 then ptindicators[Z]=1;
	ELSE IF 0<= qtrindicators[3,z] < 90 then ptindicators[Z]=0;
	end;

	/*patients with opioid per quarter*/


RUN;

/* Calculate average MME for all patients and determine what percentage had mean MME>90 */

proc sql NOPRINT;
create table &permlib..high_mme as

	/*quarter 1*/
	select 
	"Jan - Mar, &Year1" as QTR,
	mean(HighMMEPatientQtr1)*100 as high_mme,
	COUNT(DISTINCT(CASE WHEN HighMMEPatientQtr1 > 0 THEN &PatientId end)) as highmmept,
	Count(distinct(CASE WHEN TOTALMMEQTR1 >0 THEN &PatientId end)) as Totalopioidpt

	FROM &permlib..personoth1_sum2 (WHERE=(TOTALMMEQTR1 >0))
	GROUP BY QTR

	/*quarter 2*/
	UNION ALL 
	select 	"Apr - Jun, &Year1" as QTR,
	mean(HighMMEPatientQtr2)*100 as high_mme,
	COUNT(DISTINCT(CASE WHEN HighMMEPatientQtr2 > 0 THEN &PatientId end)) as highmmept,
	Count(distinct(CASE WHEN TOTALMMEQTR2 >0 THEN &PatientId end)) as Totalopioidpt
	FROM &permlib..personoth1_sum2 (WHERE=(TOTALMMEQTR2 >0))
	GROUP BY QTR
	/*quarter 3*/
	UNION ALL 
	select "Jul - Sep, &Year1" as QTR,
	mean(HighMMEPatientQtr3)*100 as high_mme,
	COUNT(DISTINCT(CASE WHEN HighMMEPatientQtr3 > 0 THEN &PatientId end)) as highmmept,
	Count(distinct(CASE WHEN TOTALMMEQTR3 >0 THEN &PatientId end)) as Totalopioidpt
	FROM &permlib..personoth1_sum2 (WHERE=(TOTALMMEQTR3 >0))
	GROUP BY QTR

    /*quarter 4*/
	UNION ALL 
	select "Oct - Dec, &Year1" as QTR,
	mean(HighMMEPatientQtr4)*100 as high_mme,
	COUNT(DISTINCT(CASE WHEN HighMMEPatientQtr4 > 0 THEN &PatientId end)) as highmmept,
	Count(distinct(CASE WHEN TOTALMMEQTR4 >0 THEN &PatientId end)) as Totalopioidpt
	FROM &permlib..personoth1_sum2 (WHERE=(TOTALMMEQTR4 >0))
	GROUP BY QTR;


quit;
