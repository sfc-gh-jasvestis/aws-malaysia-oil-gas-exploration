"""Publish simulated rig-floor drilling telemetry to AWS IoT Core (topic my/oil-gas-exploration/telemetry).

The IoT rule lands each message in S3; Snowpipe loads it into RAW.LIVE_TELEMETRY.
Rig IDs come from RAW.RIGS (RG-0000..RG-0029). Values are seeded random.
"""
import argparse
import json
import random
from datetime import datetime, timezone


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--region', default='us-west-2')
    ap.add_argument('--count', type=int, default=40)
    ap.add_argument('--seed', type=int)
    args = ap.parse_args()
    import boto3
    iot = boto3.client('iot', region_name=args.region)
    endpoint = iot.describe_endpoint(endpointType='iot:Data-ATS')['endpointAddress']
    data = boto3.client('iot-data', region_name=args.region, endpoint_url=f'https://{endpoint}')
    rng = random.Random(args.seed)
    for _ in range(args.count):
        rig = f'RG-{rng.randint(0, 29):04d}'
        alarm = rng.random() < 0.1
        msg = {'rig_id': rig,
               'event_ts': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3],
               'spp_bar': round(rng.gauss(290.0 if alarm else 190.0, 12.0), 1),
               'hookload_pct': round(min(100.0, rng.gauss(94 if alarm else 70, 3)), 1),
               'status': 'ALARM' if alarm else 'NORMAL'}
        data.publish(topic='my/oil-gas-exploration/telemetry', qos=1, payload=json.dumps(msg))
    print(f'published {args.count} messages to my/oil-gas-exploration/telemetry via {endpoint}')


if __name__ == '__main__':
    main()
