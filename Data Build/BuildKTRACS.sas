/*MACRO TO BUILD KTRACS DATA*/
%macro BUILDDATA(SET=, DATE1=, DATE2=);
libname backup "H:\Health Promotion\Injury Disability\secure_injury_data\PDMP\BACKUPS DO NOT OVERWRITE";
libname TEMP "C:\TEMP\Space";
options FMTSEARCH=(backup TEMP) nonotes msglevel=i fullstimer obs=max compress=yes REUSE=yes THREADS cpucount=2 nomlogic nosymbolgen;

%if %eval(&SET <= 14) %then %do; 
DATA TEMP.NEWKTRACS&SET (COMPRESS=YES REUSE=YES);
length patient_identifier $36. prescriber dispensary $64. patient_birthyear $4. patient_gender $1. numericid $12.;
SET BACKUP.NEWKTRACS1015 (DROP=patient_birthyear patient_gender where=(("&date1"d <= input(filled_at, anydtdte10.) <= "&date2"d) AND patient_identifier  NE "    "));
%end;

%if %eval(&SET = 15) %then %do; 
DATA TEMP.NEWKTRACS&SET (COMPRESS=YES REUSE=YES);
length patient_identifier $36. prescriber dispensary $64. patient_birthyear $4. patient_gender $1.  numericid $12.;
SET BACKUP.NEWKTRACS1015 (DROP=patient_birthyear patient_gender where=(("&date1"d <= input(filled_at, anydtdte10.) <= "&date2"d) AND patient_identifier  NE "    "))
BACKUP.NEWKTRACS1516 (DROP=patient_birthyear patient_gender where=(("&date1"d <= input(filled_at, anydtdte10.) <= "&date2"d) AND patient_identifier  NE "    "));
%end;

 %if %eval(&SET GE 16) %then %do; 
DATA TEMP.NEWKTRACS&SET (COMPRESS=YES REUSE=YES);
length patient_identifier $36. prescriber dispensary $64. patient_birthyear $4. patient_gender $1.  numericid $12.;
SET BACKUP.NEWKTRACS1617 (DROP=patient_birthyear patient_gender where=(("&date1"d <= input(filled_at, anydtdte10.) <= "&date2"d) AND patient_identifier  NE "    "));
%end;

/*READ ALL FORMATS*/
patient_birthyear = COMPRESS(PUT(patient_identifier,$BIRTHYEAR.));
patient_gender = COMPRESS(PUT(patient_identifier,$gender.));
numericid = COMPRESS(PUT(patient_identifier,$numericid.));

array charrxvar (4) refill_number authorized_refill_count quantity days_supply;
array numrxvar (4) refills_filled refills_ordered Quantity_dispensed dayssupply_dispensed;
do i = 1 to 4;
numrxvar[i]=charrxvar[i]*1;
END;
drop refill_number authorized_refill_count quantity days_supply;

length YEARF YEARW $4. MONTHF MONTHW DAYF DAYW $2. QTRF QTRW $1.;

if written_at NOT IN ('0201-08-2', '0201-08-1', '0201-08-10','1011-05-20', '0201-08-25') then written_date_C=input(written_at, anydtdte10.);
else if written_at IN ('0201-08-2', '0201-08-1', '0201-08-10','1011-05-20', '0201-08-25') then DO;
IF written_at = '0201-08-2' then written_date_C = input(put('2011-08-02',10.),yymmdd10.);
IF written_at = '0201-08-1' then written_date_C = input(put('2011-08-01',10.),yymmdd10.);
IF written_at = '1011-05-20' then written_date_C = input(put('2011-08-01',10.),yymmdd10.);
IF written_at = '0201-08-25' then written_date_C = input(put('2011-08-25',10.),yymmdd10.);
IF written_at = '0201-08-10' then written_date_C = input(put('2011-08-10',10.),yymmdd10.);
END;

filled_date_C=input(filled_at, anydtdte10.);
IF ("&date1"d <= filled_date_C <= "&date2"d);
format written_date_C filled_date_C yymmdd10.;

drop written_at filled_at;

/*CHANGE DATES FROM CHARACTER TO DATE*/
array dt (2) written_date_C  filled_date_C ;
array yt (2) YEARW YEARF;
array qt (2) QTRW QTRF;
array mt (2) MONTHW MONTHF;
array dy (2) DAYW DAYF;
do i = 1 to 2;
yt[i]=COMPRESS(PUT(year(dt[i]),best12.));
qt[i]=COMPRESS(PUT(QTR(dt[i]),best12.));
mt[i]=COMPRESS(PUT(MONTH(dt[i]),best12.));
dy[i]=COMPRESS(PUT(DAY(dt[i]),best12.));
END;

length NDC_11 $11. newrx $1.;
NDC_11=put(substr(NDC,1, 11), $11.);
if refills_filled = 0 then newrx="1";
else newrx="0";
drop NDC refills_filled;

/*CLEAN UP ZIPCODE FOR KANSAS RESIDENT:Only Kansas Residents*/
/*hard code the invalid postal code into a more appropriate value*/
If Prxmatch('/^\d{5,9}/', patient_postal_code) > 0 then  /*use perl expression to find the valid zipcodes. there are some international zipcodes*/
patient_zipcode_C=substr(patient_postal_code, 1,5); /*there were some nine digit zipcodes*/

else if substr(patient_postal_code, 1, 3) = 'KS0' then   /*this postal code begann with KSO then had a valid zipcode afterwards*/
patient_zipcode_C=substr(patient_postal_code, 4, 5);

else if substr(patient_postal_code, 1, 3) = 'SAS' then /*this postal code begann with SAS then had a valid zipcode afterwards*/
patient_zipcode_C=substr(patient_postal_code, 5, 5);

else if patient_postal_code = 'OSBORNE' then /*Give the latest zipcode for the township of Osborne*/
patient_zipcode_C=67473;

else if patient_postal_code = 'K67877' then /*remove the k*/
patient_zipcode_C=67877;

else if patient_postal_code = 'KS' then /*remove the ks*/
patient_zipcode_c= .;

else if patient_postal_code = '`' then patient_zipcode_C=.;

length ZIP_patient ZIP_prescriber ZIP_dispensary $5.;
if patient_city = 'Miltonv' then patient_zipcode_C=67466; /*Give the latest zipcode for the township of Miltonvale*/
else if patient_city = 'Jetmore' then patient_zipcode_C=67854; /*Give the latest zipcode for the township of Jetmore*/
else if patient_city = 'FARLINGTON' then patient_zipcode_C=66734; /*Give the latest zipcode for the township of Farlington*/
drop patient_postal_code;

IF MISSING(patient_zipcode_C) = 0 THEN ZIP_patient=patient_zipcode_C; /*patient zipcode*/
drop patient_zipcode_C;

/*CLEAN UP ZIPCODE FOR KANSAS PRESCRIBER*/
If Prxmatch('/^\d{5,9}/', prescriber_postal_code) > 0 then  /*use perl expression to find the valid zipcodes. there are some international zipcodes*/
prescriber_zipcode_C=substr(prescriber_postal_code, 1,5); /*there were some nine digit zipcodes*/
drop prescriber_postal_code;
if MISSING(prescriber_zipcode_C) = 0 then ZIP_prescriber=prescriber_zipcode_C; /*prescriber zipcode*/
drop prescriber_zipcode_C;

/*CLEAN UP ZIPCODE FOR KANSAS DISPENSARY*/
If Prxmatch('/^\d{5,9}/', dispensary_postal_code) > 0 then /*use perl expression to find the valid zipcodes. there are some international zipcodes*/
dispensary_zipcode_C=substr(dispensary_postal_code, 1,5); /*there were some nine digit zipcodes*/
drop dispensary_postal_code;

if MISSING(dispensary_zipcode_C) = 0 then ZIP_dispensary=dispensary_zipcode_C; /*dispensary zipcode*/
drop dispensary_zipcode_C;

/*NEW STATE AND CITY VARIABLE*/
length ptcitystate precitystate dispcitystate $50. statept statepre statedisp $2. citypt citypre citydisp $25.; 
FORMAT ptcitystate precitystate dispcitystate $50. statept statepre statedisp $2. citypt citypre citydisp $25.; 

IF MISSING(ZIP_patient) = 0 THEN ptcitystate = ZIPCITY(ZIP_patient);
IF MISSING(ZIP_prescriber) = 0 THEN precitystate = ZIPCITY(ZIP_prescriber);
IF MISSING(ZIP_dispensary) = 0 THEN dispcitystate = ZIPCITY(ZIP_dispensary);

array st (3) statept statepre statedisp;
array cy (3) citypt citypre citydisp;
array cyst (3) ptcitystate precitystate dispcitystate;
do i = 1 to 3; 
IF MISSING(cyst[i]) = 0 THEN DO;
st[i]=COMPRESS(UPCASE(SCAN(cyst[i], 2, ",")));
cy[i]=COMPRESS(UPCASE(SCAN(cyst[i], 1, ",")));
END;
END;

IF citypt = "   " THEN citypt = patient_city; 
IF citypre = "   " THEN citypre = prescriber_city; 
IF citydisp = "   " THEN citydisp = dispensary_city; 

*NOTE: a person can age throughout the KTRACS system*/
/*GET RID OF EXTREME AGE*/;

length Insurance Medicare cash military medicaid workers_comp indian_nation unknown major $1.;
array payments (9) Insurance Medicare cash military medicaid workers_comp indian_nation unknown major;
do i = 1 to 9;
payments[i]="0";
IF MISSING(payment_type) = 0 then do;
/*Count Opioids of Insurance rows*/
if payment_type = 'insurance' then payments[1]="1"; /*insurane payment*/
/*Count Opioids of Medicare rows*/
ELSE if payment_type = 'medicare' then payments[2]="1"; /*medicare payment*/ 
ELSE IF payment_type = 'paid' then payments[3]="1"; /*I am assuming these are all cash, which may not be true*/
/*Count Opioids of Medicaid rows*/
else if payment_type= "military" then payments[4]="1";
ELSE if payment_type = 'medicaid' then payments[5]="1"; /*medicaid payment*/
else if payment_type= 'workers_comp' then payments[6]="1";
ELSE if payment_type= "indian_nation" then payments[7]="1";
else if payment_type= "unknown" then payments[8]="1";
else if payment_type= "major" then payments[9]="1";
end;
end;
drop payment_type;

                            /* Your NDC variable needs to be called ndc, and it needs to be a character variable.*/
 							/* The NDC's are 11 numbers long (in the 5-4-2 billing format), and there should 	 */
 							/* be no other symbols, characters, or spaces in the NDC entry.						 */ 	
length class $15. gennme $30. prodnme $30. master_form $30. strength_per_unit $5. uom $8. drug $30. deaclasscode $1. LongShortActing $2.;
mme_dd=0;
array newvar (9) class gennme prodnme master_form strength_per_unit uom drug deaclasscode LongShortActing;

if MISSING(prescription_number) = 0 and length(NDC_11) = 11 and dayssupply_dispensed > 0 and MISSING(Quantity_dispensed) = 0 then do;
 do i = 1 to 9; 
 newvar[1]     	 = COMPRESS(put(NDC_11,class.));

 newvar[2] 			= COMPRESS(put(NDC_11,generic.)); /* gennme formerly named generic_drug_name*/
 newvar[3]      	= COMPRESS(put(NDC_11,product.)); /* prodnme formerly named product_name*/
 newvar[4]      	= COMPRESS(put(NDC_11,master_form.));
 newvar[5] 			= COMPRESS(put(NDC_11,strength.));
 newvar[6]   		= COMPRESS(put(NDC_11,uom.));
 newvar[7]			= COMPRESS(put(NDC_11,drug.));
 newvar[8]	   		= COMPRESS(put(NDC_11,deaclasscode.)); 
 newvar[9]			= COMPRESS(put(NDC_11,Longshortacting.)); /* Specific to identifying long- and short-acting opioids. Replaces DEA_class.
 													DEA_class is not included in the 2016 file */;
 	if newvar[1] = 'Opioid' THEN DO;
		*if  (prxmatch('/Patch/', newvar[4] ) > 0 ) and ( prxmatch('/Fentanyl/', newvar[7]) > 0 ) then dayssupply_dispensed = Quantity_dispensed * 3;
		*if  (prxmatch('/Patch/', newvar[4] ) > 0 ) and ( prxmatch('/Buprenorphine/', newvar[7]) > 0 ) then dayssupply_dispensed = Quantity_dispensed * 7;
			 MME_conversion_factor = put(NDC_11,MME_factor.); 
			 /*  The MME conversion factor is only for opioids;  */
/*********************************************************************************************/
/*  Using variables such as 'number_of_units_dispensed' and 'days_supply' from the 		 	 */
/*	prescription data file, for opioids, the daily dose should be calculated as follows: 	 */ 
/*																							 */
/*	Strength per Unit  * (Number of Units/ Days Supply) * MME conversion factor  =  MME/Day  */
/*  Example:  10 mg oxycodone tablets * (120 tablets/ 30 days)  * 1.5 = 60 MME/day			 */ 
/*********************************************************************************************/
			 mme_dd = Strength_Per_Unit*(Quantity_dispensed/dayssupply_dispensed)*MME_Conversion_Factor;
								end;

end;
 

END;
drop strength_per_unit MME_conversion_factor;

length project_p project_d $1.;
array projects (2) prescriber_associated_to_project dispensary_associated_to_project;
array newprojects (2) project_p project_d;
do i = 1 to 2;
if projects[i]="false" then newprojects[i]="0";
else newprojects[i]="1";
END;

drop dispensary_associated_to_project prescriber_associated_to_project;

length opioid benzo MuscleRelaxant Stimulant Misc Otherdrug $1.;
array dtype (6) opioid benzo MuscleRelaxant Stimulant Misc Otherdrug;
do i = 1 to 6;
dtype[i]="0";

/*Count Opioids of Opioid rows*/
if Class = 'Opioid' then dtype[1]="1"; /*Opioid*/
/*Count Opioids of Benzo rows*/
else if Class = 'Benzo' then dtype[2]="1"; /*Benzo*/
/*Count Opioids of MuscleRelaxant rows*/
else if Class = 'MuscleRelaxant' then dtype[3]="1"; /*MuscleRelaxant*/
/*Count Opioids of Stimulant rows*/
else if Class = 'Stimulant' then dtype[4]="1"; /*Stimulant*/
/*Count Opioids of Misc rows*/
else if Class = 'Misc' then dtype[5]="1"; /*Misc*/
else dtype[6] = "1";
END;
drop class;

length CSIIIV CSVVI $1.;
CSIIIV="0";CSVVI="0";
if otherdrug = "0" then do;
if deaclasscode = 2 or deaclasscode = 3 or deaclasscode = 4 then CSIIIV="1";
else if deaclasscode = 5 or deaclasscode = 6 then CSVVI="1";
end;

PROC SQL NOPRINT;
CREATE TABLE BACKUP.NEWKTRACS&SET AS SELECT * FROM TEMP.NEWKTRACS&SET 
ORDER BY patient_identifier, filled_date_c;
RUN;
QUIT;

PROC DATASETS LIBRARY=BACKUP;
MODIFY NEWKTRACS&SET;
INDEX CREATE patient_identifier / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE prescriber / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE dispensary / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE prescription_number / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE filled_date_c / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE ZIP_patient / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE ZIP_prescriber / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE ZIP_dispensary / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE citypt / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE citypre / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE citydisp / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE BYVAR1=(patient_identifier filled_date_c) / nomiss UPDATECENTILES = ALWAYS;
INDEX CREATE BYVAR2=(prescriber patient_identifier filled_date_c) / nomiss UPDATECENTILES = ALWAYS;
RUN;
QUIT;


%MEND;
