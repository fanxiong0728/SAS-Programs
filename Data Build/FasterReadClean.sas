/*A SAS Program with a series of DATA steps to create character string variables for faster retrieval of some numeric variables, such as long integers, dates, formats, etc.*/

/*Options and Directories*/
OPTIONS OBS=MAX  COMPRESS=NO THREADS CPUCOUNT=4;
LIBNAME pfs "C:\TEMP\Work Folder";
libname backup "H:\Health Promotion\Injury Disability\secure_injury_data\PDMP\BACKUPS DO NOT OVERWRITE";
LIBNAME MPE "C:\TEMP\MPE";
libname report "H:\Health Promotion\Injury Disability\xiong_secure\DDPI\Reporting\Sept20165Aug2017";
LIBNAME PMP "H:\Health Promotion\Injury Disability\secure_injury_data\PDMP";


/*READ ALL THE FORMAT DATASETS INTO WORK LIBRARY*/
proc format cntlin = BACKUP.KTRACS_BIRTH library=WORK ; 
run;
/*PATIENT ID FORMAT*/
proc sort data =BACKUP.UNIQUEPATIENTIDFMT OUT=BACKUP.UNIQUEPATIENTIDFMT2 TAGSORT; 
	by fmtname; 
proc format cntlin = BACKUP.UNIQUEPATIENTIDFMT2 library=WORK; 
run;
/*PRESCRIBER ID FORMAT*/
proc sort data =BACKUP.UNIQUEPRESCRIBERIDFMT OUT=BACKUP.UNIQUEPRESCRIBERIDFMT2 TAGSORT; 
	by fmtname; 
proc format cntlin = BACKUP.UNIQUEPRESCRIBERIDFMT2 library=WORK; 
run;
/*DISPENSARY ID FORMAT*/
proc sort data =BACKUP.UNIQUEDISPENSARYIDFMT OUT=BACKUP.UNIQUEDISPENSARYIDFMT2 TAGSORT; 
	by fmtname; 
proc format cntlin = BACKUP.UNIQUEDISPENSARYIDFMT2 library=WORK; 
run;
/*CDC MME 2016 TABLE*/
proc sort data =pmp.conversion_format2016 OUT=BACKUP.conversion_format2016 TAGSORT; 
	by fmtname; 
proc format cntlin = BACKUP.conversion_format2016 library=WORK;  
run;

OPTIONS OBS=MAX FMTSEARCH=(WORK) COMPRESS=YES THREADS CPUCOUNT=4;

%let MAINVAR = NEWPATID SEX AGEC NEWPREID NEWDISPID project_p2 project_d2 ;
%let DATEVAR = YEARF QTRF MONTHF filled_date_C YEARW QTRW MONTHW written_date_c;
%let DRUGVAR = RXNUMERICID CHARQUANTITY CHARDAYSSUPPLY CHARMME;
%let COMBINEDRUGVAR= COMBINEDRUGFIELDS;
%LET SETKEEPVAR = OTHERDRUG filled_date_C written_date_c patient_identifier MALE2 FEMALE2 AGE prescriber project_p dispensary project_d Quantity_dispensed dayssupply_dispensed NDC ZIP_patient ZIP_dispensary;
%let WHERECLAUSE = written_date_c GE "01JAN2013"d AND OTHERDRUG = 0 AND age NE . and dayssupply_dispensed > 0 and prescriber NE '     ' and patient_identifier NE '     ' and zipstate(ZIP_patient) = "KS" and zipstate(ZIP_dispensary) = "KS";
%let newvarcreation = ;

DATA BACKUP.NEWFASTKTRACS (KEEP=&MAINVAR &DATEVAR &COMBINEDRUGVAR &DRUGVAR) / VIEW=BACKUP.NEWFASTKTRACS;
length patient_identifier $37. prescriber $65. dispensary $65.;
SET  BACKUP.Qtryearptdata (KEEP=&SETKEEPVAR WHERE=(&WHERECLAUSE));

/*MACRO TO CODE AND ADD NEW FIELDS*/
&newvarcreation;

/*create shorter character unique ids*/
NEWPATID=PUT(patient_identifier, $CHARNUMERICPATID.);
NEWPREID=PUT(prescriber, $CHARNUMERICPREID.);
NEWDISPID=PUT(dispensary, $CHARNUMERICDISPID.);

/*create shorter patient age and gender variables*/
length sex project_p2 project_d2 $1.;
IF MALE2 > 0 THEN SEX="M";
else IF FEMALE2 > 0 THEN SEX = "F";
else SEX ="U";

project_p2=COMPRESS(INPUT(project_p,best12.));
project_d2=COMPRESS(INPUT(project_d,best12.));

length agec $3.;
AGEC=COMPRESS(INPUT(AGE,best12.));

/*USE CDC FORMAT TABLE TO OBTAIN DRUG FIELDS*/
length class $14. DRUG $18. deaclasscode $1. LongShortActing $2.;
NDC_13=put(substr(NDC,1, 11), $11.);
class = COMPRESS(put(NDC_13,$class.));
DRUG = COMPRESS(put(NDC_13,$drug.));
deaclasscode= COMPRESS(put(NDC_13,$deaclasscod.));
MME_conversion_factor = COMPRESS(put(NDC_13,$MME_factor.))*1;
LongShortActing	= COMPRESS(put(NDC_13,$Longshortac.)); /* Specific to identifying long- and short-acting opioids. Replaces DEA_class.
													DEA_class is not included in the 2016 file */
IF LongShortActing = " " THEN LongShortActing = "NA";
/*MME CALCULATION*/

length strength_per_unit 8. master_form $32.;
strength_per_unit = COMPRESS(put(NDC_13,$strength.))*1;
master_form =  COMPRESS(put(NDC_13,$master_form.));

if  (class = 'Opioid' and prxmatch('/Patch/', master_form) > 0 ) and ( prxmatch('/Fentanyl/', drug) > 0 ) then dayssupply_dispensed = Quantity_dispensed * 3;
if  (class = 'Opioid' and prxmatch('/Patch/', master_form) > 0 ) and ( prxmatch('/Buprenorphine/', drug) > 0 ) then dayssupply_dispensed = Quantity_dispensed * 7;

length mme_dd 8.;
if  (class = 'Opioid') THEN mme_dd = Strength_Per_Unit*(Quantity_dispensed/dayssupply_dispensed)*MME_Conversion_Factor;
ELSE mme_dd = 0;

/*create shorter character drug variables*/
length CHARQUANTITY $12. CHARDAYSSUPPLY $12.;
CHARQUANTITY=COMPRESS(INPUT(Quantity_dispensed,best12.));
CHARDAYSSUPPLY=COMPRESS(INPUT(dayssupply_dispensed,best12.));

length CHARMME $12. ;
CHARMME=COMPRESS(INPUT(mme_dd,best12.));

length COMBINEDRUGFIELDS $34.;
COMBINEDRUGFIELDS=CATX("|",OF CLASS,DRUG,DEACLASSCODE,LongShortActing);
LABEL COMBINEDRUGFIELDS = "CLASS|DRUG|DEACLASSCODE|LongShortActing";

length RXNUMERICID $12.;
RXNUMERICID=COMPRESS(PUT(_N_,best12.));

/*create shorter character date variables*/
length YEARF YEARW $4. MONTHF MONTHW $2. QTRF QTRW $1.;
YEARF=COMPRESS(PUT(YEAR(FILLED_DATE_C),best12.));
QTRF=COMPRESS(PUT(QTR(FILLED_DATE_C),best12.));
MONTHF=COMPRESS(PUT(MONTH(FILLED_DATE_C),best12.));

YEARW=COMPRESS(PUT(YEAR(written_date_c),best12.));
QTRW=COMPRESS(PUT(QTR(written_date_c),best12.));
MONTHW=COMPRESS(PUT(MONTH(written_date_c),best12.));
RUN;

