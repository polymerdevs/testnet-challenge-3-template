// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '../contracts/libs/Ibc.sol';
import {Dispatcher} from '../contracts/core/Dispatcher.sol';
import {IbcEventsEmitter} from '../contracts/interfaces/IbcDispatcher.sol';
import {IbcReceiver} from '../contracts/interfaces/IbcReceiver.sol';
import '../contracts/examples/Mars.sol';
import '../contracts/core/OpConsensusStateManager.sol';
import './Dispatcher.base.t.sol';

contract ChannelHandshakeTest is Base {
    string portId = 'eth1.7E5F4552091A69125d5DfCb7b8C2659029395Bdf';
    LocalEnd _local;
    CounterParty _remote;
    Mars mars;

    function setUp() public override {
        dispatcher = new Dispatcher(portPrefix, dummyConsStateManager);
        mars = new Mars(dispatcher);
        _local = LocalEnd(mars, portId, 'channel-1', connectionHops, '1.0', '1.0');
        _remote = CounterParty('eth2.7E5F4552091A69125d5DfCb7b8C2659029395Bdf', 'channel-2', '1.0');
    }

    function test_openChannel_initiator_ok() public {
        ChannelHandshakeSetting[4] memory settings = createSettings(true, true);
        string[2] memory versions = ['1.0', '2.0'];
        for (uint256 i = 0; i < settings.length; i++) {
            for (uint256 j = 0; j < versions.length; j++) {
                LocalEnd memory le = _local;
                CounterParty memory re = _remote;
                le.versionCall = versions[j];
                le.versionExpected = versions[j];
                // remoteEnd has no channelId or version if localEnd is the initiator
                openChannel(le, re, settings[i], true);
            }
        }
    }

    function test_openChannel_receiver_ok() public {
        ChannelHandshakeSetting[4] memory settings = createSettings(false, true);
        string[2] memory versions = ['1.0', '2.0'];
        for (uint256 i = 0; i < settings.length; i++) {
            for (uint256 j = 0; j < versions.length; j++) {
                LocalEnd memory le = _local;
                CounterParty memory re = _remote;
                re.version = versions[j];
                // explicit version
                le.versionCall = versions[j];
                le.versionExpected = versions[j];
                // remoteEnd version is used
                openChannel(le, re, settings[i], true);

                // auto version selection
                le.versionCall = '';
                openChannel(le, re, settings[i], true);
            }
        }
    }

    function test_connectChannel_ok() public {
        ChannelHandshakeSetting[8] memory settings = createSettings2(true);

        string[2] memory versions = ['1.0', '2.0'];
        for (uint256 i = 0; i < settings.length; i++) {
            for (uint256 j = 0; j < versions.length; j++) {
                LocalEnd memory le = _local;
                CounterParty memory re = _remote;
                le.versionCall = versions[j];
                le.versionExpected = versions[j];
                re.version = versions[j];
                openChannel(le, re, settings[i], true);
                connectChannel(le, re, settings[i], false, true);
            }
        }
    }

    function test_openChannel_receiver_fail_versionMismatch() public {
        ChannelHandshakeSetting[4] memory settings = createSettings(false, true);
        string[2] memory versions = ['1.0', '2.0'];
        for (uint256 i = 0; i < settings.length; i++) {
            for (uint256 j = 0; j < versions.length; j++) {
                LocalEnd memory le = _local;
                CounterParty memory re = _remote;
                re.version = versions[j];
                // always select the wrong version
                bool isVersionOne = keccak256(abi.encodePacked(versions[j])) == keccak256(abi.encodePacked('1.0'));
                le.versionCall = isVersionOne ? '2.0' : '1.0';
                vm.expectRevert(bytes('Version mismatch'));
                openChannel(le, re, settings[i], false);
            }
        }
    }

    function test_openChannel_initiator_fail_unsupportedVersion() public {
        ChannelHandshakeSetting[4] memory settings = createSettings(true, true);
        string[2] memory versions = ['', 'xxxxxxx'];
        for (uint256 i = 0; i < settings.length; i++) {
            for (uint256 j = 0; j < versions.length; j++) {
                LocalEnd memory le = _local;
                CounterParty memory re = _remote;
                le.versionCall = versions[j];
                le.versionExpected = versions[j];
                vm.expectRevert(bytes('Unsupported version'));
                openChannel(le, re, settings[i], false);
            }
        }
    }

    function test_openChannel_receiver_fail_invalidProof() public {
        // When localEnd initiates, no proof verification is done in openIbcChannel
        ChannelHandshakeSetting[4] memory settings = createSettings(false, false);
        string[1] memory versions = ['1.0'];
        for (uint256 i = 0; i < settings.length; i++) {
            for (uint256 j = 0; j < versions.length; j++) {
                LocalEnd memory le = _local;
                CounterParty memory re = _remote;
                le.versionCall = versions[j];
                le.versionExpected = versions[j];
                vm.expectRevert('Invalid dummy membership proof');
                openChannel(le, re, settings[i], false);
            }
        }
    }

    function test_connectChannel_fail_unsupportedVersion() public {
        // When localEnd initiates, counterparty version is only available in connectIbcChannel
        ChannelHandshakeSetting[4] memory settings = createSettings(true, true);
        string[2] memory versions = ['', 'xxxxxxx'];
        for (uint256 i = 0; i < settings.length; i++) {
            for (uint256 j = 0; j < versions.length; j++) {
                LocalEnd memory le = _local;
                CounterParty memory re = _remote;
                // no remote version applied in openChannel
                openChannel(le, re, settings[i], true);
                re.version = versions[j];
                vm.expectRevert(bytes('Unsupported version'));
                connectChannel(le, re, settings[i], false, false);
            }
        }
    }

    function test_connectChannel_fail_invalidProof() public {
        // When localEnd initiates, counterparty version is only available in connectIbcChannel
        ChannelHandshakeSetting[8] memory settings = createSettings2(true);
        string[1] memory versions = ['1.0'];
        for (uint256 i = 0; i < settings.length; i++) {
            for (uint256 j = 0; j < versions.length; j++) {
                LocalEnd memory le = _local;
                CounterParty memory re = _remote;
                // no remote version applied in openChannel
                openChannel(le, re, settings[i], true);
                re.version = versions[j];
                settings[i].proof = invalidProof;
                vm.expectRevert('Invalid dummy membership proof');
                connectChannel(le, re, settings[i], false, false);
            }
        }
    }

    function createSettings(
        bool localInitiate,
        bool isProofValid
    ) internal view returns (ChannelHandshakeSetting[4] memory) {
        Ics23Proof memory proof = isProofValid ? validProof : invalidProof;
        ChannelHandshakeSetting[4] memory settings = [
            ChannelHandshakeSetting(ChannelOrder.ORDERED, false, localInitiate, proof),
            ChannelHandshakeSetting(ChannelOrder.UNORDERED, false, localInitiate, proof),
            ChannelHandshakeSetting(ChannelOrder.ORDERED, true, localInitiate, proof),
            ChannelHandshakeSetting(ChannelOrder.UNORDERED, true, localInitiate, proof)
        ];
        return settings;
    }

    function createSettings2(bool isProofValid) internal view returns (ChannelHandshakeSetting[8] memory) {
        // localEnd initiates
        ChannelHandshakeSetting[4] memory settings1 = createSettings(true, isProofValid);
        // remoteEnd initiates
        ChannelHandshakeSetting[4] memory settings2 = createSettings(false, isProofValid);
        ChannelHandshakeSetting[8] memory settings;
        for (uint256 i = 0; i < settings1.length; i++) {
            settings[i] = settings1[i];
            settings[i + settings1.length] = settings2[i];
        }
        return settings;
    }
}

// This Base contract provides an open channel for sub-contract tests
contract ChannelOpenTestBase is Base {
    string portId = 'eth1.7E5F4552091A69125d5DfCb7b8C2659029395Bdf';
    bytes32 channelId = 'channel-1';
    address relayer = deriveAddress('relayer');
    bool feeEnabled = false;

    LocalEnd _local;
    CounterParty _remote;
    Mars mars;

    function setUp() public virtual override {
        dispatcher = new Dispatcher(portPrefix, dummyConsStateManager);
        ChannelHandshakeSetting memory setting = ChannelHandshakeSetting(
            ChannelOrder.ORDERED,
            feeEnabled,
            true,
            validProof
        );

        // anyone can run Relayers
        vm.startPrank(relayer);
        vm.deal(relayer, 100000 ether);
        mars = new Mars(dispatcher);

        _local = LocalEnd(mars, portId, channelId, connectionHops, '1.0', '1.0');
        _remote = CounterParty('eth2.7E5F4552091A69125d5DfCb7b8C2659029395Bdf', 'channel-2', '1.0');

        openChannel(_local, _remote, setting, true);
        connectChannel(_local, _remote, setting, false, true);
    }
}

// FIXME this is commented out to make the contract size smaller. We need to optimise for size
// contract DispatcherCloseChannelTest is ChannelOpenTestBase {
//     function test_closeChannelInit_success() public {
//         vm.expectEmit(true, true, true, true);
//         emit CloseIbcChannel(address(mars), channelId);
//         mars.triggerChannelClose(channelId);
//     }
//
//     function test_closeChannelInit_mustOwner() public {
//         Mars earth = new Mars(dispatcher);
//         vm.expectRevert(abi.encodeWithSignature('channelNotOwnedBySender()'));
//         earth.triggerChannelClose(channelId);
//     }
//
//     function test_closeChannelConfirm_success() public {
//         vm.expectEmit(true, true, true, true);
//         emit CloseIbcChannel(address(mars), channelId);
//         dispatcher.onCloseIbcChannel(address(mars), channelId, validProof);
//     }
//
//     function test_closeChannelConfirm_mustOwner() public {
//         vm.expectRevert(abi.encodeWithSignature('channelNotOwnedByPortAddress()'));
//         dispatcher.onCloseIbcChannel(address(mars), 'channel-999', validProof);
//     }
//
//     function test_closeChannelConfirm_invalidProof() public {
//         vm.expectRevert('Invalid dummy membership proof');
//         dispatcher.onCloseIbcChannel(address(mars), channelId, invalidProof);
//     }
// }

contract DispatcherSendPacketTest is ChannelOpenTestBase {
    // default params
    string payload = 'msgPayload';
    uint64 timeoutTimestamp = 1000;

    function test_success() public {
        bytes memory packet = abi.encodePacked(payload);
        for (uint64 index = 0; index < 3; index++) {
            vm.expectEmit(true, true, true, true);
            uint64 packetSeq = index + 1;
            emit SendPacket(address(mars), channelId, packet, packetSeq, timeoutTimestamp);
            mars.greet(payload, channelId, timeoutTimestamp);
        }
    }

    // sendPacket fails if calling dApp doesn't own the channel
    function test_mustOwner() public {
        Mars earth = new Mars(dispatcher);
        vm.expectRevert(abi.encodeWithSignature('channelNotOwnedBySender()'));
        earth.greet(payload, channelId, timeoutTimestamp);
    }
}

contract PacketSenderTestBase is ChannelOpenTestBase {
    IbcEndpoint dest = IbcEndpoint('polyibc.bsc.9876543210', 'channel-99');
    IbcEndpoint src;
    string payloadStr = 'msgPayload';
    bytes payload = bytes(payloadStr);
    bytes appAck = abi.encodePacked('{ "account": "account", "reply": "got the message" }');

    uint64 nextSendSeq = 1;
    // cached packet that was sent in `sendPacket`
    IbcPacket sentPacket;
    // ackPacket is the acknowledgement packet that is expected to be written for the `sentPacket`
    bytes ackPacket;

    function setUp() public virtual override {
        super.setUp();
        string memory marsPort = string(abi.encodePacked(portPrefix, getHexBytes(address(mars))));
        src = IbcEndpoint(marsPort, channelId);
    }

    // sendPacket writes a packet commitment, and updates cached `sentPacket` and `ackPacket`
    function sendPacket() internal {
        sentPacket = genPacket(nextSendSeq);
        ackPacket = genAckPacket(this.toStr(nextSendSeq));
        mars.greet(payloadStr, channelId, maxTimeout);
        nextSendSeq += 1;
    }

    // genPacket generates a packet for the given packet sequence
    function genPacket(uint64 packetSeq) internal view returns (IbcPacket memory) {
        return IbcPacket(src, dest, packetSeq, payload, ZERO_HEIGHT, maxTimeout);
    }

    // genAckPacket generates an ack packet for the given packet sequence
    function genAckPacket(string memory packetSeq) internal pure returns (bytes memory) {
        return ackToBytes(AckPacket(true, bytes(packetSeq)));
    }
}

// Test Chains B receives a packet from Chain A
contract DispatcherRecvPacketTest is ChannelOpenTestBase {
    IbcEndpoint src = IbcEndpoint('polyibc.bsc.9876543210', 'channel-99');
    IbcEndpoint dest;
    bytes payload = bytes('msgPayload');
    bytes appAck = abi.encodePacked('{ "account": "account", "reply": "got the message" }');

    function setUp() public override {
        super.setUp();
        string memory marsPort = string(abi.encodePacked(portPrefix, getHexBytes(address(mars))));
        dest = IbcEndpoint(marsPort, channelId);
    }

    function test_success() public {
        for (uint64 index = 0; index < 3; index++) {
            uint64 packetSeq = index + 1;
            vm.expectEmit(true, true, true, true, address(dispatcher));
            emit RecvPacket(address(mars), channelId, packetSeq);
            vm.expectEmit(true, true, false, true, address(dispatcher));
            emit WriteAckPacket(address(mars), channelId, packetSeq, AckPacket(true, appAck));
            dispatcher.recvPacket(
                IbcReceiver(mars),
                IbcPacket(src, dest, packetSeq, payload, ZERO_HEIGHT, maxTimeout),
                validProof
            );
        }
    }

    // recvPacket emits a WriteTimeoutPacket if timestamp passes chain B's block time
    function test_timeout_timestamp() public {
        uint64 packetSeq = 1;
        IbcPacket memory pkt = IbcPacket(src, dest, packetSeq, payload, ZERO_HEIGHT, 1);
        vm.expectEmit(true, true, true, true, address(dispatcher));
        emit RecvPacket(address(mars), channelId, packetSeq);
        vm.expectEmit(true, true, false, true, address(dispatcher));
        emit WriteTimeoutPacket(address(mars), channelId, packetSeq, pkt.timeoutHeight, pkt.timeoutTimestamp);
        dispatcher.recvPacket(IbcReceiver(mars), pkt, validProof);
    }

    // recvPacket emits a WriteTimeoutPacket if block height passes chain B's block height
    function test_timeout_blockHeight() public {
        uint64 packetSeq = 1;
        IbcPacket memory pkt = IbcPacket(src, dest, packetSeq, payload, Height(0, 1), 0);
        vm.expectEmit(true, true, true, true, address(dispatcher));
        emit RecvPacket(address(mars), channelId, packetSeq);
        vm.expectEmit(true, true, false, true, address(dispatcher));
        emit WriteTimeoutPacket(address(mars), channelId, packetSeq, pkt.timeoutHeight, pkt.timeoutTimestamp);
        dispatcher.recvPacket(IbcReceiver(mars), pkt, validProof);
    }

    // cannot receive packets out of order for ordered channel
    function test_outOfOrder() public {
        dispatcher.recvPacket(IbcReceiver(mars), IbcPacket(src, dest, 1, payload, ZERO_HEIGHT, maxTimeout), validProof);
        vm.expectRevert(abi.encodeWithSignature('unexpectedPacketSequence()'));
        dispatcher.recvPacket(IbcReceiver(mars), IbcPacket(src, dest, 3, payload, ZERO_HEIGHT, maxTimeout), validProof);
    }

    // TODO: add tests for unordered channel, wrong port, and invalid proof
}

// Test Chain A receives an acknowledgement packet from Chain B
contract DispatcherAckPacketTest is PacketSenderTestBase {
    function test_success() public {
        for (uint64 index = 0; index < 3; index++) {
            sendPacket();

            vm.expectEmit(true, true, false, true, address(dispatcher));
            emit Acknowledgement(address(mars), channelId, sentPacket.sequence);
            dispatcher.acknowledgement(IbcReceiver(mars), sentPacket, ackPacket, validProof);
            // confirm dapp recieved the ack
            (bool success, bytes memory data) = mars.ackPackets(sentPacket.sequence - 1);
            AckPacket memory parsed = this.parseAckData(ackPacket);
            assertEq(success, parsed.success);
            assertEq(data, parsed.data);
        }
    }

    // cannot ack packets if packet commitment is missing
    function test_missingPacket() public {
        vm.expectRevert(abi.encodeWithSignature('packetCommitmentNotFound()'));
        dispatcher.acknowledgement(IbcReceiver(mars), genPacket(1), genAckPacket('1'), validProof);

        sendPacket();
        dispatcher.acknowledgement(IbcReceiver(mars), sentPacket, ackPacket, validProof);

        // packet commitment is removed after ack
        vm.expectRevert(abi.encodeWithSignature('packetCommitmentNotFound()'));
        dispatcher.acknowledgement(IbcReceiver(mars), sentPacket, ackPacket, validProof);
    }

    // cannot recieve ack packets out of order for ordered channel
    function test_outOfOrder() public {
        for (uint64 index = 0; index < 3; index++) {
            sendPacket();
        }
        // 1st ack is ok
        dispatcher.acknowledgement(IbcReceiver(mars), genPacket(1), genAckPacket('1'), validProof);

        // only 2nd ack is allowed; so the 3rd ack fails
        vm.expectRevert(abi.encodeWithSignature('unexpectedPacketSequence()'));

        dispatcher.acknowledgement(IbcReceiver(mars), genPacket(3), genAckPacket('3'), validProof);
    }

    function test_invalidPort() public {
        Mars earth = new Mars(dispatcher);
        string memory earthPort = string(abi.encodePacked(portPrefix, getHexBytes(address(earth))));
        IbcEndpoint memory earthEnd = IbcEndpoint(earthPort, channelId);

        sendPacket();

        // another valid packet but not the same port
        IbcPacket memory packetEarth = sentPacket;
        packetEarth.src = earthEnd;

        vm.expectRevert(abi.encodeWithSignature('receiverNotOriginPacketSender()'));
        dispatcher.acknowledgement(IbcReceiver(mars), packetEarth, ackPacket, validProof);
    }

    // ackPacket fails if channel doesn't match
    function test_invalidChannel() public {
        sendPacket();

        IbcEndpoint memory invalidSrc = IbcEndpoint(src.portId, 'channel-invalid');
        IbcPacket memory packet = sentPacket;
        packet.src = invalidSrc;

        vm.expectRevert(abi.encodeWithSignature('packetCommitmentNotFound()'));
        dispatcher.acknowledgement(IbcReceiver(mars), packet, ackPacket, validProof);
    }
}

// Test Chain A receives a timeout packet from Chain B
contract DispatcherTimeoutPacketTest is PacketSenderTestBase {
    // preconditions for timeout packet
    // - packet commitment exists
    // - packet timeout is verified by Polymer client
    function test_success() public {
        for (uint64 index = 0; index < 3; index++) {
            sendPacket();

            vm.expectEmit(true, true, true, true, address(dispatcher));
            emit Timeout(address(mars), channelId, sentPacket.sequence);
            dispatcher.timeout(IbcReceiver(mars), sentPacket, validProof);
        }
    }

    // cannot timeout packets if packet commitment is missing
    function test_missingPacket() public {
        vm.expectRevert(abi.encodeWithSignature('packetCommitmentNotFound()'));
        dispatcher.timeout(IbcReceiver(mars), genPacket(1), validProof);

        sendPacket();
        dispatcher.timeout(IbcReceiver(mars), sentPacket, validProof);

        // packet commitment is removed after timeout
        vm.expectRevert(abi.encodeWithSignature('packetCommitmentNotFound()'));
        dispatcher.timeout(IbcReceiver(mars), sentPacket, validProof);
    }

    // cannot timeout packets if original packet port doesn't match current port
    function test_invalidPort() public {
        Mars earth = new Mars(dispatcher);
        string memory earthPort = string(abi.encodePacked(portPrefix, getHexBytes(address(earth))));
        IbcEndpoint memory earthEnd = IbcEndpoint(earthPort, channelId);

        sendPacket();

        // another valid packet but not the same port
        IbcPacket memory packetEarth = sentPacket;
        packetEarth.src = earthEnd;

        vm.expectRevert(abi.encodeWithSignature('receiverNotIndtendedPacketDestination()'));
        dispatcher.timeout(IbcReceiver(mars), packetEarth, validProof);
    }

    // cannot timeout packetsfails if channel doesn't match
    function test_invalidChannel() public {
        sendPacket();

        IbcEndpoint memory invalidSrc = IbcEndpoint(src.portId, 'channel-invalid');
        IbcPacket memory packet = sentPacket;
        packet.src = invalidSrc;

        vm.expectRevert(abi.encodeWithSignature('packetCommitmentNotFound()'));
        /* vm.expectRevert('Packet commitment not found'); */
        dispatcher.timeout(IbcReceiver(mars), packet, validProof);
    }

    // cannot timeout packets if proof from Polymer is invalid
    function test_invalidProof() public {
        sendPacket();

        vm.expectRevert('Invalid dummy non membership proof');
        dispatcher.timeout(IbcReceiver(mars), sentPacket, invalidProof);
    }
}
