# lability-tutorial

Hello, GitHub

This is a tutorial for working with [Lability](https://github.com/VirtualEngine/Lability/).

1. [An introduction to Lability](01-Introduction)
2. [A simple configuration](02-Simple)

## Work in progress / roadmap

Right now, this tutorial is pretty empty.
Ultimately, I hope to cover the following topics:

1.  Simple configuration:
    a single VM, connected to an existing external switch, and using a simple resource to install Firefox.

     -  Discuss the way the creds work (uses just the password, not the username)
     -  Show how to Enter-PSSession to the VM
     -  Discuss troubleshooting methods: WinRM to the VM, reset VM then log in...

2.  NAT network configuration:
    two VMs, one with two NICs acting as a NAT gateway, and one with just one NIC behind the NAT.

     -  Discuss problems related to two NICs and nondeterministic switch assignment order
     -  Discuss double-NAT
     -  Show how to connect to the VMs via PS remoting, including getting to machines behind NAT from a session on the gateway

3.  AD domain behind NAT network
    three VMs: a domain controller, a NAT gateway, and a Windows 10 client

Other items on my mind:

1.  In the Windows 10 Fall Creators Update (Windows 10 build 1709), Hyper-V started shipping with a default NAT network.
    That will make configuration easier, but my work machine doesn't have 1709 yet, so I can't test with it.
