---
title: "100% Open-Source Self-Hostable AI Code Editing: Codium & Continue.dev"
description: "A comprehensive guide to setting up fully self-hosted AI code editing with Codium and Continue.dev, keeping your code and AI interactions completely private and under your control."
date: "2025-11-27T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Programming"]
tags: ["AI", "Self-Hosting", "Privacy", "Code Editing", "Codium", "Continue.dev"]
image: "/static/assets/codium_cursor_preview.png"
---

Here’s how I keep AI-assisted coding fully under my control: Continue.dev with Codium, pointed at APIs I trust and models I host. Everything stays local or on endpoints I pick - no mistrius data blackholes, no pricy APIs with uncontrolled token usages. Just own hardware and local storage.

### Setting up the local model

`~/.continue/config.yaml`

```yaml
name: My Setup
version: 1.0.0
schema: v1

models:
  - name: "Tims Kimi"
    provider: openai
    model: moonshotai/Kimi-K2-Thinking
    apiBase: https://api.deepinfra.com/v1/openai
    apiKey: <DEEPINFRA_API_KEY>
    roles:
      - chat
      - edit
```

You can even use Google Models outside of Antrigravity:

```yaml
  - name: Gemini 3 Native
    provider: gemini
    model: gemini-3-pro-preview
    apiKey: <GOOGLEAI_API_KEY>
```

### Using self hosted models

There are several tools you can use here; the easiest is probably Ollama with its OpenAI-compatible backend.

e.g.: start qwen coder:

```bash
ollama run qwen3-coder:30b
```

Then include it in your contine.dev configuration:

```yaml
  - name: "Ollama self hosted"
    provider: openai
    model: qwen3-coder:30b
    apiBase: http://localhost:11434/v1
    roles:
      - chat
      - edit
```

And now you can edit the code completely privately using a 100% local model.


### Fixing Python Linting

Microsoft sometimes is a little b**ch, they block the pylint plugin from working with non-official VS Codes.
So I recommend using 'basedpyright'; it works with Codium, and honestly in some aspects is even better than pylint.