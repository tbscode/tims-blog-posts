---
title: "A Botched Master Thesis Proposal and My Idea for a Decentralized VPN"
description: "Attempt at creating my own Master Thesis Topic"
date: "2026-07-06"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["Networking", "Peer-Networks", "P2P"]
tags: ["VPN", "Libp2p", "Decentralized", "Open-Chat"]
---

Beginning of this year during studies of a course at University taking a course on communication systems;
I had an Idea for a Topic - or actually the idea formed for a while before - but during that time I found the motivation to craft it into a proposal.

Ultimately this didn't come to fruition - yet? - as I'd still be interested in building and testing this or a similar protocol;
or also in general learning more about p2p protocols and communication systems; also their performance and limitations in practice.

Anyways what was this 'idea' about and how did it form?
As I was learning go lang or maybe even some time before when I was playing with messengers; learning about encryption and things;
or maybe even Waaaaaay before; When I was 14 I built [this little RSA calculator app]() which only remaining archive reference is that old archive link here.

Whats my point? Yeah I was interested in encryption, privacy, decentralized systems, torrents, peer to peer - anything in that space, for a while; crypto-coin related stuff not so much - some of the blockchain use cases and technologies were still interesting to me - in a sense which technical capabilities they provide.

So some day when I was exploring to learn golang - prob a decision in one of my many ventures in building realtime chat apps - I ended up stumbling upon [libp2p]().
Very intrigued by the idea or a having a well crafted; clear protocol, that can be implemented in several languages and solve a stack of challenges in communication systems with focus on p2p.

### Initial experiments

Originally the federation experiments [were directly built into open-chat ( as a golang lib & git-submodule) ](https://github.com/msgmate-io/open-chat-go-federation)

Open-chat is my [Open-Source llm automation tool-kit](https://github.com/msgmate-io/open-chat-go) - but in the proposal I aimed to cleanly separate and re-write its implementation short protocol definition on top of libp2p that would allow easy seamless peer to peer networks / communication hopefully fulfilling the following requirements I chose:

1. is an application layer protocol, based on libp2p
2. same logic on every node, no central control node
3. automatic peer discovery and address management
4. multi network system with authentication based network join procedure
5. fully separated per-node and per-network access control and configuration
6. ability to exclude a malicious peer from a network
7. is as simple as possible while maintaining (1-6)

Loosely these were also the original thoughts when I started building it into 'open-chat' as an 'federation' implementation.
I've published all the 'unclean' early experimentation code [now here in this repo]().

In the proposal I sketed out a re-desin of that protocl and a-reimplementation relying on 4 basic data structures and 7 different api endpoints.

The minimal system desined for this Thesis would require at-least the development of these APIs:
- `GET /peer_info`: Endpoint to access node id peer information
- `GET /get_federation_node/<peer-id>/` retrieves node info of a federation member
- `POST /relay_network_request/<network>/<peer-id>/` sends a HTTP requests into the network
- `POST /register_network_peer/<network>/<peer-id>/` tries to register a network peer
- `POST /authorize/`: Used for user / network authorization
- `POST /synchronize_network/`: Synchronized Peer state for authorized network users
- `POST /add_route_rule/`: Allows defining VPN / routing rules. This is what creates and

manages network (tun) devices and proxies routing rules across nodes
Each node needs some basic data structures for:

- Users ( Admin and Network Users, hold authorization information )
- Networks ( Registered Networks )
- Peers ( libp2p manages an internal peer table, that is not persisted across restarts )
- Routing Rules ( Hold per-node information for VPN routing )

The approach this differs significantly from the proposal as it requires multiple additional models and logic to function.
Yet it was fully functional and reliable in my initial experiments and experimental deployment; [e.g.: as I described in this blog post a while ago]().

### The Proposal

Here you can read the original proposal as it was handed in - and prob read maybe once.
I censored the receiver name and the course and anything related to the people involved except my own name.

<iframe
  src="/static/assets/proposal.pdf#view=FitH"
  title="Master thesis proposal PDF"
  style="width:100%;height:70vh;border:1px solid #d9d9d9;border-radius:8px;"
></iframe>

[Open the proposal in a new tab](/static/assets/proposal.pdf)


Anyways time is scarce and working full time and trying to do any courses at-all has taken all the Energy I had so far;
So writing this post is for now shall be the 'ticket' to continue here some time.

### Outlook ?!

Yeah still like the idea; prob its horribly hard to get right and way more complicated than I imagine - quite a things I'd like to bite a thought out on though.
So given the time and opportunity I'd love to build and test such a thing even better in a Scientific context.

So maybe I shared this post with you for context; or you found it somehow
-> in any case if you are interested in helping out or have an Idea where I could hand in another proposal attemt


> then let me know: `tim+libp2p-vpn@timschupp.de`
