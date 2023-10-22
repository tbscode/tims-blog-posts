---
title: "Msgmate.io Development Update Oct 2023"
description: "A progress and state update on the development of my msgmate.io plattform"
date: "2023-10-22T16:56:47+06:00"
featured: false
postOfTheMonth: true
author: "Tim Schupp"
categories: ["DevelopmentUpdates"]
tags: ["Msgmateio", "Kubernetes"]
---

Since launching [Msgmate.io](https://msgmate.io) at the end of March, we've seen a lot of activity and received a myriad of feedback regarding its services and development.

However, the development of the direct Msgmate feature has been quite restricted. As a result, the updates that are visible to the public have also been very limited. Therefore, I am writing this article to shed some light on what's in store for Msgmate's future.

Please note that this article is somewhat technical in nature!

### Statistics

<div style="
    display: flex;
    flex-wrap: wrap;
    justify-content: space-around;
">
    <div style="
        background-color: #2C333A;
        padding: 20px;
        border-radius: 10px;
        width: 20%;
        text-align: center;
        min-width: 320px;
    ">
        <h2 style="color: #E88388; font-size: 24px;">
            <strong>Registered Users:</strong>
        </h2>
        <p>300</p>
    </div>
    <div style="
        background-color: #2C333A;
        padding: 20px;
        border-radius: 10px;
        width: 20%;
        text-align: center;
        min-width: 320px;
    ">
        <h2 style="color: #E88388; font-size: 24px;">
            <strong>Messages Exchanged:</strong>
        </h2>
        <p>6,331</p>
    </div>
    <div style="
        background-color: #2C333A;
        padding: 20px;
        border-radius: 10px;
        width: 20%;
        text-align: center;
        min-width: 320px;
    ">
        <h2 style="color: #E88388; font-size: 24px;">
            <strong>Tokens Used:</strong>
        </h2>
        <p>579,807+</p>
    </div>
    <div style="
        background-color: #2C333A;
        padding: 20px;
        border-radius: 10px;
        width: 20%;
        text-align: center;
        min-width: 320px;
        margin-bottom: 0 !important;
    ">
        <h2 style="color: #E88388; font-size: 24px;">
            <strong>Images Generated:</strong>
        </h2>
        <p>192</p>
    </div>
</div>

Since the alpha launch in March, we've had 300 users register. A total of 6,331 messages have been exchanged, using over 579,807+ tokens for prompts and completions. Furthermore, a total of 192 images have been generated.

> I've received feedback indicating interest in such a service.
> However, there were also critical comments concerning the current reliability and limited range of features available.

Rest assured, I am taking all feedback seriously and am actively working to bring you a better and enhanced user experience.

<strong style="color: red;">For now we limited msgmate.io alpha registrations untill we scaled our bot service to handle more chats in paralel</strong>


### Development in the Software Stack

My interest in large language models and their immediate applications in everyday life led me to initiate Msgmate as an experiment. Having considerable experience in development operations and infrastructure, I've managed to evolve my stack through several iterations based on the backend + infrastructure definitions I've developed over the years.

**Here's a look at the evolution of the stack:**

|Iteration|Link|Description|
|--|--|--|
|1|[Django Clean Slate](https://github.com/tbscode/django-clean-slate)|First stack iteration which involved Django + Webpack + React.|
|2|[Django NextJS Setup](https://github.com/tbscode/django_nextjssetup)|First experimental combination of Django + NextJS + React.|
|3|[Tiny Django](https://github.com/tbscode/tiny-django)|Evolution into the first version of 'Tim's Stack' initially dubbed 'tiny-django'.|
|4|[AnySearch Stack](https://github.com/tbscode/anysearch-stack)|First Live application using the stack for a submission to the tum.ai hackathon. The stack proved to be instantly viable for rapid development and easy deployment to microk8s Kubernetes clusters.|
|5|[Tim's Stack Anystack](https://github.com/tbscode/tims-stack-anystack)|Clean re-write of the stack, adding automation documentation, and more. During the Bunnyshell Jamstack Hackathon, I had the unique opportunity to|
|6|[Tim's Stack V2](https://github.com/tbscode/tims-stack-v2)|Dawn of a new age ;) Finalization work on the stack has started with the objective of making it out-of-the-box ready, usable state.|

All these updated work towards shaping the backend that msgmate.io uses and making it more robust and scalable! The bigger beta update planned for msgmate will be using the update Tims Stack V2 and there are plans for launching an android and ios app along side the new backend and interface.

### The Stack Won 2. Place!

As mentioned in the Above list [I've participated in a Hackathon using my Stack](https://blog.t1m.me/blog/tims-stack). 

> 🥳 Checkout [the hackathon page](https://devpost.com/software/tim-s-stack-anystack).

My efforts in the Bunnyshell hackathon didn't go to waste, as we managed to secure second place and win `$4000`, which I'll be reinvesting in the development of Msgmate.io!

### Msgmate.io Vision

I envision msgmate.io as the premier platform for innovators and casual users a like - who wish to engage with large language models - automated agents - and seamlessly incorporate them into their applications and everyday life. 
Msgmate should provide user-friendly developer APIs, websockets, and client applications. Fundamentally, interaction with language models and agents should be as straightforward as possible. Yet beneath the surface, the platform should offer abundant interfaces and configuration options.

### Development in the Team

Given my commitments to other projects, the time I can invest in Msgmate development is limited.
So, to advance this service further, I need more development power!

Using the prize money from the hackathon, I've already hired a NextJS + React developer to help me revamp the Msgmate interface. 

**However, I still need more developers motivated to work on LLm tooling and software.**

> I am looking for motivated (self) taught developers or students who have experience working on their own projects.
> You need to be a fast learner. Having knowledge of Docker, NextJS, React, Django would be advantageous but not a requirement.
> If you are interested in collaborating with us, get in touch at tim.timschupp@gmail.com

### Want to Stay Updated? Have Feedback or Issues to Report?

We've set up a simple form over at [`msgmate.io/newsletter`](https://msgmate.io/newsletter/). By signing up, you'll receive the next update straight to your inbox.

Feel free to add a comment to the signup request for any feedback or bugs. You can fill out the newsletter request as often as you like! Happy messaging with Msgmate.io!