-- Apply the trained K-means model to clean Silver transactions.
-- Persist the clean transaction data with its assigned cluster in Gold.

create or replace table `incubeta-assessment.retail_gold.analytics_customer_segments`
as
select
      transaction_id,
      customer_id,
      signup_date,
      purchase_date,
      amount,
      item_category,
      is_returned,
      days_to_first_purchase,
      centroid_id as predicted_cluster,
      nearest_centroids_distance
from ml.predict(model `incubeta-assessment.retail_gold.customer_segmentation_model`,
                (select
                      transaction_id,
                      customer_id,
                      signup_date,
                      purchase_date,
                      amount,
                      item_category,
                      is_returned,
                      days_to_first_purchase
                FROM `incubeta-assessment.retail_silver.cleaned_transactions`
  )
);

-- Validation

/*SELECT
  predicted_cluster,
  COUNT(*) AS transaction_count,
  ROUND(AVG(amount), 2) AS average_transaction_amount,
  ROUND(MIN(amount), 2) AS minimum_transaction_amount,
  ROUND(MAX(amount), 2) AS maximum_transaction_amount
FROM `incubeta-assessment.retail_gold.analytics_customer_segments`
GROUP BY predicted_cluster
ORDER BY predicted_cluster;*/

-- Optional reporting view for readable segment labels:

create or replace view `incubeta-assessment.retail_gold.vw_customer_segment_reporting` as
select
  *,
  case predicted_cluster
    when 1 then 'Broad category - lower spend'
    when 2 then 'Broad category - higher spend'
    when 3 then 'Automotive - mid spend'
    else 'Unclassified'
  end as segment_label
from `incubeta-assessment.retail_gold.analytics_customer_segments`;

