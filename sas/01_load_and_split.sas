cas mysess;
caslib _all_ assign;

/* 1. Load HMEQ into CAS */
proc casutil;
  load data=sampsio.hmeq outcaslib="casuser" casout="hmeq" replace;
quit;

/* 2. Quick profile */
proc cas;
  simple.summary / table={name="hmeq", caslib="casuser"};
quit;

/* 3. Stratified 70/15/15 split on the target */
proc partition data=casuser.hmeq partind samppct=70 samppct2=15 seed=42;
  by BAD;
  output out=casuser.hmeq_part copyvars=(_ALL_);
run;

/* 4. Check the split kept the default rate in each part */
proc freq data=casuser.hmeq_part;
  tables _PartInd_ * BAD / nocol nopercent;
run;
