// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../interfaces/ConsensusStateManager.sol';

/**
 * @title DummyConsensusStateManager
 * @dev This contract is a dummy implementation of a consensus state manager.
 *      It should only be used for testing purposes.
 *      The logic for checking if the proof length is greater than zero is naive.
 */

contract DummyConsensusStateManager is ConsensusStateManager {
    constructor() {}

    function addOpConsensusState(
        L1Header calldata,
        OpL2StateProof calldata,
        uint256,
        uint256
    ) external pure returns (uint256, bool) {
        return (0, false);
    }

    function getState(uint256) external pure returns (uint256, uint256, bool) {
        return (0, 0, false);
    }

    function getFraudProofEndtime(uint256) external pure returns (uint256) {
        return 0;
    }

    function verifyMembership(Ics23Proof calldata proof, bytes memory, bytes memory) external pure {
        require(proof.height > 0, 'Invalid dummy membership proof');
    }

    function verifyNonMembership(Ics23Proof calldata proof, bytes memory) external pure {
        require(proof.height > 0, 'Invalid dummy non membership proof');
    }
}
