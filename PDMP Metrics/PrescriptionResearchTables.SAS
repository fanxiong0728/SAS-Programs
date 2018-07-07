*-------------------------------------------------------------------*
 *  Author:  Fan Xiong            <fanxiong0728@gmail.com>           *
*-------------------------------------------------------------------*


/*This SAS program was used in a colloboration project to build data tables for the Event and Pattern Detection Labortoary at CMU*/

*/
/*For the PDMP, it probably makes sense to have the original transaction data plus lookup tables of "red flags" by patient, prescriber, dispenser, and drug/dose combination.  We could then join these tables to identify whether any particular transaction has any red flags.  
Perhaps the patient data would be a good place to start (and would look like your table 1a).  It would be great if we could include information about drug strength as well: the milligrams morphine equivalent for the prescribed drug/dose sounds like a promising way to go.

Red flags for a given patient could include:
* Multiple prescribers
* Multiple dispensers
* Lives in high risk area
* Multiple controlled substances (e.g., opioid + benzo)
* Total prescribed dose for that patient in mm equivalent
* Relation to red-flagged prescribers and dispensers (where one of the things that makes a provider or dispenser worrisome is their proportion of red-flagged patients, in addition to total volume.  We can worry about these "transitive" network effects later, but I think they will be particularly important.)

It does seem like a lot of what we would want to do with PDMP data alone would be longitudinal at patient level: identifying the emergence of risky behaviors and seeing if there are early indicators that let us predict them.  Once we have a handle on what makes an individual patient's behavior risky, we could then look for emerging clusters by subpopulation, geography, specific risky behaviors, etc.  Does that seem like a reasonable way to proceed?
*/


/************************ Patient Tables******************************************/

CREATE TABLE CMU.CMUPTFLAGS as select patient_identifier,
numericid, patient_birthyear, patient_gender, prescription_number, YEARF, MONTHF, DAYF, YEARW, MONTHW, DAYW,ptcitystate,

COUNT(DISTINCT(prescriber)) as prescriber_count,
COUNT(DISTINCT(dispensary)) as dispensary_count,

SUM(CASE WHEN ptcitystate = precitystate = dispcitystate THEN 1 
ELSE . END) AS SAMECITYALL label="All Patient, Prescriber, and Dispensary from the Same City", 

SUM(CASE WHEN ptcitystate = precitystate AND ptcitystate NE dispcitystate THEN 1 
ELSE  . END) AS SAMECITYPATPRE label="Only Patient & Prescriber from the Same City", 

SUM(CASE WHEN ptcitystate NE precitystate AND ptcitystate = dispcitystate THEN 1 
ELSE  . END) AS SAMECITYPATDISP label="Only Patient & Dispensary from the Same City", 

SUM(CASE WHEN ptcitystate NE precitystate AND ptcitystate NE dispcitystate AND precitystate = dispcitystate THEN 1 
ELSE  . END) AS SAMECITYPREDISP label="Only Prescriber & Dispensary from the Same City", 

SUM(ZIPCITYDISTANCE(ZIP_patient, ZIP_Prescriber)) as Patient_prescriber_distance label="Straight-line distance by Zipcode Centroids of Patient and Prescriber",
SUM(ZIPCITYDISTANCE(ZIP_patient, ZIP_dispensary)) as Patient_dispensary_distance label="Straight-line distance by Zipcode Centroids of Patient and Dispensary", 
SUM(ZIPCITYDISTANCE(ZIP_dispensary, ZIP_Prescriber)) as dispensary_prescriber_distance label="Straight-line distance by Zipcode Centroids of Dispensary and Prescriber", 

SUM(CASE WHEN OPIOID = "1" THEN 1 ELSE . END) AS OPIOID,
SUM(CASE WHEN BENZO = "1" THEN 1 ELSE . END) AS BENZO,
SUM(CASE WHEN MISC = "1" THEN 1 ELSE . END) AS MISC,
SUM(CASE WHEN STIMULANT = "1" THEN 1 ELSE . END) AS STIMULANT,
SUM(CASE WHEN MuscleRelaxant = "1" THEN 1 ELSE . END) AS MuscleRelaxant,
SUM(CASE WHEN LongShortActing = "SA" THEN 1 ELSE . END) AS SA_DRUG,
SUM(CASE WHEN LongShortActing = "LA" THEN 1 ELSE . END) AS LA_DRUG,

SUM(CASE WHEN OPIOID = "1" AND dayssupply_dispensed < 30 THEN 1 ELSE . END) AS OPIOID_30LESS,
SUM(CASE WHEN BENZO = "1" AND dayssupply_dispensed < 30  THEN 1 ELSE . END) AS BENZO_30LESS,
SUM(CASE WHEN MISC = "1" AND dayssupply_dispensed  < 30  THEN 1 ELSE . END) AS MISC_30LESS,
SUM(CASE WHEN STIMULANT = "1" AND dayssupply_dispensed  < 30  THEN 1 ELSE . END) AS STIMULANT_30LESS,
SUM(CASE WHEN MuscleRelaxant = "1" AND dayssupply_dispensed  < 30  THEN 1 ELSE . END) AS MuscleRelaxant_30LESS,
SUM(CASE WHEN LongShortActing = "SA" AND dayssupply_dispensed  < 30  THEN 1 ELSE . END) AS SA_DRUG_30LESS,
SUM(CASE WHEN LongShortActing = "LA" AND dayssupply_dispensed  < 30  THEN 1 ELSE . END) AS LA_DRUG_30LESS,

SUM(CASE WHEN OPIOID = "1" AND (dayssupply_dispensed >=30 AND dayssupply_dispensed <=90) THEN 1 ELSE . END) AS OPIOID_3090,
SUM(CASE WHEN BENZO = "1" AND(dayssupply_dispensed >=30 AND dayssupply_dispensed <=90)  THEN 1 ELSE . END) AS BENZO_3090,
SUM(CASE WHEN MISC = "1" AND (dayssupply_dispensed >=30 AND dayssupply_dispensed <=90)  THEN 1 ELSE . END) AS MISC_3090,
SUM(CASE WHEN STIMULANT = "1" AND (dayssupply_dispensed >=30 AND dayssupply_dispensed <=90) THEN 1 ELSE . END) AS STIMULANT_3090,
SUM(CASE WHEN MuscleRelaxant = "1" AND (dayssupply_dispensed >=30 AND dayssupply_dispensed <=90)  THEN 1 ELSE . END) AS MuscleRelaxant_3090,
SUM(CASE WHEN LongShortActing = "SA" AND (dayssupply_dispensed >=30 AND dayssupply_dispensed <=90) THEN 1 ELSE . END) AS SA_DRUG_3090,
SUM(CASE WHEN LongShortActing = "LA" AND (dayssupply_dispensed >=30 AND dayssupply_dispensed <=90)  THEN 1 ELSE . END) AS LA_DRUG_3090,

SUM(CASE WHEN OPIOID = "1" AND dayssupply_dispensed > 90 THEN 1 ELSE . END) AS OPIOID_MORE90,
SUM(CASE WHEN BENZO = "1" AND dayssupply_dispensed > 90  THEN 1 ELSE . END) AS BENZO_MORE90,
SUM(CASE WHEN MISC = "1" AND dayssupply_dispensed  > 90  THEN 1 ELSE . END) AS MISC_MORE90,
SUM(CASE WHEN STIMULANT = "1" AND dayssupply_dispensed  > 90 THEN 1 ELSE . END) AS STIMULANT_MORE90,
SUM(CASE WHEN MuscleRelaxant = "1" AND dayssupply_dispensed  > 90 THEN 1 ELSE . END) AS MuscleRelaxant_MORE90,
SUM(CASE WHEN LongShortActing = "SA" AND dayssupply_dispensed  > 90 THEN 1 ELSE . END) AS SA_DRUG_MORE90,
SUM(CASE WHEN LongShortActing = "LA" AND dayssupply_dispensed  > 90  THEN 1 ELSE . END) AS LA_DRUG_MORE90,

SUM(CASE WHEN deaclasscode = "2" THEN 1 ELSE . END) AS DEA_SCHEDULE2,
SUM(CASE WHEN deaclasscode = "3" THEN 1 ELSE . END) AS DEA_SCHEDULE3,
SUM(CASE WHEN deaclasscode = "4" THEN 1 ELSE . END) AS DEA_SCHEDULE4,

SUM(CASE WHEN NEWRX = "1" THEN 1 ELSE . END) AS FIRST_FILLED,
SUM(CASE WHEN NEWRX = "0" THEN 1 ELSE . END) AS REFILLED,

SUM(CASE WHEN deaclasscode = "2" AND NEWRX = "0" THEN 1 ELSE . END) AS SCHEDULE2_ABERRANT,
SUM(CASE WHEN deaclasscode = "2" AND dayssupply_dispensed  >= 30  THEN 1 ELSE . END) AS SCH2_30PLUSDAYS,

SUM(CASE WHEN refills_ordered = 0 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS0,
SUM(CASE WHEN refills_ordered = 1 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS1,
SUM(CASE WHEN refills_ordered = 2 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS2,
SUM(CASE WHEN refills_ordered = 3 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS3,
SUM(CASE WHEN refills_ordered = 4 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS4,
SUM(CASE WHEN refills_ordered = 5 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS5,
SUM(CASE WHEN refills_ordered = 6 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS6,
SUM(CASE WHEN refills_ordered = 7 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS7,
SUM(CASE WHEN refills_ordered = 8 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS8,
SUM(CASE WHEN refills_ordered = 9 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS9,
SUM(CASE WHEN refills_ordered = 10 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS10,
SUM(CASE WHEN refills_ordered = 11 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS11,
SUM(CASE WHEN refills_ordered = 12 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS12,

SUM(MME_DD) as TOTMMEDD label="Total Morphine Milligram Equivalent per Day",
AVG(MME_DD) as AVGMMEDD label="Average Morphine Milligram Equivalent per Day",

SUM(CASE WHEN MME_DD GE 40 THEN 1 ELSE . END) AS MME40RX,
SUM(CASE WHEN MME_DD GE 50 THEN 1 ELSE . END) AS MME50RX,
SUM(CASE WHEN MME_DD GE 60 THEN 1 ELSE . END) AS MME60RX,
SUM(CASE WHEN MME_DD GE 70 THEN 1 ELSE . END) AS MME70RX,
SUM(CASE WHEN MME_DD GE 80 THEN 1 ELSE . END) AS MME80RX,
SUM(CASE WHEN MME_DD GE 90 THEN 1 ELSE . END) AS MME90RX,
SUM(CASE WHEN MME_DD GE 100 THEN 1 ELSE . END) AS MME100RX,
SUM(CASE WHEN MME_DD GE 150 THEN 1 ELSE . END) AS MME150RX,
SUM(CASE WHEN MME_DD GE 200 THEN 1 ELSE . END) AS MME200RX,

SUM(CASE WHEN Insurance = "1" THEN 1 ELSE . END) AS Insurance,
SUM(CASE WHEN Medicare = "1" THEN 1 ELSE . END) AS Medicare,
SUM(CASE WHEN Cash = "1" THEN 1 ELSE . END) AS Other,
SUM(CASE WHEN Military = "1" THEN 1 ELSE . END) AS Military,
SUM(CASE WHEN Medicaid = "1" THEN 1 ELSE . END) AS Medicaid,
SUM(CASE WHEN workers_comp = "1" THEN 1 ELSE . END) AS workers_comp,
SUM(CASE WHEN indian_nation = "1" THEN 1 ELSE . END) AS indian_nation,
SUM(CASE WHEN Unknown = "1" THEN 1 ELSE . END) AS Unknown,
SUM(CASE WHEN major = "1" THEN 1 ELSE . END) AS major

FROM CMU.CMU1017 WHERE patient_gender IN ("F","M") and ("2010" <= YEARF <= "2017")
GROUP BY patient_identifier,
numericid, patient_birthyear, patient_gender, prescription_number, YEARF, MONTHF, DAYF, YEARW, MONTHW, DAYW,ptcitystate;




/************************ Prescriber Tables******************************************/


SELECT prescriber, YEARF, MONTHF, DAYF, YEARW, MONTHW, DAYW,
prescription_number,precitystate,
COUNT(DISTINCT(numericid)) as patient_count,
COUNT(DISTINCT(dispensary)) as dispensary_count,

SUM(CASE WHEN ptcitystate = precitystate = dispcitystate THEN 1 
ELSE . END) AS SAMECITY1 label="All Patient, Prescriber, and Dispensary from the Same City", 

SUM(CASE WHEN ptcitystate = precitystate AND ptcitystate NE dispcitystate THEN 1 
ELSE  . END) AS SAMECITY2 label="Only Patient & Prescriber from the Same City", 

SUM(CASE WHEN ptcitystate NE precitystate AND ptcitystate = dispcitystate THEN 1 
ELSE  . END) AS SAMECITY3 label="Only Patient & Dispensary from the Same City", 

SUM(CASE WHEN ptcitystate NE precitystate AND ptcitystate NE dispcitystate AND precitystate = dispcitystate THEN 1 
ELSE  . END) AS SAMECITY4 label="Only Prescriber & Dispensary from the Same City", 

SUM(ZIPCITYDISTANCE(ZIP_patient, ZIP_Prescriber)) as Patient_prescriber_distance label="Straight-line distance by Zipcode Centroids of Patient and Prescriber",
SUM(ZIPCITYDISTANCE(ZIP_patient, ZIP_dispensary)) as Patient_dispensary_distance label="Straight-line distance by Zipcode Centroids of Patient and Dispensary", 
SUM(ZIPCITYDISTANCE(ZIP_dispensary, ZIP_Prescriber)) as dispensary_prescriber_distance label="Straight-line distance by Zipcode Centroids of Dispensary and Prescriber", 

SUM(CASE WHEN OPIOID = "1" THEN 1 ELSE . END) AS OPIOID,
SUM(CASE WHEN BENZO = "1" THEN 1 ELSE . END) AS BENZO,
SUM(CASE WHEN MISC = "1" THEN 1 ELSE . END) AS MISC,
SUM(CASE WHEN STIMULANT = "1" THEN 1 ELSE . END) AS STIMULANT,
SUM(CASE WHEN MuscleRelaxant = "1" THEN 1 ELSE . END) AS MuscleRelaxant,
SUM(CASE WHEN LongShortActing = "SA" THEN 1 ELSE . END) AS SA_DRUG,
SUM(CASE WHEN LongShortActing = "LA" THEN 1 ELSE . END) AS LA_DRUG,

SUM(MME_DD) as MMEDD label="Morphine Milligram Equivalent per Day",

SUM(CASE WHEN deaclasscode = "2" THEN 1 ELSE . END) AS DEA_SCHEDULE2,
SUM(CASE WHEN deaclasscode = "3" THEN 1 ELSE . END) AS DEA_SCHEDULE3,
SUM(CASE WHEN deaclasscode = "4" THEN 1 ELSE . END) AS DEA_SCHEDULE4,

SUM(CASE WHEN NEWRX = "1" THEN 1 ELSE . END) AS FIRST_FILLED,
SUM(CASE WHEN NEWRX = "0" THEN 1 ELSE . END) AS REFILLED,

SUM(CASE WHEN refills_ordered = 0 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS0,
SUM(CASE WHEN refills_ordered = 1 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS1,
SUM(CASE WHEN refills_ordered = 2 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS2,
SUM(CASE WHEN refills_ordered = 3 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS3,
SUM(CASE WHEN refills_ordered = 4 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS4,
SUM(CASE WHEN refills_ordered = 5 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS5,
SUM(CASE WHEN refills_ordered = 6 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS6,
SUM(CASE WHEN refills_ordered = 7 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS7,
SUM(CASE WHEN refills_ordered = 8 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS8,
SUM(CASE WHEN refills_ordered = 9 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS9,
SUM(CASE WHEN refills_ordered = 10 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS10,
SUM(CASE WHEN refills_ordered = 11 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS11,
SUM(CASE WHEN refills_ordered = 12 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS12

FROM CMU.CMU1017 WHERE patient_gender IN ("F","M") and ("2010" <= YEARF <= "2017")
GROUP BY prescriber, precitystate, YEARF, MONTHF, DAYF, YEARW, MONTHW, DAYW, prescription_number;



/************************ Dispensary (Pharmacy) Tables******************************************/



SELECT dispensary, YEARF, MONTHF, DAYF, YEARW, MONTHW, DAYW,
prescription_number,dispcitystate,
COUNT(DISTINCT(numericid)) as patient_count,
COUNT(DISTINCT(dispensary)) as dispensary_count,

SUM(CASE WHEN ptcitystate = precitystate = dispcitystate THEN 1 
ELSE . END) AS SAMECITY1 label="All Patient, Prescriber, and Dispensary from the Same City", 

SUM(CASE WHEN ptcitystate = precitystate AND ptcitystate NE dispcitystate THEN 1 
ELSE  . END) AS SAMECITY2 label="Only Patient & Prescriber from the Same City", 

SUM(CASE WHEN ptcitystate NE precitystate AND ptcitystate = dispcitystate THEN 1 
ELSE  . END) AS SAMECITY3 label="Only Patient & Dispensary from the Same City", 

SUM(CASE WHEN ptcitystate NE precitystate AND ptcitystate NE dispcitystate AND precitystate = dispcitystate THEN 1 
ELSE  . END) AS SAMECITY4 label="Only Prescriber & Dispensary from the Same City", 

SUM(ZIPCITYDISTANCE(ZIP_patient, ZIP_Prescriber)) as Patient_prescriber_distance label="Straight-line distance by Zipcode Centroids of Patient and Prescriber",
SUM(ZIPCITYDISTANCE(ZIP_patient, ZIP_dispensary)) as Patient_dispensary_distance label="Straight-line distance by Zipcode Centroids of Patient and Dispensary", 
SUM(ZIPCITYDISTANCE(ZIP_dispensary, ZIP_Prescriber)) as dispensary_prescriber_distance label="Straight-line distance by Zipcode Centroids of Dispensary and Prescriber", 

SUM(CASE WHEN OPIOID = "1" THEN 1 ELSE . END) AS OPIOID,
SUM(CASE WHEN BENZO = "1" THEN 1 ELSE . END) AS BENZO,
SUM(CASE WHEN MISC = "1" THEN 1 ELSE . END) AS MISC,
SUM(CASE WHEN STIMULANT = "1" THEN 1 ELSE . END) AS STIMULANT,
SUM(CASE WHEN MuscleRelaxant = "1" THEN 1 ELSE . END) AS MuscleRelaxant,
SUM(CASE WHEN LongShortActing = "SA" THEN 1 ELSE . END) AS SA_DRUG,
SUM(CASE WHEN LongShortActing = "LA" THEN 1 ELSE . END) AS LA_DRUG,

SUM(MME_DD) as MMEDD label="Morphine Milligram Equivalent per Day",

SUM(CASE WHEN deaclasscode = "2" THEN 1 ELSE . END) AS DEA_SCHEDULE2,
SUM(CASE WHEN deaclasscode = "3" THEN 1 ELSE . END) AS DEA_SCHEDULE3,
SUM(CASE WHEN deaclasscode = "4" THEN 1 ELSE . END) AS DEA_SCHEDULE4,

SUM(CASE WHEN NEWRX = "1" THEN 1 ELSE . END) AS FIRST_FILLED,
SUM(CASE WHEN NEWRX = "0" THEN 1 ELSE . END) AS REFILLED,

SUM(CASE WHEN refills_ordered = 0 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS0,
SUM(CASE WHEN refills_ordered = 1 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS1,
SUM(CASE WHEN refills_ordered = 2 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS2,
SUM(CASE WHEN refills_ordered = 3 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS3,
SUM(CASE WHEN refills_ordered = 4 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS4,
SUM(CASE WHEN refills_ordered = 5 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS5,
SUM(CASE WHEN refills_ordered = 6 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS6,
SUM(CASE WHEN refills_ordered = 7 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS7,
SUM(CASE WHEN refills_ordered = 8 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS8,
SUM(CASE WHEN refills_ordered = 9 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS9,
SUM(CASE WHEN refills_ordered = 10 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS10,
SUM(CASE WHEN refills_ordered = 11 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS11,
SUM(CASE WHEN refills_ordered = 12 THEN 1 ELSE . END) AS AUTHORIZED_REFILLS12

FROM CMU.CMU1017 WHERE patient_gender IN ("F","M") and ("2010" <= YEARF <= "2017")
GROUP BY dispensary, dispcitystate, YEARF, MONTHF, DAYF, YEARW, MONTHW, DAYW, prescription_number;
