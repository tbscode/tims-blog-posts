---
title: "Breaking Through NAT: Decentralized Self-Hosting Via Open-Chat"
description: "How Open-Chat's Federation Enables Anybody to Host Anything Anywhere"
date: "2025-11-07"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Automation", "Peer-Networks", "Networking"]
tags: ["Open-Chat", "Libp2p", "federation", "msgmate", "msgmate.io"]
---

[Open-Chat](https://github.com/msgmate-io/open-chat-go) is now in its 7th iteration and fully rewritten in Golang.
It now has 'federation' features using libp2p, allowing you to quickly spin up your own network of Open-Chat nodes.

Open-Chat network members can freely communicate with one another and are automatically joined into a completely independent, self-healing overlay network.

### Creating an Open-Chat Network

Open-Chat networks can be established inside private networks, across public networks *or across both*.
To penetrate across public and private networks, Open-Chat needs to be able to route traffic back to itself through a router,
or it needs to have at least one public relay peer available as an alternate path.

#### **1. Prepare a Bootstrap and Relay Node**
On our public node, which we want to use as a 'relay' and 'bootstrap' peer, download the Open-Chat binary [from the GitHub release page](https://github.com/msgmate-io/open-chat-go/releases).
Be sure to download the one with the '-federation' build included.
E.g.:

```bash
wget -O open-chat https://github.com/msgmate-io/open-chat-go/releases/download/build-10/open-chat-federation-0.0.111-linux-amd64
chmod +x open-chat # make it executable
```

#### **2. Start the first federation node**

For the 'bootstrapper' node, you'll have to specify basic admin credentials and network credentials.
- Network credentials allow 'read-only' network operations and are required to be known for joining a network.
- Admin credentials are individual to each node; they are required to perform any elevated privilege action, e.g. creating proxy routes.

All of these can simply be specified like this:

```bash
./open-chat --default-network-credentials "<network-name>:<password>" --root-credentials "<user>:<password>"
```

You can also initialize node credentials without revealing them by specifying `--root-credentials "<username>:hashed_<pdf-hashed-password>"`.
Now that our bootstrapper node is available, we can use its peer ID to bootstrap other nodes.

> If you want to persist your Open-Chat configuration system-wide, just run it with `--install`.

We can extract its peer ID either by logging in to the UI with the admin user or via the Open-Chat CLI:

```bash
./open-chat client login                # you'll be prompted to enter username and password
./open-chat client identity -b64        # reveals the node ID in a reusable base64 format
eyJpZCI6ICI8TE9DQUxfUEVFUl9JRD4iLCAiY29ubmVjdF9tdWx0aWFkcmVzcyI6IFsiL2lwNC88U09NRV9JUF9BRFJFU1M+L3RjcC8wL3AycC88TE9DQUxfUEVFUl9JRD4iXX0=
```

#### **3. Adding other nodes to the network**

The only things you need are the bootstrap peer string and the network credentials.

```bash
./open-chat -dnc "<network-name>:<password>" -rc "<different-node-specific-admin-creds>" -bs "<base64-bootstrap-peer-string>"
```

Now we just need to wait a moment until these nodes find each other and establish connections.
Let's see if the nodes are connected.

```bash
./open-chat client login          # ....
./open-chat client nodes -ls    # list all available nodes
```

Now let's *see if we can send requests to the node*:

```bash
./open-chat client get-metrics --node <remote-peer-id>
```

Hooray, it works! **Now where do we go from here?**

#### **4. Establish on-demand proxy routing rules**

When we have a network, we can model its traffic in any way we like.
Open-Chat nodes can configure arbitrary routing rules on a per-node basis;
every node can only route traffic that goes through itself.

To route traffic through another node, routing rules on that node need to be established,
so the admin credentials for that node must be known.

Since we control the full network, we know the admin credentials of every node and can establish any routing rules we want.

**Let's use Open-Chat to create an ngrok-like TLS reverse proxy for services behind NAT.** To achieve this, we need:
1. A single public peer in our control with a `<PUBLIC-IP>`
2. A domain name A record pointing to that IP `<HOSTNAME>`
3. A private node behind NAT that hosts some TCP service on `<peer-port>`

> All the steps presented here can also be run from a single node, by using network requests that are built into Open-Chat.
> For simplicity, we run commands on individual nodes, but there are also workflows that allow controlling routing rule requests to ANY node from a single network member.

##### 1. Use Open-Chat to request a TLS certificate on the public node

```bash
./open-chat client tls --hostname "<HOSTNAME>" --key-prefix "<self-defined-certificate-prefix>"
```
This will automatically start the ACME challenge process and save the obtained certificate in the Open-Chat node's database.

##### 2. Establish TLS-to-network routing rules

First, we need to tell the public node to accept TLS traffic using the just-obtained certificate.
It should only accept traffic coming from `"<HOSTNAME>"`, and the traffic should be routed to a specific port on the system.

```bash
./open-chat client proxy --direction "egress" --traffic-origin "<HOSTNAME>" --traffic-target "<key-prefix>:<peer-port>" --kind "tls" --key-prefix "<self-defined-certificate-prefix>"
```

This creates an 'egress' proxy that accepts incoming traffic from `"<HOSTNAME>"` and tunnels it into the network.

```bash
./open-chat client proxy --direction "egress" --traffic-origin "<own-peer-id>:<peer-port>" --traffic-target "<remote-peer-id>:<peer-port>" --kind tcp
```

This establishes a routing rule from the network to the remote peer node.
Now the only thing left to do is for the local node to tunnel network traffic from that peer to the `<peer-port>` that runs the TCP service.

##### 3. Accept network traffic on a local port

Traffic is now routed from the domain to the public peer, from there inside the network, and to the remote peer.
But currently the remote peer would just drop the traffic because it doesn't know what to do with it. Let's route it to the port that runs our service:

```bash
./open-chat client proxy --direction "ingress" --traffic-origin "<own-peer-id>:<peer-port>" --traffic-target "<remote-peer-id>:<peer-port>" --kind tcp
```


### Conclusion and Outlook

**This article merely gives a hint of what Open-Chat Federation is able to do**; the options from there go much further.
Just as food for thought, the following things are only a few lines of Open-Chat rules away:

1. **Decentralized multi-site hosting behind NAT**
Host a swarm of servers behind NAT in different locations, route them through multiple public peers in a 'load balancing' fashion,
and you have a load-resilient decentralized server infrastructure that masks the actual server locations, allows for easy traffic filtering, and allows for easy horizontal scaling by simply extending the node pool.
2. **Persistent self-hosted ngrok**. As shown in this article, Open-Chat can easily be used to create development routing rules like tools such as ngrok can do.
3. **Self-managed overlay networks for anything**. This concept extends to any application; even fully private applications can easily use Open-Chat routing rules to manage traffic in your local network. *You may even use it in offline local networks!*
