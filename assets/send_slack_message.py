import os
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

SLACK_API_TOKEN = os.environ["SLACK_API_TOKEN"]
CHANNEL_ID = os.environ["CHANNEL_ID"]
MESSAGE = os.environ["MESSAGE"]

bot_token = SLACK_API_TOKEN
message = MESSAGE
client = WebClient(token=bot_token)

response = client.chat_postMessage(
    channel=CHANNEL_ID,
    mrkdwn=True,
    text=message,
    unfurl_links=False,
    unfurl_media=False
)

print(response, response.status_code)

