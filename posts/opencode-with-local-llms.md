---
title: "Opencode; Usability with Local LLMs on iGPU w 128GB vram: My Tests"
description: "Testing and configuring opencode for usage with local llms"
date: "2026-03-07"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["AI", "Hardware"]
tags: ["LLM", "Ollama", "Benchmark", "AMD", "LLM-Agents", "Open-Code"]
image: "/static/assets/strix-halo-vram.png"
---

[Opencode](https://opencode.ai/) is a pretty cool and neatly composable terminal based llm coding agent.
For a project at [tb-software](https://timschupp.de/) and also private personal use in general I'm especially interesting in the usage of open-code or similar tools with local llms, hosted on own hardware. See [my article on running and testing local llms on a 128gb strix halo setup here](https://blog.t1m.me/blog/local-llms-on-strix-halo-128gb-shared-ram).
This article will describe my personal setup as well as some hints how to manage it using a nix-flake - this functions more as future reference - than direct instructions. But it may help someone configure open-code for local llm usage.

### Configuring Open-Code

Just create a `opencode.json` like this:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": { ... },
}
```
Then start adding your providers, fistly the local llm one, e.g.: you could use here [ollama]() though there are probaly some better and more performant options out there ( _these I still have to test again / with newer models_ ). But project like localai lammacpp, ... come to mind. Anything that host api compatible with the openai api schema really.

```json
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "ollama-local",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": { ... }
```
e.g.: to test the models from [my latest benchark](https://blog.t1m.me/blog/local-llms-on-strix-halo-128gb-shared-ram) i added. _Of course you will have to pull the models and corretly setup and start the local lmm server first ( check my other post for an example using ollama on vulkan + nix )._

```json
        "qwen3-coder-next": { "name": "qwen3-coder-next" },
        "mdq100/Qwen3-Coder-30B-A3B-Instruct:30b": { "name": "qwen-code-instuct-small"},
        "nemotron-3-nano": { "name": "nemotron-3-nano" },
        "glm-4.7-flash": { "name": "glm-4.7-flash" },
        "gpt-oss:120b": { "name": "gpt-oss:120b" }
```

### Usability / Review

As already stated in my benchmark post I was impressed by the performance and usability of the small llms, especially on small simple task like file editing, moving things around, manipulating issues, making simple commits and more. *So it is definitely somewhat hopeful that these open models do seems to perform for some use-case*; So I would say with care and good guardrails they can applied for certain tasks; especially when fully private data processing is required.

Also for the full potential of open-code and priming agents to be able to perform certain tasks in certain environments; you should definitely checkout and learn [how open-code mcps](https://opencode.ai/docs/mcp-servers/) and [agent skills](https://opencode.ai/docs/skills/) are set-up. I my experience the small local models perform best with easy; repeatable and easy to verify tasks - especially when given the right context clues and tools to use - but tasks that involve steps hard to statically automate ( e.g.: text based decision; complex semi autonomous task; browser use; search etc... ). Also it is possible to build in restrictive confirmation based tools for oversight.

### External Providers

Also if you want to use other remove non local providers to test oss models, you could add the following. _Note the api keys are taken from environment you don't need to include them in the config_.

#### 1. Deepinfra

```json
    "deepinfra": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "DeepInfra",
      "options": {
        "baseURL": "https://api.deepinfra.com/v1",
        "apiKeyEnv": "DEEPINFRA_API_KEY"
      },
      "models": { ... }
```

#### 2. groq

```json
    "groq": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Groq",
      "options": {
        "baseURL": "https://api.groq.com/openai/v1",
        "apiKeyEnv": "GROQ_API_KEY"
      },
      "models": { ... }
```

#### a complete config example

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen3-coder-next": { "name": "qwen3-coder-next" },
        "mdq100/Qwen3-Coder-30B-A3B-Instruct:30b": { "name": "qwen-code-instuct-small"},
        "nemotron-3-nano": { "name": "nemotron-3-nano" },
        "glm-4.7-flash": { "name": "glm-4.7-flash" },
        "gpt-oss:120b": { "name": "gpt-oss:120b" }
      }
    },
    "deepinfra": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "DeepInfra",
      "options": {
        "baseURL": "https://api.deepinfra.com/v1",
        "apiKeyEnv": "DEEPINFRA_API_KEY"
      },
      "models": {
        "nvidia/Nemotron-3-Nano-30B-A3B": { "name": "nvidia/Nemotron-3-Nano-30B-A3B" },
        "moonshotai/Kimi-K2.5": { "name": "moonshotai/Kimi-K2.5" },
        "Qwen/Qwen3-235B-A22B-Instruct-2507": { "name": "Qwen/Qwen3-235B-A22B-Instruct-2507" },
        "MiniMaxAI/MiniMax-M2.5": { "name": "MiniMaxAI/MiniMax-M2.5" }
      }
    },
    "groq": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Groq",
      "options": {
        "baseURL": "https://api.groq.com/openai/v1",
        "apiKeyEnv": "GROQ_API_KEY"
      },
      "models": {
        "moonshotai/kimi-k2-instruct": { "name": "moonshotai/kimi-k2-instruct" },
        "qwen/qwen3-32b": { "name": "qwen/qwen3-32b" }
      }
    }
  }
}
```

### Managing a global open-code install via nix

To mange my local open-code installation and configuration I've setup a simple nix flake, in a git sub-module that stores and pulls my open-code configuration and makes it globally available on configuration update.

```nix
{
  description = "Install opencode.json as a global OpenCode config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      opencodeJsonPath = ./opencode.json;

      commonOptions = { lib, ... }:
        {
          options.opencodeOllamaLocalSetup = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to install the OpenCode config file globally.";
            };
          };
        };

      nixosModule = { config, lib, ... }:
        let
          cfg = config.opencodeOllamaLocalSetup;
          defaultUsers = lib.attrNames (lib.filterAttrs (_: user:
            (user.isNormalUser or false) || ((user.uid or null) != null && user.uid >= 1000)
          ) config.users.users);
          targetUsers = if cfg.users == null then defaultUsers else cfg.users;
          existingUsers = lib.filter (name: lib.hasAttr name config.users.users) targetUsers;
          userRules = lib.concatLists (map (name:
            let
              user = config.users.users.${name};
              homeDir = user.home or "/home/${name}";
              groupName = user.group or name;
            in [
              "d ${homeDir}/.config/opencode 0700 ${name} ${groupName} -"
              "L+ ${homeDir}/.config/opencode/opencode.json - ${name} ${groupName} - ${opencodeJsonPath}"
            ]
          ) existingUsers);
        in
        {
          options.opencodeOllamaLocalSetup.users = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "Users to receive ~/.config/opencode/opencode.json (null = all normal users).";
          };

          config = lib.mkIf cfg.enable {
            systemd.tmpfiles.rules = userRules;
          };
        };

      homeManagerModule = { config, lib, ... }:
        let
          cfg = config.opencodeOllamaLocalSetup;
        in
        {
          config = lib.mkIf cfg.enable {
            xdg.configFile."opencode/opencode.json".source = opencodeJsonPath;
          };
        };
    in
    {
      nixosModules.default = { ... }: {
        imports = [ commonOptions nixosModule ];
      };
      homeManagerModules.default = { ... }: {
        imports = [ commonOptions homeManagerModule ];
      };
    };
}
```
