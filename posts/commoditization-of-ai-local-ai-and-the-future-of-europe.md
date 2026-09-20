---
title: "The Commoditization of AI, Local AI and the Future of Europe"
description: "Why I think the commoditization of 'AI' has started, how local and open-source models change the equation, and what that could mean for Europe."
date: "2026-09-20"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["AI", "Programming"]
tags: ["AI", "Local LLM", "Open-Source", "Privacy", "Europe", "Opinion"]
---

> **Note on terms:** I use KI (German) and AI interchangeably at the start; from here on I keep 'AI' in quotes. Everything below is my personal opinion and could well be wrong.

Shenanigans from OpenAI and Anthropic are ever present - *in my opinion more desperation, than anything else*.
But in my opinion *the commoditization of 'AI' has started* - and it will be fast from here.

### Always an early adopter

When it comes to technology I was *always an early adopter*, [I've even kinda predicted the relevance of harnesses when I started open-chat 3 years ago](https://www.youtube.com/watch?v=OqT_kIhz8Dc).
I've used LLMs from the start, few people knew that I was even checking out GPT-2 before the public release of GPT-3.

Since I was young I've been very interested and intrigued by ML systems or generally the thought to create something 'intelligent' that could become lively even possibly.
In my mind this is something that humans would naturally try to create - *this is not a rating - I'm not saying this is a good thing*.

I've been experimenting with 'AI' programming for a while, I've tried all hyped tools, I've even played with ['aider'](https://aider.chat/) before agentic coding really became a thing.
*The twist here isn't the 'AI' models -> It is their general agentic capability + some coding knowledge*.

At the moment though I believe *'AI' is a net negative for humanity so-far* - the cat is out of the bag argument is hard to get rid of.
But I think there is a *better way to use this technology*. This better way are 'local models'.

### A better way: local models

It gives, and takes little:

- Full privacy achievable through local hardware
- DSGVO compatible European hosters popping up everywhere
- Post-alignment and fine-tuning allows custom use-case models (in the past only through provider APIs possible)
- Sovereignty from the US
- Small model training and distillation flourishes

And many more advantages, esp that possibly we have these models simply running on our own devices and we can control how they think and act.

### The threshold is finally passed

I think the threshold is finally passed.
[After running Qwen3.8](https://blog.t1m.me/blog/vllm-litellm-on-amd-strix-halo) I've now moved to using qwen3.8-next-flash (new post on this soon) this runs directly on my cluster.
My results after literally switching 100% to OSS LLMs in coding for over 2 weeks now - *I'm never going back* - are that HELL YES THEY ARE GOOD ENOUGH FOR SURE!

### The pricing and value proposition

And then if you just take a look at the pricing differences then, *you realize fast* -
if the business case from US tech companies relies *on us using their compute in their datacenters* -
somebody has to make sure there is enough value to actually use them there.
*I strongly believe this value proposition isn't working out at the moment*.

### A less dystopian path for Europe

To me all of this gives some 'hope' at least that Europe will be fine, and that *there might still be a 'less dystopian path' for the global 'AI' rollout*.
But we will see :) Anyways *things could also be made or broken with the mid-term elections in the USA*.

Anyways, I'll be using only OSS models in all my private workflows from now on!
I'll report further; but you can already see open-chat is taking over development currently, with a fully automated agent starting to make more and more changes and commits in [open-chat-go](https://github.com/msgmate-io/open-chat-go).

More on open-chat soon too — it is becoming a *seriously helpful tool*.

Cheers Tim

<p class="post-image-grid-caption">Some insights on open-chat working in its own code-base.</p>

<div class="post-image-grid">
  <img width="2114" height="908" alt="Open-chat user automation overview" src="/static/assets/commoditization_post/open-chat-coding-user-automation-overview.png" />
  <img width="1555" height="1015" alt="Open-chat coding agent running on OSS LLMs" src="/static/assets/commoditization_post/open-chat-coding-agent-oss-llms.png" />
  <img width="1483" height="982" alt="Open-chat coding contributions" src="/static/assets/commoditization_post/open-chat-coding-contributions.png" />
  <img width="1531" height="1268" alt="Open-chat benchmark summary overview" src="/static/assets/commoditization_post/open-chat-benchmark-summary-overview.png" />
</div>
