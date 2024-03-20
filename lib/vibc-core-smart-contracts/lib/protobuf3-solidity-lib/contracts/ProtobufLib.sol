// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.4 <0.9.0;

library ProtobufLib {
    /// @notice Protobuf wire types.
    enum WireType {
        Varint,
        Bits64,
        LengthDelimited,
        StartGroup,
        EndGroup,
        Bits32,
        WIRE_TYPE_MAX
    }

    /// @dev Maximum number of bytes for a varint.
    /// @dev 64 bits, in groups of base-128 (7 bits).
    uint64 internal constant MAX_VARINT_BYTES = 10;

    ////////////////////////////////////
    // Decoding
    ////////////////////////////////////

    /// @notice Decode key.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#structure
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Field number
    /// @return Wire type
    function decode_key(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64,
            WireType
        )
    {
        // The key is a varint with encoding
        // (field_number << 3) | wire_type
        (bool success, uint64 pos, uint64 key) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0, WireType.WIRE_TYPE_MAX);
        }

        uint64 field_number = key >> 3;
        uint64 wire_type_val = key & 0x07;
        // Check that wire type is bounded
        if (wire_type_val >= uint64(WireType.WIRE_TYPE_MAX)) {
            return (false, pos, 0, WireType.WIRE_TYPE_MAX);
        }
        WireType wire_type = WireType(wire_type_val);

        // Start and end group types are deprecated, so forbid them
        if (wire_type == WireType.StartGroup || wire_type == WireType.EndGroup) {
            return (false, pos, 0, WireType.WIRE_TYPE_MAX);
        }

        return (true, pos, field_number, wire_type);
    }

    /// @notice Decode varint.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#varints
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_varint(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        uint64 val;
        uint64 i;

        for (i = 0; i < MAX_VARINT_BYTES; i++) {
            // Check that index is within bounds
            if (i + p >= buf.length) {
                return (false, p, 0);
            }

            // Get byte at offset
            uint8 b = uint8(buf[p + i]);

            // Highest bit is used to indicate if there are more bytes to come
            // Mask to get 7-bit value: 0111 1111
            uint8 v = b & 0x7F;

            // Groups of 7 bits are ordered least significant first
            val |= uint64(v) << uint64(i * 7);

            // Mask to get keep going bit: 1000 0000
            if (b & 0x80 == 0) {
                // [STRICT]
                // Check for trailing zeroes if more than one byte is used
                // (the value 0 still uses one byte)
                if (i > 0 && v == 0) {
                    return (false, p, 0);
                }

                break;
            }
        }

        // Check that at most MAX_VARINT_BYTES are used
        if (i >= MAX_VARINT_BYTES) {
            return (false, p, 0);
        }

        // [STRICT]
        // If all 10 bytes are used, the last byte (most significant 7 bits)
        // must be at most 0000 0001, since 7*9 = 63
        if (i == MAX_VARINT_BYTES - 1) {
            if (uint8(buf[p + i]) > 1) {
                return (false, p, 0);
            }
        }

        return (true, p + i + 1, val);
    }

    /// @notice Decode varint int32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_int32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // [STRICT]
        // Highest 4 bytes must be 0 if positive
        if (val >> 63 == 0) {
            if (val & 0xFFFFFFFF00000000 != 0) {
                return (false, pos, 0);
            }
        }

        return (true, pos, int32(uint32(val)));
    }

    /// @notice Decode varint int64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_int64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, int64(val));
    }

    /// @notice Decode varint uint32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_uint32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // [STRICT]
        // Highest 4 bytes must be 0
        if (val & 0xFFFFFFFF00000000 != 0) {
            return (false, pos, 0);
        }

        return (true, pos, uint32(val));
    }

    /// @notice Decode varint uint64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_uint64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, val);
    }

    /// @notice Decode varint sint32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_sint32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // [STRICT]
        // Highest 4 bytes must be 0
        if (val & 0xFFFFFFFF00000000 != 0) {
            return (false, pos, 0);
        }

        // https://stackoverflow.com/questions/2210923/zig-zag-decoding/2211086#2211086
        uint64 zigzag_val;
        unchecked {
            zigzag_val = (val >> 1) - (~(val & 1) + 1);
        }

        return (true, pos, int32(uint32(zigzag_val)));
    }

    /// @notice Decode varint sint64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_sint64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // https://stackoverflow.com/questions/2210923/zig-zag-decoding/2211086#2211086
        uint64 zigzag_val;
        unchecked {
            zigzag_val = (val >> 1) - (~(val & 1) + 1);
        }

        return (true, pos, int64(zigzag_val));
    }

    /// @notice Decode Boolean.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded bool
    function decode_bool(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            bool
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, false);
        }

        // [STRICT]
        // Value must be 0 or 1
        if (val > 1) {
            return (false, pos, false);
        }

        if (val == 0) {
            return (true, pos, false);
        }

        return (true, pos, true);
    }

    /// @notice Decode enumeration.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded enum as raw int
    function decode_enum(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        return decode_int32(p, buf);
    }

    /// @notice Decode fixed 64-bit int.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_bits64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        uint64 val;

        // Check that index is within bounds
        if (8 + p > buf.length) {
            return (false, p, 0);
        }

        for (uint64 i = 0; i < 8; i++) {
            uint8 b = uint8(buf[p + i]);

            // Little endian
            val |= uint64(b) << uint64(i * 8);
        }

        return (true, p + 8, val);
    }

    /// @notice Decode fixed uint64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_fixed64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_bits64(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, val);
    }

    /// @notice Decode fixed int64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_sfixed64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_bits64(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, int64(val));
    }

    /// @notice Decode fixed 32-bit int.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_bits32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        uint32 val;

        // Check that index is within bounds
        if (4 + p > buf.length) {
            return (false, p, 0);
        }

        for (uint64 i = 0; i < 4; i++) {
            uint8 b = uint8(buf[p + i]);

            // Little endian
            val |= uint32(b) << uint32(i * 8);
        }

        return (true, p + 4, val);
    }

    /// @notice Decode fixed uint32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_fixed32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        (bool success, uint64 pos, uint32 val) = decode_bits32(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, val);
    }

    /// @notice Decode fixed int32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_sfixed32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        (bool success, uint64 pos, uint32 val) = decode_bits32(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, int32(val));
    }

    /// @notice Decode length-delimited field.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_length_delimited(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        // Length-delimited fields begin with a varint of the number of bytes that follow
        (bool success, uint64 pos, uint64 size) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // Check for overflow
        unchecked {
            if (pos + size < pos) {
                return (false, pos, 0);
            }
        }

        // Check that index is within bounds
        if (size + pos > buf.length) {
            return (false, pos, 0);
        }

        return (true, pos, size);
    }

    /// @notice Decode string.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Size in bytes
    function decode_string(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            string memory
        )
    {
        (bool success, uint64 pos, uint64 size) = decode_length_delimited(p, buf);
        if (!success) {
            return (false, pos, "");
        }

        bytes memory field = new bytes(size);
        for (uint64 i = 0; i < size; i++) {
            field[i] = buf[pos + i];
        }

        return (true, pos + size, string(field));
    }

    /// @notice Decode bytes array.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_bytes(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return decode_length_delimited(p, buf);
    }

    /// @notice Decode embedded message.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_embedded_message(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return decode_length_delimited(p, buf);
    }

    /// @notice Decode packed repeated field.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_packed_repeated(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return decode_length_delimited(p, buf);
    }

    ////////////////////////////////////
    // Encoding
    ////////////////////////////////////

    /// @notice Encode key.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#structure
    /// @param field_number Field number
    /// @param wire_type Wire type
    /// @return Marshaled bytes
    function encode_key(uint64 field_number, uint64 wire_type) internal pure returns (bytes memory) {
        uint64 key = (field_number << 3) | wire_type;

        bytes memory buf = encode_varint(key);

        return buf;
    }

    /// @notice Encode varint.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#varints
    /// @param n Number
    /// @return Marshaled bytes
    function encode_varint(uint64 n) internal pure returns (bytes memory) {
        // Count the number of groups of 7 bits
        // We need this pre-processing step since Solidity doesn't allow dynamic memory resizing
        uint64 tmp = n;
        uint64 num_bytes = 1;
        while (tmp > 0x7F) {
            tmp = tmp >> 7;
            num_bytes += 1;
        }

        bytes memory buf = new bytes(num_bytes);

        tmp = n;
        for (uint64 i = 0; i < num_bytes; i++) {
            // Set the first bit in the byte for each group of 7 bits
            buf[i] = bytes1(0x80 | uint8(tmp & 0x7F));
            tmp = tmp >> 7;
        }
        // Unset the first bit of the last byte
        buf[num_bytes - 1] &= 0x7F;

        return buf;
    }

    /// @notice Encode varint int32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_int32(int32 n) internal pure returns (bytes memory) {
        return encode_varint(uint64(int64(n)));
    }

    /// @notice Decode varint int64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_int64(int64 n) internal pure returns (bytes memory) {
        return encode_varint(uint64(n));
    }

    /// @notice Encode varint uint32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_uint32(uint32 n) internal pure returns (bytes memory) {
        return encode_varint(n);
    }

    /// @notice Encode varint uint64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_uint64(uint64 n) internal pure returns (bytes memory) {
        return encode_varint(n);
    }

    /// @notice Encode varint sint32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sint32(int32 n) internal pure returns (bytes memory) {
        // https://developers.google.com/protocol-buffers/docs/encoding#signed_integers
        uint32 mask = 0;
        if (n < 0) {
            unchecked {
                mask -= 1;
            }
        }
        uint32 zigzag_val = (uint32(n) << 1) ^ mask;

        return encode_varint(zigzag_val);
    }

    /// @notice Encode varint sint64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sint64(int64 n) internal pure returns (bytes memory) {
        // https://developers.google.com/protocol-buffers/docs/encoding#signed_integers
        uint64 mask = 0;
        if (n < 0) {
            unchecked {
                mask -= 1;
            }
        }
        uint64 zigzag_val = (uint64(n) << 1) ^ mask;

        return encode_varint(zigzag_val);
    }

    /// @notice Encode Boolean.
    /// @param b Boolean
    /// @return Marshaled bytes
    function encode_bool(bool b) internal pure returns (bytes memory) {
        uint64 n = b ? 1 : 0;

        return encode_varint(n);
    }

    /// @notice Encode enumeration.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_enum(int32 n) internal pure returns (bytes memory) {
        return encode_int32(n);
    }

    /// @notice Encode fixed 64-bit int.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_bits64(uint64 n) internal pure returns (bytes memory) {
        bytes memory buf = new bytes(8);

        uint64 tmp = n;
        for (uint64 i = 0; i < 8; i++) {
            // Little endian
            buf[i] = bytes1(uint8(tmp & 0xFF));
            tmp = tmp >> 8;
        }

        return buf;
    }

    /// @notice Encode fixed uint64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_fixed64(uint64 n) internal pure returns (bytes memory) {
        return encode_bits64(n);
    }

    /// @notice Encode fixed int64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sfixed64(int64 n) internal pure returns (bytes memory) {
        return encode_bits64(uint64(n));
    }

    /// @notice Decode fixed 32-bit int.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_bits32(uint32 n) internal pure returns (bytes memory) {
        bytes memory buf = new bytes(4);

        uint64 tmp = n;
        for (uint64 i = 0; i < 4; i++) {
            // Little endian
            buf[i] = bytes1(uint8(tmp & 0xFF));
            tmp = tmp >> 8;
        }

        return buf;
    }

    /// @notice Encode fixed uint32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_fixed32(uint32 n) internal pure returns (bytes memory) {
        return encode_bits32(n);
    }

    /// @notice Encode fixed int32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sfixed32(int32 n) internal pure returns (bytes memory) {
        return encode_bits32(uint32(n));
    }

    /// @notice Encode length-delimited field.
    /// @param b Bytes
    /// @return Marshaled bytes
    function encode_length_delimited(bytes memory b) internal pure returns (bytes memory) {
        // Length-delimited fields begin with a varint of the number of bytes that follow
        bytes memory length_buf = encode_uint64(uint64(b.length));
        bytes memory buf = new bytes(b.length + length_buf.length);

        for (uint64 i = 0; i < length_buf.length; i++) {
            buf[i] = length_buf[i];
        }

        for (uint64 i = 0; i < b.length; i++) {
            buf[i + length_buf.length] = b[i];
        }

        return buf;
    }

    /// @notice Encode string.
    /// @param s String
    /// @return Marshaled bytes
    function encode_string(string memory s) internal pure returns (bytes memory) {
        return encode_length_delimited(bytes(s));
    }

    /// @notice Encode bytes array.
    /// @param b Bytes
    /// @return Marshaled bytes
    function encode_bytes(bytes memory b) internal pure returns (bytes memory) {
        return encode_length_delimited(b);
    }

    /// @notice Encode embedded message.
    /// @param m Message
    /// @return Marshaled bytes
    function encode_embedded_message(bytes memory m) internal pure returns (bytes memory) {
        return encode_length_delimited(m);
    }

    /// @notice Encode packed repeated field.
    /// @param b Bytes
    /// @return Marshaled bytes
    function encode_packed_repeated(bytes memory b) internal pure returns (bytes memory) {
        return encode_length_delimited(b);
    }
}
