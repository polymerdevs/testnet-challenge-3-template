// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../contracts/libs/Ibc.sol';
import 'forge-std/Test.sol';

contract IbcTest is Ibc, Test {
    function test_packet_commitment_proof_key() public {
        IbcPacket memory packet = IbcPacket(
            IbcEndpoint('portid', hex'6368616e6e656c2d30'),
            IbcEndpoint('', 0),
            12,
            hex'',
            Height(0, 0),
            0
        );
        assertEq('commitments/ports/portid/channels/channel-0/sequences/12', this.packetCommitmentProofKey(packet));
    }

    function test_packet_ack_proof_key() public {
        IbcPacket memory packet = IbcPacket(
            IbcEndpoint('', 0),
            IbcEndpoint('portid', hex'6368616e6e656c2d30'),
            12,
            hex'',
            Height(0, 0),
            0
        );
        assertEq('acks/ports/portid/channels/channel-0/sequences/12', this.ackProofKey(packet));
    }

    function test_channel_proof_key() public {
        bytes memory key = bytes(
            'channelEnds/ports/polyibc.eth1.71C95911E9a5D330f4D621842EC243EE1343292e/channels/channel-0'
        );

        assertEq(
            key,
            this.channelProofKey(
                'polyibc.eth1.71C95911E9a5D330f4D621842EC243EE1343292e',
                IbcUtils.toBytes32('channel-0')
            )
        );
    }

    function test_string_to_bytes32() public {
        assertEq(bytes32(hex'6368616e6e656c2d30'), IbcUtils.toBytes32('channel-0'));
    }

    function test_bytes32_to_string() public {
        assertEq('channel-0', toStr(bytes32(hex'6368616e6e656c2d30')));
    }

    function test_uint256_to_string() public {
        assertEq('1', toStr(1));
        assertEq('112233445566', toStr(112233445566));
        assertEq('16', toStr(16));
    }

    function test_parse_ack() public {
        // this data is taken from the write_acknowledgement event emitted by polymer
        bytes memory ack = bytes(
            '{"result":"eyAiYWNjb3VudCI6ICJhY2NvdW50IiwgInJlcGx5IjogImdvdCB0aGUgbWVzc2FnZSIgfQ=="}'
        );

        AckPacket memory parsed = this.parseAckData(ack);
        assertTrue(parsed.success);
        assertEq(bytes('{ "account": "account", "reply": "got the message" }'), parsed.data);

        bytes memory error = bytes('{"error":"this is an error message"}');
        AckPacket memory parsederr = this.parseAckData(error);
        assertFalse(parsederr.success);
        assertEq(bytes('this is an error message'), parsederr.data);
    }
}
