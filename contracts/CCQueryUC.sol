//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CCQueryUC is UniversalChanIbcApp {
    // app specific state
    uint64 private counter;
    mapping(uint64 => address) public counterMap;
    mapping(address => bool) public addressMap;

    event LogQuery(address indexed caller, string query, uint64 counter);
    event LogAcknowledgement(string message);

    string private constant SECRET_MESSAGE = "Polymer is not a bridge: ";
    string private constant LIMIT_MESSAGE = "Sorry, but the 500 limit has been reached, stay tuned for challenge 4";

    constructor(address _middleware) UniversalChanIbcApp(_middleware) {}

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

    // IBC logic

    /**
     * @dev Sends a packet with the caller's address over the universal channel.
     * @param destPortAddr The address of the destination application.
     * @param channelId The ID of the channel to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     */https://forum.polymerlabs.org/t/challenge-4-cross-chain-nft-minting-with-polymer/595
    function sendUniversalPacket(address destPortAddr, bytes32 channelId, uint64 timeoutSeconds) external {
        // TODO - Implement sendUniversalPacket to send a packet which will be received by the other chain
        // The packet should contain the caller's address and a query string
        // See onRecvUniversalPacket for the expected packet format in https://forum.polymerlabs.org/t/challenge-3-cross-contract-query-with-polymer/475
        // Steps:
        // 1. Encode the caller's address and the query string into a payload
        // 2. Set the timeout timestamp at 10h from now
        // 3. Call the IbcUniversalPacketSender to send the packet

        // Example of how to properly encode, set timestamp and send a packet can be found in XCounterUC.sol
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet)
        external
        override
        onlyIbcMw
        returns (AckPacket memory ackPacket)
    {
        // You can leave the following function empty
        // This contract will need to be sending and acknowledging packets and not receiving them to complete the challenge
        // The reference implemention of onRecvUniversalPacket on the base contract you will be calling is below

        /*
        recvedPackets.push(UcPacketWithChannel(channelId, packet));
        uint64 _counter = getCounter();

        (address _caller, string memory _query) = abi.decode(packet.appData, (address, string));

        require(!addressMap[_caller], "Address already queried");
        if (_counter >= 500) {
            return AckPacket(true, abi.encode(LIMIT_MESSAGE));
        }

        if (keccak256(bytes(_query)) == keccak256(bytes("crossChainQuery"))) {
            increment();
            addressMap[_caller] = true;
            uint64 newCounter = getCounter();
            emit LogQuery(_caller, _query, newCounter);

            string memory counterString = Strings.toString(newCounter);

            string memory _ackData = string(abi.encodePacked(SECRET_MESSAGE, counterString));

            return AckPacket(true, abi.encode(_ackData));
        }
        */
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the ack was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack)
        external
        override
        onlyIbcMw
    {
        // TODO - Implement onUniversalAcknowledgement to handle the received acknowledgment packet
        // The packet should contain the secret message from the Base Contract at address: 0x528f7971cE3FF4198c3e6314AA223C83C7755bf7
        // Steps:
        // 1. Decode the counter from the ack packet
        // 2. Emit a LogAcknowledgement event with the message

        // An example of how to properly decode and handle an ack packet can be found in XCounterUC.sol
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // do logic
    }
}
