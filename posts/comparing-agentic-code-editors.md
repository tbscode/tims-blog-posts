---
title: "Comparing Agentic Code Editors"
description: "A comparison of Antigravity, Cursor, Windsurf, and Codium + Continue for agentic coding tasks."
date: "2025-12-06T10:40:00+01:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["Programming", "AI"]
tags: ["Antigravity", "Cursor", "Windsurf", "Codium", "Continue", "Agentic"]
image: "/static/assets/agentic_editors/cover_image_inspired_large.png"
---

I have been testing several "Agentic" code editors to understand their current capabilities and limitations. This article compares **Antigravity** (Google), **Cursor** (Anysphere), **Windsurf**, and the open-source combination of **VSCodium + Continue**.

## The Contenders

### Antigravity (Google)
Antigravity is Google's entry into the agentic coding space, leveraging their compute and model capabilities. It integrates well for complex, multi-step reasoning tasks.

**Notes:**
- **Pricing:** No official pricing model exists yet.
- **Rate Limits:** The current rate limits are low and can interrupt workflow during intensive sessions.

![Antigravity Screenshot](/static/assets/agentic_editors/antigravity_screenshot.png)

### Cursor
Cursor is a fork of VS Code built by Anysphere. It includes a "Cursor Tab" feature for predictive edits.

**Cloud Agents:**
Cursor's agents operate in a sandboxed cloud environment. They can execute terminal commands, edit files, and create/refine Pull Requests. This is useful for repetitive, dynamic tasks. For example, I used it to integrate new automatic emails for **Little World**, where the agent edited configuration files across multiple locations and restructured code, replacing a previously manual process.

**Pricing:**
The Pro plan costs approximately **€20/month**. However, it includes a limited number of "fast" agent edits; exceeding this limit results in throttling or requires purchasing usage tokens.

![Cursor Screenshot](/static/assets/agentic_editors/cursor_screenshot.png)

### Windsurf
Windsurf is another editor in this space, emphasizing a "Flow" state. Some of the original engineers behind Windsurf are now employed at Google.

### Codium + Continue
For a fully open-source stack, **VSCodium** (a telemetry-free VS Code build) combined with the **Continue** extension allows the use of own models (e.g., Claude 3.5 Sonnet, GPT-4o) while maintaining data control.

![Codium Screenshot](/static/assets/agentic_editors/codium_screenshot.png)

**Trade-offs:**
- **Privacy:** No telemetry or data egress without explicit configuration.
- **Usability:** Major vendors (like Microsoft) do not support non-official builds. Proprietary extensions like Pylance/Pylint are often disabled or broken, requiring workarounds.

[Read my guide on setting up Codium + Continue here](https://timschupp.de/blog/self-hosted-ai-code-editing)

## Verdict

These tools are useful for specific workflows, particularly repetitive tasks involving consistent steps (e.g., adding a database field, updating the API, and modifying the frontend).

### Reality Check

They are not perfect. In my experience, they produce a significant amount of incorrect output. My acceptance rate is approximately **20-30%** of the suggested code. Even accepted code often requires rewriting to match specific requirements. They function as assistants, not replacements.

## Python Tooling Note

The official **Pylint extension for VS Code is proprietary** (part of the Pylance/Python bundle) and is disabled on non-official IDEs like VSCodium.

If using an editor other than the official VS Code or Cursor, I recommend **[basedpyright](https://github.com/DetachHead/basedpyright)** as an open-source alternative.
