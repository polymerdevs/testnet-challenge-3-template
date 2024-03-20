// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.4 <0.9.0;

import "./ProtobufLib.sol";

contract TestFixture {
    // Functions are not pure so that we can measure gas

    function decode_key(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint64,
            ProtobufLib.WireType
        )
    {
        return ProtobufLib.decode_key(p, buf);
    }

    function decode_varint(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return ProtobufLib.decode_varint(p, buf);
    }

    function decode_int32(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        return ProtobufLib.decode_int32(p, buf);
    }

    function decode_int64(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        return ProtobufLib.decode_int64(p, buf);
    }

    function decode_uint32(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        return ProtobufLib.decode_uint32(p, buf);
    }

    function decode_uint64(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return ProtobufLib.decode_uint64(p, buf);
    }

    function decode_sint32(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        return ProtobufLib.decode_sint32(p, buf);
    }

    function decode_sint64(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        return ProtobufLib.decode_sint64(p, buf);
    }

    function decode_bool(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            bool
        )
    {
        return ProtobufLib.decode_bool(p, buf);
    }

    function decode_enum(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        return ProtobufLib.decode_enum(p, buf);
    }

    function decode_bits64(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return ProtobufLib.decode_bits64(p, buf);
    }

    function decode_fixed64(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return ProtobufLib.decode_fixed64(p, buf);
    }

    function decode_sfixed64(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        return ProtobufLib.decode_sfixed64(p, buf);
    }

    function decode_bits32(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        return ProtobufLib.decode_bits32(p, buf);
    }

    function decode_fixed32(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        return ProtobufLib.decode_fixed32(p, buf);
    }

    function decode_sfixed32(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        return ProtobufLib.decode_sfixed32(p, buf);
    }

    function decode_length_delimited(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return ProtobufLib.decode_length_delimited(p, buf);
    }

    function decode_string(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            string memory
        )
    {
        return ProtobufLib.decode_string(p, buf);
    }

    function decode_bytes(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return ProtobufLib.decode_bytes(p, buf);
    }

    function decode_embedded_message(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return ProtobufLib.decode_embedded_message(p, buf);
    }

    function decode_packed_repeated(uint64 p, bytes memory buf)
        public
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return ProtobufLib.decode_packed_repeated(p, buf);
    }

    function encode_key(uint64 field_number, uint64 wire_type) public pure returns (bytes memory) {
        return ProtobufLib.encode_key(field_number, wire_type);
    }

    function encode_varint(uint64 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_varint(n);
    }

    function encode_int32(int32 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_int32(n);
    }

    function encode_int64(int64 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_int64(n);
    }

    function encode_uint32(uint32 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_uint32(n);
    }

    function encode_uint64(uint64 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_uint64(n);
    }

    function encode_sint32(int32 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_sint32(n);
    }

    function encode_sint64(int64 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_sint64(n);
    }

    function encode_bool(bool b) public pure returns (bytes memory) {
        return ProtobufLib.encode_bool(b);
    }

    function encode_enum(int32 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_enum(n);
    }

    function encode_bits64(uint64 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_bits64(n);
    }

    function encode_fixed64(uint64 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_fixed64(n);
    }

    function encode_sfixed64(int64 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_sfixed64(n);
    }

    function encode_bits32(uint32 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_bits32(n);
    }

    function encode_fixed32(uint32 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_fixed32(n);
    }

    function encode_sfixed32(int32 n) public pure returns (bytes memory) {
        return ProtobufLib.encode_sfixed32(n);
    }

    function encode_length_delimited(bytes memory b) public pure returns (bytes memory) {
        return ProtobufLib.encode_length_delimited(b);
    }

    function encode_string(string memory s) public pure returns (bytes memory) {
        return ProtobufLib.encode_string(s);
    }

    function encode_bytes(bytes memory b) public pure returns (bytes memory) {
        return ProtobufLib.encode_bytes(b);
    }

    function encode_embedded_message(bytes memory m) public pure returns (bytes memory) {
        return ProtobufLib.encode_embedded_message(m);
    }

    function encode_packed_repeated(bytes memory b) public pure returns (bytes memory) {
        return ProtobufLib.encode_packed_repeated(b);
    }
}
