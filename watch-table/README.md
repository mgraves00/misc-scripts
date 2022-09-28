# watchtabled

Simple shell daemon that will watch a specified pftable(s) and if any addresses are added/removed will take appropiate action adding or removing the addresses in bgpd.

## Syntax

```
watchtabled [-dh] [-s sleep_time ] <-t pftable:ASN:LOCAL>...
```

## Arguments

- -d		Do not daemonize
- -h		Syntax help
- -s		Sleep time in seconds (default: 30)
- -t		PF table to watch and the ASN:Local value to add as a community

## Bugs

It is a shell script daemon.

