// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import '../contracts/core/OpConsensusStateManager.sol';
import '../contracts/utils/DummyProofVerifier.sol';
import './Proof.base.t.sol';

contract OptimisticConsensusStateManagerTest is ProofBase {
    OptimisticConsensusStateManager manager;
    ProofVerifier verifier;

    constructor() {
        verifier = new DummyProofVerifier();
    }

    function setUp() public override {
        super.setUp();
        manager = new OptimisticConsensusStateManager(1, verifier, l1BlockProvider);
    }

    function test_addOpConsensusState_newOpConsensusStateCreatedWithPendingStatus() public {
        (, bool ended) = manager.addOpConsensusState(emptyl1header, invalidStateProof, 1, 1);
        assertEq(false, ended);
    }

    function test_addOpConsensusState_addingAlreadyTrustedOpConsensusStateIsNoop() public {
        manager.addOpConsensusState(emptyl1header, invalidStateProof, 1, 1);

        // fast forward time.
        vm.warp(block.timestamp + 100);

        // the fraud proof window has passed.
        manager.addOpConsensusState(emptyl1header, invalidStateProof, 1, 1);

        (, , bool ended) = manager.getState(1);
        assertEq(true, ended);
    }

    function test_addOpConsensusState_addingPendingOpConsensusStateWithDifferentValuesIsError() public {
        manager.addOpConsensusState(emptyl1header, invalidStateProof, 1, 1);

        vm.expectRevert(
            bytes(
                'cannot update a pending optimistic consensus state with a different appHash, please submit fraud proof instead'
            )
        );
        manager.addOpConsensusState(emptyl1header, invalidStateProof, 1, 2);
    }

    function test_addOpConsensusState_addingSameOpConsensusStateIsNoop() public {
        manager.addOpConsensusState(emptyl1header, invalidStateProof, 1, 1);

        (, uint256 originalFraudProofEndTime, ) = manager.getState(1);

        vm.warp(block.timestamp + 1);

        // adding the same appHash later doesn't update the fraud
        // proof end time.
        manager.addOpConsensusState(emptyl1header, invalidStateProof, 1, 1);
        (, uint256 newFraudProofEndTime, ) = manager.getState(1);
        assertEq(originalFraudProofEndTime, newFraudProofEndTime);
    }

    function test_zero_proof_window() public {
        manager = new OptimisticConsensusStateManager(0, verifier, l1BlockProvider);
        manager.addOpConsensusState(emptyl1header, invalidStateProof, 1, 1);
        (, , bool ended) = manager.getState(1);
        assertEq(true, ended);
    }

    function test_getState_nonExist() public {
        (uint256 appHash, , bool ended) = manager.getState(1);
        assertEq(0, appHash);
        assertEq(false, ended);
    }
}

contract OptimisticConsensusStateManagerWithRealVerifierTest is ProofBase {
    OptimisticConsensusStateManager manager;

    function setUp() public override {
        super.setUp();
        manager = new OptimisticConsensusStateManager(1, opProofVerifier, l1BlockProvider);
    }

    function test_addOpConsensusState_newAppHashWithValidProof() public {
        // trick the L1Block contract into thinking it is updated with the right l1 header
        setL1BlockAttributes(keccak256(RLPWriter.writeList(l1header.header)), l1header.number);

        manager.addOpConsensusState(l1header, validStateProof, 1, uint256(apphash));

        // since we are setting using an already known apphash, the proof is ignored
        manager.addOpConsensusState(emptyl1header, invalidStateProof, 1, uint256(apphash));
    }

    function test_addOpConsensusState_newAppHashWithInvalidProof() public {
        setL1BlockAttributes(keccak256(RLPWriter.writeList(l1header.header)), l1header.number);
        vm.expectRevert('MerkleTrie: ran out of proof elements');
        manager.addOpConsensusState(l1header, invalidStateProof, 1, uint256(apphash));
    }
}
