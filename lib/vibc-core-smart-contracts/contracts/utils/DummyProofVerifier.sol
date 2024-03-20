// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../interfaces/ProofVerifier.sol';

contract DummyProofVerifier is ProofVerifier {
    function verifyStateUpdate(L1Header calldata, OpL2StateProof calldata, bytes32, bytes32, uint64) external pure {}

    function verifyMembership(bytes32, bytes calldata, bytes calldata, Ics23Proof calldata) external pure {}

    function verifyNonMembership(bytes32, bytes calldata, Ics23Proof calldata) external pure {}
}
