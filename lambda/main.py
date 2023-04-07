import boto3
import calendar
import pytz
import logging
from slack_sdk.webhook import WebhookClient
from datetime import date, timedelta, datetime
from os import environ

# Get aws session
session = boto3.session.Session()
# Get lambda default logger handler
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_config():
    """
    Gets configs from environment variables.
    """
    return {'alerts_only': str(environ['alerts_only']), 
            'slack_webhook_url': str(environ['slack_webhook_url']),
            'alert_threshold': float(environ['alert_threshold'])}


def get_cost():
    """
    Calculates percentual increase/decrease of cost comparing current month forecaste with previous month cost.
    """
    utc = pytz.UTC
    today = datetime.now(utc)
    
    # this month
    last_day = calendar.monthrange(today.year, today.month)[1]
    month_end = date(today.year, today.month, last_day)
    
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
    
    logger.info(f'previous month:{previous_month_cost}')
    
    # By the end of the month, do a forecast between that day and the next one (1st day of next month)
    # to avoid api validation errors
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
    logger.info(f'Forecasted cost: {forecasted_cost}')

    logger.info(f'last month start: {last_month_start}, last month end: {last_month_end}')
    logger.info(f'Today: {today}, month end: {month_end}')

    return previous_month_cost, forecasted_cost


def post_message(msg, cfg):
    """
    Posts message to slack.
    """
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
    logger.info(f'Sending to slack: {msg}')    
    response = webhook.send(text=msg, blocks=blocks)


def lambda_handler(event, context):
    """
    AWS lambda main function
    """
    # Get environment variables on each execution to allow hot updates to env vars
    cfg = get_config()
    logger.info(f'CFG object:{str(cfg)}')
    
    logger.info('Calculating cost')
    previous_month_cost, forecasted_cost = get_cost()
    alert_threshold = cfg['alert_threshold']
    
    percent = round(forecasted_cost / previous_month_cost * 100, 2)
    logger.info(f'Calculated percent: {percent}%')
    
    msg = f"Your AWS cost for this month is forecasted to be {percent}% of the previous month"
    
    # A 10% threshold will trigger an alert if the forecast percent is 110% vs previous month
    if cfg['alerts_only'].lower() == 'true' and percent >= alert_threshold + 100:
        # send alerts to slack only if alerts_only_mode is on, and the forecasted percent exceeds the threshold
        logger.info('Sending message in alert only mode')
        post_message(msg, cfg)
    elif cfg['alerts_only'].lower() == 'false':
        # send alerts regularly informing the forecasted percent disregarding the threshold
        logger.info('Sending message in scheduled mode')
        post_message(msg, cfg)
    else:
        logger.info('None of the conditions were met. NO message was sent')
