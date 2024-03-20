//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract GasAudit {
    event OpenIbcChannel1(
        address indexed portAddress,
        bytes32 indexed channelId,
        string counterpartyPortId,
        bytes32 coutnerpartyChannelId
    );

    event OpenIbcChannel2(
        address indexed portAddress,
        string channelId,
        string counterpartyPortId,
        string coutnerpartyChannelId
    );

    mapping(bytes32 => bool) channelIds1;
    mapping(string => bool) channelIds2;

    function callWithBytes32(
        address portAddress,
        bytes32 channelId,
        string calldata counterpartyPortId,
        bytes32 coutnerpartyChannelId
    ) external {
        channelIds1[channelId] = true;
        emit OpenIbcChannel1(portAddress, channelId, counterpartyPortId, coutnerpartyChannelId);
    }

    function callWithString(
        address portAddress,
        string calldata channelId,
        string calldata counterpartyPortId,
        string calldata coutnerpartyChannelId
    ) external {
        channelIds2[channelId] = true;
        emit OpenIbcChannel2(portAddress, channelId, counterpartyPortId, coutnerpartyChannelId);
    }
}
