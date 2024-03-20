// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SecureMerkleTrie} from 'optimism/libraries/trie/SecureMerkleTrie.sol';
import {RLPReader} from 'optimism/libraries/rlp/RLPReader.sol';
import {RLPWriter} from 'optimism/libraries/rlp/RLPWriter.sol';

import '../interfaces/ProofVerifier.sol';

contract OpProofVerifier is ProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    // @notice index of the l1 state root in the "l1 header"
    uint internal constant L1_STATE_ROOT_INDEX = 3;

    // @notice index of the l1 number in the "l1 header"
    uint internal constant L1_NUMBER_INDEX = 8;

    // @notice known L2 Output Oracle contract address to verify state update proofs against
    address l2OutputOracleAddress;

    constructor(address _l2OutputOracleAddress) {
        l2OutputOracleAddress = _l2OutputOracleAddress;
    }

    /**
     * @dev Prove that the provided app hash (L2 state root) is valid. Done so by proving that the L2OutputOracle
     * contains an output proposal within its state that we can derive from the given app hash. The high level
     * approach is:
     *
     * A. Prove the given L1 state root.
     * B. Prove the prescence of an output proposal in the L2OutputOracle contract.
     * C. Derive the output proposal from the apphash.
     *
     * A more detailed explanation of the process goes as follows. All steps must be valid in order for the
     * app hash to be accepted. Otherwise, the function will revert.
     *
     * 1. Provided L1 header hash and number match that of the trusted ones. The trusted attributes must come
     *    from Optimism's L1Block contract. Given that this contract only holds the latest L1 attributes, there's
     *    a good chance for a race-condition to happen, so check them first.
     *
     * 2. Provided L1 header data includes the L1 state root. Compute the header hash and check it against the
     *    trusted one. In case of a match, the state root must be valid.
     *
     * 3. Based on the L1 state root and using the provided account proof and L2OutputOracle address, get the
     *    value stored in the MerkleTrie leaf. This is the state account.
     *
     * 4. With the state account root and using the provided storage proof and output proposal key, get the
     *    vlue stored in the MerkleTrie leaf. This is the output proposal root.
     *
     * 5. With the provided apphash and L2 Blockc hash, try to compute a new output root and match it against
     *    the one we just proved to be valid.
     */
    function verifyStateUpdate(
        L1Header calldata l1header,
        OpL2StateProof calldata proof,
        bytes32 appHash,
        bytes32 trustedL1BlockHash,
        uint64 trustedL1BlockNumber
    ) external view {
        require(trustedL1BlockNumber == l1header.number, 'Invalid L1 block number');

        // this computes the L1 header hash
        require(trustedL1BlockHash == keccak256(RLPWriter.writeList(l1header.header)), 'Invalid L1 block hash');

        // these two checks are here to verify that the "plain" (i.e. not RLP encoded) values in the l1header are
        // the same ones found in l1header.header (i.e. RLP encoded). This is because it is cheaper to RLP
        // encode that decode
        require(
            keccak256(RLPWriter.writeUint(l1header.number)) == keccak256(l1header.header[L1_NUMBER_INDEX]),
            'Invalid RLP encoded L1 block number'
        );
        require(
            keccak256(RLPWriter.writeBytes(abi.encode(l1header.stateRoot))) ==
                keccak256(l1header.header[L1_STATE_ROOT_INDEX]),
            'Invalid RLP encoded L1 state root'
        );

        //  stateAccount looks like this struct. We are interested in the Root field which is the one at index 2
        //  type StateAccount struct {
        //     Nonce    uint64       // index 0
        //     Balance  *big.Int     // index 1
        //     Root     common.Hash  // index 2
        //     CodeHash []byte       // index 3
        //  }
        RLPReader.RLPItem[] memory stateAccount = SecureMerkleTrie
            .get(abi.encodePacked(l2OutputOracleAddress), proof.accountProof, l1header.stateRoot)
            .toRLPItem()
            .readList();

        bytes memory outputRoot = SecureMerkleTrie.get(
            abi.encode(proof.l2OutputProposalKey),
            proof.outputRootProof,
            bytes32(bytes(stateAccount[2].readBytes()))
        );

        // now that the output root is verified, we need to verify the app hash. To do so we try to derive the
        // the output root the same way the proposer did.
        // See https://github.com/polymerdao/optimism/blob/polymer/v1.2.0/op-service/eth/output.go#L44
        require(
            keccak256(
                abi.encodePacked(
                    bytes32(0), // version
                    appHash,
                    bytes32(0), // message passer storage root.
                    proof.l2BlockHash
                )
            ) == bytes32(bytes(outputRoot.toRLPItem().readBytes())),
            'Invalid apphash'
        );
    }

    function verifyNonMembership(bytes32, bytes calldata, Ics23Proof calldata) external pure {
        revert('verifyNonMembership is not implemented');
    }

    /**
     * @dev verifies a chain of ICS23 proofs
     * Each computed subroot starting from index 0 must match the value of the next proof (hence chained proofs).
     * The cosmos SDK and ics23 support chained proofs to switch between different proof specs.
     * Custom proof specs are not supported here. Only Iavl and Tendermint or similar proof specs are supported.
     */
    function verifyMembership(
        bytes32 appHash,
        bytes calldata key,
        bytes calldata value,
        Ics23Proof calldata proofs
    ) external pure {
        // first check that the provided proof indeed proves the keys and values.
        require(keccak256(key) == keccak256(proofs.proof[0].key), 'Invalid proof key');
        require(keccak256(value) == keccak256(proofs.proof[0].value), 'Invalid proof value');
        // proofs are chained backwards. First proof in the list (proof[0]) corresponds to the packet proof, meaning
        // that can be checked against the next subroot value (i.e. ibc root). Once the first proof is verified,
        // we can check the second that corresponds to the ibc proof, that is checked against the app hash (app root)
        require(bytes32(proofs.proof[1].value) == verify(proofs.proof[0]), 'Invalid packet proof');
        require(appHash == verify(proofs.proof[1]), 'Invalid ibc state proof');
    }

    // this code was adapted from the ICS23 membership verification found here:
    // https://github.com/cosmos/ics23/blob/go/v0.10.0/go/ics23.go#L36
    function verify(OpIcs23Proof calldata proof) internal pure returns (bytes32) {
        bytes32 hashedData = sha256(proof.value);
        bytes32 computed = sha256(
            abi.encodePacked(
                proof.prefix,
                encodeVarint(proof.key.length),
                proof.key,
                encodeVarint(hashedData.length),
                hashedData
            )
        );

        for (uint256 i = 0; i < proof.path.length; i++) {
            computed = sha256(abi.encodePacked(proof.path[i].prefix, computed, proof.path[i].suffix));
        }

        return computed;
    }

    function encodeVarint(uint256 value) internal pure returns (bytes memory) {
        bytes memory result;
        while (value >= 0x80) {
            bytes.concat(result, bytes1(uint8((value & 0x7F) | 0x80)));
            value >>= 7;
        }
        return bytes.concat(result, bytes1(uint8(value)));
    }
}
