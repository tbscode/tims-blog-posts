---
title: "Announcing Open-Chat: A Sovereign, Local-First 'AI' Platform"
description: "Open-chat is a portable, composable, self-hostable platform for sovereign, private and self-controlled 'AI' — now released under AGPL."
date: "2026-10-03"
featured: true
postOfTheMonth: true
highlight: true
image: "/static/assets/open_chat_release/cover.jpg"
video: "k4_KK-o8jEU"
author: "Tim Schupp"
categories: ["AI", "DevelopmentUpdates"]
tags: ["Open-Chat", "Open-Source", "LLM", "Self-Hosting", "AI", "Privacy", "Announcement"]
---

Hello everybody.

Some of you might know [this video here from two something years ago](https://www.youtube.com/watch?v=OqT_kIhz8Dc), where I presented the concept for 'open-chat' and said: *"So I'm only developing on this project in my free time and cannot make any promises on the development speed, but I'm very motivated to help bringing out stuff that lets us run models locally."*

Well, it was quite silent since then - except for maybe some heard that I shut down the original [beta.msgmate.io](https://msgmate.io) due to time constraints - now today I'm finally back with a *serious update*.

In my free time I've fully re-written [open-chat](https://github.com/msgmate-io/open-chat-go) in Go lang, especially to prepare for portability, cross-device compatibility and scalability.

So now open-chat is everything that I need, that you as a product "AI" user / developer may need, that a company rolling out "AI" products to their employees needs - and anything I ever wanted in an actual "AI" orchestration tool, while being fully sovereign, private and self-hostable. Fully self-controlled "AI" orchestration for you.

Open-chat bundles all the functions and strives to be able to do anything any other fancy LLM provider online chat interface or local Codex app or Claude app can do - *while being different*: open-chat is local-first, open-chat is multi-user first, open-chat is control and sandbox integration by itself, open-chat has built-in governance, built-in automation and is an orchestration tool at once. This sort of tool never existed in my opinion - so I created it.

And I want to offer it to everybody. Of course such a tool and such an application is highly complex, but bit by bit I think I'll be able to make this accessible to anyone. Open-chat is fully extensible, it may compile in custom integrations, and you can of course also develop your own private integrations.

I've designed open-chat in such a way that it fulfills any criteria that any OSS tool has missed for me. I've tested a lot of them - ask my friends, I was switching "AI" and automation tools every 3 days. They all somewhat work and of course have their use case and niche, but there were always some things that my software architecture / DevOps / platform engineering mind was missing. So I kind of re-thought the concept and created what I think is the right solution here.

In my opinion such a tool has to be a platform, an "AI" orchestration tool and an "AI" runtime - but it may never contain any external services or binaries. It shall only interface with any other tool, application, app or service.

The tool itself MUST BE PORTABLE, IT MUST BE COMPOSABLE, IT MUST BE SELF-HOSTABLE, and it must not ever write any custom client code - the clients must always be derived and generated from the back-end API specification. Yeah, I know, strict rules - but these come with a lot of power: if the tool orchestrates, ports and builds itself, it may *evolve itself*. And we can already see that with open-chat actually now developing itself in its own code base, using open-chat.

That's just a taste of the possibilities. For example, see how easy it is to set up an [MCP](https://modelcontextprotocol.io) connection to a Google Workspace with three clicks - and suddenly your local LLM at home can search, edit and work on your Google files fully privately (well, Google has the data, of course). I've tested this, it definitely works - I've hosted and deployed open-source models on [my private cluster](https://blog.t1m.me/blog/building-own-private-kuberntes-ai-cluster) and tested open-chat with it. And if you want to read my comment on the state of open-source "AI", [read this blog article](https://blog.t1m.me/blog/commoditization-of-ai-local-ai-and-the-future-of-europe). All of this works without any US big tech, OpenAI or Anthropic shenanigans - just with the mini PC in your own basement.

You can connect any MCP - for example throw in [Playwright](https://playwright.dev) and start controlling your browser sandboxes with any model. This ain't limited to anything, really.

Open-chat is already taking over development. Open-chat has voice input, open-chat can do image processing - and any imaginable thing that can be done out there with some open-source model can be integrated with open-chat.

Open-chat itself orchestrates its own sandboxes with Docker or Kubernetes (or any other backend we add in the future). It allows for full access control definition for any multi-user account, fine-grained tool confirmations, executions and scopings, and it has a full async runtime with its own workers that is horizontally scalable - the distribution is directly built in. It's designed to be extensible and efficient from the ground up, and it's still a tiny binary.

For now it will be really hard to grasp what it is, but as I release more and more demos and benchmarks and announce the first company integrations (already some in the making here), things will become more clear.

For now the most important thing is that you get an idea and I get the message out there: I think having good sovereign "AI" infrastructure in Europe will be an important game changer for us - and that is what I want to contribute to.

For now open-chat's core is released under AGPL, and there are several closed-source optional integrations at the moment. Depending on requests and reception of this release, I'm planning to open-source more and more of them.

Open-chat itself is also cross-platform from the ground up. An Android app is already in the making - and contrary to any other LLM tool, the app will actually include the full server, so once local LLMs become feasible you'll be able to take all your workflows directly onto your phone. iOS is also in the making, so no worries there.

I seriously believe such a tool has massive potential, especially because it solves several access-right management and orchestration issues that I didn't really see solved anywhere else - or at least not in non-proprietary software.

And I'm very confident that the negative impact of LLMs on code quality, or for coding in general, is very controllable by introducing error-correcting tests, having good CIs, having benchmarks, having human oversight, having self-healing deployments, and so on. I'm actively rolling out these parts in my workflows already, and I'll also be publishing more and more benchmarks, tests and results.

At some point open-chat / [msgmate](https://msgmate.io) will also release its own benchmarking. I'm already testing all the open-source LLMs on all the pre-existing workflows that work, so I can verify whether any future model - or any smaller model - will also work. My aim is to provide a state-of-the-art overview of open-source LLM capabilities, and to analyze them by energy consumption, intelligence, token usage, memory usage and speed - and hopefully show how fast and when we can use open-source LLMs in which use case.

Many things said here - many things I will have to show over the next months and years. Still, my time to work on open-chat is quite limited, but depending on the interest and reception of the first release I'll make sure that development efforts can also be scaled.

I'm also very curious about possible collaborations or contracts on integrations, pilots, or from people that just want to use the tool. I'll happily offer development and integration services alongside possible talks about custom development of integrations or custom licensing for companies.

Contact me for an initial talk: tim@timschupp.de

Anyways, let's see where this goes - [check out open-chat today](https://github.com/msgmate-io/open-chat-go). Thanks for listening.

Cheers Tim
