// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import '../contracts/libs/Ibc.sol';
import {Dispatcher} from '../contracts/core/Dispatcher.sol';
import '../contracts/examples/Mars.sol';
import '../contracts/core/OpConsensusStateManager.sol';
import './Proof.base.t.sol';
import {stdStorage, StdStorage} from 'forge-std/Test.sol';

using stdStorage for StdStorage;

contract DispatcherIbcWithRealProofs is IbcEventsEmitter, ProofBase {
    Mars mars;
    Dispatcher dispatcher;
    OptimisticConsensusStateManager consensusStateManager;

    CounterParty ch0 =
        CounterParty('polyibc.eth1.71C95911E9a5D330f4D621842EC243EE1343292e', IbcUtils.toBytes32('channel-0'), '1.0');
    CounterParty ch1 =
        CounterParty('polyibc.eth2.71C95911E9a5D330f4D621842EC243EE1343292e', IbcUtils.toBytes32('channel-1'), '1.0');
    string[] connectionHops0 = ['connection-0', 'connection-3'];
    string[] connectionHops1 = ['connection-2', 'connection-1'];

    function setUp() public override {
        super.setUp();
        consensusStateManager = new OptimisticConsensusStateManager(1, opProofVerifier, l1BlockProvider);
        dispatcher = new Dispatcher('polyibc.eth1.', consensusStateManager);
        mars = new Mars(dispatcher);
    }

    function test_ibc_channel_open_init() public {
        CounterParty memory counterparty = CounterParty(ch1.portId, bytes32(0), '');

        vm.expectEmit(true, true, true, true);
        emit OpenIbcChannel(address(mars), '1.0', ChannelOrder.NONE, false, connectionHops1, ch1.portId, bytes32(0));
        // since this is open chann init, the proof is not used. so use an invalid one
        dispatcher.openIbcChannel(mars, ch1, ChannelOrder.NONE, false, connectionHops1, counterparty, invalidProof);
    }

    function test_ibc_channel_open_try() public {
        Ics23Proof memory proof = load_proof('/test/payload/channel_try_pending_proof.hex');

        vm.expectEmit(true, true, true, true);
        emit OpenIbcChannel(address(mars), '1.0', ChannelOrder.NONE, false, connectionHops1, ch0.portId, ch0.channelId);

        dispatcher.openIbcChannel(mars, ch1, ChannelOrder.NONE, false, connectionHops1, ch0, proof);
    }

    function test_ibc_channel_ack() public {
        Ics23Proof memory proof = load_proof('/test/payload/channel_ack_pending_proof.hex');

        vm.expectEmit(true, true, true, true);
        emit ConnectIbcChannel(address(mars), ch0.channelId);

        dispatcher.connectIbcChannel(mars, ch0, connectionHops0, ChannelOrder.NONE, false, false, ch1, proof);
    }

    function test_ibc_channel_confirm() public {
        Ics23Proof memory proof = load_proof('/test/payload/channel_confirm_pending_proof.hex');

        vm.expectEmit(true, true, true, true);
        emit ConnectIbcChannel(address(mars), ch1.channelId);

        dispatcher.connectIbcChannel(mars, ch1, connectionHops1, ChannelOrder.NONE, false, true, ch0, proof);
    }

    function test_ack_packet() public {
        Ics23Proof memory proof = load_proof('/test/payload/packet_ack_proof.hex');

        // plant a fake packet commitment so the ack checks go through
        stdstore
            .target(address(dispatcher))
            .sig(dispatcher.sendPacketCommitment.selector)
            .with_key(address(mars))
            .with_key(ch0.channelId)
            .with_key(uint256(1))
            .checked_write(true);

        IbcPacket memory packet;
        packet.data = bytes('packet-1');
        packet.timeoutTimestamp = 15566401733896437760;
        packet.src.channelId = ch0.channelId;
        packet.src.portId = string(abi.encodePacked('polyibc.eth1.', IbcUtils.toHexStr(address(mars))));
        packet.dest.portId = ch1.portId;
        packet.dest.channelId = ch1.channelId;
        packet.sequence = 1;

        // this data is taken from the write_acknowledgement event emitted by polymer
        bytes memory ack = bytes(
            '{"result":"eyAiYWNjb3VudCI6ICJhY2NvdW50IiwgInJlcGx5IjogImdvdCB0aGUgbWVzc2FnZSIgfQ=="}'
        );

        vm.expectEmit(true, true, true, true);
        emit Acknowledgement(address(mars), packet.src.channelId, packet.sequence);

        dispatcher.acknowledgement(mars, packet, ack, proof);
    }

    function test_recv_packet() public {
        Ics23Proof memory proof = load_proof('/test/payload/packet_commitment_proof.hex');

        // this data is taken from polymerase/tests/e2e/tests/evm.events.test.ts MarsDappPair.createSentPacket()
        IbcPacket memory packet;
        packet.data = bytes('packet-1');
        packet.timeoutTimestamp = 15566401733896437760;
        packet.dest.channelId = ch1.channelId;
        packet.dest.portId = string(abi.encodePacked('polyibc.eth1.', IbcUtils.toHexStr(address(mars))));
        packet.src.portId = ch0.portId;
        packet.src.channelId = ch0.channelId;
        packet.sequence = 1;

        vm.expectEmit(true, true, true, true);
        emit WriteAckPacket(
            address(mars),
            packet.dest.channelId,
            packet.sequence,
            AckPacket(true, abi.encodePacked('{ "account": "account", "reply": "got the message" }'))
        );
        dispatcher.recvPacket(mars, packet, proof);
    }

    function test_timeout_packet() public {
        vm.skip(true); // not implemented
    }

    function load_proof(string memory filepath) internal returns (Ics23Proof memory) {
        (bytes32 apphash, Ics23Proof memory proof) = abi.decode(
            vm.parseBytes(vm.readFile(string.concat(rootDir, filepath))),
            (bytes32, Ics23Proof)
        );

        // this loads the app hash we got from the testing data into the consensus state manager internals
        // at the height it's supposed to go. That is, a block less than where the proof was generated from.
        stdstore
            .target(address(consensusStateManager))
            .sig('consensusStates(uint256)')
            .with_key(proof.height - 1)
            .checked_write(apphash);
        // trick the fraud time window check
        vm.warp(block.timestamp + 1);

        return proof;
    }
}
