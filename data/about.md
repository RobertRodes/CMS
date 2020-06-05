# How the Internet Works: Part 5
## The Internet Layer: Routers

Routers are used to send traffic from one network to another. Every local network that is part of the internet has at least one router. There are also routers that are not part of the local network, typically those which handle longer internet trips. The router is responsible for opening (or "de-encapsulating") a packet, looking at a packet's IP address, determining where to send the packet based on its IP address, re-encapsulating the packet using the frame protocol of the destination node (usually some form of Ethernet, but not always), and forwarding the frame. 

Each router has a *routing table*, which is a list of IP addresses that it can send to. When a router receives a packet, it searches its routing table to determine the closest match to the packet's IP address, and forwards it there. To determine the closest match, the router goes from the specific to the general, using this (somewhat simplified) logic:

  1. If the *routing prefix* (see *How Routers Evaluate IP Addresses* below) on a table entry is the same as IP address's, then the destination node is local to that router. Send the packet there.
  2. Otherwise, send the packet to the closest match to the IP address in the routing table. The closest match uses a "longest match wins" principle: the more numbers matching at the beginning of the destination address and the table's address, the closer the match.
  3. If there are no IP addresses in the routing table that even partially match, send the packet to the *default gateway*. This is the IP address of another router, which will repeat this process. Eventually, the packet will find its way to a router that is more directly connected to the node with the destination IP address.

This is somewhat simplified because (among other reasons) the routers that are responsible for long-distance traffic (called *core routers*) don't have local nodes or default gateways. Their routing tables only contain the addresses of other routers, so they work exclusively with step 2.

### How Routers Evaluate IP Addresses

An IP address has two logical parts: the *routing prefix* (the first group), which identifies a network, and the *host identifier* (the second group), which identifies a node on that network. The more bits that are used for the routing prefix, the fewer can be used for individual host identifiers, so the larger the routing prefix, the smaller the network. 

For example, one of the Charter Communications networks has all the numbers from `24.158.0.0` to `24.158.255.255`. So, its routing prefix is `24.158`, and there are 65,534 possible host identifiers. (Of course, two bytes have 65,536 possible values, but the highest and lowest available  addresses are always reserved for the router's IP address and the *broadcast address*, respectively. The broadcast address is used to send to every node on the network, typically for some form of resource discovery.) 

A typical office network uses the first three bytes for the routing prefix, and so has 254 numbers that can be used for host identifiers.

The router uses a *subnet mask* or *netmask* to distinguish the routing prefix from the host identifier. The netmask uses the same format as an ordinary IP address, with bits set to 1 for the routing prefix, and set to 0 for the host identifier. Therefore, in the network in the above example, the subnet mask is `255.255.255.0`. It follows that the logical `AND` of the subnet mask and any IP address on the network will be the routing prefix. It further follows that the logical `AND` of the one's complement (a one's complement of a number is the number with all its bits reversed) of the subnet mask (`0.0.0.255`, in our case) will be the host identifier.

Let's look at an example of how this works. Suppose one of the nodes on a 254-node network has the IP address `169.254.190.93`. The routing prefix would be `169.254.190`, and the host identifier would be `93`. Now, suppose our router receives a packet with the destination address `169.254.190.93`. The router will first apply the subnet mask:

| Decimal | `169` | `254` | `190` | `93` |
| :--- | ---:| ---:| ---:| ---:|
| Binary  | `10101001` | `11111110` | `10111110` | `01011101`
| Netmask | `11111111` | `11111111` | `11111111` | `00000000`
| Binary `AND` Netmask | `10101001` | `11111110` | `10111110` | `00000000`

The bottom line of this table in decimal is `169.254.190.0`, or the router's IP address. So, the router knows that the destination IP address is in its own network, and `AND`s the one's complement of the subnet mask with it: 

Decimal | `169` | `254` | `190` | `93`
:--- |---:|---:|---:|---:
Binary   | `10101001` | `11111110` | `10111110` | `01011101`
One's c. of Netmask | `00000000` | `00000000` | `00000000` | `11111111`
Binary `AND` One's c. | `00000000` | `00000000` | `00000000` | `01011101`

The result in decimal is `0.0.0.93`, or the destination's host identifier. The router then finds the MAC address of the host (there are various ways to do this, depending on the actual network configuration) and sends the packet to it.

The next article will begin our discussion of the transport layer.