

 *-------------------------------------------------------------------*
 *  Author:  Fan Xiong            <fanxiong0728@gmail.com>           *
 *-------------------------------------------------------------------*
 
/*This SAS program was used to unzip the NCHS NVSS single year of age-bridged race population estimate files for
multiple years using a URL to extract the original data from the CDC FTP site*/

**************
BINARY TRANSFER (read)
Reading a file with FTP, BINARY:
This is useful if the file needs to remain completely intact. 
For example, when moving a ZIP, Excel, or SAS dataset file.
***************;
filename nvss1015 ftp 'pcen_v2015_y1015_sas7bdat.zip' host='ftp.cdc.gov' 
user='anonymous' password='fxiong@kdheks.gov' 
cd='/pub/Health_Statistics/NCHS/Datasets/NVSS/bridgepop/2015' recfm=s debug;

FILENAME lcl 'C:\Users\fxiong\Desktop User\pcen_v2015_y1015_sas7bdat.zip' recfm=n;

DATA _NULL_;
N=1;
INFILE nvss1015 NBYTE=n;
INPUT;
FILE lcl ;
PUT _INFILE_ @@; 
RUn;

filename v2015zip zip 'C:\Users\fxiong\Desktop User\pcen_v2015_y1015_sas7bdat.zip';

data contents;
length memname $200. isFolder 8;
fid=dopen("v2015zip");
 if fid=0 then
  stop;
 memcount=dnum(fid);
 do i=1 to memcount;
  memname=dread(fid,i);
  /* check for trailing / in folder name */
  isFolder = (first(reverse(trim(memname)))='/');
  output;
 end;
 rc=dclose(fid);
run;

 /* create a report of the ZIP contents */
title "Files in the ZIP file";
proc print data=contents noobs N;
run;

/* Copy a zipped data set into the WORK library */
filename ds "%sysfunc(getoption(work))/pcen_v2015_y1015_sas7bdat.sas7bdat" ;
 
data _null_;
   /* reference the member name WITH folder path */
   infile v2015zip(pcen_v2015_y1015_sas7bdat.sas7bdat) 
	  lrecl=256 recfm=F length=length eof=eof unbuf;
   file   ds lrecl=256 recfm=N;
   input;
   put _infile_ $varying256. length;
   return;
 eof:
   stop;
run;
ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/datasets/nvss/bridgepop/2000_09/icen_2000_09_y0509.sas.zip
/*
**************
BINARY TRANSFER (read)
Reading a file with FTP, BINARY:
This is useful if the file needs to remain completely intact. 
For example, when moving a ZIP, Excel, or SAS dataset file.
****************/
;
filename nvss0509 ftp 'icen_2000_09_y0509.sas.zip' host='ftp.cdc.gov' 
user='anonymous' password='fxiong@kdheks.gov' 
cd='/pub/Health_Statistics/NCHS/datasets/nvss/bridgepop/2000_09/' recfm=s debug;

FILENAME lcl 'C:\Users\fxiong\Desktop User\icen_2000_09_y0509.sas.zip' recfm=n;

DATA _NULL_;
N=1;
INFILE nvss0509 NBYTE=n;
INPUT;
FILE lcl ;
PUT _INFILE_ @@; 
RUn;

filename inter zip 'C:\Users\fxiong\Desktop User\icen_2000_09_y0509.sas.zip';

data contents;
length memname $200. isFolder 8;
fid=dopen("inter");
 if fid=0 then
  stop;
 memcount=dnum(fid);
 do i=1 to memcount;
  memname=dread(fid,i);
  /* check for trailing / in folder name */
  isFolder = (first(reverse(trim(memname)))='/');
  output;
 end;
 rc=dclose(fid);
run;

 /* create a report of the ZIP contents */
title "Files in the ZIP file";
proc print data=contents noobs N;
run;

/* Copy a zipped data set into the WORK library */
filename ds "%sysfunc(getoption(work))/icen_2000_09_y0509.sas7bdat" ;
 
data _null_;
   /* reference the member name WITH folder path */
   infile inter(icen_2000_09_y0509.sas7bdat) 
	  lrecl=256 recfm=F length=length eof=eof unbuf;
   file   ds lrecl=256 recfm=N;
   input;
   put _infile_ $varying256. length;
   return;
 eof:
   stop;
run;

/*
**************
BINARY TRANSFER (read)
Reading a file with FTP, BINARY:
This is useful if the file needs to remain completely intact. 
For example, when moving a ZIP, Excel, or SAS dataset file.
****************/
;
filename nvss0004 ftp 'icen_2000_09_y0004.sas.zip' host='ftp.cdc.gov' 
user='anonymous' password='fxiong@kdheks.gov' 
cd='/pub/Health_Statistics/NCHS/datasets/nvss/bridgepop/2000_09' recfm=s debug;

FILENAME lcl 'C:\Users\fxiong\Desktop User\icen_2000_09_y0004.sas.zip' recfm=n;

DATA _NULL_;
N=1;
INFILE nvss0004 NBYTE=n;
INPUT;
FILE lcl ;
PUT _INFILE_ @@; 
RUn;

filename inter zip 'C:\Users\fxiong\Desktop User\icen_2000_09_y0004.sas.zip';

data contents;
length memname $200. isFolder 8;
fid=dopen("inter");
 if fid=0 then
  stop;
 memcount=dnum(fid);
 do i=1 to memcount;
  memname=dread(fid,i);
  /* check for trailing / in folder name */
  isFolder = (first(reverse(trim(memname)))='/');
  output;
 end;
 rc=dclose(fid);
run;

 /* create a report of the ZIP contents */
title "Files in the ZIP file";
proc print data=contents noobs N;
run;

/* Copy a zipped data set into the WORK library */
filename ds "%sysfunc(getoption(work))/icen_2000_09_y0004.sas7bdat" ;
 
data _null_;
   /* reference the member name WITH folder path */
   infile inter(icen_2000_09_y0004.sas7bdat) 
	  lrecl=256 recfm=F length=length eof=eof unbuf;
   file   ds lrecl=256 recfm=N;
   input;
   put _infile_ $varying256. length;
   return;
 eof:
   stop;
run;


/*Begin Populaton Build*/
data ks0015;
	set Pcen_v2015_y1015_sas7bdat icen_2000_09_y0509 icen_2000_09_y0004;  
where ST_FIPS=20;
/*Kansas is ST_FIPS=20*/
/*ALWAYS SUBSET TO A STATE BEFORE MAPPING COUNTY NAMES OR OTHER ATTRIBUTES 
TO COUNTY SINCE COUNTIES FROM MULTIPLE STATES CAN HAVE THE SAME FIPS*/

length  sex $6.;

	if racesex = 1 OR racesex = 3 or racesex = 5 or racesex = 7 then sex='male';
	if racesex = 2 OR racesex = 4 or racesex = 6 or racesex = 8 then sex='female';

/*Age is a numeric variable: age */
length ageg $5.;
ageg=compress(put(age, ageg.));

/*County and State FIPS are Numeric variables*/
/*IMPORTANT NOTE: COUNTY FIPS CODE DO NOT INCLUDE THE STATE FIPS CODE*/
/*County FIPS: CO_FIPS*/
HLTPRPN=compress(put(CO_FIPS, HLTPRPN.));
HLTPRPN_=put(HLTPRPN, $HPRNDSA.);

run;

/*Generate US 2000 Standard Population */
/*You may not have access to my folder so please save the standard population tables to your own folder and change the path below*/
PROC IMPORT datafile="H:\Health Promotion\Injury Disability\xiong_secure\PDMP\Datasets\US_std_pop.xls" dbms=xls out=US2000STD replace; run;
data Us2000std;
set us2000std;
length ageg $5.;
ageg=put(age_, ageg.);
run;
proc means data=US2000Std noprint;
class ageg;
types ageg;
var population pyear;
output out=US_Standard (drop=_TYPE_ _FREQ_) SUM(population pyear) = standard_population pyear;
run;
data standardpop;
set US_Standard;
proportion=pyear/274634;
run;

PROC SUMMARY data=KS0015 nway noprint threads CHARTYPE;  /*NOTE: I like to use the noprint, threads, and chartype options for efficient processing*/
class %qscan(&class,2) %qscan(&class,3) %qscan(&class,4) %qscan(&class,5) / ascending; /*An order by 'ascending' or 'descending' can be used to sort it*/
var pop2000 pop2001 pop2002 pop2003 pop2004 pop2005 pop2006 pop2007 pop2008 pop2009 pop2010_jul pop2011 pop2012 pop2013 pop2014 pop2015;
output out=KSpop (DROP=_TYPE_ _FREQ_) 
sum(pop2000 pop2001 pop2002 pop2003 pop2004 pop2005 pop2006 pop2007 pop2008 pop2009 pop2010_jul pop2011 pop2012 pop2013 pop2014 pop2015)= pop2000 pop2001 pop2002 pop2003 pop2004 pop2005 pop2006 pop2007 pop2008 pop2009 pop2010 pop2011 pop2012 pop2013 pop2014 pop2015;
RUN;

