---
title: "Local LLMs on Strix Halo 128GB Shared Ram: My Tests"
description: "Stricks Halo 128GB ram, 100% Local LLM Agents, my tests"
date: "2026-02-22"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["AI", "Hardware"]
tags: ["LLM", "Ollama", "Benchmark", "AMD"]
image: "/static/assets/strix-halo-vram.png"
---

## Local LLMs on Strix Halo 128GB Shared Ram: My Tests

LLMs are sometimes stupid, sometimes impressive, often unpredictable and almost never private.
Bigger models are generally hosted in clouds and proprietary, sometimes you can limit access or censor data presented to model providers but almost never you can restrict access fully or be really sure how and when your data is being used.

These are just some of the reason why you might want to run models locally. But hardware especially graphics cards that can run these models are very pricey and the vram requirement for the more 'mid-range' models just exceeds what is possible with local models.

For some time Apple had an alternative to expensive graphics cards with their m-chip line-up allowing shared-vram with integrated graphics and cpu, but the prices for higher ram mac configurations are still rediculisly high. 
But now there is a 'cheaper' option available for consumers.At [tb-software](https://timschupp.de/) we tested the highest available 128GB ram configuration of a mini PC with the new strix-halo chip to test it and it's ability for running local LLMs.

This article reports our early findings and summaries some configuration steps and the measurement setup we used.
To this point we tested 5 LLMs and more tests are coming. [Also we investigated the use and usability of local agents with opencode](toto).

### Setting up ollama with vulkan

Firstly I needed to allocate allocate vram to the internal grafics card, we have not played with the 'dynamic' setting here yet.
For these tests we have chosen to set the vram to `65536 Mib` so there is about `67 GB` ram still available to the cpu. We can also test influnce on load speed and inference of varying the available amount of vram in the future.

<img width="1451" height="234" alt="Image" src="/static/assets/strix-halo-vram.png" />

Thests where run on nix-os and to access all the libaries required to use the ollama lulkan backend we had to install some additonal packages and libaries, specificly we had to add `vulkan-loader` to the nixos system libaries and run ollama with `OLLAMA_LLM_LIBRARY=vulkan OLLAMA_VULKAN=1 ollama serve`. I used `amdgpu_top` to monitor the vram and grafics usage.

### The Test Setup

To test the LLMs for now I just wantend to know basic results for load speed and completion speeds.
I've created a simple fork of [ollam benchmark]() to measure the results based on an running ollama backend.

If you had the exact same hardware, system and configurations, test could be replicated via:

```bash
python3 -m venv venv
source venv/bin/active
pip install git+https://github.com/tbscode/tims-ollama-bench-fork.git
tims_llm_benchmark run --custombenchmark=<your-model-config>.yml
```

With models file:

```yaml
file_name: "<config-name>.yml"
version: 2.0.custom
models:
  - model: "<model-name>"
```

And run them all via

```bash
tims_llm_benchmark run --custombenchmark=model-configs/qwen3-coder-next.yaml
tims_llm_benchmark run --custombenchmark=model-configs/nemotron-3-nano.yaml
tims_llm_benchmark run --custombenchmark=model-configs/glm-4.7-flash.yaml
tims_llm_benchmark run --custombenchmark=model-configs/gpt-oss-120b.yaml
```

<img width="1906" height="917" alt="Image" src="/static/assets/ollama-benchmark.png" />

### Test Results

Based on this benchmark and personal prompts and agents tests I've created this table to summarize the results.
There are many more tests to be done and likely also perforce improvements through improved configuration, these are just my initial findings and a preliminary re-view. *But I can definitely say that there are functional local models out there that can definitely complete simply tasks locally on this hardware!*

| Name | Size (GB) | Quality | Load Speed | Tokens / sec |
|--|--|--|--|--|
| **qwen3-coder-next** | 61GB | 👾👾👾👾👾 | Fast | `35.094` |
| **nemotron-3-nano** | 34GB | 👾👾👾👾 | Very Fast | `63.566` |
| **glm-4.7-flash** | 40GB | 👾👾👾👾 | Slow | `50.098` |
| **gpt-oss:120b** | 70GB | 👾👾👾👾 | Very Slow | `31.532` |

All these models are usable for smaller and simpler local agentic and coding tasks, involving basic files manipulations and tool calls e.g.: via open-code. I was especially impressed by how well `qwen3-coder-next` performed, and also `nemotron-3-nano` that was incredibly fast and smart for such a small thinking model.

Refs:
- https://github.com/tbscode/tims-llm-benchmark
- https://github.com/tbscode/tims-opencode
- https://github.com/tbscode/tims-ollama-bench-fork

### Controlled autonomous agents with open-code
