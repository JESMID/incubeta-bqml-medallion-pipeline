-- Train a native BigQuery ML K-means model.
-- Features: amount and item_category.

create or replace model `incubeta-assessment.retail_gold.customer_segmentation_model`
options (
          model_type = 'KMEANS',
          num_clusters = 3,
          standardize_features = TRUE,
          kmeans_init_method = 'KMEANS++') as

      select 
          amount,
          item_category
      from `incubeta-assessment.retail_silver.cleaned_transactions`;

-- Query evaluationa (Optional);
-- select * from ml.evaluate(model `incubeta-assessment.retail_gold.customer_segmentation_model`);
