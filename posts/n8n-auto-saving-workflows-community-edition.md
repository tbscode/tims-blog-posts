---
title: "n8n community edition: synchronize workflows to github"
description: "A n8n workflow setup, that synchronizes workflow and credential changes directly to github"
date: "2025-10-08"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Automation"]
tags: ["Workflow", "Automation", "n8n"]
---

N8n is a cool workflow and automation tool, that has a fair free plan and public code policy.
The community edition can be used and self-hosted by anybody, though it doesn't offer all the features n8n-cloud does.

For example the community edition doesn't allow synchronizing workflows and changes to a github repository.
But that's no issue really cause we can just craft a simple n8n workflow, that easily synchronizes all workflows into a private repo.

> If you don't have n8n set up yet, see my post on [self-hosting n8n on Kubernetes](/blog/n8n-on-kubernetes).

### Workflow setup

N8n has a n8n-trigger, for when an active workflow was updated.
This trigger can be used to run a workflow in the moment when it is saved.

Using this we can craft a simple workflow that accepts a n8n workflow ID and uses that and some github credentials to store the workflow as JSON inside a repository.

![N8n workflow](/static/assets/n8n_self_backup_workflow.png)

### (optional) Automatic Credentials Backup

Also if you followed my other blog post on [installing n8n in kubernetes](/blog/n8n-on-kubernetes), you can also add a simple workflow that allows you to automatically backup your n8n credentials, every time a workflow is changed.

This workflow runs a GitHub Actions workflow and waits for its completion. The GitHub workflow uses stored secrets and an encrypted data store to access your Kubernetes cluster, downloads the credentials from the running n8n pod, then saves them encrypted to your repository.

The setup handles all the Kubernetes complexity—you just need to configure GitHub secrets for cluster access and point the workflow at your n8n namespace.

> If someone wants the actual workflow configurations, they should write me an email at `tim+blog@timschupp.de`.