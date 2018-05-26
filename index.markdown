# lability-tutorial

Hello, GitHub 👨‍💻

This is a tutorial for working with [Lability](https://github.com/VirtualEngine/Lability/).

I recently found Lability and really came to like it.
However, unfortunately its documentation is a bit sparse.
I am writing this tutorial to help people get started with this dope module for building Hyper-V test labs.
I hope it's useful.
❤

This tutorial not yet complete -
below you can find a table of contents / to do list.
Where a chapter has been started (not necessarily completed!),
there will be a link to the chapter;
where a chapter has not yet been started,
there will be a list of things to cover.

**Feedback and pull requests are welcome!**
Open issues or submit PRs [on Github](https://github.com/mrled/lability-tutorial).

1. [An introduction to Lability](01-Introduction)

2. [A simple configuration](02-Simple)

3.  Debugging VMs that won't come up:
    the previous single VM lab, but with a faulty DSC configuration
    that prevents the machine from ever presenting the logon screen.

     -  Logging in via Powershell remoting if possible
     -  Resetting the VMs so you can log on and see what went wrong
     -  DSC logs in Event Viewer
     -  Lability logs in C:\Bootstrap
     -  Deleting existing VHDs before redeploying a lab when troubleshooting
     -  Filtering the error list

4.  Expanding our simple VM example

     -  Types of switches and what happens if the switch doesn't already exist
     -  Lab prefixes
     -  Custom resources (install Firefox)
     -  DSC modules, version specifiers, and what happens if DSC modules are not defined in the config data

5.  NAT network configuration:
    two VMs, one with two NICs acting as a NAT gateway, and one with just one NIC behind the NAT.

     -  Discuss problems related to two NICs and nondeterministic switch assignment order
     -  Discuss double-NAT
     -  Show how to connect to the VMs behind NAT via PS remoting if the gateway is up

6.  AD domain behind NAT network
    three VMs: a domain controller, a NAT gateway, and a Windows 10 client

Other items on my mind:

1.  In the Windows 10 Fall Creators Update (Windows 10 build 1709), Hyper-V started shipping with a default NAT network.
    That will make configuration easier, but my work machine doesn't have 1709 yet, so I can't test with it.
