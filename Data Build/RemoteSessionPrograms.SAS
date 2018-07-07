/*A SAS Program Template I used to create read, manipulate, and export summary reports for hospital discharge claims (HD) using %include and SAS/Macro with the Remote Sessions procedure*/

options fmtsearch=(WORK HD) compress=yes REUSE=yes mlogic symbolgen CPUCOUNT=ACTUAL THREADS 

/*Intialize a Local SAS Session*/

SASCMD='!sascmd -nosyntaxcheck -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" 
-SORTSIZE 2G -UBUFSIZE 64K -IBUFSIZE 32767 -BUFNO 200 -IBUFNO 20 -UBUFNO 20 -MEMSIZE 16G -BUFSIZE 64K' sysrputsync autosignon;
%include 'H:\Health Promotion\Injury Disability\xiong_secure\DDPI FACTSHEETS\FX_COUNTY CODES AND REGIONS MASTER LIST.sas' / source2;

LIBNAME HD "C:\TEMP\Medical Discharges\HD";
proc format library=HD;
value agecat_f	 
  .='missing'
  1='<1 yr old'
  2='1-4 yrs'
  3='5-14 yrs'
  4='15-24 yrs'
  5='25-34 yrs'
  6='35-44 yrs'
  7='45-54 yrs'
  8='55-64 yrs'
  9='65-74 yrs'
  10='75-84 yrs'
  11='85+ yrs'
;
run;

/*Intialize a REMOTE SAS Session*/

/*First Task Reads and Manipulate 2015 Data*/

rsubmit HD2015 wait=no sysrputsync=yes ;
options DSACCEL=ANY fmtsearch=(WORK HD) compress=yes REUSE=yes mlogic symbolgen CPUCOUNT=ACTUAL THREADS 
CPUCOUNT=2 mlogic symbolgen;
LIBNAME HD "C:\TEMP\Medical Discharges\HD";
%include 'H:\Health Promotion\Injury Disability\xiong_secure\DDPI FACTSHEETS\FX_COUNTY CODES AND REGIONS MASTER LIST.sas' / source2;

	/*Read LOG-IN Information*/
	%include "C:\TEMP\Medical Discharges\SAS CONNECT PROGRAMS for HD\LOGINORACLE.sas";
	%LOGIN;

	/*Export HD Year Specific Data from ORACLE and Create a View*/
	%include "C:\TEMP\Medical Discharges\SAS CONNECT PROGRAMS for HD\EXPORTHD.sas";
	%EXPORTHD(YEAR=2015);

	/*Manipulate SAS View*/
	%include "C:\TEMP\Medical Discharges\SAS CONNECT PROGRAMS for HD\MANIPULATEDATAV2.sas";
	%ManipulateHD (YEAR=2015);

	/*Create PROC FREQ output of SAS View*/
	%include "C:\TEMP\Medical Discharges\SAS CONNECT PROGRAMS for HD\FREQMACRO.sas";
	%FREQMACRO(DATA=Ksicd102015);

endrsubmit;

/*Second Task Reads and Manipulate 2016 Data*/

rsubmit HD2016 wait=no sysrputsync=yes ;
options DSACCEL=ANY fmtsearch=(WORK HD) compress=yes REUSE=yes mlogic symbolgen CPUCOUNT=ACTUAL THREADS 
CPUCOUNT=2 mlogic symbolgen;
LIBNAME HD "C:\TEMP\Medical Discharges\HD";
%include 'H:\Health Promotion\Injury Disability\xiong_secure\DDPI FACTSHEETS\FX_COUNTY CODES AND REGIONS MASTER LIST.sas' / source2;

	/*Read LOG-IN Information*/
	%include "H:\Health Promotion\Injury Disability\xiong_secure\ORACLE\LOGINORACLE.sas";
	%LOGIN;

	/*Export HD Year Specific Data from ORACLE and Create a View*/
	%include "C:\TEMP\Medical Discharges\SAS CONNECT PROGRAMS for HD\EXPORTHD.sas";
	%EXPORTHD(YEAR=2016PROVISIONAL);

	/*Manipulate SAS View*/
	%include "C:\TEMP\Medical Discharges\SAS CONNECT PROGRAMS for HD\MANIPULATEDATAV2.sas";
	%ManipulateHD (YEAR=2016PROVISIONAL);

	/*Create PROC FREQ output of SAS View*/
	%include "C:\TEMP\Medical Discharges\SAS CONNECT PROGRAMS for HD\FREQMACRO.sas";
	%FREQMACRO(DATA=Ksicd102016provisional);

endrsubmit;

/*List all Running Tasks in the Local SAS Log*/
LISTTASK _ALL_;
/*Finish all Running Tasks before returning to the local SAS Session*/
WAITFOR _ALL_ HD2015 HD2016;
/*Sign Off and Close All Remote SAS Sessions*/
SIGNOFF HD2015;
SIGNOFF HD2016;

