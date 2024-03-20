//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import '../libs/Ibc.sol';
import './IbcDispatcher.sol';
import './IbcReceiver.sol';

/**
 * @title IbcUniversalPacketSender
 * @dev IbcUniversalPacketSender is called by end-users of IBC middleware contracts to send a packet over a MW stack.
 */
interface IbcUniversalPacketSender {
    function sendUniversalPacket(
        bytes32 channelId,
        bytes32 destPortAddr,
        bytes calldata appData,
        uint64 timeoutTimestamp
    ) external;
}

interface IbcMwPacketSender {
    // sendMWPacket must be called by another authorized IBC middleware contract.
    // NEVER by a dApp contract.
    // The middleware contract may choose to send the packet by calling IbcCoreSC or another IBC MW.
    function sendMWPacket(
        bytes32 channelId,
        // original source address of the packet
        bytes32 srcPortAddr,
        bytes32 destPortAddr,
        // source middleware ids bit AND
        uint256 srcMwIds,
        bytes calldata appData,
        uint64 timeoutTimestamp
    ) external;
}

// IBC middleware contracts must implement this interface to relay universal channel packets to other IBC middleware contracts.
// If the MW contract also receives ucPacket as the final destination, it must also implement IbcUniversalPacketReceiver.
interface IbcMwPacketReceiver {
    function onRecvMWPacket(
        bytes32 channelId,
        UniversalPacket calldata ucPacket,
        // 0-based receiver middleware index in the MW stack.
        //  0 for the first MW directly called by UniversalChannel MW.
        // `mwIndex-1` is the last MW that delivers the packet to the non-MW dApp.
        // Each mw in the stack must increment mwIndex by 1 before calling the next MW.
        uint256 mwIndex,
        address[] calldata mwAddrs
    ) external returns (AckPacket memory ackPacket);

    function onRecvMWAck(
        bytes32 channelId,
        UniversalPacket calldata ucPacket,
        // 0-based receiver middleware index in the MW stack.
        //  0 for the first MW directly called by UniversalChannel MW.
        // `mwIndex-1` is the last MW that delivers the packet to the non-MW dApp.
        // Each mw in the stack must increment mwIndex by 1 before calling the next MW.
        uint256 mwIndex,
        address[] calldata mwAddrs,
        AckPacket calldata ack
    ) external;

    function onRecvMWTimeout(
        bytes32 channelId,
        UniversalPacket calldata ucPacket,
        uint256 mwIndex,
        address[] calldata mwAddrs
    ) external;
}

// dApps and IBC middleware contracts need to implement this interface to receive universal channel packets as packets' final destination.
interface IbcUniversalPacketReceiver {
    function onRecvUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata ucPacket
    ) external returns (AckPacket memory ackPacket);

    function onUniversalAcknowledgement(
        bytes32 channelId,
        UniversalPacket memory packet,
        AckPacket calldata ack
    ) external;

    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external;
}

interface IbcMiddlwareProvider is IbcUniversalPacketSender, IbcMwPacketSender {
    /**
     * @dev MW_ID is the ID of MW contract on all supported virtual chains.
     * MW_ID must:
     * - be globally unique, ie. no two MWs should have the same MW_ID registered on Polymer chain.
     * - be identical on all supported virtual chains.
     * - be identical on one virtual chain across multiple deployed MW instances. Each MW instance belong exclusively to one MW stack.
     * - be 1 << N, where N is a non-negative integer [0,255], and not in conflict with other MWs.
     */
    function MW_ID() external view returns (uint256);
}

/**
 * @title IbcMiddleware
 * @notice IBC middleware interface must be implemented by a IBC-middleware contract, similar to ICS-30
 *  https://github.com/cosmos/ibc/tree/main/spec/app/ics-030-middleware.
 * Current limitations:
 *   - IbcMiddleware must sit on top of a UniversalChannel MW or another IbcMiddleware.
 *   - IbcMiddleware cannnot own an IBC channel. Instead, UniversalChannel MW owns channels.
 */
interface IbcMiddleware is IbcMiddlwareProvider, IbcMwPacketReceiver, IbcUniversalPacketReceiver {

}

/**
 * @title IbcUniversalChannelMW
 * @notice This interface must be implemented by IBC universal channel middleware contracts.
 * IbcUniversalChannelMW is a special type of IbcMiddleware that owns IBC channels, which are multiplexed for other IbcMiddleware.
 * IbcUniversalChannelMW cannot sit on top of other MW, and must talk to IbcDispatcher directly.
 */
interface IbcUniversalChannelMW is IbcMiddlwareProvider, IbcPacketReceiver, IbcChannelReceiver {

}

/**
 * @title IbcMwEventsEmitter
 * @notice IBC middleware events interface.
 * @dev IBC middleware contracts should emit events specific to their own middleware,
 * and can choose to emit events not defined in this interface if needed.
 */
interface IbcMwEventsEmitter {
    event SendMWPacket(
        bytes32 indexed channelId,
        bytes32 indexed srcPortAddr,
        bytes32 indexed destPortAddr,
        // middleware UID
        uint256 mwId,
        bytes appData,
        uint64 timeoutTimestamp,
        bytes mwData
    );
    event RecvMWPacket(
        bytes32 indexed channelId,
        bytes32 indexed srcPortAddr,
        bytes32 indexed destPortAddr,
        // middleware UID
        uint256 mwId,
        bytes appData,
        bytes mwData
    );
    event RecvMWAck(
        bytes32 indexed channelId,
        bytes32 indexed srcPortAddr,
        bytes32 indexed destPortAddr,
        // middleware UID
        uint256 mwId,
        bytes appData,
        bytes mwData,
        AckPacket ack
    );
    event RecvMWTimeout(
        bytes32 indexed channelId,
        bytes32 indexed srcPortAddr,
        bytes32 indexed destPortAddr,
        // middleware UID
        uint256 mwId,
        bytes appData,
        bytes mwData
    );
}

/**
 * @title IbcMwUser
 * @dev Contracts that send and recv universal packets via IBC MW should inherit IbcMwUser or implement similiar functions.
 * @notice IbcMwUser ensures only authorized IBC middleware can call IBC callback functions.
 */
contract IbcMwUser is Ownable {
    // default middleware
    address public mw;
    mapping(address => bool) public authorizedMws;

    /**
     * @dev Constructor function that takes an IbcMiddleware address and grants the IBC_ROLE to the Polymer IBC Dispatcher.
     * @param _middleware The address of the IbcMiddleware contract.
     */
    constructor(address _middleware) Ownable() {
        mw = _middleware;
        _authorizeMiddleware(_middleware);
    }

    /**
     * @dev Set the default IBC middleware contract in the MW stack.
     * When sending packets, the default middleware is the next middleware in the MW stack.
     * When receiving packets, the default middleware is the previous middleware in the MW stack.
     * @param _middleware The address of the IbcMiddleware contract.
     * @notice The default middleware is authorized automatically.
     */
    function setDefaultMw(address _middleware) external onlyOwner {
        _authorizeMiddleware(_middleware);
        mw = _middleware;
    }

    /**
     * @dev register an authorized middleware so that modifier onlyIbcMw can be used to restrict access to only authorized middleware.
     * Only the address with the IBC_ROLE can execute the function.
     * @notice Should add this modifier to all IBC-related callback functions.
     */
    function authorizeMiddleware(address middleware) external onlyOwner {
        _authorizeMiddleware(middleware);
    }

    function _authorizeMiddleware(address middleware) internal {
        authorizedMws[address(middleware)] = true;
    }

    /// This function is called for plain Ether transfers, i.e. for every call with empty calldata.
    // An empty function body is sufficient to receive packet fee refunds.
    receive() external payable {}

    /**
     * @dev Modifier to restrict access to only the IBC middleware.
     * Only the address with the IBC_ROLE can execute the function.
     * Should add this modifier to all IBC-related callback functions.
     */
    modifier onlyIbcMw() {
        require(authorizedMws[msg.sender], 'unauthorized IBC middleware');
        _;
    }
}
