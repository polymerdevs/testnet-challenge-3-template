#!/usr/bin/env bash

set -euo pipefail

# before running this script, make sure to follow the readme file in the solidity-protobuf repo
# and install the dependencies

ROOT_DIR="$( realpath "$(dirname "$0")" )"
SOLIDITY_PROTOBUF_DIR="$ROOT_DIR/../../solidity-protobuf/"
PROTO_OUTDIR="$ROOT_DIR/../lib/proto"
SOLC_VERSION='0.8.15'

if [[ ! -d "$SOLIDITY_PROTOBUF_DIR" ]] ; then
	echo "Cannot find solidity protobuf code generator. Tried $SOLIDITY_PROTOBUF_DIR"
	echo "Clone the repo from: https://github.com/datachainlab/solidity-protobuf/"
	exit 1
fi

for F in "$ROOT_DIR"/*.proto; do
	if [[ ! -f "$F" ]]; then
		continue
	fi

	echo "Generating $F"
	protoc \
        	-I"$ROOT_DIR" \
		-I"$SOLIDITY_PROTOBUF_DIR/protobuf-solidity/src/protoc/include" \
		--plugin=protoc-gen-sol="$SOLIDITY_PROTOBUF_DIR/protobuf-solidity/src/protoc/plugin/gen_sol.py" \
		--sol_out="gen_runtime=./ProtoBufRuntime.sol&solc_version=$SOLC_VERSION:$PROTO_OUTDIR" \
		"$F"
done

# to run these, install prettier and the solidity plugin with
# npm install --global prettier prettier-plugin-solidity
for F in "$PROTO_OUTDIR"/*.sol; do
	prettier --config "$ROOT_DIR/../.prettierrc.yml" --write "$F"
done
