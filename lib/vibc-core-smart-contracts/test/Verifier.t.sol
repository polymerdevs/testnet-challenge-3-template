// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../contracts/core/OpProofVerifier.sol';
import '../contracts/libs/Ibc.sol';
import 'forge-std/Test.sol';
import './Proof.base.t.sol';

contract OpProofVerifierStateUpdateTest is ProofBase {
    function test_verify_state_update_sucess() public view {
        // this emulates the L1Block contract on whatever L2 our verifier is running. For the sake of passing
        // the verification, the provided L1 header must match the L1 block known by the L1Block contract.
        bytes32 trustedL1BlockHash = keccak256(RLPWriter.writeList(l1header.header));
        uint64 trustedL1BlockNumber = l1header.number;

        opProofVerifier.verifyStateUpdate(l1header, validStateProof, apphash, trustedL1BlockHash, trustedL1BlockNumber);
    }

    function test_verify_state_update_invalid_address() public {
        bytes32 trustedL1BlockHash = keccak256(RLPWriter.writeList(l1header.header));
        uint64 trustedL1BlockNumber = l1header.number;

        OpProofVerifier verifier = new OpProofVerifier(address(0x690B9A9E9aa1C9dB991C7721a92d351Db4FaC990));
        vm.expectRevert('MerkleTrie: invalid large internal hash');
        verifier.verifyStateUpdate(l1header, validStateProof, apphash, trustedL1BlockHash, trustedL1BlockNumber);
    }

    function test_verify_state_update_invalid_l1_number() public {
        vm.expectRevert('Invalid L1 block number');
        opProofVerifier.verifyStateUpdate(emptyl1header, invalidStateProof, bytes32(0), bytes32(0), 42);
    }

    function test_verify_state_update_invalid_l1_hash() public {
        vm.expectRevert('Invalid L1 block hash');
        opProofVerifier.verifyStateUpdate(emptyl1header, invalidStateProof, bytes32(0), bytes32(0), 0);
    }

    function test_verify_state_update_invalid_rlp_computed_hash() public {
        // just so the verifier can reach item at index 8
        emptyl1header.header = new bytes[](9);
        vm.expectRevert('Invalid RLP encoded L1 block number');
        opProofVerifier.verifyStateUpdate(
            emptyl1header,
            invalidStateProof,
            bytes32(0),
            keccak256(RLPWriter.writeList(emptyl1header.header)),
            0
        );
    }

    function test_verify_state_update_invalid_rlp_computed_state_root() public {
        // just so the verifier can reach item at index 8
        emptyl1header.header = new bytes[](9);
        emptyl1header.header[8] = RLPWriter.writeUint(0);
        vm.expectRevert('Invalid RLP encoded L1 state root');
        opProofVerifier.verifyStateUpdate(
            emptyl1header,
            invalidStateProof,
            bytes32(0),
            keccak256(RLPWriter.writeList(emptyl1header.header)),
            0
        );
    }

    function test_verify_state_update_invalid_proof() public {
        emptyl1header.header = new bytes[](9);
        emptyl1header.header[8] = RLPWriter.writeUint(0);
        emptyl1header.header[3] = RLPWriter.writeBytes(abi.encode(emptyl1header.stateRoot));
        vm.expectRevert('MerkleTrie: ran out of proof elements');
        opProofVerifier.verifyStateUpdate(
            emptyl1header,
            invalidStateProof,
            bytes32(0),
            keccak256(RLPWriter.writeList(emptyl1header.header)),
            0
        );
    }

    function test_verify_state_update_invalid_apphash() public {
        vm.expectRevert('Invalid apphash');
        opProofVerifier.verifyStateUpdate(
            l1header,
            validStateProof,
            bytes32(0),
            keccak256(RLPWriter.writeList(l1header.header)),
            l1header.number
        );
    }
}

contract OpProofVerifierMembershipVerificationTest is ProofBase {
    function test_channel_try_pending_proof_success() public view {
        // cd test-data-generator && go run ./cmd/ --type channel_try_pending > ../test/payload/channel_try_pending_proof.hex
        string memory input = vm.readFile(string.concat(rootDir, '/test/payload/channel_try_pending_proof.hex'));

        string[] memory connectionHops = new string[](2);
        connectionHops[0] = 'connection-2';
        connectionHops[1] = 'connection-1';

        CounterParty memory counterparty = CounterParty(
            'polyibc.eth1.71C95911E9a5D330f4D621842EC243EE1343292e',
            IbcUtils.toBytes32('channel-0'),
            '1.0'
        );
        this.run_packet_proof_verification(
            input,
            this.channelProofKey(
                'polyibc.eth2.71C95911E9a5D330f4D621842EC243EE1343292e',
                IbcUtils.toBytes32('channel-1')
            ),
            this.channelProofValue(ChannelState.TRY_PENDING, ChannelOrder.NONE, '1.0', connectionHops, counterparty)
        );
    }

    function test_channel_ack_pending_proof_success() public view {
        // cd test-data-generator && go run ./cmd/ --type channel_ack_pending > ../test/payload/channel_ack_pending_proof.hex
        string memory input = vm.readFile(string.concat(rootDir, '/test/payload/channel_ack_pending_proof.hex'));

        string[] memory connectionHops = new string[](2);
        connectionHops[0] = 'connection-0';
        connectionHops[1] = 'connection-3';

        CounterParty memory counterparty = CounterParty(
            'polyibc.eth2.71C95911E9a5D330f4D621842EC243EE1343292e',
            IbcUtils.toBytes32('channel-1'),
            ''
        );
        this.run_packet_proof_verification(
            input,
            this.channelProofKey(
                'polyibc.eth1.71C95911E9a5D330f4D621842EC243EE1343292e',
                IbcUtils.toBytes32('channel-0')
            ),
            this.channelProofValue(ChannelState.ACK_PENDING, ChannelOrder.NONE, '1.0', connectionHops, counterparty)
        );
    }

    function test_channel_confirm_pending_proof_success() public view {
        // cd test-data-generator && go run ./cmd/ --type channel_confirm_pending > ../test/payload/channel_confirm_pending_proof.hex
        string memory input = vm.readFile(string.concat(rootDir, '/test/payload/channel_confirm_pending_proof.hex'));

        string[] memory connectionHops = new string[](2);
        connectionHops[0] = 'connection-2';
        connectionHops[1] = 'connection-1';

        CounterParty memory counterparty = CounterParty(
            'polyibc.eth1.71C95911E9a5D330f4D621842EC243EE1343292e',
            IbcUtils.toBytes32('channel-0'),
            '1.0'
        );
        this.run_packet_proof_verification(
            input,
            this.channelProofKey(
                'polyibc.eth2.71C95911E9a5D330f4D621842EC243EE1343292e',
                IbcUtils.toBytes32('channel-1')
            ),
            this.channelProofValue(ChannelState.CONFIRM_PENDING, ChannelOrder.NONE, '1.0', connectionHops, counterparty)
        );
    }

    function test_packet_commitment_verification_success() public view {
        // generate the packet_commitment_proof.hex file with the following command:
        // cd test-data-generator && go run ./cmd/ --type packet > ../test/payload/packet_commitment_proof.hex
        string memory input = vm.readFile(string.concat(rootDir, '/test/payload/packet_commitment_proof.hex'));

        // this data is taken from polymerase/tests/e2e/tests/evm.events.test.ts MarsDappPair.createSentPacket()
        IbcPacket memory packet;
        packet.data = bytes('packet-1');
        packet.timeoutTimestamp = 15566401733896437760;
        packet.src.portId = 'polyibc.eth1.71C95911E9a5D330f4D621842EC243EE1343292e';
        packet.src.channelId = IbcUtils.toBytes32('channel-0');
        packet.sequence = 1;

        this.run_packet_proof_verification(
            input,
            this.packetCommitmentProofKey(packet),
            abi.encode(this.packetCommitmentProofValue(packet))
        );
    }

    function test_packet_ack_verification_success() public view {
        // generate the packet_ack_proof.hex file with the following command:
        // cd test-data-generator && go run ./cmd/ --type ack > ../test/payload/packet_ack_proof.hex
        string memory input = vm.readFile(string.concat(rootDir, '/test/payload/packet_ack_proof.hex'));

        IbcPacket memory packet;
        packet.data = bytes('packet-1');
        packet.timeoutTimestamp = 15566401733896437760;
        packet.dest.portId = 'polyibc.eth2.71C95911E9a5D330f4D621842EC243EE1343292e';
        packet.dest.channelId = IbcUtils.toBytes32('channel-1');
        packet.sequence = 1;

        // this data is taken from the write_acknowledgement event emitted by polymer
        bytes memory ack = bytes(
            '{"result":"eyAiYWNjb3VudCI6ICJhY2NvdW50IiwgInJlcGx5IjogImdvdCB0aGUgbWVzc2FnZSIgfQ=="}'
        );

        this.run_packet_proof_verification(input, this.ackProofKey(packet), abi.encode(this.ackProofValue(ack)));
    }

    // helpers -----------------------------------------------------------------

    function run_packet_proof_verification(string memory input, bytes calldata key, bytes calldata value) public view {
        bytes memory encoded = vm.parseBytes(input);
        (bytes32 computedApphash, Ics23Proof memory proofs) = abi.decode(encoded, (bytes32, Ics23Proof));
        return opProofVerifier.verifyMembership(computedApphash, key, value, proofs);
    }
}
