cas mysess;
caslib _all_ assign;

/* 1. Missing-value flags (missingness itself can be predictive) */
data casuser.hmeq_flag;
  set casuser.hmeq_part;
  MISS_DEBTINC = missing(DEBTINC);
  MISS_MORTDUE = missing(MORTDUE);
  MISS_VALUE   = missing(VALUE);
run;

/* 2. Impute: median for numerics, mode for categoricals */
proc varimpute data=casuser.hmeq_flag;
  input MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / ctech=median;
  input REASON JOB / ntech=mode;
  output out=casuser.hmeq_imp copyvars=(_ALL_);
run;

/* 3. Logistic regression baseline (imputed vars are prefixed IM_) */
proc logselect data=casuser.hmeq_imp;
  partition rolevar=_PartInd_(train='1' validate='2' test='0');
  class IM_REASON IM_JOB;
  model BAD(event='1') = LOAN IM_MORTDUE IM_VALUE IM_YOJ IM_DEROG IM_DELINQ
                         IM_CLAGE IM_NINQ IM_CLNO IM_DEBTINC
                         IM_REASON IM_JOB
                         MISS_DEBTINC MISS_MORTDUE MISS_VALUE;
  output out=casuser.hmeq_scored pred=P_BAD copyvars=(BAD _PartInd_);
run;

/* 4. Assess by partition: look for AUC/KS/Gini and compare train vs validation vs test */
proc assess data=casuser.hmeq_scored;
  input P_BAD;
  target BAD / level=nominal event='1';
  by _PartInd_;
run;
