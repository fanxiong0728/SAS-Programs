*-------------------------------------------------------------------*
 *  Author:  Fan Xiong            <fanxiong0728@gmail.com>           *
*-------------------------------------------------------------------*

*-------------------------------------------------------------------*
/*

Linkage method was based in part on 
Dusetzina SB, Tyree S, Meyer AM, et al. 
Linking Data for Health Services Research: A Framework and Instructional Guide [Internet]. 
Rockville (MD): Agency for Healthcare Research and Quality (US); 2014 Sep. 4, An Overview of Record Linkage Methods. 
Available from: https://www.ncbi.nlm.nih.gov/books/NBK253312/

*/

/*This program was a training program using CMS Medicare Part D data to estimate the propensity of a prescriber to belong into a speciality field.*/

/*Further implementation was conducted on PDMP data to match prescribers on first name, last name, and location to their CMS reported Part D speciality.*/

/*Prescriber Data */

proc import datafile="H:\Health Promotion\Injury Disability\secure_injury_data\PDMP\Prescriber Population Files\12.31.2015 Kansas Prescribers.xls" dbms=xls out=prescriber;
run;

data prescriber2;
/*create fields for speciality, first name, last name, and county*/
length spec_ speciality1-speciality5 $103. FirstName_ $50. LastName_ $50. County_ $50. STATE $2.;
set prescriber;
STATE="KS";
/*place all character variables to standardized in an array*/
array cvars (*) Firstname LastName Spec County;
/*create new character variables based on standardizion*/
array newcvars (*) Firstname_ LastName_ Spec_ County_;

do i = 1 to dim(cvars);

/*Set all Invalid Values to Blank or Missing*/
if cvars[i] IN ("NULL","  ") THEN newcvars[i] = "  ";
ELSE newcvars[i] = cvars[i];

/*Remove all Special Characters e.g., compress() and leading/trailing spaces e.g., strip()*/
IF newcvars[i] NE "   " THEN newcvars[i]=STRIP(compress(newcvars[i], ":-'.,’{}[]/\()+~`!&#$%^&*_<>?"));
/*Make all characters in a string uppercase*/
IF newcvars[i] NE "   " THEN  newcvars[i]=upcase(newcvars[i]);
END;

/*Create Multiple Specialty Fields for Providers with More than 1 Specialty in Kansas*/
/*Use the SCAN function to specify any delimiter and strip the specialty found*/
array special (*) speciality1-speciality5;
do i = 1 to 5;
if Spec_ NE "   " THEN special[i]=STRIP(SCAN(Spec_,i,";"));
END;

KEEP Firstname_ LastName_ Spec_ speciality1-speciality5 County_ STATE;

run;

/*Prescriber Medicare NPI or DEA Data */
/*NOTE: The Prescriber Summary File is an open source data from the Center for Medicare and Medicaid Services. It is used here for illustrative and educative purpose only*/
/*Data Source: Medicare Provider Utilization and Payment Data: 2015 Part D Prescriber
			   Available at https://data.cms.gov/Medicare-Claims/Medicare-Provider-Utilization-and-Payment-Data-201/3z4d-vmhm */

DATA WORK.PartD_Prescriber_PUF_NPI_Drug_15;
	LENGTH
		npi								$ 10
		nppes_provider_last_org_name	$ 70
		nppes_provider_first_name		$ 20
		nppes_provider_city				$ 40
		nppes_provider_state			$  2
		specialty_description			$ 75
		description_flag				$  1
		drug_name		 		 		$ 30
		generic_name					$ 30
		bene_count						   8
		total_claim_count				   8
		total_30_day_fill_count			   8
		total_day_supply				   8
		total_drug_cost					   8
		bene_count_ge65					   8
		bene_count_ge65_suppress_flag	$  1
		total_claim_count_ge65			   8
		ge65_suppress_flag				$  1
		total_30_day_fill_count_ge65	   8
		total_day_supply_ge65			   8
		total_drug_cost_ge65			   8
	;
	
	INFILE 'C:\Users\fxiong\Downloads\PartD_Prescriber_PUF_NPI_DRUG_15\PartD_Prescriber_PUF_NPI_Drug_15.txt'
		dlm='09'x
		pad missover
		firstobs = 2
		dsd;

	INPUT
		npi							
		nppes_provider_last_org_name
		nppes_provider_first_name
		nppes_provider_city
		nppes_provider_state
		specialty_description
		description_flag
		drug_name
		generic_name
		bene_count
		total_claim_count
		total_30_day_fill_count
		total_day_supply
		total_drug_cost
		bene_count_ge65
		bene_count_ge65_suppress_flag
		total_claim_count_ge65
		ge65_suppress_flag
		total_30_day_fill_count_ge65
		total_day_supply_ge65
		total_drug_cost_ge65
	;	

	LABEL
		npi								= "National Provider Identifier"
		nppes_provider_last_org_name	= "Last Name/Organization Name of the Provider"
		nppes_provider_first_name		= "First Name of the Provider"
		nppes_provider_city				= "City of the Provider"
		nppes_provider_state			= "State Code of the Provider"
		specialty_description			= "Provider Specialty Type"
		description_flag				= "Source of Provider Specialty"
		drug_name		 		 		= "Brand Name"
		generic_name					= "USAN Generic Name - Short Version"
		bene_count						= "Number of Medicare Beneficiaries"
		total_claim_count 				= "Number of Medicare Part D Claims, Including Refills"
		total_30_day_fill_count			= "Number of Standardized 30-Day Fills, Including Refills"
		total_day_supply 				= "Number of Day's Supply for All Claims"
		total_drug_cost 				= "Aggregate Cost Paid for All Claims"
		bene_count_ge65					= "Number of Medicare Beneficiaries Age 65+"
		bene_count_ge65_suppress_flag	= "Reason for Suppression of Bene_Count_Ge65"
		total_claim_count_ge65			= "Number of Claims, Including Refills, for Beneficiaries Age 65+"
		ge65_suppress_flag				= "Reason for Suppression of Total_Claim_Count_Ge65, Total_30_Day_Fill_Count_Ge65, Total_Day_Supply_Ge65 and Total_Drug_Cost_Ge65"
		total_30_day_fill_count_ge65	= "Number of Standardized 30-Day Fills, Including Refills, for Beneficiaries Age 65+"
		total_day_supply_ge65			= "Number of Day's Supply for All Claims for Beneficiaries Age 65+"
		total_drug_cost_ge65			= "Aggregate Cost Paid for All Claims for Beneficiaries Age 65+"
;

RUN;

PROC FREQ DATA=PartD_Prescriber_PUF_NPI_Drug_15 NOPRINT;
TABLES nppes_provider_first_name*nppes_provider_last_org_name*specialty_description*NPI*nppes_provider_city*nppes_provider_state / OUT=PARTDPROVIDERS NOPRINT;
WEIGHT total_claim_count; /*Number of Medicare Part D Claims for All Drugs*/
RUN;

DATA PARTD;

/*create fields for speciality, first name, last name, and county*/
length speciality1-speciality5 $103. FirstName_ $50. LastName_ $50. CITY $50. STATE $2.;
SET PARTDPROVIDERS;

/*place all character variables to standardized in an array*/
array cvars (*) nppes_provider_first_name nppes_provider_last_org_name specialty_description nppes_provider_city nppes_provider_state;

/*create new character variables based on standardizion*/
array newcvars (*) Firstname_ LastName_ Spec_ CITY STATE ;

do i = 1 to dim(cvars);

/*Set all Invalid Values to Blank or Missing*/
if cvars[i] IN ("NULL","  ") THEN newcvars[i] = "  ";
ELSE newcvars[i] = cvars[i];

/*Remove all Special Characters e.g., compress() and leading/trailing spaces e.g., strip()*/
IF newcvars[i] NE "   " THEN newcvars[i]=STRIP(compress(newcvars[i], ":-'.,’{}[]/\()+~`!&#$%^&*_<>?"));
/*Make all characters in a string uppercase*/
IF newcvars[i] NE "   " THEN  newcvars[i]=upcase(newcvars[i]);
END;

/*Create Multiple Specialty Fields for Providers with More than 1 Specialty in Kansas*/
/*For all the fields use a single Part D Specialiy for each of the five potential fields*/
array special (*) speciality1-speciality5;
do i = 1 to 5;
if Spec_ NE "   " THEN special[i]=STRIP(Spec_);
END;

/*Total Claims*/
TOTAL=COUNT;
KEEP npi CITY STATE Firstname_ LastName_ Spec_ speciality1-speciality5 TOTAL ;
RUN;

/*U-probability*/

/*Calculate probabilistic weights*/

/* MATCH FIRST NAMES */
/* First Name Estimations*/
%macro probabweight (matchvar=);
proc freq data = prescriber2  noprint;
table &matchvar /   out = KS_&matchvar;

data KS_&matchvar;
set KS_&matchvar;
attrib uprob&matchvar length = 8. format = 10.9;
uprob&matchvar = percent / 100;
run;

proc sql noprint;
create table 
M_&matchvar as 
select a.NPI, a.city, a.state,
a.&matchvar as PARTD_&matchvar, 
b.&matchvar as KS_&matchvar,
LOG(0.95 / percent)  as weight&matchvar

FROM PARTD as a LEFT JOIN KS_&matchvar as b 
	/*Use Soundex to match by phonetic across each character strings*/
    /*Alternatives include SPEDIS, COMPGEN, or other comparison measures*/
	ON SOUNDEX(a.&matchvar) = SOUNDEX(b.&matchvar)
order by a.state,a.NPI,a.CITY;
QUIT;

DATA M_&matchvar;
SET M_&matchvar;
IF weight&matchvar = . THEN weight&matchvar =0;
RUN;

%MEND;

%probabweight (matchvar=firstname_);
%probabweight (matchvar=LastName_);
%probabweight (matchvar=speciality1);
%probabweight (matchvar=speciality2);
%probabweight (matchvar=speciality3);
%probabweight (matchvar=speciality4);
%probabweight (matchvar=speciality5);
%probabweight (matchvar=State);

PROC SQL NOPRINT;
CREATE TABLE PARTMATCHES AS 
SELECT a.NPI, a.CITY, A.STATE, 
a.KS_firstname_ , 
b.KS_LastName_, 
c.KS_speciality1 , 
d.KS_speciality2, 
e.KS_speciality3, 
f.KS_speciality4, 
g.KS_speciality5 , 
h.KS_State,

a.weightfirstname_ , 
b.weightLastName_, 
c.weightspeciality1 , 
d.weightspeciality2, 
e.weightspeciality3, 
f.weightspeciality4, 
g.weightspeciality5 , 
h.weightState,
a.weightfirstname_ + b.weightLastName_ + weightspeciality1+weightspeciality2+weightspeciality3+weightspeciality4+weightspeciality5+weightState as probmatch
FROM M_firstname_ as a LEFT JOIN  M_LastName_ as b on a.npi=b.npi and a.city=b.city and a.state=b.state
	LEFT JOIN  M_speciality1  as c on a.npi=c.npi and a.city=c.city and a.state=c.state
	LEFT JOIN  M_speciality2 as d on a.npi=d.npi and a.city=d.city and a.state=d.state
	LEFT JOIN  M_speciality3 as e on a.npi=e.npi and a.city=e.city and a.state=e.state
	LEFT JOIN  M_speciality4 as f on a.npi=f.npi and a.city=f.city and a.state=f.state
	LEFT JOIN  M_speciality5 as g on a.npi=g.npi and a.city=g.city and a.state=g.state
	LEFT JOIN  M_State as h on a.npi=h.npi and a.city=h.city and a.state=h.state

;
QUIT;

PROC SUMMARY DATA=PARTMATCHES NOPRINT THREADS;
CLASS NPI CITY STATE KS_firstname_ KS_LastName_ KS_speciality1 KS_speciality2 KS_speciality3 KS_speciality4 KS_speciality5 KS_State / GROUPINTERNAL MISSING;
TYPES NPI*CITY*STATE*KS_firstname_*KS_LastName_*KS_speciality1*KS_speciality2*KS_speciality3*KS_speciality4*KS_speciality5*KS_State ;
OUTPUT OUT=SUMSCORES (DROP=_TYPE_ RENAME=_FREQ_=MATCHES) 
SUM(probmatch weightfirstname_ weightLastName_ weightspeciality1 weightspeciality2 weightspeciality3 weightspeciality4 weightspeciality5 weightState) = 
probmatch weightfirstname_ weightLastName_ weightspeciality1 weightspeciality2 weightspeciality3 weightspeciality4 weightspeciality5 weightState;
RUN;

LIBNAME MATCH "C:\TEMP\Matching Algorithims";
RUN;

PROC DATASETS LIBRARY=WORK;
SAVE SUMSCORES;
RUN;

DATA MATCH.PRESCRIBERSCORES;
SET SUMSCORES;
RUN;

DATA MATCH.KSPRESCRIBERSCORES;
SET MATCH.PRESCRIBERSCORES;
WHERE STATE = "KS";
RUN;

/*Use optimal matching macro program to complete matching by prescriber scores*/
