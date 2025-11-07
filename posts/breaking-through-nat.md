---
title: "Breaking Trough NAT: Decentralized Self-Hosting Via Open-Chat"
description: "How Open-Chats Federation Enables anybody to host anything anywhere"
date: "2025-11-07"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Automation", "Peer-Networks", "Networking"]
tags: ["Open-Chat", "Libp2p", "federation", "msgmate", "msgmate.io"]
---

[Open-Chat](https://github.com/msgmate-io/open-chat-go) is not in it's 7th iteration and fully re-written in golang.
It now as 'federation' features using libp2p, it allows you to quickly spin-up your own network of open-chat nodes.

Open-Chat network member can freely communicate with another, they are automatically joined into a completely independent self-healing overlay-network.

### Creating a Open-Chat Network

Open-Chat Networks can be established inside private networks, across public networks *or across both*.
To be able to penetrate across public and private networks open-chat need to be able to route traffic back to itself trough a router, 
or it need to have at-least one public relay peer available to use as alternate path.

#### **1. Prepare a Bootstrap and Relay Node**
On our public node, we want to use as 'relay' and 'bootstrap' peer, download the Open-Chat binary [from the github release page](https://github.com/msgmate-io/open-chat-go/releases)
Be sure to download the one with '-federation' build in.
E.g.: 

```bash
wget -O open-chat https://github.com/msgmate-io/open-chat-go/releases/download/build-10/open-chat-federation-0.0.111-linux-amd64
chmod +x open-chat # make it executable
```

#### **2. Start first federation node**

For the 'bootstrapper' node you'll have to specify base admin credentials and network-credentials
- network credentials allow 'read-only' network operations and are required to be known for joining a network
- admin credentials are individual to each node, they are required to perform any elevated privilege action, e.g.: creating proxy routes

All can simply be specified like this:

```bash
./open-chat --default-network-credentials "<network-name>:<password>" --root-credentials "<user>:<password>"
```

You can also initalize not credentials without revealing them by specifying `--root-credentials "<username>:hashed_<pdf-hashed-password>"`.
Now that our bootstrapper node is available we can use its peer-id to bootstrap other nodes.

> If you want to persis your open-chat configuration system wide just run it with `--install`

We can extract it's peer Id by either loggin in to the UI with the admin user, or via the Open-Chat cli:

```bash
./open-chat client login                # you'll be promted to ender username and password
./open-chat client identity -b64        # revals the node id in a re-usable base64 format
eyJpZCI6ICI8TE9DQUxfUEVFUl9JRD4iLCAiY29ubmVjdF9tdWx0aWFkcmVzcyI6IFsiL2lwNC88U09NRV9JUF9BRFJFU1M+L3RjcC8wL3AycC88TE9DQUxfUEVFUl9JRD4iXX0=
```

#### **3. Adding other nodes to the network**

The only thing you need is the bootstrap peer string and the networks credentials

```bash
./open-chat -dnc "<network-name>:<password>" -rc "<different-node-specific-admin-creds>" -bs "<base64-bootstrap-peer-string>"
```

Now we just need to wait a moment untill these nodes found each other and established connections.
Lets see if the nodes are connected.

```bash
./open-chat client login          # ....
./open-chat client nodes -ls    # list all available nodes
```

Now lets *see if we can send requests to the node*:

```bash
./open-chat client get-metrics --node <remote-peer-id>
```

Hurray it works! **Now where do we go from here?**

#### **4. Establish on-demand proxy routing rules**

When we have a network, we can model its traffic in any-way we like.
Open-chat nodes can configure arbitrary routing rules on per-node basis, 
every node can only route traffic that goes trough itself.

To route traffic trough another node, routing rules on that node need to be established, 
thus the admin credentials for that node must be known.

Since we control the full network we know admin credentials of very node and can establish any routing rules we want.

**Lets use open-chat to create a ngrok-like TLS to behind NAT reverse-proxy**, to achieve this we need:
1. A single public peer in our control with an `<PUBLIC-IP>`
2. A domain name A-Record pointing that IP `<HOSTNAME>`
3. A private behind NAT node that hosts some TCP service on `<peer-port>`

> All the steps presented here can also be run from a single node, by using network-requests that are build in to Open-Chat.
> For simplicity we run command on individual nodes, but there are also workflows that allow controlling routing rule requests to ANY node just from a single network member.

##### 1. Use open-chat to request TLS certificate on the public node

```bash
./open-chat client tls --hostname "<HOSTNAME>" --key-prefix "<self-defined-certificate-prefix>"
```
This will automatically start the ACME challenge process and saves the obtained certificate in the Open-Chat nodes database.

##### 2. Establish TLS to network routing rules

First we need to tell the public node to accept TLS traffic using the just obtained certificate.
It should only accept traffic coming from `"<HOSTNAME>"` and the traffic should be routed to a specific port on the system.

```bash
./open-chat client proxy --direction "egress" --traffic-origin "<HOSTNAME>" --traffic-target "<key-prefix>:<peer-port>" --kind "tls" --key-prefix "<self-defined-certificate-prefix>"
```

This create an 'egress' proxy that accepts incoming traffic from the `"<HOSTNAME>"` and runnels it into the network.

```bash
./open-chat client proxy --direction "egress" --traffic-origin "<own-peer-id>:<peer-port>" --traffic-target "<remote-peer-id>:<peer-port>" --kind tcp
```

This establishes an 'ingress' rule from the network to the remote peer node.
Now the only thing that is left to do is the local node to tunnel network traffic from that peer to the `<peer-port>` that runs the TCP service.

##### 3. Accept Network Traffic on a local Port

Traffic is now routes from the domain to the public peer, from there inside the network and to the remote peer.
But currently the remote peer would just drop the traffic as it doesn't know what to do with it, lets route it to the port that runs our service:

```bash
./open-chat client proxy --direction "ingress" --traffic-origin "<own-peer-id>:<peer-port>" --traffic-target "<remote-peer-id>:<peer-port>" --kind tcp
```


### Conclusion and Outlook

**This Article merely gives a hint what Open-Chat Federation is able to do**, options from there go way further.
Just as food for though, the following thins are only a few lines of open-chat rules away:

1. **Decentralized Multi-Site behind NAT hosting**
Host a swarm of Server behind NAT on different locations, route them trough multiple public peers in a 'load balancing' fashion
and you have a load resilient decentralized server infrastructure that masks the actual server locations, allows for easy traffic filtering and allows for easy horizontal scaling by just extending the node pool.
2. **Persistent self hosted Ngrok**. As shown in this article open-chat can easily be used to create development routing rules as tools like ngrok can do.
3. **Self managed overlay networks for anything**. This connect extends to any application, also the ones fully privately easily use open-chat routing rules to manage traffic in your local network, *you may even use it in offline local networks!*.
