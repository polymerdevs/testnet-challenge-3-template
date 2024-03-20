//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/CustomChanIbcApp.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CCQuery is CustomChanIbcApp {
    // app specific state
    uint64 private counter;
    mapping(uint64 => address) public counterMap;

    event LogQuery(address indexed caller, string query, uint64 counter);
    event LogAcknowledgement(string message);

    string private constant SECRET_MESSAGE = "Polymer is not a bridge: ";

    constructor(IbcDispatcher _dispatcher) CustomChanIbcApp(_dispatcher) {}

    // app specific logic
    function resetCounter() internal {
        counter = 0;
    }

    function increment() internal {
        counter++;
    }

    function getCounter() internal view returns (uint64) {
        return counter;
    }

    function uint64ToString(uint64 value) public pure returns (string memory) {
        // Special case for zero
        if (value == 0) {
            return "0";
        }

        // Calculate the length of the uint64 value
        uint64 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        // Allocate enough space to store the string representation
        bytes memory buffer = new bytes(digits);

        // Convert each digit to its ASCII representation
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }

        return string(buffer);
    }
    // IBC logic

    /**
     * @dev Sends a packet with the caller address over a specified channel.
     * @param channelId The ID of the channel (locally) to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     */
    function sendPacket(bytes32 channelId, uint64 timeoutSeconds) external {
        // NOTE: This should be never used
        // encoding the caller address to update counterMap on destination chain
        // bytes memory payload = abi.encode(msg.sender, "crossChainQuery");

        // // setting the timeout timestamp at 10h from now
        // uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        // // // calling the Dispatcher to send the packet
        // dispatcher.sendPacket(channelId, payload, timeoutTimestamp);
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param packet the IBC packet encoded by the source and relayed by the relayer.
     */
    function onRecvPacket(IbcPacket memory packet)
        external
        override
        onlyIbcDispatcher
        returns (AckPacket memory ackPacket)
    {
        recvedPackets.push(packet);
        (address _caller, string memory _query) = abi.decode(packet.data, (address, string));

        if (keccak256(bytes(_query)) == keccak256(bytes("crossChainQuery"))) {
            increment();

            uint64 _counter = getCounter();

            emit LogQuery(_caller, _query, _counter);

            string memory counterString = Strings.toString(_counter);

            counterMap[packet.sequence] = _caller;

            string memory _ackData = string(abi.encodePacked(SECRET_MESSAGE, counterString));

            return AckPacket(true, abi.encode(_ackData));
        }
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onAcknowledgementPacket(IbcPacket calldata, AckPacket calldata ack) external override onlyIbcDispatcher {
        ackPackets.push(ack);

        (string memory message) = abi.decode(ack.data, (string));

        // emit LogAcknowledgement(message);
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param packet the IBC packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutPacket(IbcPacket calldata packet) external override onlyIbcDispatcher {
        timeoutPackets.push(packet);
        // do logic
    }
}
