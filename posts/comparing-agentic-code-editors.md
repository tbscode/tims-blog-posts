---
title: "Comparing Agentic Code Editors"
description: "My verdict on Antigravity, Cursor, and Codium + Continue for agentic coding tasks."
date: "2025-11-27T10:40:00+01:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["Programming", "AI"]
tags: ["Antigravity", "Cursor", "Codium", "Continue", "Agentic"]
image: "/static/assets/agentic_editors/antigravity_screenshot.png"
---

In this article, I want to share my experiences with the new wave of "Agentic" code editors that are transforming how we write software. I've been testing a few of the major players: **Antigravity** (from Google), **Cursor** (an independent startup), and the open-source combo of **VSCodium + Continue**.

## The Contenders

### Antigravity (Google)
Antigravity is Google's entry into the agentic coding space. It leverages their massive compute and model capabilities. It feels very integrated and powerful, especially when dealing with complex, multi-step reasoning tasks.

![Antigravity Screenshot](/static/assets/agentic_editors/antigravity_screenshot.png)

### Cursor
Cursor is an independent fork of VS Code. It's built by a startup (Anysphere) and has gained a lot of traction for its smooth user experience and "Cursor Tab" feature which predicts your next edits. It feels very native and fast.

![Cursor Screenshot](/static/assets/agentic_editors/cursor_screenshot.png)

### Codium + Continue
For those who prefer a fully open-source stack, using **VSCodium** (the telemetry-free build of VS Code) combined with the **Continue** extension is a great option. It allows you to bring your own models (like Claude 3.5 Sonnet or GPT-4o) and maintain full control over your data.

![Codium Screenshot](/static/assets/agentic_editors/codium_screenshot.png)

[Read my full guide on setting up Codium + Continue here](https://timschupp.de/blog/self-hosted-ai-code-editing)

## The Verdict

Overall, these tools are **really cool and very impressive** for certain types of work. They shine particularly bright when it comes to **repetitive tasks** that involve the same list of steps every time—like "add a new field to the database, update the API, and add it to the frontend form." They can automate a lot of the boilerplate drudgery.

### The Reality Check

However, it's not all magic. In my experience, they still produce **a lot of crap**. You often have to reject the output or significantly refine your request.

My personal **acceptance rate is about 20-30%** of the suggested code. And even when I do accept it, I often find myself re-writing portions of the generated code to match my specific style or requirements. They are assistants, not replacements.

## A Note on Python Tooling

One specific annoyance I've encountered is with Python linting. The official **Pylint extension for VS Code is proprietary** (part of the Pylance/Python closed-source bundle), and Microsoft has some "shenanigans" in place to disable it on non-official IDEs like VSCodium or other forks.

Because of this, if you are using an editor other than the official VS Code (or Cursor, which has its own plugins), I strongly recommend using **[basedpyright](https://github.com/DetachHead/basedpyright)**. It's a great open-source alternative that works reliably across different editors.
