-- ============================================================================
-- 09_AWS_INTEGRATION.SQL — AWS services for Upstream Exploration Analytics
-- Account: <YOUR_AWS_ACCOUNT_ID> | Region: ap-southeast-1
-- Skip this script for Snowflake-only build
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA APP;

-- ==================== AMAZON S3 ====================
-- Storage integration for S3 landing zone
CREATE OR REPLACE STORAGE INTEGRATION aws_malaysia_oil_gas_exploration_S3_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/snowflake-sea-demos-s3'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://<YOUR_S3_BUCKET>/aws-malaysia-oil-gas-exploration/');

-- External stage for data landing
CREATE OR REPLACE STAGE RAW.LANDING_STAGE
  STORAGE_INTEGRATION = aws_malaysia_oil_gas_exploration_S3_INT
  URL = 's3://<YOUR_S3_BUCKET>/aws-malaysia-oil-gas-exploration/';

