---
title: "Send Slack Notifications on Deployments with GitHub Actions"
description: "Set up Slack notifications for deployments using GitHub Actions and the Python slack_sdk package, keeping your team updated automatically."
date: "2023-12-12"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Automation"]
tags: ["Slack", "GitHub Actions", "slack_sdk", "Python", "CI/CD"]
---

- [the python script](https://github.com/tbscode/tims-blog-posts/blob/main/assets/send_slack_message.py)

Need to notify your team about deployment status on Slack? Automate the process using the slack_sdk Python package with GitHub Actions. Here's how to set it up step by step:

### Creating Your Slack App for Notifications

1. **Create a Slack App**: Go to the [Slack API](https://api.slack.com/apps) section, select 'Create New App', input a name, and choose your workspace.

2. **Set Permissions**: In the Slack app settings, navigate to 'Features' > 'OAuth & Permissions'. Under 'Scopes', add `chat:write` for your bot to send messages. Once you save changes, click 'Install to Workspace'.

3. **Retrieve Your Slack Bot Token**: After installing the app to your workspace, grab your 'Bot User OAuth Token' from the 'OAuth & Permissions' page. Securely store this token as it will be used to authenticate your GitHub Actions script.

### Setting Up GitHub Actions to Send Slack Notifications

First, include your Slack API token as a secret in your GitHub repository:

1. In your GitHub repo, go to 'Settings', then 'Secrets'.
2. Select 'New Repository Secret', and add your Slack API token under `SLACK_API_TOKEN`.

Now, integrate the `send_slack_message.py` script with your deployment process:

```python
# send_slack_message.py
import os
from slack_sdk import WebClient

client = WebClient(token=os.environ["SLACK_API_TOKEN"])

response = client.chat_postMessage(
    channel=os.environ["CHANNEL_ID"],
    mrkdwn=True,
    text=os.environ["MESSAGE"],
)

print(response["message"]["text"])
```

Add a GitHub Actions step in your workflow to execute the notification script:

```yaml
jobs:
  deployment:
    runs-on: ubuntu-latest
    steps:
      # ... previous steps for deployment ...
      
      - name: Notify Slack Channel
        env:
          SLACK_API_TOKEN: ${{ secrets.SLACK_API_TOKEN }}
          CHANNEL_ID: 'your-channel-id'
          MESSAGE: "*Deployment Update*\nImage: ${{ steps.build.outputs.IMAGE_URL }}\nURL: ${{ steps.deploy.outputs.WEBSITE_URL }}"
        run: |
          pip install slack_sdk
          wget -qO- https://raw.githubusercontent.com/tbscode/tims-blog-posts/main/assets/send_slack_message.py | python3 -
```

Replace `your-channel-id` with the actual Slack channel ID where you wish to send notifications. 

> Replace the script url with a self hosted fork of [send_slack_message.py](https://github.com/tbscode/tims-blog-posts/blob/main/assets/send_slack_message.py)

Remember to update the `MESSAGE` variable with relevant details for your deployment, such as image URL or site URL.

Executing the GitHub Action with these configurations will automatically send your predefined message to the designated Slack channel, informing your team about the latest deployment status.

Your GitHub Actions workflow now works seamlessly with Slack for real-time notifications!