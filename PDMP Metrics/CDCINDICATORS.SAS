
/*This is a MACRO program to be used with RSUBMIT procedure to create a single year of PDMP indicators required by the CDC for grant reporting and surveilliance. 


%macro pfsindicator(subsetmacro=,START_DATE=,END_DATE=,class=,demo1=,YEAR0=,YEAR1=,YEAR2=,SET0=,SET1=);

%let N = %SYSFUNC(DATDIF("&start_date."d,"&end_date."d, "act/act"));

/*Create Qtr Column Stop period*/
%let COLBASE=%sysfunc(DATDIF("&start_date."d,"01JAN&YEAR1."d, "act/act"));
%let COLQTR1=%sysfunc(DATDIF("&start_date."d,"01APR&YEAR1."d, "act/act")); 
%let COLQTR2=%sysfunc(DATDIF("&start_date."d,"01JUL&YEAR1."d, "act/act")); 
%let COLQTR3=%sysfunc(DATDIF("&start_date."d,"01OCT&YEAR1."d, "act/act")); 
%let COLQTR4=%sysfunc(DATDIF("&start_date."d,"&end_date."d, "act/act")); 

libname backup "H:\Health Promotion\Injury Disability\secure_injury_data\PDMP\BACKUPS DO NOT OVERWRITE";
libname REPORT&SET1 "C:\TEMP\KTRACS BACKUP\Opioid\&year1";
LIBNAME T0 "C:\TEMP\KTRACS BACKUP\Opioid";

options msglevel=i COMPRESS=YES REUSE=YES FMTSEARCH=(REPORT&SET1 WORK BACKUP) THREADS CPUCOUNT=4 mlogic symbolgen;
DATA REPORT&SET1..NEWKTRACS  
(KEEP=patient_identifier prescriber dispensary numericid RX&class RXbenzo LARX filled_date_C sdate edate row col mme_dd dayssupply_dispensed)

/ VIEW = REPORT&SET1..NEWKTRACS ;
SET  backup.NEWKTRACS&SET0 
					(keep=statept statedisp patient_identifier  numericid &demo1 prescriber dispensary prescription_number DRUG 
					CSIIIV LongShortActing &class benzo filled_date_C dayssupply_dispensed drug mme_dd written_date_C) 
					
	 backup.NEWKTRACS&SET1 (keep=statept statedisp patient_identifier numericid &demo1 prescriber dispensary prescription_number DRUG 
					CSIIIV LongShortActing &class benzo filled_date_C dayssupply_dispensed drug mme_dd written_date_C) 	
	;
WHERE numericid NE "  " AND prescriber NE "   " AND prescription_number NE "   " AND dispensary NE "  " AND statept = "KS" AND statedisp = "KS"
						AND ("&START_DATE"d <= filled_date_C < "&END_DATE"d)
						and (&class="1" OR BENZO = "1") AND (dayssupply_dispensed > 0) AND 
					(DRUG NE "&DRUGEXCLUDE") AND (patient_birthyear GE "1899") AND ("&START_DATE"d  <= written_date_C < "&END_DATE"d);
ROWID=_N_;

	/*KANSAS KEEPS THE VARIABLES FROM THE PDMP AS CHARACTER VARIABLES TO SAVE SPACE AND INCREASE PERFORMANCE.
	/*SAVING NUMERIC VARIABLE AS CHARACTERS IS A TECHNIQUE GENERALLY USED IN THE HEALTHCARE INDUSTRY TO ENSURE EFFICIENCY AND CONSISTENT QUALITY.*/
	/*SO, INTEGERS (days) IS GENERALLY ALWAYS BETTER STORED AS CHARACTER VARIABLES. ONLY IMPRECISE OR RANDOM VARIABLES NEED TO BE NUMERIC.			*/
	/*THIS MEANS A MULTIPLIER WAS NECESSARY TO ENUMERATE THEM BACK TO NUMERIC: CHANGE IF NECESSARY*/
	RX&class=&class * 1;
	RXbenzo=benzo *1;

	if LongShortActing="LA" then
		LARX=1;
	ELSE if LongShortActing="SA" then
		LARX=0;

	/*DROP ALL THE CHARACTER VARIABELS THAT WE DON'T NEED. THIS INCREASES SOME PERFORMANCE SAVINGS SINCE THERE IS A LIMIT TO HOW WIDE AN OBSERVATION CAN BE (32,767 VARIABLES IN WINDOWS).*/
	DROP &CLASS BENZO LongShortActing;

	/*BASELINE REPORTING START DATE IS CONSIDERED FIRST. THIS ENSURES YOU ARE COUNTING THE RIGHT QUARTERS.*/
	/*USE A DOUBLE AMPERSAND SIGN FOR MORE EFFICIENT CALLING OF A 'NESTED' MACRO VARIABLE*/
	sdate="&&start_date"d;

	/*REPORTING END DATE IS FILLED DATE + DAYS OF SUPPLY WITH A -1 CORRECTION SO THAT THE FIRST PRESCRIPTION DATE IS THE SAME AS THE FILLED DATE */
	/*USE A DOUBLE AMPERSAND SIGN FOR MORE EFFICIENT CALLING OF A 'NESTED' MACRO VARIABLE*/
	edate=(filled_date_C+dayssupply_dispensed) - 1;

	/*ENUMERATE THE PRESCRIPTION END DATE*/
	if (&year0 <=year(edate) <=&year1) then
		edate=edate;

	/*IF THE YEAR OF ENDDATE IS WITHIN THE INTERVALS OF INTEREST*/
	/*OTHWERWISE, SET IT TO THE REPORTING END DATE: DEC 31*/
	else
		edate="&&end_date"d - 1;

	/*ROW is the an indicator indicating where in the reportng date interval where a prescribed drug history begins for that prescription*/
	ROW=(filled_date_c-sdate) + 1;

	/*COL is the COLUMN indicating where in the reportng date interval where a prescribed drug history ends for that prescription*/
	COL=(edate-sdate) + 1;
    &subsetmacro; 
	RUN;

	
PROC SQL NOPRINT;

CREATE TABLE REPORT&SET1..NEWKTRACS&SET1 as
		SELECT * FROM REPORT&SET1..NEWKTRACS					
ORDER BY numericid,ROW,COL;

QUIT;


DATA

	/*==NAME THE DATA STEP BY THE LIBNAME SPECIFIIED ABOVE AND THE TYPE OF REPORT==*/
	REPORT&SET1..&CLASS.&SET0.&SET1  

	/*==VARIABLES TO KEEP==*/
(KEEP=numericid benzodays1-benzodays&N &class.days1-&class.days&N &class.mme1-&class.mme&N laday1-laday&N &class.COUNT 
		benzocount OPIOIDDAYS BENZODAYS LARXTOTAL SARXTOTAL NOOPIOID) /*==A SAS VIEW IN THE DATA STEP MUST HAVE THE SAME NAME AS THE DATA PROGRAM.==*/ 

/*create a view*/
/ VIEW=REPORT&SET1..&CLASS.&SET0.&SET1;

/*read in the SQL VIEW*/
	SET REPORT&SET1..NEWKTRACS&SET1;

	/*NOT ALL VARIABLES IN THE LAST VIEW WAS NECESSARY. MODIFY THIS PART FOR VARIABLES YOU NEED. THE MORE VARIABLE TO SUMMARIZE, THE LONGER IT WILL TAKE BUT IT'S A CONSTANT TIME INCREASE BY THE NUMBER OF VARIABLES.*/

	/*THE NOTSORTED OPTION IS INVOKED TO LET SAS KNOW THERE IS NO NEED TO CHECK FOR SORTING WITHIN THE ENTIRE DATA BEFORE EXECUTION*/
	BY numericid NOTSORTED;

	/*YOU MUST HAVE A RETAIN STATEMENT AT THIS PART OF THE PROGRAM TO MAKE SURE IT CARRIES THE VARIABLE BEING ENUMERATED FOR EACH PATIENT FOR EACH RX FORWARD.*/
	RETAIN benzodays1-benzodays&N &class.days1-&class.days&N &class.mme1-&class.mme&N laday1-laday&N &class.COUNT 
		BENZOCOUNT OPIOIDDAYS BENZODAYS LARXTOTAL SARXTOTAL NOOPIOID;

	/* ====================================== */
	/* == USE MULTIDIMENSIONAL ARRAY STATEMENTS TO sum VARIABLES*/
	/* ====================================== */
	/*YOU MUST SPECIFY THE FIRST.PATIENTID TO MAKE SURE YOU DON'T REWRITE PREVIOUS COUNTS. IT WILL EXECUTE THE CODE BY BLOCKS OF PRESCRIPTIONS FOR EACH PATIENT*/
	IF first.numericid THEN
		DO;

			/*============ IN ORDER TO COUNT VARIABLES AND CARRY-THEM FORWARD, INITALIZE ALL THE INDICATOR'S PRESCRIPTION DAYS TO 0.============ */
			/*============ THE MAIN IDEA IS TO ENUMERATE EVERYTHING TO ZERO AND THEN ONLY ADD UP BY ENUMERATION WITHIN EACH PATIENTS, THE NUMBER OF SCRIPTS WRITTEN ON THOSE DAYS. ============*/
			/*============ A PATIENT WITH ONLY 1 PRESCRIPTION SHOULD ONLY BE EXECUTED ONCE. A PATIENT WITH MORE PRESCRIPTIONS WILL USUALLY TAKE MORE TIME TO EXECUTE.============*/
			/*=========FOR SAS PROGRAMMERS UNFAMILIAR WITH MULTIDIMENSIONAL ARRAY, PAY CAREFUL ATTENTION TO THE ARRAY BRACKETS AND HOW TO EXPLICITY SPECIFIY THE CURRENT COLUMNS/ROWS IN THE ARRAY ========= */
			ARRAY INTIALIZE (4, &N) benzodays1-benzodays&N &class.days1-&class.days&N &class.mme1-&class.mme&N laday1-laday&N;

			do j=1 to %SYSFUNC(DATDIF("&&start_date."d,"&&end_date."d, "act/act"));

				/*START A LOOP FOR EACH VARIABLES REPORTING DAYS*/
				/*DON'T LOOP ACROSS THE VARIABLES OR IT WILL TAKE A LONG TIME. RATHER EXPLICITLY SPECIFIED IT AS BELOW SO SAS ATTACHES NEW COLUMNS RATHER THAN LOOPING IT BACK TO THE START. */
				/*THIS CREATES ALL THE COLUMNS IN SEQUENCE AT ABOUT THE SAME TIME*/
				/*THIS MEANS THE COLUMNS TO BE CREATED ARE:  BENZODAYS1-BENZODAYS&N       AND IS SET TO 0*/
				INTIALIZE[1, j]=0;

				/*THIS MEANS THE COLUMNS TO BE CREATED ARE:  &class.days1-&class.days&N  AND IS SET TO 0*/
				INTIALIZE[2, j]=0;

				/*THIS MEANS THE COLUMNS TO BE CREATED ARE:  &class.mme1-&class.mme&N   AND IS SET TO 0*/
				INTIALIZE[3, j]=0;

				/*THIS MEANS THE COLUMNS TO BE CREATED ARE:  laday1-laday&N (LONG-ACTING OPIOIDS) AND IS SET TO 0*/
				INTIALIZE[4, j]=0;

				/*NUMBER OF  BENO   RX*/
				benzocount=0;

				/*NUMBER OF  &class RX*/
						&class.COUNT=0;

				/*NUMBER OF  &class DAYS*/
						&class.DAYS=0;

				/*TOTAL NUMBER OF BENZO DAYS OF SUPPLY PRESCRIBED*/
				BENZODAYS=0;

				/*TOTAL NUMBER OF LONG-ACTING OPIOIDS*/
				LARXTOTAL=0;

				/*TOTAL NUMBER OF SHORT-ACTING OPIOIDS*/
				SARXTOTAL=0;

				/*TOTAL NUMBER OF NON-OPIOIDS*/
				NOOPIOID=0;
			END;
		END;

	/* ------------------------------------------------------------------------------- */
	/* ----- Accumulate statistics FOR THE TOTAL NUMBER PRESCIBED RX.---------------- */
	/*------THESE DON'T FEED INTO THE PRESCRIPTION DAYS RATHER THEY ARE USED TO ENSURE DATA QUALITY------------------------------ */
	/* ----------------------------------------------------------------- */
	IF RX&class=1 THEN
		DO;
			OPIOIDDAYS+dayssupply_dispensed;
			&class.COUNT+1;

			IF LARX=1 THEN
				LARXTOTAL+ 1;
			ELSE IF LARX=0 THEN
				SARXTOTAL +1;
		END;
	ELSE IF RX&class=0 THEN
		DO;
			NOOPIOID + 1;
		END;

	IF RXbenzo=1 then
		DO;
			BENZOCOUNT+1;
			BENZODAYS+dayssupply_dispensed;
		END;

	/* ----------------------------------------------------------------- */
	/* ----- Accumulate PRESRIPTION DAYS statistics ------------------------------ */
	/* ----------------------------------------------------------------- */
	ARRAY SUMVAR (4, &N) benzodays1-benzodays&N &class.days1-&class.days&N &class.mme1-&class.mme&N laday1-laday&N;

	/*REMEMBER WE CREATED TWO VARIABLES TO SPECIFY WHEN TO BEGIN AND END THE COUNTING. THE RETAIN STATEMENT WILL KEEP ANY PAST-RX DATA.*/
	DO J=ROW TO COL;

		/*IF AND ONLY IF THE ROW IS AN OPIOID*/
		IF RX&class=1 THEN
			DO;

				/*IF AND ONLY IF THE ROW IS AN OPIOID*/
				SUMVAR[2, j]+RX&class;

				/*IF AND ONLY IF THE ROW IS AN OPIOID*/
				SUMVAR[3, j]+mme_dd;

				IF LARX=1 THEN
					SUMVAR[4, j]+LARX;
			END;

		/*IF AND ONLY IF THE ROW IS A BENZO*/
		IF RXbenzo=1 THEN
			DO;

				/*IF AND ONLY IF THE ROW IS A BENZO*/
				SUMVAR[1, j]+RXbenzo;
			END;
	END;

	/* ----------------------------------------------------------------- */
	/* --- Output/KEEP ONLY observation after the last subgroup ---- */
	/* --- observation --------------------------------------------- */
	/* ----------------------------------------------------------------- */
	IF last.numericid;
RUN;


DATA REPORT&SET1..&CLASS.&YEAR1 
						 (KEEP=YEAR numericid &class.COUNT BENZOCOUNT OPIOIDDAYS 
		BENZODAYS LARXTOTAL SARXTOTAL NOOPIOID
						 &class.QTR0 SA&CLASS.QTR0 LA&CLASS.QTR0 
		OVERLAPQTR0&CLASS  LAOVERLAPQTR0&CLASS SALAOVERLAPQTR0&CLASS PATMME90QTR0 
		TOTALMMEQTR0 PTQTR0 NAOPIOIDQTR0
						 &class.QTR1 SA&CLASS.QTR1 LA&CLASS.QTR1 
		OVERLAPQTR1&CLASS  LAOVERLAPQTR1&CLASS SALAOVERLAPQTR1&CLASS PATMME90QTR1 
		TOTALMMEQTR1 PTQTR1 NAOPIOIDQTR1
						 &class.QTR2 SA&CLASS.QTR2 LA&CLASS.QTR2 
		OVERLAPQTR2&CLASS  LAOVERLAPQTR2&CLASS SALAOVERLAPQTR2&CLASS PATMME90QTR2 
		TOTALMMEQTR2 PTQTR2 NAOPIOIDQTR2
						 &class.QTR3 SA&CLASS.QTR3 LA&CLASS.QTR3 
		OVERLAPQTR3&CLASS  LAOVERLAPQTR3&CLASS SALAOVERLAPQTR3&CLASS PATMME90QTR3 
		TOTALMMEQTR3 PTQTR3 NAOPIOIDQTR3
						 &class.QTR4 SA&CLASS.QTR4 LA&CLASS.QTR4 
		OVERLAPQTR4&CLASS  LAOVERLAPQTR4&CLASS SALAOVERLAPQTR4&CLASS PATMME90QTR4 
		TOTALMMEQTR4 PTQTR4 NAOPIOIDQTR4 OPIOIDBENZOQTR0 OPIOIDBENZOQTR1 
		OPIOIDBENZOQTR2 OPIOIDBENZOQTR3 OPIOIDBENZOQTR4) 

/ VIEW=REPORT&SET1..&CLASS.&YEAR1;

SET REPORT&SET1..&CLASS.&SET0.&SET1  ;

BY numericid NOTSORTED;

YEAR=&YEAR1;

	/*YOU MUST HAVE A RETAIN STATEMENT AT THIS PART OF THE PROGRAM TO MAKE SURE IT CARRIES THE VARIABLE BEING ENUMERATED FOR EACH PATIENT FOR EACH RX FORWARD.*/
	RETAIN 					 &class.QTR0 SA&CLASS.QTR0 LA&CLASS.QTR0 
		OVERLAPQTR0&CLASS  LAOVERLAPQTR0&CLASS SALAOVERLAPQTR0&CLASS PATMME90QTR0 
		TOTALMMEQTR0 PTQTR0 NAOPIOIDQTR0
						 &class.QTR1 SA&CLASS.QTR1 LA&CLASS.QTR1 
		OVERLAPQTR1&CLASS  LAOVERLAPQTR1&CLASS SALAOVERLAPQTR1&CLASS PATMME90QTR1 
		TOTALMMEQTR1 PTQTR1 NAOPIOIDQTR1
						 &class.QTR2 SA&CLASS.QTR2 LA&CLASS.QTR2 
		OVERLAPQTR2&CLASS  LAOVERLAPQTR2&CLASS SALAOVERLAPQTR2&CLASS PATMME90QTR2 
		TOTALMMEQTR2 PTQTR2 NAOPIOIDQTR2
						 &class.QTR3 SA&CLASS.QTR3 LA&CLASS.QTR3 
		OVERLAPQTR3&CLASS  LAOVERLAPQTR3&CLASS SALAOVERLAPQTR3&CLASS PATMME90QTR3 
		TOTALMMEQTR3 PTQTR3 NAOPIOIDQTR3
						 &class.QTR4 SA&CLASS.QTR4 LA&CLASS.QTR4 
		OVERLAPQTR4&CLASS  LAOVERLAPQTR4&CLASS SALAOVERLAPQTR4&CLASS PATMME90QTR4 
		TOTALMMEQTR4 PTQTR4 NAOPIOIDQTR4 OPIOIDBENZOQTR0 OPIOIDBENZOQTR1 
		OPIOIDBENZOQTR2 OPIOIDBENZOQTR3 OPIOIDBENZOQTR4;

	/*SET UP ARRAY VARIABLES FOR THE WIDE REPORTING DATE COLUMNS CREATED IN THE LAST STEP*/
	array days (&N) &class.days1-&class.days&N;
	array LA (&N) laday1-laday&N;
	array DD (&N) &class.mme1-&class.mme&N;
	array BZ (&N) benzodays1-benzodays&N;

	/*THIS IS FOR THE OVERLAPPING OPIOID BENZO INDICATOR: SET IT UP OUTSIDE OF THE MULTIDIMENSIONAL ARRAY SINCE IT WILL BE CREATED LAST AFTER SUMMARIZING ALL THE OPIOIDS AND BENZO DATA*/
	array OPBZ (5) OPIOIDBENZOQTR0 OPIOIDBENZOQTR1 OPIOIDBENZOQTR2 OPIOIDBENZOQTR3 
		OPIOIDBENZOQTR4;

	/*============ IN ORDER TO COUNT VARIABLES AND CARRY-THEM FORWARD, INITALIZE ALL THE INDICATOR'S REPORTING PERIOD TO 0.============ */
	/*============ THE MAIN IDEA IS TO ENUMERATE EVERYTHING TO ZERO AND THEN ONLY ADD UP BY ENUMERATION WITHIN EACH PATIENTS, THE NUMBER OF SCRIPTS WRITTEN ON THOSE DAYS. ============*/
	/*============ A PATIENT WITH ONLY 1 PRESCRIPTION SHOULD ONLY BE EXECUTED ONCE. A PATIENT WITH MORE PRESCRIPTIONS WILL USUALLY TAKE MORE TIME TO EXECUTE.============*/
	/*=========FOR SAS PROGRAMMERS UNFAMILIAR WITH MULTIDIMENSIONAL ARRAY, PAY CAREFUL ATTENTION TO THE ARRAY BRACKETS AND HOW TO EXPLICITY SPECIFIY THE CURRENT COLUMNS/ROWS IN THE ARRAY ========= */
	array values (5, 10) &class.QTR0 SA&CLASS.QTR0 LA&CLASS.QTR0 
		OVERLAPQTR0&CLASS  LAOVERLAPQTR0&CLASS SALAOVERLAPQTR0&CLASS PATMME90QTR0 
		TOTALMMEQTR0 PTQTR0 NAOPIOIDQTR0
						 &class.QTR1 SA&CLASS.QTR1 LA&CLASS.QTR1 
		OVERLAPQTR1&CLASS  LAOVERLAPQTR1&CLASS SALAOVERLAPQTR1&CLASS PATMME90QTR1 
		TOTALMMEQTR1 PTQTR1 NAOPIOIDQTR1
						 &class.QTR2 SA&CLASS.QTR2 LA&CLASS.QTR2 
		OVERLAPQTR2&CLASS  LAOVERLAPQTR2&CLASS SALAOVERLAPQTR2&CLASS PATMME90QTR2 
		TOTALMMEQTR2 PTQTR2 NAOPIOIDQTR2
						 &class.QTR3 SA&CLASS.QTR3 LA&CLASS.QTR3 
		OVERLAPQTR3&CLASS  LAOVERLAPQTR3&CLASS SALAOVERLAPQTR3&CLASS PATMME90QTR3 
		TOTALMMEQTR3 PTQTR3 NAOPIOIDQTR3
						 &class.QTR4 SA&CLASS.QTR4 LA&CLASS.QTR4 
		OVERLAPQTR4&CLASS  LAOVERLAPQTR4&CLASS SALAOVERLAPQTR4&CLASS PATMME90QTR4 
		TOTALMMEQTR4 PTQTR4 NAOPIOIDQTR4;

	do c=1 to 10;
		values{1, c}=0;
		values{2, c}=0;
		values{3, c}=0;
		values{4, c}=0;
		values{5, c}=0;
		OPBZ{1}=0;
		OPBZ{2}=0;
		OPBZ{3}=0;
		OPBZ{4}=0;
		OPBZ{5}=0;
	END;

	/* ----------------------------------------------------------------- */
	/* ----- Accumulate statistics ------------------------------ */
	/* ----------------------------------------------------------------- */
	/*start a j loop for quarterly reporting period indicator columns*/
    /*comment out each quarterly time window - loop or explicilty define the j-loop value to run it by quarter*/

	/*for example: 
	jan to mar reporting period would be: 	
	do j =&COLBASE to &COLQTR1;

	/*
;
	/*use the following for the entire reporitng period plus the last year's fourth quarter*/
	/*NOTE: CHANGE THIS INITIAL DO-LOOP IF YOU WANT A SPECIFIC REPORTING QUARTER. THIS IS THE ONLY LOOP THAT CAN BE CHANGED WITHUOT CAUSING AN 'ERROR: ARRAY OUT OF SCRIPT.*/
	do j= 1 to &N;
	
	/*run an i loop for each quarterly time window: 
	/*base year previous quarter: october &year0 to december &year0*/

	/*NOTE: DON'T CHANGE THESE LOOPS AND EXPLICIT ARRAYS OR THE PROGRMA WON'T RUNT*/
		IF 1 <=j <=&COLBASE then
			i=1;

		/*report year first quarter: jan &year1 to march &year1*/
		else if &COLBASE < j <=&COLQTR1 then
			i=2;

		/*report year second quarter: apr &year1 to jul &year1*/
		else if &COLQTR1 < j <=&COLQTR2 then
			i=3;

		/*report year third quarter: aug &year1 to sept &year1*/
		ELSE IF &COLQTR2 < j <=&COLQTR3 then
			i=4;

		/*report year fourth quarter : oct &year1 to dec &year1*/
		else if &COLQTR3 < j <=&COLQTR4 THEN
			i=5;

		/*set i to missing to end the loop*/
		else
			i=.;

		/*INDICATOR#23: Patient days with >=90 MME per Day*/
		IF DD[j] GE 90 THEN
			values[i, 7]+1;

		/*INDICATOR#24 BUILD: number of patients who have not been prescribed opioid analgesics in the past 60 days prescribed long-acting extended release opioids*/
		IF DD[j]=0 THEN
			values[i, 10]+1;

		/*if there is an opioid prescription history on a date then the value should be greater than */
		IF days[j] > 0 THEN
			DO;

				/*Number of Opioid Analgesic prescription days*/
				values[i, 1]+1;

				/*Number of SA Opioid Analgesic prescription days*/
				IF LA[j]=0 THEN
					values[i, 2]+1;

				/*Number of LA opioid days per quarter*/
				ELSE IF LA[j] > 0 THEN
					values[i, 3]+1;

				/*INDICATOR#26: Number of prescription days with any overlapping &CLASS*/
				IF days[j] GE 2 then
					values[i, 4]+1;

				/*KS INDICATOR: Number of prescription days with any overlapping LA/ER &CLASS */
				IF LA[j] GE 2 THEN
					values[i, 5]+1;

				/*KS INDICATOR: Number of prescription days with any overlapping LA/ER and SA &CLASS */
				IF (days[j]-LA[j]) > 0 THEN
					values[i, 6] + 1;

				/*KS INDICATOR: Cumulative MME*/
				IF DD[j] > 0 then
					values[i, 8]+DD[j];

				/*patients with opioids*/
				IF OPIOIDCOUNT GE 1 THEN
					values[i, 9]=1;
			END;

		/*Indicator 27: Opioid and Benzo days overlap*/
		IF days[j] > 0 AND BZ[j] > 0 THEN
			OPBZ[i] + 1;

		/*end the j loop for reporting days*/
END;
	/* ----------------------------------------------------------------- */
	/* --- Output observation after the last subgroup ---- */
	/* --- observation --------------------------------------------- */
	/* ----------------------------------------------------------------- */
	IF last.numericid;
RUN;


/* ====================================== */
/* == STEP 4: USE PROC SQL TO CREATE A VIEW OF THE INDICATOR-QUARTER PERIOD DATA VIEW ============= */
/* == CASE-WHEN CONDITIONAL LOGICS ARE USED TO ENUMERATE PATIENT COUNTS AND DIRECT RECALL OF THE SUMMARY PRESCRIPTION DATA ARE KEPT= */
/* ====================================== */
PROC SQL NOPRINT;
	CREATE VIEW REPORT&SET1..PTVIEW&YEAR1
AS
	/*ALL COLUMNS FROM DATA SUMMARY ABOVE*/
	SELECT a.*, /*Flag patient with Opioids*/
	/*INDICATOR#22: Opioid Patients per Quarter*/
	Case when a.&class.QTR0 > 0 THEN 1 ELSE 0 END AS &class.PTQTR0, Case when 
		a.&class.QTR1 > 0 THEN 1 ELSE 0 END AS &class.PTQTR1, Case when 
		a.&class.QTR2 > 0 THEN 1 ELSE 0 END AS &class.PTQTR2, Case when 
		a.&class.QTR3 > 0 THEN 1 ELSE 0 END AS &class.PTQTR3, Case when 
		a.&class.QTR4 > 0 THEN 1 ELSE 0 END AS &class.PTQTR4, 
		/*INDICATOR#23: Patients with >=90 MME per Day*/
		CASE WHEN a.PATMME90QTR0 > 0 THEN 1 ELSE 0 END AS PATMME90FQTR0, CASE WHEN 
		a.PATMME90QTR1 > 0 THEN 1 ELSE 0 END AS PATMME90FQTR1, CASE WHEN 
		a.PATMME90QTR2 > 0 THEN 1 ELSE 0 END AS PATMME90FQTR2, CASE WHEN 
		a.PATMME90QTR3 > 0 THEN 1 ELSE 0 END AS PATMME90FQTR3, CASE WHEN 
		a.PATMME90QTR4 > 0 THEN 1 ELSE 0 END AS PATMME90FQTR4, 
		/*INDICATOR#25: Opioid Naive Count and Build*/
		/*NEED a DATASET FOR 60 DAYS for correct count. But previous quarter history is a good proxy if the focus is on cross-sectional trends.*/
		/*IT IS DIFFICULT TO CALCULATE A MEASURE OF 60-DAYS CONTINUOUSLY BY QUARTER FOR EACH DAY OF THE YEAR WITHOUT THE USE OF TIME-TO-EVENT INDICATORS*/
		/*SEE THE 30-, 60-, 90- days mortality rate following surgical complications as a good example of the challenge*/
		/*this variable says: if there was no opioid in the past quarter and if there is a long-actiong opioid in this quarter, then count it as an opioid naive prescribed la/er.*/
		CASE WHEN a.&class.QTR0=0 AND LA&CLASS.QTR1 > 0 THEN 1 ELSE 0 END AS 
		OPIOIDNAIVEFQTR1, CASE WHEN a.&class.QTR1=0 AND LA&CLASS.QTR2 > 0 THEN 1 ELSE 
		0 END AS OPIOIDNAIVEFQTR2, CASE WHEN a.&class.QTR2=0 AND LA&CLASS.QTR3 > 0 
		THEN 1 ELSE 0 END AS OPIOIDNAIVEFQTR3, CASE WHEN a.&class.QTR3=0 AND 
		LA&CLASS.QTR4 > 0 THEN 1 ELSE 0 END AS OPIOIDNAIVEFQTR4, 
		/*INDICATOR#26: Patients with at least 1 prescription day with overlapping opioids*/
		CASE WHEN a.OVERLAPQTR0&CLASS > 0 THEN 1 ELSE 0 END AS PTOVERQTR0&CLASS, CASE 
		WHEN a.OVERLAPQTR1&CLASS > 0 THEN 1 ELSE 0 END AS PTOVERQTR1&CLASS, CASE WHEN 
		a.OVERLAPQTR2&CLASS > 0 THEN 1 ELSE 0 END AS PTOVERQTR2&CLASS, CASE WHEN 
		a.OVERLAPQTR3&CLASS > 0 THEN 1 ELSE 0 END AS PTOVERQTR3&CLASS, CASE WHEN 
		a.OVERLAPQTR4&CLASS > 0 THEN 1 ELSE 0 END AS PTOVERQTR4&CLASS, 
		/*INDICATOR#27: Patient prescription days with overlapping opioids + benzos*/
		CASE WHEN a.OPIOIDBENZOQTR0 > 0 THEN 1 ELSE 0 END AS PTOVERQTR0OPBZ, CASE 
		WHEN a.OPIOIDBENZOQTR1 > 0 THEN 1 ELSE 0 END AS PTOVERQTR1OPBZ, CASE WHEN 
		a.OPIOIDBENZOQTR2 > 0 THEN 1 ELSE 0 END AS PTOVERQTR2OPBZ, CASE WHEN 
		a.OPIOIDBENZOQTR3 > 0 THEN 1 ELSE 0 END AS PTOVERQTR3OPBZ, CASE WHEN 
		a.OPIOIDBENZOQTR4 > 0 THEN 1 ELSE 0 END AS PTOVERQTR4OPBZ FROM 
		REPORT&SET1..&CLASS.&YEAR1 AS A;
QUIT;

/* ====================================== */
/* == STEP 5: A PROC SUMMARY IS USED TO CREATE A PATIENT-LEVEL TABLE FROM THE SQL VIEW ============= */
/* == A BY STATEMENT IS USED ON PATIENT IDENTIFIER TO REDUCE THE NEED FOR BUILDING CLASSIFICATION VARIABLES= */
/* == A MAX= / AUTONAME IS USED TO FIND THE LARGEST NON-MISSING VALUE FOR ALL NUMERIC VARIABLES--> THIS IS AN EASY TO OBTAIN THE LAST RECORD DATE  == */
/* == OUTPUT VARIABLES WILL END WITH _MAX == */
/* ====================================== */
PROC SUMMARY DATA=REPORT&SET1..PTVIEW&YEAR1 CHARTYPE noprint;
	CLASS numericid / groupinternal;
	TYPES numericid;
	VAR _NUMERIC_;
	OUTPUT OUT=REPORT&SET1..PTDATA&YEAR1 (DROP=_TYPE_ RENAME=_FREQ_=DUPLICATES) MAX= / 
		autoname;
	/* ====================================== */
	/* == STEP 6: A PROC SUMMARY IS USED TO CREATE A REPORTING TABLE FROM THE SQL VIEW ============= */
	/* == REMOVAL OF THE RUN STATEMENT IS APPLIED TO REDUCE THE NEED FOR LOADING THE OUTPUT SUMMARY TABLE = */
	/* == A SUM= / AUTONAME IS USED TO SUMMARIZE ALL NUMERIC COUNTS  == */
	/* == OUTPUT VARIABLES WILL END WITH _MAX_SUM == */
	/* ====================================== */
PROC SUMMARY DATA=REPORT&SET1..PTDATA&YEAR1 CHARTYPE noprint;
	VAR _NUMERIC_;
	OUTPUT OUT=REPORT&SET1..SUMMARY&YEAR1 (DROP=_TYPE_ RENAME=_FREQ_=ALLPATIENTS) SUM= / 
		autoname;
RUN;
QUIT;

DATA SUMMARYREPORT&YEAR1 (KEEP=YEAR INDICATOR ESTIMATES);
SET REPORT&SET1..SUMMARY&YEAR1;

array indicators (*) _NUMERIC_;
do i = 1 to DIM(indicators);
Estimates=indicators[i];
INDICATOR=VNAME(indicators[i]);
YEAR=&YEAR1;
OUTPUT;
END;
RUN;
%mend;
