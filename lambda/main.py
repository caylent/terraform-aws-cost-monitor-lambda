#!/usr/bin/python3
import yaml
import boto3
import calendar
import pytz
import json
from slack_sdk.webhook import WebhookClient
from datetime import date, timedelta, datetime
from botocore.exceptions import ClientError

session = boto3.session.Session()

def get_config():
    with open('config.yml', 'r') as f:
        return yaml.safe_load(f)

def get_cost():
    utc = pytz.UTC
    today = datetime.now(utc)
    
    # this month
    last_day = calendar.monthrange(today.year, today.month)[1]
    month_end =  date(today.year, today.month, last_day)
    
    # last month
    last_month_end = date(today.year, today.month, 1) - timedelta(days=1)
    last_month_start = date(last_month_end.year, last_month_end.month, 1)
    today = date(today.year, today.month, today.day)

    client = session.client('ce')
    result = client.get_cost_and_usage(
        TimePeriod={
            'Start': str(last_month_start),
            'End': str(last_month_end)
        },
        Granularity='MONTHLY',
        Metrics=[
            'UnblendedCost',
        ],
    )

    previous_month_cost = float(result['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])

    if today == month_end:
        month_end = month_end + timedelta(days=1)

    result = client.get_cost_forecast(
    TimePeriod={
        'Start': str(today),
        'End': str(month_end)
    },
    Metric='UNBLENDED_COST',
    Granularity='MONTHLY'
    )

    forecasted_cost = float(result['Total']['Amount'])

    return previous_month_cost, forecasted_cost


def post_message(cfg, msg):

    client = session.client(
        service_name='secretsmanager'
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=cfg.get('secret_name')
        )
    except ClientError as e:
        raise e

    secret = json.loads(get_secret_value_response['SecretString'])
    webhook = WebhookClient(secret[cfg['slack_webhook_secret_key']])
    blocks = [{
            'type': 'section',
            'text': {
                'type': 'mrkdwn',
                'text': '*AWS COST ALERT*'
            }
        },
        {
            "type": "section",
            "text": {
            "type": "mrkdwn",
            "text": msg
            }
        }
    ]
    
    response = webhook.send(text=msg, blocks=blocks)


def lambda_handler(event, context):
    
    previous_month_cost, forecasted_cost = get_cost()
    cfg = get_config()
    alert_threshold = cfg.get('alert_threshold')
    
    percent = round(forecasted_cost / previous_month_cost * 100, 2)
    hi_lo = 'HIGHER'

    if percent > 100:
        percent = percent -100
    else:
        percent = 100 -percent
        hi_lo = 'LOWER'
    
    msg = f"Your AWS cost for this month is forecasted to be {percent}% {hi_lo} than previous month"
    
    if cfg.get('alerts_only') and percent > 100 and percent > alert_threshold:
        post_message(cfg, msg)
    elif not cfg.get('alerts_only'):
        post_message(cfg, msg)

    
if __name__ == '__main__':
    lambda_handler('e', 'c')