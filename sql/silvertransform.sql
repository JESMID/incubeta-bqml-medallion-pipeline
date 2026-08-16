-- Silver outputs from the Bronze schema in GCP (SQL script)
-- POC pattern: full refresh using the stored procedure.

create or replace procedure 
`incubeta-assessment.retail_silver.sp_refresh_silver_transactions`()

begin

create or replace table
`incubeta-assessment.retail_silver.transaction_exceptions`
as
select
      transaction_id,
      customer_id,
      SAFE_CAST(signup_date as date) as signup_date,
      purchase_date,
      amount,
      item_category,
      is_returned,
      'invalid_amount_less_than_or_equal_to_zero' as exception_reason
from `retail_bronze.raw_transactions`
where amount <= 0;

create or replace table
`incubeta-assessment.retail_silver.cleaned_transactions`
as
   with typed_transactions as
        (select
              transaction_id,
              customer_id,
              SAFE_CAST(signup_date as date) as signup_date_raw,
              purchase_date,
              cast(amount as numeric) as amount,
              item_category,

              case
                when upper(trim(is_returned)) = 'TRUE' then TRUE
                when upper(trim(is_returned)) = 'FALSE' then FALSE
                else FALSE
                end as is_returned
        from `retail_bronze.raw_transactions`
        where amount > 0)

    select
          transaction_id,
          customer_id,
          coalesce(signup_date_raw, purchase_date) as signup_date,
          purchase_date,
          amount,
          item_category,
          is_returned,
          date_diff(purchase_date, coalesce(typed_transactions.signup_date_raw, purchase_date),day) as days_to_first_purchase
    from typed_transactions;

end;

-- Execute after deployment:
-- call `incubeta-assessment.retail_silver.sp_refresh_silver_transactions`();
