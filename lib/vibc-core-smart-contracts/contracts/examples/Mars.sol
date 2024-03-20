//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import '../libs/Ibc.sol';
import '../interfaces/IbcReceiver.sol';
import '../interfaces/IbcDispatcher.sol';

contract Mars is IbcReceiverBase, IbcReceiver {
    // received packet as chain B
    IbcPacket[] public recvedPackets;
    // received ack packet as chain A
    AckPacket[] public ackPackets;
    // received timeout packet as chain A
    IbcPacket[] public timeoutPackets;
    bytes32[] public connectedChannels;

    string[] supportedVersions = ['1.0', '2.0'];

    constructor(IbcDispatcher _dispatcher) IbcReceiverBase(_dispatcher) {}

    function onRecvPacket(IbcPacket memory packet) external onlyIbcDispatcher returns (AckPacket memory ackPacket) {
        recvedPackets.push(packet);
        return AckPacket(true, abi.encodePacked('{ "account": "account", "reply": "got the message" }'));
    }

    function onAcknowledgementPacket(IbcPacket calldata, AckPacket calldata ack) external onlyIbcDispatcher {
        ackPackets.push(ack);
    }

    function onTimeoutPacket(IbcPacket calldata packet) external onlyIbcDispatcher {
        timeoutPackets.push(packet);
    }

    function onOpenIbcChannel(
        string calldata version,
        ChannelOrder,
        bool,
        string[] calldata,
        CounterParty calldata counterparty
    ) external view onlyIbcDispatcher returns (string memory selectedVersion) {
        if (bytes(counterparty.portId).length <= 8) {
            revert invalidCounterPartyPortId();
        }
        /**
         * Version selection is determined by if the callback is invoked on behalf of ChanOpenInit or ChanOpenTry.
         * ChanOpenInit: self version should be provided whereas the counterparty version is empty.
         * ChanOpenTry: counterparty version should be provided whereas the self version is empty.
         * In both cases, the selected version should be in the supported versions list.
         */
        bool foundVersion = false;
        selectedVersion = keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked(''))
            ? counterparty.version
            : version;
        for (uint256 i = 0; i < supportedVersions.length; i++) {
            if (keccak256(abi.encodePacked(selectedVersion)) == keccak256(abi.encodePacked(supportedVersions[i]))) {
                foundVersion = true;
                break;
            }
        }
        require(foundVersion, 'Unsupported version');
        // if counterpartyVersion is not empty, then it must be the same foundVersion
        if (keccak256(abi.encodePacked(counterparty.version)) != keccak256(abi.encodePacked(''))) {
            require(
                keccak256(abi.encodePacked(counterparty.version)) == keccak256(abi.encodePacked(selectedVersion)),
                'Version mismatch'
            );
        }

        return selectedVersion;
    }

    function onConnectIbcChannel(
        bytes32 channelId,
        bytes32,
        string calldata counterpartyVersion
    ) external onlyIbcDispatcher {
        // ensure negotiated version is supported
        bool foundVersion = false;
        for (uint256 i = 0; i < supportedVersions.length; i++) {
            if (keccak256(abi.encodePacked(counterpartyVersion)) == keccak256(abi.encodePacked(supportedVersions[i]))) {
                foundVersion = true;
                break;
            }
        }
        require(foundVersion, 'Unsupported version');
        connectedChannels.push(channelId);
    }

    function onCloseIbcChannel(bytes32 channelId, string calldata, bytes32) external onlyIbcDispatcher {
        // logic to determin if the channel should be closed
        bool channelFound = false;
        for (uint256 i = 0; i < connectedChannels.length; i++) {
            if (connectedChannels[i] == channelId) {
                delete connectedChannels[i];
                channelFound = true;
                break;
            }
        }
        require(channelFound, 'Channel not found');
    }

    /**
     * This func triggers channel closure from the dApp.
     * Func args can be arbitary, as long as dispatcher.closeIbcChannel is invoked propperly.
     */
    function triggerChannelClose(bytes32 channelId) external onlyOwner {
        dispatcher.closeIbcChannel(channelId);
    }

    /**
     * @dev Sends a packet with a greeting message over a specified channel.
     * @param message The greeting message to be sent.
     * @param channelId The ID of the channel to send the packet to.
     * @param timeoutTimestamp The timestamp at which the packet will expire if not received.
     */

    function greet(string calldata message, bytes32 channelId, uint64 timeoutTimestamp) external {
        dispatcher.sendPacket(channelId, bytes(message), timeoutTimestamp);
    }
}
