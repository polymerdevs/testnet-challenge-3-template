const BN = web3.utils.BN;
const protobuf = require("protobufjs/light");

const TestFixture = artifacts.require("TestFixture");

contract("protobufjs", async (accounts) => {
  describe("protobufjs", async () => {
    it("protobufjs encoding", async () => {
      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
      const message = Message.create({ field: 300 });
      const encoded = Message.encode(message).finish().toString("hex");

      // field 1 -> 08
      // 300 -> ac 02
      assert.equal(encoded, "08ac02");
    });

    it("protobufjs not bijective", async () => {
      // Show protobufjs is not bijective
      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
      const decoded = Message.decode(Buffer.from("08FFFFFFFFFFFFFFFFFF7F", "hex"));
      const field = decoded.toJSON().field;

      assert.equal(field, "18446744073709551615");
    });

    it("protobufjs accepts extra bytes", async () => {
      // Show protobufjs accepts up to 8 bytes for 4-byte ints
      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint32"));
      const decoded = Message.decode(Buffer.from("08FFFFFFFFFFFFFFFFFF01", "hex"));
      const field = decoded.toJSON().field;

      assert.equal(field, "4294967295");
    });
  });
});

contract("TestFixture", async (accounts) => {
  describe("constructor", async () => {
    it("should deploy", async () => {
      await TestFixture.new();
    });
  });

  //////////////////////////////////////
  // NOTICE
  // Tests call functions twice, once to run and another to measure gas.
  //////////////////////////////////////

  describe("decode", async () => {
    describe("passing", async () => {
      it("varint", async () => {
        const instance = await TestFixture.new();

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
        const message = Message.create({ field: 300 });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_varint.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, 3);
        assert.equal(val, 300);

        await instance.decode_varint(1, "0x" + encoded);
      });

      it("key", async () => {
        const instance = await TestFixture.new();

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 2, "uint64"));
        const message = Message.create({ field: 3 });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_key.call(0, "0x" + encoded);
        const { 0: success, 1: pos, 2: field, 3: type } = result;
        assert.equal(success, true);
        assert.equal(pos, 1);
        assert.equal(field, 2);
        assert.equal(type, 0);

        await instance.decode_key(0, "0x" + encoded);
      });

      it("int32 positive", async () => {
        const instance = await TestFixture.new();

        const v = 300;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_int32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_int32(1, "0x" + encoded);
      });

      it("int32 negative", async () => {
        const instance = await TestFixture.new();

        const v = -300;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_int32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_int32(1, "0x" + encoded);
      });

      it("int32 max", async () => {
        const instance = await TestFixture.new();

        const v = 2147483647;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_int32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_int32(1, "0x" + encoded);
      });

      it("int32 min", async () => {
        const instance = await TestFixture.new();

        const v = -2147483648;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_int32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_int32(1, "0x" + encoded);
      });

      it("uint32", async () => {
        const instance = await TestFixture.new();

        const v = 300;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_uint32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_uint32(1, "0x" + encoded);
      });

      it("uint32 max", async () => {
        const instance = await TestFixture.new();

        const v = 4294967295;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_uint32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_uint32(1, "0x" + encoded);
      });

      it("uint64", async () => {
        const instance = await TestFixture.new();

        const v = "4294967296";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_uint64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_uint64(1, "0x" + encoded);
      });

      it("uint64 max", async () => {
        const instance = await TestFixture.new();

        const v = "18446744073709551615";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_uint64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos.toNumber(), encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_uint64(1, "0x" + encoded);
      });

      it("int64 max", async () => {
        const instance = await TestFixture.new();

        const v = "9223372036854775807";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_int64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_int64(1, "0x" + encoded);
      });

      it("int64 min", async () => {
        const instance = await TestFixture.new();

        const v = "-9223372036854775808";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_int64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_int64(1, "0x" + encoded);
      });

      it("sint32 max", async () => {
        const instance = await TestFixture.new();

        const v = 2147483647;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sint32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_sint32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_sint32(1, "0x" + encoded);
      });

      it("sint32 min", async () => {
        const instance = await TestFixture.new();

        const v = -2147483648;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sint32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_sint32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_sint32(1, "0x" + encoded);
      });

      it("sint64 max", async () => {
        const instance = await TestFixture.new();

        const v = "9223372036854775807";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sint64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_sint64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_sint64(1, "0x" + encoded);
      });

      it("sint64 min", async () => {
        const instance = await TestFixture.new();

        const v = "-9223372036854775808";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sint64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_sint64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_sint64(1, "0x" + encoded);
      });

      it("bool true", async () => {
        const instance = await TestFixture.new();

        const v = true;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "bool"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_bool.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_bool(1, "0x" + encoded);
      });

      it("bool false", async () => {
        const instance = await TestFixture.new();

        const v = false;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "bool"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_bool.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_bool(1, "0x" + encoded);
      });

      it("enum", async () => {
        const instance = await TestFixture.new();

        const EnumStruct = {
          ONE: 1,
          TWO: 2,
          THREE: 3,
        };

        const v = EnumStruct.THREE;

        const Message = new protobuf.Type("Message")
          .add(new protobuf.Field("field", 1, "bool"))
          .add(new protobuf.Field("field2", 2, "Enum"))
          .add(new protobuf.Enum("Enum", EnumStruct));
        const message = Message.create({ field: 1, field2: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_enum.call(3, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_enum(3, "0x" + encoded);
      });

      it("bits64", async () => {
        const instance = await TestFixture.new();

        const v = "4294967296";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "fixed64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_bits64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_bits64(1, "0x" + encoded);
      });

      it("fixed64", async () => {
        const instance = await TestFixture.new();

        const v = "4294967296";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "fixed64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_fixed64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_fixed64(1, "0x" + encoded);
      });

      it("sfixed64 max", async () => {
        const instance = await TestFixture.new();

        const v = "9223372036854775807";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sfixed64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_sfixed64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_sfixed64(1, "0x" + encoded);
      });

      it("sfixed64 min", async () => {
        const instance = await TestFixture.new();

        const v = "-9223372036854775808";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sfixed64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_sfixed64.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_sfixed64(1, "0x" + encoded);
      });

      it("bits32", async () => {
        const instance = await TestFixture.new();

        const v = 300;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "fixed32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_bits32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_bits32(1, "0x" + encoded);
      });

      it("fixed32", async () => {
        const instance = await TestFixture.new();

        const v = 300;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "fixed32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_fixed32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_fixed32(1, "0x" + encoded);
      });

      it("sfixed32 max", async () => {
        const instance = await TestFixture.new();

        const v = 2147483647;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sfixed32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_sfixed32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_sfixed32(1, "0x" + encoded);
      });

      it("sfixed32 min", async () => {
        const instance = await TestFixture.new();

        const v = -2147483648;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sfixed32"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_sfixed32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_sfixed32(1, "0x" + encoded);
      });

      it("length-delimited", async () => {
        const instance = await TestFixture.new();

        const v = Buffer.from("deadbeef", "hex");

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "bytes"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_length_delimited.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, 2);
        assert.equal(val, encoded.length / 2 - 2);

        await instance.decode_length_delimited(1, "0x" + encoded);
      });

      it("string", async () => {
        const instance = await TestFixture.new();

        const v = "foobar";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "string"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_string.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, encoded.length / 2);
        assert.equal(val, v);

        await instance.decode_string(1, "0x" + encoded);
      });

      it("bytes", async () => {
        const instance = await TestFixture.new();

        const v = Buffer.from("deadbeef", "hex");

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "bytes"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_bytes.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, 2);
        assert.equal(val, encoded.length / 2 - 2);

        await instance.decode_bytes(1, "0x" + encoded);
      });

      it("embedded message", async () => {
        const instance = await TestFixture.new();

        const v = 300;

        const EmbeddedMessage = new protobuf.Type("EmbeddedMessage").add(new protobuf.Field("field", 1, "uint64"));
        const embeddedMessage = EmbeddedMessage.create({ field: 300 });

        const Message = new protobuf.Type("Message")
          .add(new protobuf.Field("field", 1, "EmbeddedMessage"))
          .add(EmbeddedMessage);
        const message = Message.create({ field: embeddedMessage });

        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_embedded_message.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, 2);
        assert.equal(val, encoded.length / 2 - 2);

        await instance.decode_embedded_message(1, "0x" + encoded);
      });

      it("packed repeated", async () => {
        const instance = await TestFixture.new();

        const v = [300, 42, 69];

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64", "repeated"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_packed_repeated.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, true);
        assert.equal(pos, 2);
        assert.equal(val, encoded.length / 2 - 2);

        await instance.decode_packed_repeated(1, "0x" + encoded);
      });
    });

    describe("failing", async () => {
      it("uint32 too large", async () => {
        const instance = await TestFixture.new();

        const v = "4294967296";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_uint32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("uint64 too large", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_uint64.call(0, "0xFFFFFFFFFFFFFFFFFFFF01");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("key varint invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_key.call(0, "0xFFFFFFFFFFFFFFFFFFFFF1");
        const { 0: success, 1: pos, 2: field, 3: type } = result;
        assert.equal(success, false);
      });

      it("key wire type invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_key.call(0, "0x0F");
        const { 0: success, 1: pos, 2: field, 3: type } = result;
        assert.equal(success, false);
      });

      it("key wire type start group", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_key.call(0, "0x03");
        const { 0: success, 1: pos, 2: field, 3: type } = result;
        assert.equal(success, false);
      });

      it("key wire type end group", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_key.call(0, "0x04");
        const { 0: success, 1: pos, 2: field, 3: type } = result;
        assert.equal(success, false);
      });

      it("varint index out of bounds", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_varint.call(0, "0x80");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("varint trailing zeroes", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_varint.call(0, "0x8000");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("varint more than 64 bits", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_varint.call(0, "0xFFFFFFFFFFFFFFFFFF7F");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("int32 varint invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_int32.call(0, "0xFFFFFFFFFFFFFFFFFFFFF1");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("int32 high bytes nonzero", async () => {
        const instance = await TestFixture.new();

        const v = "4294967296";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_int32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("int64 varint invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_int64.call(0, "0xFFFFFFFFFFFFFFFFFFFFF1");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("uint32 varint invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_uint32.call(0, "0xFFFFFFFFFFFFFFFFFFFFF1");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("sint32 varint invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_sint32.call(0, "0xFFFFFFFFFFFFFFFFFFFFF1");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("sint32 high bytes nonzero", async () => {
        const instance = await TestFixture.new();

        const v = "4294967296";

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_sint32.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("sint64 varint invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_sint64.call(0, "0xFFFFFFFFFFFFFFFFFFFFF1");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("bool varint invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_bool.call(0, "0xFFFFFFFFFFFFFFFFFFFFF1");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("bool not 0 or 1", async () => {
        const instance = await TestFixture.new();

        const v = 2;

        const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
        const message = Message.create({ field: v });
        const encoded = Message.encode(message).finish().toString("hex");

        const result = await instance.decode_bool.call(1, "0x" + encoded);
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("bits64 too short", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_bits64.call(0, "0x00");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("fixed64 bits64 invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_fixed64.call(0, "0x00");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("sfixed64 bits64 invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_sfixed64.call(0, "0x00");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("bits32 too short", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_bits32.call(0, "0x00");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("fixed32 bits32 invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_fixed32.call(0, "0x00");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("sfixed32 bits32 invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_sfixed32.call(0, "0x00");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("length-delimited varint invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_length_delimited.call(0, "0xFFFFFFFFFFFFFFFFFFFFF1");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("length-delimited out of bounds", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_length_delimited.call(0, "0xAC02");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("string length-delimited invalid", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_string.call(0, "0xFFFFFFFFFFFFFFFFFFFFF1");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });

      it("length-delimited overflow", async () => {
        const instance = await TestFixture.new();

        const result = await instance.decode_length_delimited.call(0, "0xFFFFFFFFFFFFFFFFFF01");
        const { 0: success, 1: pos, 2: val } = result;
        assert.equal(success, false);
      });
    });
  });

  describe("encode", async () => {
    it("varint", async () => {
      const instance = await TestFixture.new();

      const v = 300;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_varint.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_varint(v);
    });

    it("key", async () => {
      const instance = await TestFixture.new();

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 2, "uint64"));
      const message = Message.create({ field: 1 });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_key.call(2, 0);
      assert.equal(result, "0x" + encoded.slice(0, 2));

      await instance.encode_key(2, 0);
    });

    it("int32 positive", async () => {
      const instance = await TestFixture.new();

      const v = 300;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_int32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_int32(v);
    });

    it("int32 negative", async () => {
      const instance = await TestFixture.new();

      const v = -300;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_int32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_int32(v);
    });

    it("int32 max", async () => {
      const instance = await TestFixture.new();

      const v = 2147483647;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_int32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_int32(v);
    });

    it("int32 min", async () => {
      const instance = await TestFixture.new();

      const v = -2147483648;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_int32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_int32(v);
    });

    it("uint32", async () => {
      const instance = await TestFixture.new();

      const v = 300;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_uint32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_uint32(v);
    });

    it("uint32 max", async () => {
      const instance = await TestFixture.new();

      const v = 4294967295;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_uint32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_uint32(v);
    });

    it("uint64", async () => {
      const instance = await TestFixture.new();

      const v = "4294967296";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_uint64.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_uint64(v);
    });

    it("uint64 max", async () => {
      const instance = await TestFixture.new();

      const v = "18446744073709551615";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_uint64.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_uint64(v);
    });

    it("int64 max", async () => {
      const instance = await TestFixture.new();

      const v = "9223372036854775807";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_int64.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_int64(v);
    });

    it("int64 min", async () => {
      const instance = await TestFixture.new();

      const v = "-9223372036854775808";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "int64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_int64.call(new BN(v));
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_int64(new BN(v));
    });

    it("sint32 max", async () => {
      const instance = await TestFixture.new();

      const v = 2147483647;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sint32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_sint32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_sint32(v);
    });

    it("sint32 min", async () => {
      const instance = await TestFixture.new();

      const v = -2147483648;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sint32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_sint32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_sint32(v);
    });

    it("sint64 max", async () => {
      const instance = await TestFixture.new();

      const v = "9223372036854775807";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sint64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_sint64.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_sint64(v);
    });

    it("sint64 min", async () => {
      const instance = await TestFixture.new();

      const v = "-9223372036854775808";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sint64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_sint64.call(new BN(v));
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_sint64(new BN(v));
    });

    it("bool true", async () => {
      const instance = await TestFixture.new();

      const v = true;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "bool"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_bool.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_bool(v);
    });

    it("bool false", async () => {
      const instance = await TestFixture.new();

      const v = false;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "bool"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_bool.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_bool(v);
    });

    it("enum", async () => {
      const instance = await TestFixture.new();

      const EnumStruct = {
        ONE: 1,
        TWO: 2,
        THREE: 3,
      };

      const v = EnumStruct.THREE;

      const Message = new protobuf.Type("Message")
        .add(new protobuf.Field("field", 1, "bool"))
        .add(new protobuf.Field("field2", 2, "Enum"))
        .add(new protobuf.Enum("Enum", EnumStruct));
      const message = Message.create({ field: 1, field2: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_enum.call(v);
      assert.equal(result, "0x" + encoded.slice(6));

      await instance.encode_enum(v);
    });

    it("bits64", async () => {
      const instance = await TestFixture.new();

      const v = "4294967296";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "fixed64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_bits64.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_bits64(v);
    });

    it("fixed64", async () => {
      const instance = await TestFixture.new();

      const v = "4294967296";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "fixed64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_fixed64.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_fixed64(v);
    });

    it("sfixed64 max", async () => {
      const instance = await TestFixture.new();

      const v = "9223372036854775807";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sfixed64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_sfixed64.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_sfixed64(v);
    });

    it("sfixed64 min", async () => {
      const instance = await TestFixture.new();

      const v = "-9223372036854775808";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sfixed64"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_sfixed64.call(new BN(v));
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_sfixed64(new BN(v));
    });

    it("bits32", async () => {
      const instance = await TestFixture.new();

      const v = 300;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "fixed32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_bits32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_bits32(v);
    });

    it("fixed32", async () => {
      const instance = await TestFixture.new();

      const v = 300;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "fixed32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_fixed32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_fixed32(v);
    });

    it("sfixed32 max", async () => {
      const instance = await TestFixture.new();

      const v = 2147483647;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sfixed32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_sfixed32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_sfixed32(v);
    });

    it("sfixed32 min", async () => {
      const instance = await TestFixture.new();

      const v = -2147483648;

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "sfixed32"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_sfixed32.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_sfixed32(v);
    });

    it("length-delimited", async () => {
      const instance = await TestFixture.new();

      const v = Buffer.from("deadbeef", "hex");

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "bytes"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_length_delimited.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_length_delimited(v);
    });

    it("string", async () => {
      const instance = await TestFixture.new();

      const v = "foobar";

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "string"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_string.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_string(v);
    });

    it("bytes", async () => {
      const instance = await TestFixture.new();

      const v = Buffer.from("deadbeef", "hex");

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "bytes"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_bytes.call(v);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_bytes(v);
    });

    it("embedded message", async () => {
      const instance = await TestFixture.new();

      const v = 300;

      const EmbeddedMessage = new protobuf.Type("EmbeddedMessage").add(new protobuf.Field("field", 1, "uint64"));
      const embeddedMessage = EmbeddedMessage.create({ field: 300 });

      const encodedEmbeddedMessage = EmbeddedMessage.encode(embeddedMessage).finish().toString("hex");

      const Message = new protobuf.Type("Message")
        .add(new protobuf.Field("field", 1, "EmbeddedMessage"))
        .add(EmbeddedMessage);
      const message = Message.create({ field: embeddedMessage });

      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_embedded_message.call("0x" + encodedEmbeddedMessage);
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_embedded_message("0x" + encodedEmbeddedMessage);
    });

    it("packed repeated", async () => {
      const instance = await TestFixture.new();

      const v = [300, 42, 69];

      const Message = new protobuf.Type("Message").add(new protobuf.Field("field", 1, "uint64", "repeated"));
      const message = Message.create({ field: v });
      const encoded = Message.encode(message).finish().toString("hex");

      const result = await instance.encode_packed_repeated.call("0x" + encoded.slice(4));
      assert.equal(result, "0x" + encoded.slice(2));

      await instance.encode_packed_repeated("0x" + encoded.slice(4));
    });
  });
});
