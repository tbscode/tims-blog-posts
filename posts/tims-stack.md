---
title: "Tim's Stack: Dynamic Cross-platform Web App Stack, deployed with Bunnyshell"
description: "This article showcases a high-performing web app stack I created for a recent Bunnyshell hackathon, using Docker, Kubernetes, Microk8s, Django and Next.js."
date: "2023-07-09T16:56:47+06:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps"]
tags: ["Microk8s", "Kubernetes", "Django", "Helm", "Next.js", "Docker", "Bunnyshell"]
---

> UPDATE: We made 2. Place! 🥳 Checkout [the hackathon page](https://devpost.com/software/tim-s-stack-anystack).

<iframe width="560" height="315" src="https://www.youtube.com/embed/_06vvSltvvY?si=ZMTgD9l2TFNTTa_2" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

> Checkout the [full stack code](https://github.com/tbscode/tims-stack-anystack) on my repo

## Introduction

I recently participated in the Bunnyshell hackathon, where I successfully orchestrated a dynamic cross-platform web app stack. I want to share with you in detail my development process, core features, and the benefits of this stack.

This stack is primarily designed for dynamic, real-time web apps, with a specific inclination towards mobile clients. One of the prominent features is that any changes made in the backend can be directly and instantly transmitted to the clients via a WebSocket connection, thanks to Redux for smooth state management.

## Architecture

I used a Docker container-based architecture using Helm for my application. Docker simplifies the process of managing my application's lifecycle, while Helm assists in deploying my Docker images into a Kubernetes cluster.

Here is an image representation of my stack's architecture:

![stack overview](/static/assets/overview_graph.png)

## Building the Stack

The stack incorporates:

- **Django Backend**: Django is utilised for the backend due to its simplicity and rapid development capabilities. Features like Celery for task management and DRF Spectacular for API documentation are added advantages.

- **Next.js + React Frontend**: Next.js powers the frontend, providing performance benefits, SEO capabilities, and better developer experience.

- **Postgresql & Redis**: They act as primary databases for data and celery respectively.

- **Documentation**: Pdoc3 was used to generate code documentation from backend code.

## Configuring the Stack on Bunnyshell

Bunnyshell significantly simplifies cloud management and deployment automation making it a breeze to set up a Kubernetes cluster and to deploy my application there.

In addition to this, I also exemplify setting up a private Microk8s cluster. Microk8s serves as a lightweight, lean, and efficient Kubernetes distribution, enabling quick and easy deployment of Kubernetes resources even on a low-end VPS.

I hope you find this stack setup helpful and efficient for your next big project. The GitHub repository contains all the code with appropriate comments and READMEs for further exploration.

Happy Coding!

## Technologies

The following table provides a quick overview of the key technologies integrated into the stack:

| Component | Technology | Purpose |
|-----------|------------|---------|
| Frontend  | Next.js + React | Rich UI |
|           | Tailwind CSS + DaisyUI | Styling |
|           | Redux | State Management |
|           | Capacitor | Native integrations and iOS/Android PWA export |
| Backend   | Django | Application Framework |
|           | Celery | Task Management |
|           | Django REST Framework + django_rest_dataclasses | REST API Development |
|           | DRF Spectacular | API Documentation |
|           | Django Channels | Managing WebSockets |
| Documentation | Pdoc3 | Code Documentation |
| Database  | PostgreSQL | Primary Backend Database |
|           | Redis | Broker for Celery and Django Channels |
| Containerization | Docker | Container Creation and Management |
| Deployment and Orchestration | Helm + Bunnyshell | Simplified deployment, Scaling and Management |

Each of these technologies has been selected for its specific capabilities that contribute to the efficient operation of the entire web application stack.