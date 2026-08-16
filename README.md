# incubeta-bqml-medallion-pipeline
BigQuery Medallion Architecture and BQML K-means assessment

A BigQuery proof of concept that ingests synthetic retail transactions, 
applies a Bronze-Silver-Gold Medallion Architecture, 
quarantines invalid transactions, 
and produces K-means customer/transaction segments using native BigQuery Machine Learning.

## Objectives

- Ingesting raw retail transaction data into Bronze
- Clean, standardise, and validate records in Silver
- Isolate invalid transactions in an exceptions table
- Build a BigQuery ML K-means model using `amount` and `item_category`
- Generate Gold-layer transaction records with an assigned cluster
- Provide version-controlled SQL and proof of execution

## Architecture

```text
> Manual CSV file
> retail_bronze.raw_transactions
    --> amount <= 0 --> retailsilver.transaction_exceptions
    
> retailsilver.cleaned_transactions
> retailgold.customer_segmentation_model
> retailgold.analytics_customer_segments
> retailgold.vw_customer_segment_reporting
```

## Data layers

| Layer | BigQuery object | Purpose |
|---|---|---|
| Bronze | `retailbronze.raw_transactions` | Raw CSV ingestion with minimal change |
| Silver | `retailsilver.cleaned_transactions` | Typed, validated transaction records |
| Silver | `retailsilver.transaction_exceptions` | Invalid transactions where `amount <= 0` |
| Gold | `retailgold.customer_segmentation_model` | Native BQML K-means model |
| Gold | `retailgold.analytics_customer_segments` | Clean transactions with `predicted_cluster` |
| Gold | `retailgold.vw_customer_segment_reporting` | Readable reporting segment labels |

## Silver transformation logic

The stored procedure `sp_refresh_silver_transactions` is a repeatable, idempotent POC transformation that rebuilds the Silver outputs from Bronze.

- Converts `signup_date` from `STRING` to `DATE` using `SAFE_CAST`
- Defaults a null `signup_date` to `purchase_date`
- Converts null or unrecognised `is_returned` values to `FALSE`
- Casts `amount` to `NUMERIC`
- Routes transactions with `amount <= 0` to `transaction_exceptions`
- Excludes invalid-amount records from `cleaned_transactions`
- Creates `days_to_first_purchase` using `DATE_DIFF(purchase_date, signup_date, DAY)`

### Execute Silver refresh

```sql
CALL `incubeta-assessment.retailsilver.sp_refresh_silver_transactions`();
```

## BQML segmentation

A K-means model was trained in BigQuery ML with:

- Features: `amount` and `item_category`
- Clusters: 3
- Numeric feature standardisation: enabled
- Initialisation method: K-means++

### Evaluation results

| Metric | Result |
|---|---:|
| Davies–Bouldin index | 1.36306745785338 |
| Mean squared distance | 0.993360397943806 |

The cluster IDs are technical model identifiers and should not be treated as business rankings. Centroid inspection produced these working interpretations:

| Predicted cluster | Working reporting label | Observed interpretation |
|---:|---|---|
| 1 | Broad category - lower spend | Approximate centroid amount: 302.06 |
| 2 | Broad category - higher spend | Approximate centroid amount: 905.27 |
| 3 | Automotive - mid spend | Approximate centroid amount: 371.40; Automotive category weight: 1.0 |

## Data-quality reconciliation

| Output | Row count |
|---|---:|
| Bronze raw transactions | 10,000 |
| Silver cleaned transactions | 9,593 |
| Silver transaction exceptions | 407 |

Reconciliation check:

```text
10,000 Bronze records = 9,593 clean records + 407 exception records
```

## Repository structure

```text
.
├── sql/
│   ├── silvertransform.sql
│   ├── goldmodeltraining.sql
│   └── goldprediction.sql
├── proof/
│   ├── final_gold_schema.png
│   ├── final_gold_preview.png
│   └── model_evaluation.png
└── README.md
```

## Production orchestration approach

For production implementation, Cloud Storage (GCS) would be used as a controlled landing zone for source files before ingestion to Bronze. 
A Dataform workflow, Scheduled Query, or Cloud Composer DAG could orchestrate the stages: 
validate/load Bronze, call the Silver stored procedure, retrain the model on an agreed cadence, generate Gold predictions, and run reconciliation checks.

The POC uses full-refresh `CREATE OR REPLACE` statements for clarity and repeatability. 
A production design would add: pipeline run metadata, 
                               data-quality audit logging, 
                               schema validation, 
                               source-file lineage, 
                               alerting, and 
                               incremental `MERGE` or `APPEND` processing where appropriate.

## AI usage disclosure

Perplexity AI was used as a learning and implementation aid. It assisted with:

- GitHub navigation
- BigQuery SQL for the BQML model, predictions, and validation checks
- Structuring this repository documentation

All SQL was executed, validated, and reviewed in the BigQuery environment by the repository author.
