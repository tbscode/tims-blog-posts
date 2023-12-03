---
title: "Understanding Solid Authentication"
description: "Exploring the workings of OpenID Connect, the Solid Community Server implementation, and reverse-engineering client authentication with Python requests."
date: "2023-12-05T16:56:47+06:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["Programming", "Reverse Engineering"]
tags: ["Solid", "Kubernetes"]
---

# Solid Authentication Overview

> A presentation prepared for the
> 'Data Ecosystems Lab'

## Content

This blog article delves into several key aspects of Solid authentication and OpenID Connect, providing insights into the mechanisms and practical implementation details:

- **Introduction to Solid and OpenID Connect**: An overview of the Solid framework and how OpenID Connect (OIDC) serves as a foundational technology for secure authentication.
- **The Solid Community Server's Authentication Process**: A closer look at how the Solid Community Server implements OIDC and the intricacies involved in user verification.
- **Reverse Engineering Authentication with Python**: Step-by-step guidance on how to reverse engineer client authentication processes using the Python `requests` library.
- **Jupyter Notebook Demonstration**: A practical example showcasing the authentication flow within a Jupyter notebook, accessible for interactive learning and experimentation.
- **Flow Charts and Visual Aids**: The inclusion of original and comprehensive flow charts to visualize the authentication sequence as defined by the Solid project.

> If you want to deploy solid on a self hosted kubernetes cluster [checkout this blog post](todo)

## Presentation Slides

<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vR9IbBdC5t9iGfPpiIm6voYEIJvfLBghO4rQoI1J57_cqfim40nndh1kjCajXyoTt77bQVvMgLaLkDJ/embed?start=false&loop=true&delayms=5000" frameborder="0" width="960" height="569" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>

## Flow Chart

- To view the original flow chart as published by the Solid project, please visit this link: [Solid OIDC Flow Chart](https://solidproject.org/TR/oidc)
- For a full-size preview of the flow chart, click here: [Full Size Flow Chart Preview](https://viewer.diagrams.net/?tags=%7B%7D&target=blank&highlight=0000ff&edit=_blank&layers=1&nav=1&title=diagramm.xml#R7V1bc5s6Hv8s%2B%2BCZPQ9muIMfEyduu3POnJwmnc4%2BdTDItrbYooBz6adfCYQBIQw4gLFDHxpbSCDD73%2B%2FMFHm29dPvuVt%2FkIOcCey6LxOlLuJLEu6PsN%2FyMhbPKLOxHhg7UOHTkoHHuFvQAeTaXvogCA3MUTIDaGXH7TRbgfsMDdm%2BT56yU9bITd%2FVc9ag8LAo225xdHv0Ak38aipien4ZwDXm%2BTKkkiPbK1kMh0INpaDXjJDyv1EmfsIhfGn7escuOTmJfclXrcoOXrYmA92YZ0F1l8z%2F%2B1ZeX02ZO8Xev3n7uvn%2Byk9y7Pl7ukPnsi6i893u0L4tPiGWXZ8QP%2B1Jzu9naPtCvmhZaVD5PFaoTUlS6aBb%2Bfmb8KQPKobsjF5QaYEwhqhtQssDwaCjbZ42A7wlMXK2kKX4IR7DX1N%2Fn4LgJ9skZ4vOURvc%2FiWPDt8xz3ycb91%2F4Qr4MId%2FnbrAR9uQYhPo9y5dPghHbt92cAQPHrx737BqI5%2BxNbF3yT8EQMttPASslzE3x0feU%2BWvwYhHbCR61peAJfRNsiID%2By9H8Bn8BUEMcDJKNqH5NLzA3DJoId%2FNh4JQh9fgwwCKwhfQEB%2B3w683DsYnMkPNG7T2wMOB9I7Ru754bi7RJnVmds6ZyaVnOAZ%2BCHEZFGyFP%2FAZ%2BDk1oq5CT7a75zCDOMucyi%2Bv0VYJxjFOwCvmSEK808A4Ufnv%2BEp9KhKKe4t%2F%2FUlpd8DlW4ytGsmlGpRnrE%2BnDklK%2FyBUlYDKpM5VMZgNYMwD%2BFHH21Bu51odwxkMUA2aI12lpsFLRdMYQTLR0IFQZEMPiDSitg6yhTrA07LAc7gAa6IN0PtCm9aFVfvgV3XlBwx674lgnpk7FdGbq0zdmkmC9KskrmroqArRXrTZ1pH9GZcGr3hR0CoTfwOll%2BculSXoZUENDcuXO%2Fw2BKFId4pObFzQ7RuMuYi%2B2cOwRj0ebQmyFTuDig8II5S2AFC4jEIBWjv019%2FVAKHCT2XzdPjeWTPRwHpA9cKMeHn7Q0OrujSByLTs0DOSwxJYURB%2FIPoqhSd%2BN5ab5lpVFUov46eV4UklbERmPms6iRpufn4Q7wDZnWyHbRaBSCcsOR0uG%2BnU5jZSIOqA0%2FkgR3h8lawObAofJhaoOYZgLsH2uPdI%2Fpn%2BriczuGta6w%2BoeSHdw1IWWcAqTOAjCnn3YBUWEDqtQCW6FlyxS5LyOYEFB57GJfD5yl%2FFx989AydVMFa%2BsmMmz0Wm7L4CDB2OYexYhMjtHzKqLRdsdJG75B2lIk1MJRUQ8iTsMbR3xSesTRrwVjiEvWskWgZjfOugLeCrjtHLvKje64AydGAQSAY%2BugnyByZ6YZi6VxAHuXatVHKyiixnj1%2FGHwPRIONjR%2F0T3wX54unV%2Fe7uPu8n0rKiNFBYLQnxOk8rshBXBsOpJ37v7WyeX38NtP%2Bewe%2B%2Ff72%2FIIBp46AGxDgCkCqi8G6gDP0%2FgDH3a3Ec5EPWrX2wa89wd7BiSLeIXu%2FBZEGfPX%2BFOonyfpTjilXvZuvWjf%2BFEU7yT9SZr6yuywxsjtytPAJ8eJ8mSkh%2Fv1ljpeQVIAVXJ9uqI502R5dGnl6kbuiS8ZvKVf4ORVN4%2B6rJh2zVxsiHVf6quyDRZVSlCJG%2F3K0mFJGMhgTf%2BQZwLQuSqL3GpNXUwLuL23k0%2F3ThIT3Fw7YoqmHsLxeeD7CNicg57F8PKBsQVNfFiZRy3WBi9a%2BtWXU3tyxBi6tFXwFiRtaKtrFK9MGts2zi5emprblqJFnfEGXVRBlXhJFGzYwF9ByZVD7JKAOTZqlIwg69pcg2Ec%2B13TW0PGpq4Zucv02iqQqmkofSxbR0b%2BWcCsyuJ1xDBu5V9xeoEK1hkEcH567MGPQjKrUgFQppaOQscIkMyXXOc3EKexyAKqR%2FGGDybMipM%2BZBcF6oRTWvdRW0JnR9hW1EaQV%2Fuq%2Bgs4JBY2afCRjHv5%2BpKq8gKBN9Hgsry5AL%2BpHb1fkEimR038OQdheNCCFF706ocggfqbBhvjhRfx44G5C6ze60UZ2KAo7tMi5A8zQQlbZiQYX0E22hndAvw0r5Y0iTBREkW7hvUlwjK6usCH%2BtpLgGJpQxePOIcnQuPuqJy5kreJXDUADUs7rHBqawRMgFzrTDbDccDO1PE8IMFOwXPwRCg54vgDh4ljAXHGFi26bYNmScS3pusDo9zzz2uxZvPASeD4umPNXjaCtFQC9uABM96MwqZIpGIPDtFpZl9kapmfDh3RTP%2B95flIL5JdYNFaUlIsBtLAjB9yPCCyCIIxke9DpJFYUqRxTR571TLeVps6HkkUXEqChxHeEvC4%2FbOhowHRUHlma8lLR%2Bem09ckyCbdIA5CdvNzFk2jwFKgHnrU7EerxicKtN90H%2FjQSHRNV3FrQFUJpK2zJyicQhJKs%2FCuDuPiKp9ViXB8Q6dGppLBqncoLYWem9QJOjefMbcVN1U%2FsIefBolGPrANLnNR2YHVeY8m4l1RVFQzmLC0FGCRTLrtUTaeRLjN1Mbzddhxo0JpVwlxOXKz7OBZb1VQ3I6x5cFbhXqceyjSGIupm47UWeG0tkjUcRfcUa5RJSRNe8L2b%2FtyhFyzHF4RkoDONk1j3PsYl2l2AWO8pLc0siHVeB4jOMtO4xTJyFaovCa1mCVrjvlukkJgYP5hF5XtHNE8NyteZVoCvBCccNJVHRgu%2Ba1Mr2iol%2BmAbnaG42Kn0F1wRdu5J0xGCnD9p7HbuAye4ZASpvE5PHULoWPx2LNUbRKne%2B8SbxiqSksxhUrzaY6Mzd8pYH3%2FF%2BFLVeviSOqttH%2BF1xfDSeLFUHvvqrLBYHcXj1eBLEwvsy6yHL6kN7YuPr8ryjiZRBAyIXbCFZFmS4EgMgLoa8SnlFk8buJt05yOm3ulyH%2FHR1pCVxRdqb6nqBejNNEHM%2FtPz52yrHIMpxFNp58Cauet6s00PIDdRO28IfWjp7ngydDz8P%2BUHY%2BZWWupXJEmeNOg1vFcZe%2B4yplzmfyE9%2FvB9xpw7JI38si30uV6XUyLKJzhj3pe3x1TlaLwmXVqvz36suOcyriiS4W9H1pVhXVJeqGtyj4yL32GukZU0hn5TvbAQkNKUmWDU06tOaD905Gp1g8C1dtx1rkFlN4dzCMqvh1ZC85hp0eiruEAkgJFUw4s3tg2C45GLi5ChMosDDhsyuNl7bdjTXEYkt4mLg%2Bj5oOZztkaQe7eprTUgM7vInGr2%2BG7MS02TdVY26kXO46M1m6Z3ZE4fe8KjUlpQSu2Il49KaalSym1C26dSOkgd4csOhtBy8TwHz3rCz4Oc7itwoE%2B8%2FxevE2iFwhpN58QIZblXtaBZFOdy7JPKli29SV6mvZBWs2y9uQljcK9TU%2BiyPKpmy4C2pGl5sMeBz7U5zdKyf64jgEyp9CUMB8aMJZaImXF%2Fvfx3HGUTkz9%2FUOlKOFYi9m4iqyVhf%2BnxGiUnE%2B1WERUS7kz6qjj2JK1ClNWJcUsLEX3K537sfUjieseZG5cL5u7URxOykpa%2BmyzBsFFkr9lcs378P63aXWlLXotaymIYC8oPaoh1bzfNhKSpR9LSncVKS3aTqkqCyb9Uebfd4hKlYolUXMK%2B35hdIjffmGFWXKVaHrHkXLjvAzACpUpN%2BkNZgbkWYpGoa8Sdrl9ImWxk1eBF19SOBBQ3Ub48sOpxYUkyrabJziJ7Du9M46s%2F5zcqfXyPIHgm0dmJToXmjxiUxKckWjsnfoJw9RbPwYIoBPFBGMnXDVkcWKQYndx9WVwCvOtsaXot8%2FMw7LVpkr4r774IR51XZs4L9nZmj5bHeiP1tg4go%2FrUWog8peFJTZ5bk%2B8fvGdxFoqysJETn57YBsRQmEYjkUVgbQkG4v9jmCYTo2%2FTDTa587YDD4KXZDv01H5LVgU9r63oHL4sGxr39cfd2Q7nbVA6nAqpsZvcO7vJcdPFe24fIvNSIc6uIHxxSAIXEf6Uve6WAflzCEl%2FjZq2J%2BXC4v3O8WLz4qK8z5KZB4TMK7DrStDz36NSaToNh%2F%2B0Aa%2FkJUqHN0%2F0V5zZKnIkLnJ4pSddWSzlfOQaLBbPB%2BR54Rk%2BNk4IkolVQpTAH%2FaGCKXdGmRtl4zJIuCvT5sobLbcQ5ccTYod9r77%2FgjaIE0YpqUwL7bK42vs6xPaE3NjpzqGLJISpowg%2FQFSMZouGNW3mMEW1Ddu51S9M%2FWNy3V5geJr5LqYj5K0fuTD37HOF%2FHaWyuAdpbn3j2gh%2FjQZ2A5UfuFi2em7DuedJ6oVyRuAK0zaX9Bb3k6HX6PwI1yXMRF1ABTXEVpsXvPRZbTq6r4PvwQxpUtglNzcDI4DYV67wtzFa8oYqKetZ5R63WaBvuMWktkUUuuVDd%2FVKvaaXvJLFyMVfbNbyLhPB9tvWhRzBqCiFVkepd1%2FvK4Ab2upRr4%2BZzr8sYYpUysvdewzBgUJoV1bb%2BFRSrQi5IrZS6u0GcFCmlS%2FFxsR2Gc9210fDfBB%2B0IewbhwCKd7ZnUVjdYw%2BBe52TUsvvsWC5I1%2B25sn0Q10F7%2B6WbsZY8Hz7HB%2F7znaSH%2FARv12gs8bTbvo2lI9mG14CwKis9Msqv3khXCxmJvGY9vUOv1ZcRPnx7SlXexA4WD%2BmvHyHb9SxGXiHb1axpO7WQ7WpW5aEWs11NtWJJMdvVrEqQLWa7Vm6smO1qNnq5MyfbtXDfh6BR80K2o%2FOkDl2pbEmrWdNiau49kcouVdd9IlfutWs9uTzWcIIoYYWIQ1jw6DtponO06BNhfRV1sXWCV6QR25f02TGe39i2rEvfvfLvy46lVJok1QFzuaxQL%2BEHyQDtrP7Z8rwoLxxP0e7%2FyDCJZSXjuKioTR67vCSK9gI1%2BKuPyO1PsY1%2F1%2BYv5AAy4%2F8%3D)

<iframe frameborder="0" style="width:100%;height:833px;" src="https://viewer.diagrams.net/?tags=%7B%7D&highlight=0000ff&edit=_blank&layers=1&nav=1&title=diagramm.xml#R7V1bc5s6Hv8s%2B%2BCZPQ9muIMfEyduu3POnJwmnc4%2BdTDItrbYooBz6adfCYQBIQw4gLFDHxpbSCDD73%2B%2FMFHm29dPvuVt%2FkIOcCey6LxOlLuJLEu6PsN%2FyMhbPKLOxHhg7UOHTkoHHuFvQAeTaXvogCA3MUTIDaGXH7TRbgfsMDdm%2BT56yU9bITd%2FVc9ag8LAo225xdHv0Ak38aipien4ZwDXm%2BTKkkiPbK1kMh0INpaDXjJDyv1EmfsIhfGn7escuOTmJfclXrcoOXrYmA92YZ0F1l8z%2F%2B1ZeX02ZO8Xev3n7uvn%2Byk9y7Pl7ukPnsi6i893u0L4tPiGWXZ8QP%2B1Jzu9naPtCvmhZaVD5PFaoTUlS6aBb%2Bfmb8KQPKobsjF5QaYEwhqhtQssDwaCjbZ42A7wlMXK2kKX4IR7DX1N%2Fn4LgJ9skZ4vOURvc%2FiWPDt8xz3ycb91%2F4Qr4MId%2FnbrAR9uQYhPo9y5dPghHbt92cAQPHrx737BqI5%2BxNbF3yT8EQMttPASslzE3x0feU%2BWvwYhHbCR61peAJfRNsiID%2By9H8Bn8BUEMcDJKNqH5NLzA3DJoId%2FNh4JQh9fgwwCKwhfQEB%2B3w683DsYnMkPNG7T2wMOB9I7Ru754bi7RJnVmds6ZyaVnOAZ%2BCHEZFGyFP%2FAZ%2BDk1oq5CT7a75zCDOMucyi%2Bv0VYJxjFOwCvmSEK808A4Ufnv%2BEp9KhKKe4t%2F%2FUlpd8DlW4ytGsmlGpRnrE%2BnDklK%2FyBUlYDKpM5VMZgNYMwD%2BFHH21Bu51odwxkMUA2aI12lpsFLRdMYQTLR0IFQZEMPiDSitg6yhTrA07LAc7gAa6IN0PtCm9aFVfvgV3XlBwx674lgnpk7FdGbq0zdmkmC9KskrmroqArRXrTZ1pH9GZcGr3hR0CoTfwOll%2BculSXoZUENDcuXO%2Fw2BKFId4pObFzQ7RuMuYi%2B2cOwRj0ebQmyFTuDig8II5S2AFC4jEIBWjv019%2FVAKHCT2XzdPjeWTPRwHpA9cKMeHn7Q0OrujSByLTs0DOSwxJYURB%2FIPoqhSd%2BN5ab5lpVFUov46eV4UklbERmPms6iRpufn4Q7wDZnWyHbRaBSCcsOR0uG%2BnU5jZSIOqA0%2FkgR3h8lawObAofJhaoOYZgLsH2uPdI%2Fpn%2BriczuGta6w%2BoeSHdw1IWWcAqTOAjCnn3YBUWEDqtQCW6FlyxS5LyOYEFB57GJfD5yl%2FFx989AydVMFa%2BsmMmz0Wm7L4CDB2OYexYhMjtHzKqLRdsdJG75B2lIk1MJRUQ8iTsMbR3xSesTRrwVjiEvWskWgZjfOugLeCrjtHLvKje64AydGAQSAY%2BugnyByZ6YZi6VxAHuXatVHKyiixnj1%2FGHwPRIONjR%2F0T3wX54unV%2Fe7uPu8n0rKiNFBYLQnxOk8rshBXBsOpJ37v7WyeX38NtP%2Bewe%2B%2Ff72%2FIIBp46AGxDgCkCqi8G6gDP0%2FgDH3a3Ec5EPWrX2wa89wd7BiSLeIXu%2FBZEGfPX%2BFOonyfpTjilXvZuvWjf%2BFEU7yT9SZr6yuywxsjtytPAJ8eJ8mSkh%2Fv1ljpeQVIAVXJ9uqI502R5dGnl6kbuiS8ZvKVf4ORVN4%2B6rJh2zVxsiHVf6quyDRZVSlCJG%2F3K0mFJGMhgTf%2BQZwLQuSqL3GpNXUwLuL23k0%2F3ThIT3Fw7YoqmHsLxeeD7CNicg57F8PKBsQVNfFiZRy3WBi9a%2BtWXU3tyxBi6tFXwFiRtaKtrFK9MGts2zi5emprblqJFnfEGXVRBlXhJFGzYwF9ByZVD7JKAOTZqlIwg69pcg2Ec%2B13TW0PGpq4Zucv02iqQqmkofSxbR0b%2BWcCsyuJ1xDBu5V9xeoEK1hkEcH567MGPQjKrUgFQppaOQscIkMyXXOc3EKexyAKqR%2FGGDybMipM%2BZBcF6oRTWvdRW0JnR9hW1EaQV%2Fuq%2Bgs4JBY2afCRjHv5%2BpKq8gKBN9Hgsry5AL%2BpHb1fkEimR038OQdheNCCFF706ocggfqbBhvjhRfx44G5C6ze60UZ2KAo7tMi5A8zQQlbZiQYX0E22hndAvw0r5Y0iTBREkW7hvUlwjK6usCH%2BtpLgGJpQxePOIcnQuPuqJy5kreJXDUADUs7rHBqawRMgFzrTDbDccDO1PE8IMFOwXPwRCg54vgDh4ljAXHGFi26bYNmScS3pusDo9zzz2uxZvPASeD4umPNXjaCtFQC9uABM96MwqZIpGIPDtFpZl9kapmfDh3RTP%2B95flIL5JdYNFaUlIsBtLAjB9yPCCyCIIxke9DpJFYUqRxTR571TLeVps6HkkUXEqChxHeEvC4%2FbOhowHRUHlma8lLR%2Bem09ckyCbdIA5CdvNzFk2jwFKgHnrU7EerxicKtN90H%2FjQSHRNV3FrQFUJpK2zJyicQhJKs%2FCuDuPiKp9ViXB8Q6dGppLBqncoLYWem9QJOjefMbcVN1U%2FsIefBolGPrANLnNR2YHVeY8m4l1RVFQzmLC0FGCRTLrtUTaeRLjN1Mbzddhxo0JpVwlxOXKz7OBZb1VQ3I6x5cFbhXqceyjSGIupm47UWeG0tkjUcRfcUa5RJSRNe8L2b%2FtyhFyzHF4RkoDONk1j3PsYl2l2AWO8pLc0siHVeB4jOMtO4xTJyFaovCa1mCVrjvlukkJgYP5hF5XtHNE8NyteZVoCvBCccNJVHRgu%2Ba1Mr2iol%2BmAbnaG42Kn0F1wRdu5J0xGCnD9p7HbuAye4ZASpvE5PHULoWPx2LNUbRKne%2B8SbxiqSksxhUrzaY6Mzd8pYH3%2FF%2BFLVeviSOqttH%2BF1xfDSeLFUHvvqrLBYHcXj1eBLEwvsy6yHL6kN7YuPr8ryjiZRBAyIXbCFZFmS4EgMgLoa8SnlFk8buJt05yOm3ulyH%2FHR1pCVxRdqb6nqBejNNEHM%2FtPz52yrHIMpxFNp58Cauet6s00PIDdRO28IfWjp7ngydDz8P%2BUHY%2BZWWupXJEmeNOg1vFcZe%2B4yplzmfyE9%2FvB9xpw7JI38si30uV6XUyLKJzhj3pe3x1TlaLwmXVqvz36suOcyriiS4W9H1pVhXVJeqGtyj4yL32GukZU0hn5TvbAQkNKUmWDU06tOaD905Gp1g8C1dtx1rkFlN4dzCMqvh1ZC85hp0eiruEAkgJFUw4s3tg2C45GLi5ChMosDDhsyuNl7bdjTXEYkt4mLg%2Bj5oOZztkaQe7eprTUgM7vInGr2%2BG7MS02TdVY26kXO46M1m6Z3ZE4fe8KjUlpQSu2Il49KaalSym1C26dSOkgd4csOhtBy8TwHz3rCz4Oc7itwoE%2B8%2FxevE2iFwhpN58QIZblXtaBZFOdy7JPKli29SV6mvZBWs2y9uQljcK9TU%2BiyPKpmy4C2pGl5sMeBz7U5zdKyf64jgEyp9CUMB8aMJZaImXF%2Fvfx3HGUTkz9%2FUOlKOFYi9m4iqyVhf%2BnxGiUnE%2B1WERUS7kz6qjj2JK1ClNWJcUsLEX3K537sfUjieseZG5cL5u7URxOykpa%2BmyzBsFFkr9lcs378P63aXWlLXotaymIYC8oPaoh1bzfNhKSpR9LSncVKS3aTqkqCyb9Uebfd4hKlYolUXMK%2B35hdIjffmGFWXKVaHrHkXLjvAzACpUpN%2BkNZgbkWYpGoa8Sdrl9ImWxk1eBF19SOBBQ3Ub48sOpxYUkyrabJziJ7Du9M46s%2F5zcqfXyPIHgm0dmJToXmjxiUxKckWjsnfoJw9RbPwYIoBPFBGMnXDVkcWKQYndx9WVwCvOtsaXot8%2FMw7LVpkr4r774IR51XZs4L9nZmj5bHeiP1tg4go%2FrUWog8peFJTZ5bk%2B8fvGdxFoqysJETn57YBsRQmEYjkUVgbQkG4v9jmCYTo2%2FTDTa587YDD4KXZDv01H5LVgU9r63oHL4sGxr39cfd2Q7nbVA6nAqpsZvcO7vJcdPFe24fIvNSIc6uIHxxSAIXEf6Uve6WAflzCEl%2FjZq2J%2BXC4v3O8WLz4qK8z5KZB4TMK7DrStDz36NSaToNh%2F%2B0Aa%2FkJUqHN0%2F0V5zZKnIkLnJ4pSddWSzlfOQaLBbPB%2BR54Rk%2BNk4IkolVQpTAH%2FaGCKXdGmRtl4zJIuCvT5sobLbcQ5ccTYod9r77%2FgjaIE0YpqUwL7bK42vs6xPaE3NjpzqGLJISpowg%2FQFSMZouGNW3mMEW1Ddu51S9M%2FWNy3V5geJr5LqYj5K0fuTD37HOF%2FHaWyuAdpbn3j2gh%2FjQZ2A5UfuFi2em7DuedJ6oVyRuAK0zaX9Bb3k6HX6PwI1yXMRF1ABTXEVpsXvPRZbTq6r4PvwQxpUtglNzcDI4DYV67wtzFa8oYqKetZ5R63WaBvuMWktkUUuuVDd%2FVKvaaXvJLFyMVfbNbyLhPB9tvWhRzBqCiFVkepd1%2FvK4Ab2upRr4%2BZzr8sYYpUysvdewzBgUJoV1bb%2BFRSrQi5IrZS6u0GcFCmlS%2FFxsR2Gc9210fDfBB%2B0IewbhwCKd7ZnUVjdYw%2BBe52TUsvvsWC5I1%2B25sn0Q10F7%2B6WbsZY8Hz7HB%2F7znaSH%2FARv12gs8bTbvo2lI9mG14CwKis9Msqv3khXCxmJvGY9vUOv1ZcRPnx7SlXexA4WD%2BmvHyHb9SxGXiHb1axpO7WQ7WpW5aEWs11NtWJJMdvVrEqQLWa7Vm6smO1qNnq5MyfbtXDfh6BR80K2o%2FOkDl2pbEmrWdNiau49kcouVdd9IlfutWs9uTzWcIIoYYWIQ1jw6DtponO06BNhfRV1sXWCV6QR25f02TGe39i2rEvfvfLvy46lVJok1QFzuaxQL%2BEHyQDtrP7Z8rwoLxxP0e7%2FyDCJZSXjuKioTR67vCSK9gI1%2BKuPyO1PsY1%2F1%2BYv5AAy4%2F8%3D"></iframe>


## Jupyter Notebook

- For a hands-on demonstration of the reverse-engineered authentication using the Python `requests` library, access the Jupyter Notebook here: [Presentation: Reverse-Engineered Authentication Notebook](https://colab.research.google.com/drive/17H9eaPhxgqb4yonFpfEle39pQjWghL_o?usp=sharing)


<link rel="stylesheet" href="https://github.githubassets.com/assets/gist-embed-f65f23c5975e.css">
<div id="gist126680771" class="gist">
    <div class="gist-file" translate="no">
      <div class="gist-data">
        <div class="js-gist-file-update-container js-task-list-container file-box">
          <div id="file-copy-of-reverseengineeredsolidauthenticationbytimschupp-ipynb" class="file my-2">
            <div itemprop="text" class="Box-body p-0 blob-wrapper data type-jupyter-notebook">
              <div class="render-wrapper">
                <div class="render-container is-render-pending js-render-target"
                     data-identity="b896a2c7-130f-40d6-9e79-f19c42218f0a"
                     data-host="https://notebooks.githubusercontent.com"
                     data-type="ipynb">
                  <svg style="box-sizing: content-box; color: var(--color-icon-primary);" width="64" height="64" viewBox="0 0 16 16" fill="none" data-view-component="true" class="octospinner mx-auto anim-rotate">
                    <circle cx="8" cy="8" r="7" stroke="currentColor" stroke-opacity="0.25" stroke-width="2" vector-effect="non-scaling-stroke" fill="none"></circle>
                    <path d="M15 8a7.002 7.002 0 00-7-7" stroke="currentColor" stroke-width="2" stroke-linecap="round" vector-effect="non-scaling-stroke"></path>
                  </svg>
                  <div class="render-viewer-error">Sorry, something went wrong. <a class="Link--inTextBlock" href="https://gist.github.com/user-1024/00f76dfe47a63659de070d449c9946f9.js">Reload?</a></div>
                  <div class="render-viewer-fatal">Sorry, we cannot display this file.</div>
                  <div class="render-viewer-invalid">Sorry, this file is invalid so it cannot be displayed.</div>
                  <iframe class="render-viewer"
                          src="https://notebooks.githubusercontent.com/view/ipynb?bypass_fastly=true&amp;color_mode=auto&amp;commit=db9efc58d843777a23609c871a7478f9a282b6c4&amp;docs_host=https%3A%2F%2Fdocs.github.com&amp;enc_url=68747470733a2f2f7261772e67697468756275736572636f6e74656e742e636f6d2f676973742f757365722d313032342f30306637366466653437613633363539646530373064343439633939343666392f7261772f646239656663353864383433373737613233363039633837316137343738663961323832623663342f636f70792d6f662d72657665727365656e67696e6565726564736f6c696461757468656e7469636174696f6e627974696d7363687570702e6970796e62&amp;logged_in=false&amp;nwo=user-1024%2F00f76dfe47a63659de070d449c9946f9&amp;path=copy-of-reverseengineeredsolidauthenticationbytimschupp.ipynb&amp;repository_id=126680771&amp;repository_type=Gist#b896a2c7-130f-40d6-9e79-f19c42218f0a"
                          sandbox="allow-scripts allow-same-origin allow-top-navigation"
                          title="File display"
                          name="b896a2c7-130f-40d6-9e79-f19c42218f0a">
                    Viewer requires iframe.
                  </iframe>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="gist-meta">
          <a href="https://gist.github.com/user-1024/00f76dfe47a63659de070d449c9946f9/raw/db9efc58d843777a23609c871a7478f9a282b6c4/copy-of-reverseengineeredsolidauthenticationbytimschupp.ipynb" style="float:right" class="Link--inTextBlock">view raw</a>
          <a href="https://gist.github.com/user-1024/00f76dfe47a63659de070d449c9946f9#file-copy-of-reverseengineeredsolidauthenticationbytimschupp-ipynb" class="Link--inTextBlock">
            copy-of-reverseengineeredsolidauthenticationbytimschupp.ipynb
          </a>
          hosted with ❤ by <a class="Link--inTextBlock" href="https://github.com">GitHub</a>
        </div>
      </div>
    </div>
</div>