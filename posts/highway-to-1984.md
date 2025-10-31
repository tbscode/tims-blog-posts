---
title: "'War is peace. Freedom is slavery. Ignorance is strength.'"
description: "A quote from the Party in George Orwell's 1984. Indicators for increasing Surveillance, just a curated reference list, with some comments."
date: "1984-09-21T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Programming"]
tags: ["Microk8s", "Kubernetes"]
---

This list is in no way exhaustive, nor does it deeply analyze and or compare.
The list is meant for later reference and comments, if you find factually false information, please contact me `tim+blog@timschupp.de`.
If you have comments are discussion points, also contact me. For a [change log, check the github history of this article](https://github.com/tbscode/tims-blog-posts/).

The developments in Surveillance are related to the power exercises of a few,
there are many more laws and regulation being instated that don't directly foster surveillance but ensure retention of power and ongoing corruption in governments and state actors. This goes so far that we pass many laws that have 'seemingly good intentions' but contain many causes that directly consolidate power of a few companies and actors, **this is a whole topic in itself and thus will receive it's own blog article in the future**.

<p style="text-align:center;">
  <img src="/static/assets/ClippyTimDark.png" alt="Clippy and Calvin" />
</p>

#### Why this list?

I'm convinced that misinformation and surveillance are some of the biggest Threats to democracy our way to live and our freedom to manage and control the live we lead. Especially currently I feel that a lot of the privacy protections the EU had in place are weakening and we are rapidly making steps towards surveillance.
Therefore I created this curated list, so I can share it when this topic is touched in a conversation.

Some quotes:

- `"[NSA] surveillance… threatens the core principles of a democratic society."` — Sir Tim Berners-Lee (2013)
- `"Spying on individuals on a massive scale, without strict legal rules and democratic oversight, ... harms freedom of speech, association and participation."` — Council of Europe Commissioner for Human Rights (2013)

## `#UK-1` Online Safety Act

Under the umbrella of 'protect children online' the UK-Online-Safety-Act enables nationwide censorship of content.
It enforces age-checks on any publicly accessible web-page in the UK that host content which is 'age-restricted'.
The UK's Office for Communications (Ofcom) is enforcing the law by fining website owners that don't introduce age verification.
Age verification 

Additional Concerns are that the Online Safety act also contains status around *Encryption & client-side scanning*,
which some argue could enable even further reaching surveillance.

**Tim's Comment**: The enforcement hits the wrong target here. If it were actually fulfilling the goal of online safety, it would be no issue at all to enable global authentication at carrier level, thus restrict children's access without enforcing change with the platform owners. The way the law is currently set-up it allows for targeted censorship, which use we have already seen (3). Also forcing plattform owner to perform the age verification on their plattform but trough a 3rd party ventor, opens up many new angels for internet usage tracking of individuals.
The EU's Digital Services Act is a somewhat 'weaker' but well better designed law that enforce similar but more controlled measures to protect against similar dangers.

#### Reference:

1. [Wikipedia](https://en.wikipedia.org/wiki/Online_Safety_Act_2023)
2. [Discord Data Breach](https://proton.me/blog/discord-age-verfication-breach) Though this is only indirectly related to the safety act it clearly shows the danger of processing and storing ID's.
3. [Safety Act Used For Censorship Instead Protection](https://www.theguardian.com/technology/2025/aug/04/social-media-battles-and-barbs-on-both-sides-of-atlantic-over-uk-online-safety-act?utm_source=chatgpt.com)


## `#EU-1` Chat-Control

Since 2022 brought to the EU courts multiple times, a law under the name "Chat-Control" Proposes measure toward ensuring child safety, combating [CSAM](https://en.wikipedia.org/wiki/Child_pornography) online, targeting specifically messaging services.
 
The proposal calls for scanning messaging content for CSAM or abuse, many experts have noted that this crashes with end-to-end-encryption on a technical level, and thus would only be feasible with client side scanning, which in turn bypasses the whole concept of end to end encryption.

**Tim's Comment**: Again, enforcement seems misdirected. If the actual goal is protecting children, this can be pursued with targeted, court-supervised investigations and better cross-border policing **and especially better education and measure for parents to protect their kids**. But not through normalizing client side bulk scanning. Mandating mechanisms that break or bypass E2EE opens the door to selective filtering and abuse. As with many other these, we know **existing capabilities WILL be abused**.

#### Reference:

1. [Wikipedia: EU regulation on CSAM detection/"Chat Control"](https://en.wikipedia.org/wiki/Chat_control)
2. [EDRi: Why client-side scanning is a threat to privacy and security](https://edri.org/our-work/chat-control-what-is-actually-going-on/)
3. [Signal: Scanning content on your phone breaks end-to-end encryption](https://aboutsignal.com/news/the-end-of-private-conversations-signal-threatens-to-leave-the-eu-if-chat-control-becomes-mandatory/).
4. [Bugs in our Pockets: The Risks of Client-Side Scanning](https://arxiv.org/abs/2110.07450)


## `#EU-2` Facial Scanning and the EU-AI-Act

The new EU-AI-Act contain several regulation in terms of use and application of facial recognition - which can be in-part seen as positive protection - of application for facial scanning, and the use of biometric data.
If compared to several other countries this law is very careful and mandates regulatory oversight and allows use only in narrowly defined scenarios, but regardless it mandates the use of facial scanning in several scenarios. It gives the regulatory decision power to the member state in question and enforces reporting and self-regulation.

**Tim's Comment**: Forbidding facial scanning in many scenarios is a step in the right direction! But the effectiveness and the bias of regulatory oversight for the cases where it will be permitted is to be questioned. Also the member state enforcement or actions if these rules are broken aren't defined well. Thus generally more options for surveillance are given and roll-out of these systems will be supported by these regulation existing.


#### Reference:

1. [EU Parliament](https://www.europarl.europa.eu/news/en/press-room/20240308IPR19015/artificial-intelligence-act-meps-adopt-landmark-law#:~:text=Law%20enforcement%20exemptions%20The%20use,linked%20to%20a%20criminal%20offence)

## `#GOGL-1` Mandatory developer verification coming for all APP's

Starting in September 2026 (with rollout stages beginning March 2026), Google will require **developer verification** for **every app** installed on certified Android devices—including apps from third‑party stores and direct APK installs; ADB installs are the notable exception (1)(2)(4). Any install outside Play (F‑Droid, other stores, direct downloads) must be tied to a verified legal identity and registered package names, extending Play‑style checks to off‑Play distribution (1)(3).

Practically, anonymous or hobbyist distribution becomes much harder: unverified installs ( which they want use to call 'sideloads' ) will fail on certified devices, and third‑party stores can only ship apps from verified developers (4)(5). Google presents this as curbing PHAs and ban‑evasion while "keeping Android open and safe" (1).

This coincides with broader use of Play Integrity, where apps check "installed by Play" and device/strong integrity. That tends to exclude non‑certified OSes like GrapheneOS despite strong security properties, leading to breakage in banking, payments, transit, streaming, and games when developers enforce those verdicts (5)(6).

**Tim's Comment**: Useful against re‑uploads, but it centralizes control and blurs certification with security. Prefer **hardware key attestation** for stronger, targeted trust—and treat "installed by Play" and device/strong integrity as advisory, not hard gates, so secure alt‑OS users aren’t collateral (6)(5).

#### Reference:

1. [Android Developer Verification Policy](https://developer.android.com/developer-verification?utm_source=chatgpt.com)
2. [Android Developers Blog: Rollout Timeline](https://android-developers.googleblog.com/2025/08/elevating-android-security.html?utm_source=chatgpt.com)
3. [The Verge: Google Verification Requirement](https://www.theverge.com/news/765881/google-android-apps-side-loading-developer-verification?utm_source=chatgpt.com)
4. [Hackaday: Non-ADB APK Installs Require Registration](https://hackaday.com/2025/10/06/google-confirms-non-adb-apk-installs-will-require-developer-registration/?utm_source=chatgpt.com)
5. [Play Integrity API Overview](https://developer.android.com/google/play/integrity/overview?utm_source=chatgpt.com)
6. [GrapheneOS: Attestation Compatibility Guide](https://grapheneos.org/articles/attestation-compatibility-guide?utm_source=chatgpt.com)
7. [F-Droids statement](https://f-droid.org/en/2025/09/29/google-developer-registration-decree.html)


## `#MSFT-1` Windows Recal + MSA tied TUID

Similar as Google Integriy APIs todo, section to be written...


### More to check-out

This Post isn't finished, nor does it contain really much, just contains what I was able to write down in a few hours.
I strongly encourage everyone to do their own research on the topic, circle back, comment, [and maybe also help me extend this post, simply open an issue on my github with your proposed changes.](https://github.com/tbscode/tims-blog-posts/issues/new/choose).

##### Reference:

1. [The Survailence Report](https://surveillancereport.tech/)
2. [Missfits: Enshitification](https://us.macmillan.com/books/9780374619329/enshittification/)
3. [Manufacturing Consent](https://en.wikipedia.org/wiki/Manufacturing_Consent) A book more relevant then ever. 
*Quick Call-out: 🔩 you Studien Stiftung Deutschland for discrediting 'Manufactoring Consent' as globally not relevant topic in 2017*