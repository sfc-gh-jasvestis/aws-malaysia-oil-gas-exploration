-- ============================================================================
-- 09_AWS_INTEGRATION.SQL — AWS services for Upstream Exploration Analytics
-- Account: 018437500440 | Region: ap-southeast-1
-- Skip this script for Snowflake-only build
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA APP;

-- ==================== AMAZON S3 ====================
-- Storage integration for S3 landing zone
CREATE OR REPLACE STORAGE INTEGRATION aws_malaysia_oil_gas_exploration_S3_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::018437500440:role/snowflake-sea-demos-s3'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://sea-aws-demos-018437500440/aws-malaysia-oil-gas-exploration/');

-- External stage for data landing
CREATE OR REPLACE STAGE RAW.LANDING_STAGE
  STORAGE_INTEGRATION = aws_malaysia_oil_gas_exploration_S3_INT
  URL = 's3://sea-aws-demos-018437500440/aws-malaysia-oil-gas-exploration/';

