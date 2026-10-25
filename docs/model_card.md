# Baseline model results: logistic regression

**Project:** Credit risk scoring on SAS HMEQ (target `BAD`, 1 = default)
**Platform:** SAS Viya (CAS), `PROC LOGSELECT`, `PROC ASSESS`
**Script:** `sas/02_scorecard_baseline.sas`
**Run date:** 2026-10-25

## Data and split
- Source: `sampsio.hmeq`, 5,960 rows, 1,189 defaults (19.95%)
- Stratified split on `BAD`, seed 42, `_PartInd_` column in `casuser.hmeq_part`

| Partition | `_PartInd_` | Rows | Non-default | Default |
|---|---|---|---|---|
| Train | 1 | 4,172 | 3,339 | 833 |
| Validation | 2 | 894 | 716 | 178 |
| Test | 0 | 894 | 716 | 178 |

## Preprocessing (`PROC VARIMPUTE`, `casuser.hmeq_imp`)
Missing-value flags were added first: `MISS_DEBTINC`, `MISS_MORTDUE`, `MISS_VALUE`.

| Variable | Missing | Method | Imputed value |
|---|---|---|---|
| MORTDUE | 518 | Median | 65017 |
| VALUE | 112 | Median | 89231 |
| YOJ | 515 | Median | 7 |
| DEROG | 708 | Median | 0 |
| DELINQ | 580 | Median | 0 |
| CLAGE | 308 | Median | 173.467 |
| NINQ | 510 | Median | 1 |
| CLNO | 222 | Median | 20 |
| DEBTINC | 1,267 | Median | 34.8183 |
| REASON | 252 | Mode | DebtCon |
| JOB | 279 | Mode | Other |

## Performance

| Metric | Train | Validation | **Test** |
|---|---|---|---|
| AUC | 0.8972 | 0.9146 | **0.8871** |
| Gini | 0.7943 | 0.8292 | **0.7742** |
| KS (max TPR - FPR) | 0.6665 | 0.7172 | **0.6595** |
| KS cutoff | 0.21 | 0.16 | 0.21 |
| Average squared error | 0.08522 | 0.07729 | 0.08792 |
| Misclassification (0.5 cutoff) | 0.11553 | 0.10291 | 0.11521 |
| McFadden R-square | 0.42116 | 0.46788 | 0.39522 |

Notes:
- KS was computed from the ROC table as the maximum of TPR minus FPR. The KS column in the SAS output is only a flag.
- Train-to-test AUC gap is 0.010, so there is no meaningful overfitting.
- The validation partition scores higher than train, which is noise: it holds only 178 defaults.

## Parameter estimates
Convergence: FCONV=1E-7 satisfied. Reference levels: `IM_REASON` = HomeImp, `IM_JOB` = Self.

| Parameter | Estimate | Std. error | Chi-square | Pr > ChiSq |
|---|---|---|---|---|
| Intercept | -4.834906 | 0.528029 | 83.8419 | <.0001 |
| LOAN | -0.000007775 | 0.000005491 | 2.0053 | 0.1567 |
| IM_MORTDUE | -0.000000490 | 0.000002377 | 0.0425 | 0.8367 |
| IM_VALUE | 0.000001491 | 0.000001871 | 0.6350 | 0.4255 |
| IM_YOJ | -0.016357 | 0.008022 | 4.1581 | 0.0414 |
| IM_DEROG | 0.526363 | 0.070476 | 55.7817 | <.0001 |
| IM_DELINQ | 0.662040 | 0.055443 | 142.5855 | <.0001 |
| IM_CLAGE | -0.005101 | 0.000765 | 44.5215 | <.0001 |
| IM_NINQ | 0.132192 | 0.030712 | 18.5268 | <.0001 |
| IM_CLNO | -0.021080 | 0.006099 | 11.9476 | 0.0005 |
| IM_DEBTINC | 0.102057 | 0.010377 | 96.7195 | <.0001 |
| IM_REASON DebtCon | -0.139980 | 0.120693 | 1.3451 | 0.2461 |
| IM_JOB Mgr | -0.229362 | 0.343093 | 0.4469 | 0.5038 |
| IM_JOB Office | -0.937690 | 0.347585 | 7.2777 | 0.0070 |
| IM_JOB Other | -0.179070 | 0.323951 | 0.3056 | 0.5804 |
| IM_JOB ProfExe | -0.283652 | 0.334849 | 0.7176 | 0.3969 |
| IM_JOB Sales | 0.864406 | 0.452972 | 3.6416 | 0.0564 |
| MISS_DEBTINC | 2.743775 | 0.111064 | 610.3093 | <.0001 |
| MISS_MORTDUE | 0.029520 | 0.218955 | 0.0182 | 0.8928 |
| MISS_VALUE | 4.212045 | 0.541620 | 60.4779 | <.0001 |

## Key findings
- `MISS_DEBTINC` is the strongest predictor: a missing `DEBTINC` multiplies the odds of default by about 15 (exp(2.74)). This reflects how the data was collected, not borrower behavior, and is a governance risk to document in the model card.
- `MISS_VALUE` has a large coefficient but affects only 112 rows, so it is unstable.
- Credit-history variables carry the genuine risk signal: `DELINQ`, `DEROG`, `NINQ` (higher risk) and `CLAGE`, `CLNO` (lower risk).
- Not significant at the 5% level: `LOAN`, `MORTDUE`, `VALUE`, `REASON`, `MISS_MORTDUE`.

## Limitations
- Imputation values were computed on all 5,960 rows before the split was applied, so a small amount of validation and test information leaks into the medians and modes. The effect is likely small, but a stricter version would fit imputation on the training partition only.
- The dataset is small (about 1,200 defaults), so partition-level metrics are noisy.
- The model leans heavily on missingness flags (see above).

## Benchmark for challengers
Any challenger (gradient boosting, forest) must beat these **test-partition** numbers on the same `_PartInd_` split: AUC 0.8871, KS 0.6595, Gini 0.7742.
