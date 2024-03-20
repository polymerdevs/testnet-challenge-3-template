# Universal Channel and IBC Middleware 

## Overview

[IBC Middleware](https://github.com/cosmos/ibc/tree/main/spec/app/ics-030-middleware) (MW) is an integral part of the IBC protocol. IBC Middleware will enable arbitrary extensions to an application's functionality without requiring changes to the application or core IBC.

https://github.com/cosmos/ibc/tree/main/spec/app/ics-030-middleware


## Universal Channel

The Universal Channel (UC) is designed to simplify the process of sending and receiving IBC packets for dApp users. Without the UC, dApp users would need to perform a channel handshake every time they want to establish a new IBC connection. This can be a complex and error-prone process, especially for users who are not familiar with the intricacies of the IBC protocol.

The UC abstracts away these complexities by providing a single, universal channel between *two chains* that all dApps can use to send and receive IBC packets. The UC handles the channel handshake and IBC core authentication, so dApp users do not need to worry about it. See caveat below. 

You can see the implementation of the Universal Channel in the [UniversalChannelHandler.sol](../contracts/UniversalChannelHandler.sol) contract.

### IBC packets vs. Universal Packets

For regular IBC packets, both packet sender and receiver with unique IBC ports are the exclusive owners of the channel, with two channel ends on each chain, respectively.

For Universal Packets, packet sender and receiver still have unique IBC ports for packet routing, but they do not own the channel. Instead, the Universal Channel Middleware contract owns the channel, and it is responsible for handling the channel handshake and authentication.
One sender can send universal packets over the same universal channel to multiple receivers, and one receiver contract can receive universal packets from multiple senders over the same universal channel too. 

On the sender side, a universal packet is packed into a regular IBC packet and sent over the universal channel. 

On the receiver side, The Universal Channel Middleware contract unpacks the regular IBC packet, extracts the universal packet, and passes it to the next Middleware, if any, in the middleware stack, until it reaches the final destination specified in `UniversalPacket.destPortAddress` field.

### How Universal Channel Middleware Works

The Universal Channel Middleware works by packing and unpacking a UniversalPacket into a regular IBC packet's data field. This allows the Middleware to handle the contents of the packet in a generic way, without needing to know the specifics of the packet's format.

The Universal Channel Middleware is defined in the [UniversalChannelHandler.sol](../contracts/UniversalChannelHandler.sol) contract, and it implements the `IbcUniversalChannelMW` interface defined in [IbcMiddleware.sol](../contracts/IbcMiddleware.sol).

### Using Universal Channel to Send and Receive Packets 

As a dApp user, you can use either UC or another MW stack on top of UC to send and receive IBC packets.

### Sending Universal Packets

To send a packet, you need to call the sendUniversalPacket function of the UC. This function takes four arguments:

- `channelId`: The ID of the channel you want to send the packet over.
- `destPortAddr`: The address of the destination port.
- `appData`: The data payload specific to your dApps.
- `timeoutTimestamp`: The timestamp in nanoseconds at which the packet should timeout on destination chain.

Here's a simplified example of how to send a packet:
```solidity
// first, get the Universal Channel Handler contract instance
IbcUniversalPacketSender uc = IbcUniversalPacketSender(0x1234567890...);
// get `channelId` from Polymer registry that represents a unidirectional path from the running chain to a destination chain, from the running's perspective
uc.sendUniversalPacket(channelId, destPortAddr, appData, timeoutTimestamp);
```

### Receiving Packets, Acks, and Timeouts

To be able to receive a packet, you need to implement the [`IbcUniversalPacketReceiver`](../contracts/IbcMiddleware.sol) interface in your contract. This function is called by the UC when a packet is received. 

Here's a simplified example of how to receive a packet:
```solidity
// Implement the IbcUniversalPacketReceiver interface in your contract
contract MyContract is IbcUniversalPacketReceiver {
    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata ucPacket)
        external
        onlyIbcMw
        override
    {
        // use channelId to identify which chain the packet came from
        // Handle the received packet
        ...
    }
    // similar callbacks for acks and timeouts
}
```

You can also check out the [Earth contract](../contracts/Earth.sol) for a more complete example of how to use the Universal Channel or a MW stack to send and receive packets.

## Creating a Middleware Stack

A Middleware stack is a sequence of Middleware contracts that a packet passes through in order. Each Middleware in the stack can inspect and potentially modify the packet before passing it on to the next Middleware.

To create a Middleware stack, you need to register the Middleware contracts with the Universal Channel Middleware. This is done using the registerMwStack function in the [UniversalChannelHandler.sol](../contracts/UniversalChannelHandler.sol) contract. The Middleware contracts are identified by a bitmap and an array of addresses.

Check out tests in [Universal channel and MW tests](../test/universal.channel.t.sol) for full examples of how to register a Middleware stack.

## Limitation and Future Work

Currently, the Universal Channel Middleware requires the Middleware contracts to be registered with their MW stack contracts' addresses. 

In the future, Polymer will provide a global registry of Middleware stacks, which maps MW stack ID to a list of MW contract addresses on Polymer chain. 

### Caveats

When using the Universal Channel and Middleware, it's important to be aware of the following caveats:

- The Middleware contracts MUST be trusted, otherwise they should never be used. They have the ability to inspect and modify the packets, so they should be carefully audited to ensure they do not introduce any security vulnerabilities.
- The order of Middleware contracts in the stack matters. Each Middleware contract passes the packet to the next Middleware in the stack, so the order in which they are registered will determine the order in which they process the packet.

