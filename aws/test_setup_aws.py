import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from setup_aws import ident, names


class SetupAwsTests(unittest.TestCase):
    def test_names_are_scoped_to_prefix_account_region(self):
        n = names('my-oil-gas-exploration', '123456789012', 'us-west-2')
        self.assertEqual(n['bucket'], 'my-oil-gas-exploration-123456789012-us-west-2')
        self.assertEqual(n['storage_int'], 'MY_OIL_GAS_EXPLORATION_S3_INT')
        self.assertEqual(n['iot_rule'], 'my_oil_gas_exploration_telemetry')

    def test_rejects_unsafe_identifiers(self):
        for bad in ['DB; DROP', 'a-b', '1abc', '']:
            with self.assertRaises(ValueError):
                ident(bad)


if __name__ == '__main__':
    unittest.main()
