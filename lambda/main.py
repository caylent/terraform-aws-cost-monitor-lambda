#!/usr/bin/python3
import yaml
import boto3
import calendar
import pytz
import json
import logging
from slack_sdk.webhook import WebhookClient
from datetime import date, timedelta, datetime
from botocore.exceptions import ClientError
from os import environ

session = boto3.session.Session()


def get_config():
    return {'alerts_only': str(environ['alerts_only']), 
       'slack_webhook_url':str(environ['slack_webhook_url']), 
       'alert_threshold': float(environ['alert_threshold'])}

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
    
    print(f'previous month:{previous_month_cost}')
    
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
    print(f'Forecasted cost: {forecasted_cost}')

    return previous_month_cost, forecasted_cost


def post_message(msg, cfg):

    client = session.client(
        service_name='secretsmanager'
    )

    webhook = WebhookClient(cfg['slack_webhook_url'])
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
    print(f'Sending to slack: {msg}')    
    response = webhook.send(text=msg, blocks=blocks)


def lambda_handler(event, context):
    cfg = get_config()
    print(f'CFG object:{str(cfg)}')
    
    print('Calculating cost')
    previous_month_cost, forecasted_cost = get_cost()
    alert_threshold = cfg['alert_threshold']
    
    percent = round(forecasted_cost / previous_month_cost * 100, 2)
    print(f'Calculated percent: {percent}%')
    
    msg = f"Your AWS cost for this month is forecasted to be {percent}% of the previous month"
    
    if cfg['alerts_only'].lower() == 'true' and percent > alert_threshold + 100:
        print('Sending message in alert only mode')
        post_message(msg, cfg)
    elif cfg['alerts_only'].lower() == 'false':
        print('Sending message in scheduled mode')
        post_message(msg, cfg)
    else:
        print('None of the conditions were met. NO message was sent')

    
if __name__ == '__main__':
    lambda_handler('e', 'c')