

L1RPC='https://eth-sepolia.g.alchemy.com/v2/nQBLX8FnrRZoqSQeySHwlDbmPnOmCSVe'
L2OOADDR='0x5cA3f8919DF7d82Bf51a672B7D73Ec13a2705dDb'
SLOT_INDEX='0x3'

# Slot index of the output proposal within the output proposal list is calculated as follows:
# OUTPUT_PROPOSAL_SLOT_INDEX = keccak( bytes32( SLOT_INDEX ) ) + ( OUTPUT_PROPOSAL_INDEX * OUTPUT_PROPOSAL_SIZE)
#
# - SLOT_INDEX is 0x3
# - OUTPUT_PROPOSAL_INDEX is the element index within the list of proposals. Something the user needs to provide
# - OUTPUT_PROPOSAL_SIZE is the size of the OutputProposal struct in bytes32 words. Looking at the smart contract that
#   defines (https://github.com/polymerdao/optimism/blob/develop/packages/contracts-bedrock/src/libraries/Types.sol#L13)
#   we can see this is 2 bytes32 words
#
# Putting it together we have:
#
# OUTPUT_PROPOSAL_SLOT_INDEX = \
# 	keccak( 0x0000000000000000000000000000000000000000000000000000000000000003 ) + \
# 	( OUTPUT_PROPOSAL_INDEX * 2 )
#
OUTPUT_PROPOSAL_INDEX='0x9'
L1_BLOCK_HEIGHT='0x4df537' #'5109047'
BASE_SLOT_HASH="$( cast keccak "$( printf '0x%064x' "$SLOT_INDEX" )"  )"
OUTPUT_PROPOSAL_SLOT_INDEX="$( python3 -c "print(hex($BASE_SLOT_HASH + ($OUTPUT_PROPOSAL_INDEX * 2)))" )"

curl "$L1RPC" -s -X POST  -H 'Content-Type: application/json' --data "$(
	jq -n --arg address "$L2OOADDR" --arg slot "$OUTPUT_PROPOSAL_SLOT_INDEX" --arg tag "$L1_BLOCK_HEIGHT" '{
		"jsonrpc":"2.0",
		"id":"1",
		"method":"eth_getProof",
		"params":[$address,[$slot],$tag]
	}'
)" > "output_at_block_l1_${L1_BLOCK_HEIGHT}_with_proof.json"

curl "$L1RPC" -s -X POST  -H 'Content-Type: application/json' --data "$(
	jq -n --arg tag "$L1_BLOCK_HEIGHT" '{
		"jsonrpc":"2.0",
		"id":"1",
		"method":"eth_getBlockByNumber",
		"params":[$tag,false]
	}'
)" > "l1_block_${L1_BLOCK_HEIGHT}.json"

# The storageProof.value value we get there should match the outputRoot being used here
# https://sepolia.etherscan.io/tx/0x8a8c03286c9da4c206386a4a567aceabfba2788419904bcb760ed68e1e48267e
# that is 0x69cf8daa7e45fae8ba4bae698652bdc45cbde62057e25e41addf9000a87a99c8
#
# From the same page we can get the L1 block hash (0x27627c02dd7c760bbec27c2d4087899663d151c1db4940acf9e530cf6fefc83a)
# so we can get the L1 state root.
#
# This is the block https://sepolia.etherscan.io/block/0x27627c02dd7c760bbec27c2d4087899663d151c1db4940acf9e530cf6fefc83a
# and this is the state root 0x86f3b255f8b02accde34a0f7ecf3507bf8c95942e5cf311413811fa31f294886
#

# need to set up port forwarding to use this. See 'just forward-peptide-ports' from infra repo
L2RPC='localhost:8545'
L2_BLOCK_HEIGHT='0x4b0'

curl -s "$L2RPC" -X POST -H 'Content-Type: application/json' --data "$(
	jq -n --arg tag "$L2_BLOCK_HEIGHT" '{
		"jsonrpc":"2.0",
		"id":"1",
		"method":"eth_getBlockByNumber",
		"params":[$tag,false]
	}'
)" > "l2_block_${L2_BLOCK_HEIGHT}.json"
