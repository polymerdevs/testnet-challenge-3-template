//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import '../libs/Ibc.sol';
import '../interfaces/IbcReceiver.sol';
import '../interfaces/IbcDispatcher.sol';
import '../interfaces/IbcMiddleware.sol';

contract Earth is IbcMwUser, IbcUniversalPacketReceiver {
    struct UcPacketWithChannel {
        bytes32 channelId;
        UniversalPacket packet;
    }

    struct UcAckWithChannel {
        bytes32 channelId;
        UniversalPacket packet;
        AckPacket ack;
    }

    // received packet as chain B
    UcPacketWithChannel[] public recvedPackets;
    // received ack packet as chain A
    UcAckWithChannel[] public ackPackets;
    // received timeout packet as chain A
    UcPacketWithChannel[] public timeoutPackets;

    constructor(address _middleware) IbcMwUser(_middleware) {}

    function greet(address destPortAddr, bytes32 channelId, bytes calldata message, uint64 timeoutTimestamp) external {
        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId,
            IbcUtils.toBytes32(destPortAddr),
            message,
            timeoutTimestamp
        );
    }

    // For testing only; real dApps should implment their own ack logic
    function generateAckPacket(
        bytes32,
        address srcPortAddr,
        bytes calldata appData
    ) external view returns (AckPacket memory ackPacket) {
        return AckPacket(true, abi.encodePacked(this, srcPortAddr, 'ack-', appData));
    }

    function onRecvUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external onlyIbcMw returns (AckPacket memory ackPacket) {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));
        return this.generateAckPacket(channelId, IbcUtils.toAddress(packet.srcPortAddr), packet.appData);
    }

    function onUniversalAcknowledgement(
        bytes32 channelId,
        UniversalPacket memory packet,
        AckPacket calldata ack
    ) external onlyIbcMw {
        // verify packet's destPortAddr is the ack's first encoded address. See generateAckPacket())
        require(ack.data.length >= 20, 'ack data too short');
        address ackSender = address(bytes20(ack.data[0:20]));
        require(IbcUtils.toAddress(packet.destPortAddr) == ackSender, 'ack address mismatch');
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));
    }

    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
    }
}
