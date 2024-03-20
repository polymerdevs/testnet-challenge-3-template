// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import '../contracts/libs/Ibc.sol';
import '../contracts/core/OpProofVerifier.sol';
import {L1Block} from 'optimism/L2/L1Block.sol';

contract ProofBase is Test, Ibc {
    using stdJson for string;
    string rootDir = vm.projectRoot();

    OpL2StateProof validStateProof;
    OpL2StateProof invalidStateProof;

    Ics23Proof validProof;
    Ics23Proof invalidProof;

    L1Header emptyl1header;

    L1Header l1header;
    bytes32 l2BlockHash;

    bytes32 apphash;

    L1Block l1BlockProvider = new L1Block();
    OpProofVerifier opProofVerifier = new OpProofVerifier(address(0x5cA3f8919DF7d82Bf51a672B7D73Ec13a2705dDb));

    constructor() {
        // generate the channel_proof.hex file with the following command:
        // cd test-data-generator && go run ./cmd/ --type l1 > ../test/payload/l1_block_0x4df537.hex
        // this is the "rlp" half-encoded header that would be sent by the relayer. this was produced
        // by the test-data-generator tool.
        l1header = abi.decode(
            vm.parseBytes(vm.readFile(string.concat(rootDir, '/test/payload/l1_block_0x4df537.hex'))),
            (L1Header)
        );

        // this calculates the key for the given output proposal in the list of proposals that live on the
        // L2OO contract. The list lives on slot 3, the item we are looking for is the one with index 9
        // and the 2 means that the output proposal itself is 2 32bytes words in size.
        bytes32 l2OutputProposalKey = bytes32(uint256(keccak256(abi.encode(uint256(0x3)))) + uint256(0x9) * 2);

        // this happens to be the polymer height when the L2OO was updated with the output proposal
        // we are using in the test
        string memory l2BlockJson = vm.readFile(string.concat(rootDir, '/test/payload/l2_block_0x4b0.json'));
        l2BlockHash = abi.decode(l2BlockJson.parseRaw('.result.hash'), (bytes32));
        apphash = abi.decode(l2BlockJson.parseRaw('.result.stateRoot'), (bytes32));

        // the output proof height must match that of the l1 header
        string memory outputProposalJson = vm.readFile(
            string.concat(rootDir, '/test/payload/output_at_block_l1_0x4df537_with_proof.json')
        );

        validStateProof = OpL2StateProof(
            abi.decode(outputProposalJson.parseRaw('.result.accountProof'), (bytes[])),
            abi.decode(outputProposalJson.parseRaw('.result.storageProof[0].proof'), (bytes[])),
            l2OutputProposalKey,
            l2BlockHash
        );

        validProof.height = 10;
    }

    function setL1BlockAttributes(bytes32 hash, uint64 number) public {
        vm.prank(l1BlockProvider.DEPOSITOR_ACCOUNT());
        l1BlockProvider.setL1BlockValues(
            number,
            0, //          timestamp
            0, //          basefee
            hash,
            0, //          sequenceNumber
            bytes32(0), // batcherHash
            0, //          l1FeeOverhead
            0 //           l1FeeScalar
        );
    }

    function setUp() public virtual {
        delete emptyl1header;
        delete invalidStateProof;
    }
}
