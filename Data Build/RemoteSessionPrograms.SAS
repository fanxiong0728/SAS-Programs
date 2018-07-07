
/*A SAS Program Template I used to create multiple summary reports using %include and SAS/Macro with the Remote Sessions procedure*/

options compress=yes REUSE=yes mlogic symbolgen CPUCOUNT=ACTUAL THREADS SASCMD='!sascmd -nosyntaxcheck -CONFIG "C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg" -SORTSIZE 2G -UBUFSIZE 64K -IBUFSIZE 32767 -BUFNO 200 -IBUFNO 20 -UBUFNO 20 -MEMSIZE 16G -BUFSIZE 64K' sysrputsync autosignon;
LIBNAME PMP "H:\Health Promotion\Injury Disability\secure_injury_data\PDMP";
libname backup "H:\Health Promotion\Injury Disability\secure_injury_data\PDMP\BACKUPS DO NOT OVERWRITE";
libname final "H:\Health Promotion\Injury Disability\secure_injury_data\PDMP\KTRACS Final Data";
LIBNAME TEMP "C:\TEMP\SPACE";
run;

rsubmit REPORT10 wait=no sysrputsync=yes ;
options DSACCEL=ANY THREADS FULLSTIMER DBSLICEPARM=(ALL) msglevel=i COMPRESS=YES REUSE=YES FMTSEARCH=(WORK BACKUP) THREADS CPUCOUNT=ACTUAL mlogic symbolgen;
	RUN;
	LIBNAME ALLTEMP ("C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2010" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2011" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2012"
				"C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2013" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2014" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2015" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2016");
	%sysrput PATH10=%sysfunc(pathname(ALLTEMP));
	%include "H:\Health Promotion\Injury Disability\xiong_secure\DDPI FACTSHEETS\PCC\KTRACS MACRO PCC 4.28.2017.sas";
	%VIEWSQL (SET=10);
endrsubmit;

rsubmit REPORT11 wait=no sysrputsync=yes ;
options DSACCEL=ANY THREADS FULLSTIMER DBSLICEPARM=(ALL) msglevel=i COMPRESS=YES REUSE=YES FMTSEARCH=(WORK BACKUP) THREADS CPUCOUNT=ACTUAL mlogic symbolgen;
	RUN;	
	LIBNAME ALLTEMP ("C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2010" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2011" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2012"
				"C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2013" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2014" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2015" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2016");
	%include "H:\Health Promotion\Injury Disability\xiong_secure\DDPI FACTSHEETS\PCC\KTRACS MACRO PCC 4.28.2017.sas";
	%VIEWSQL (SET=11);
	%sysrput PATH11=%sysfunc(pathname(ALLTEMP));
endrsubmit;

rsubmit REPORT12 wait=no sysrputsync=yes;
options DSACCEL=ANY THREADS FULLSTIMER DBSLICEPARM=(ALL) msglevel=i COMPRESS=YES REUSE=YES FMTSEARCH=(WORK BACKUP) THREADS CPUCOUNT=ACTUAL mlogic symbolgen;
	RUN;
	LIBNAME ALLTEMP ("C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2010" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2011" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2012"
				"C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2013" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2014" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2015" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2016");
	%include "H:\Health Promotion\Injury Disability\xiong_secure\DDPI FACTSHEETS\PCC\KTRACS MACRO PCC 4.28.2017.sas";
	%VIEWSQL (SET=12);
	%sysrput PATH12=%sysfunc(pathname(ALLTEMP));
endrsubmit;

rsubmit REPORT13 wait=no sysrputsync=yes;
options DSACCEL=ANY THREADS FULLSTIMER DBSLICEPARM=(ALL) msglevel=i COMPRESS=YES REUSE=YES FMTSEARCH=(WORK BACKUP) THREADS CPUCOUNT=ACTUAL mlogic symbolgen;
	RUN;
	LIBNAME ALLTEMP ("C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2010" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2011" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2012"
				"C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2013" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2014" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2015" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2016");
	%include "H:\Health Promotion\Injury Disability\xiong_secure\DDPI FACTSHEETS\PCC\KTRACS MACRO PCC 4.28.2017.sas";
	%VIEWSQL (SET=13);
	%sysrput PATH13=%sysfunc(pathname(ALLTEMP));
endrsubmit;

rsubmit REPORT14 wait=no sysrputsync=yes;
options DSACCEL=ANY THREADS FULLSTIMER DBSLICEPARM=(ALL) msglevel=i COMPRESS=YES REUSE=YES FMTSEARCH=(WORK BACKUP) THREADS CPUCOUNT=ACTUAL mlogic symbolgen;
	RUN;
	LIBNAME ALLTEMP ("C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2010" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2011" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2012"
				"C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2013" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2014" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2015" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2016");
	%include "H:\Health Promotion\Injury Disability\xiong_secure\DDPI FACTSHEETS\PCC\KTRACS MACRO PCC 4.28.2017.sas";
	%VIEWSQL (SET=14);
	%sysrput PATH4=%sysfunc(pathname(ALLTEMP));
endrsubmit;

rsubmit REPORT15 wait=no sysrputsync=yes;
options DSACCEL=ANY THREADS FULLSTIMER DBSLICEPARM=(ALL) msglevel=i COMPRESS=YES REUSE=YES FMTSEARCH=(WORK BACKUP) THREADS CPUCOUNT=ACTUAL mlogic symbolgen;
	RUN;
	LIBNAME ALLTEMP ("C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2010" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2011" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2012"
				"C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2013" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2014" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2015" "C:\Users\fxiong\TEMP\KTRACS BACKUP\Opioid\2016");
	%include "H:\Health Promotion\Injury Disability\xiong_secure\DDPI FACTSHEETS\PCC\KTRACS MACRO PCC 4.28.2017.sas";
	%VIEWSQL (SET=15);
	%sysrput PATH15=%sysfunc(pathname(ALLTEMP));
endrsubmit;

LISTTASK _ALL_;
WAITFOR _ALL_ REPORT10 REPORT11 REPORT12 REPORT13 REPORT14 REPORT15;
SIGNOFF REPORT10;
SIGNOFF REPORT11;
SIGNOFF REPORT12;
SIGNOFF REPORT13;
SIGNOFF REPORT14;
SIGNOFF REPORT15;
