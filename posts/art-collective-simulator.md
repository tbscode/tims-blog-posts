---
title: "Art Collective Simulator"
description: "A Game Dev Story–inspired isometric simulation for the Vibrational Network with evolving features from tasks and stats to events and rooms."
date: "2021-01-15T12:00:00+00:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["Games", "Design", "Development"]
tags: ["Isometric", "Godot", "Simulation", "Pathfinding", "A*", "Android", "iOS"]
image: "/assets/archive/game_play_new_jamsession.gif"
---

Art Collective Simulator is a Game Dev Story–inspired simulation for the Vibrational Network, a Hamburg-based collective of musical and visual artists. I developed the codebase, while Giaco and Togrul contributed graphics and music.

The project evolved rapidly across several months, adding systems for characters, tasks, rooms, and events, alongside a modernized dynamic UI and mobile support.

### Feature timeline

#### Up to Jan 2020

- Task section
- Stat-based score generation
- Personalizable and random characters
- First event-related states (e.g., playing instruments)
- Event guest simulations
- Multiple rooms and teleports
- Completely updated dynamic UI

![Jam session gameplay](/assets/archive/game_play_new_jamsession.gif)

#### July

- Full game-state saving and loading
- Game phases
- Phase-based task selection
- Automatic task-based score generation
- Several new game tasks
- Android and iOS compatibility

![June/July gameplay](/assets/archive/june_july.gif)

#### June

- A* pathfinding
- Character stats such as Intelligence, Speed, Creativity
- Stats-based scoring system

#### May

Started programming the simulations with a complete task system. Tasks control entities by working through task queues. Tasks are selected based on player actions and game state.

![Simulation](/assets/archive/simulation.gif)

#### April

First visual prototype: basic isometric functionality — y-sorting, 2D movement, clickable tiles, character animation, and walk cycles.

![First gameplay](/assets/archive/first_game_play.gif)

#### March

I started developing the general framework using the Godot game engine. I outlined core concepts and scoped the project. The following diagrams show interactions between scores, entities, and events — the game's main components.

![Implementation](/assets/archive/implementation.jpg)

![Event hosting](/assets/archive/event_hosting.jpg)

#### February

I began the collaboration with the Vibrational Network in Hamburg — a collective of musical and visual artists. A friend reached out about developing a game; I was motivated to build my first isometric game: a Game Dev Story–style simulation with art.


