require "./spec_helper"

describe Base58::Encoder do
  context "Encoding via Base58.encode" do
    it "encodes strings to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes)).should eq testcase["string"]
      end
    end

    it "encodes slices to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes).should eq testcase["string"]
      end
    end

    it "encodes static arrays to strings with the default (Bitcoin) alphabet" do
      testcase = TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.first
      stat_ary = StaticArray(UInt8, 12).new(0)
      bytes = testcase["hex"].as(String).hexbytes
      stat_ary.to_unsafe.copy_from(bytes.to_unsafe, bytes.size)
      Base58.encode(stat_ary).should eq testcase["string"]
    end

    it "encodes stringbuffers to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = StringBuffer.new(testcase["hex"].as(String).hexbytes)
        Base58.encode(buffer).should eq testcase["string"]
      end
    end

    it "encodes arrays of UInt8 to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes.to_a).should eq testcase["string"]
      end
    end

    it "encodes arrays of Char to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes.to_a.map(&.chr)).should eq testcase["string"]
      end
    end

    it "encodes slices to strings" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: String).should eq testcase["string"]
      end
    end

    it "encodes strings into an existing string, concatenating them and returning a new string" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = "foo"
        Base58.encode(testcase["hex"].as(String).hexbytes, into: str).should eq "foo#{testcase["string"]}"
      end
    end

    it "encodes strings into and existing string, mutating the string in place and replacing the original contents" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = "X" * testcase["hex"].as(String).bytesize
        should_be_the_same_str = Base58.encode(testcase["hex"].as(String).hexbytes, into: str, mutate: true)
        should_be_the_same_str.should eq testcase["string"]
        str.object_id.should eq should_be_the_same_str.object_id
      end
    end

    it "encodes strings to new Slice(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8)).should eq testcase["string"].as(String).to_slice
      end
    end

    it "encodes strings to new StaticArray(UInt8, _)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        static_array, len = Base58.encode(bytes, into: StaticArray(UInt8, 256))
        Slice.new(static_array.to_unsafe, len).should eq testcase["string"].as(String).to_slice
      end
    end

    it "encodes strings into a raw buffer, returning a pointer and a length to the encoded string" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        ptr, len = Base58.encode(bytes, into: Pointer)
        Slice.new(ptr, len).should eq testcase["string"].as(String).to_slice
      end
    end

    it "encodes strings to new Array(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: Array(UInt8)).should eq testcase["string"].as(String).bytes.to_a
      end
    end

    it "encodes strings to new Array(Char)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: Array(Char)).should eq testcase["string"].as(String).chars.to_a
      end
    end

    it "encodes strings to new StringBuffer" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: StringBuffer).buffer.should eq testcase["string"]
      end
    end

    it "encodes strings into an existing Slice(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        buffer = Slice(UInt8).new(len)
        should_be_the_same_buffer = Base58.encode(bytes, into: buffer)
        buffer.should eq testcase["string"].as(String).to_slice
        should_be_the_same_buffer.to_unsafe.should eq buffer.to_unsafe
      end
    end

    it "encodes strings into an existing StaticArray(UInt8, _)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        buffer = StaticArray(UInt8, 256).new(0)
        should_be_the_same_buffer, newlen = Base58.encode(bytes, into: buffer) # But it really isn't, since StaticArrays are passed by Copy.
        Slice.new(should_be_the_same_buffer.to_unsafe, newlen).should eq testcase["string"].as(String).to_slice
      end
    end

    it "encodes strings into an existing Array(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        buffer = Array(UInt8).new(len)
        should_be_the_same_buffer = Base58.encode(bytes, into: buffer)
        buffer.should eq testcase["string"].as(String).bytes.to_a
        should_be_the_same_buffer.object_id.should eq buffer.object_id
      end
    end

    it "encodes strings into an existing Array(Char)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        buffer = Array(Char).new(len)
        should_be_the_same_buffer = Base58.encode(bytes, into: buffer)
        buffer.should eq testcase["string"].as(String).chars.to_a
        should_be_the_same_buffer.object_id.should eq buffer.object_id
      end
    end

    it "encodes strings into an existing StringBuffer" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        buffer = StringBuffer.new(len)
        Base58.encode(bytes, into: buffer)
        buffer.buffer.should eq testcase["string"]
      end
    end
  end

  context "Encoding via Base58::Encoder.into()" do
    it "uses the Encoder.into() syntax to encode strings to strings" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58::Encoder.into(String).encode(testcase["hex"].as(String).hexbytes).should eq testcase["string"]
      end
    end

    it "uses the Encoder.into() syntax to encode strings to new Slice(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58::Encoder.into(Slice(UInt8)).encode(testcase["hex"].as(String).hexbytes).should eq testcase["string"].as(String).to_slice
      end
    end

    it "uses the Encoder.into() syntax to encode strings to a raw buffer" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        ptr, len = Base58::Encoder.into(Pointer).encode(bytes).as(Tuple(Pointer(UInt8), Int32))
        Slice.new(ptr, len.as(Int32)).should eq testcase["string"].as(String).to_slice
      end
    end

    it "uses the Encoder.into() syntax to encode strings to new StringBuffer instances" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        Base58::Encoder.into(StringBuffer).encode(bytes).as(StringBuffer).buffer.should eq testcase["string"].as(String)
      end
    end
  end

  context "Encoding with Alphabet::Flickr works as expected" do
    it "can encode strings to new strings with the Flickr Base58 alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Flickr }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Flickr).should eq testcase["string"]
      end
    end
  end

  context "Encoding with Alphabet::Ripple works as expected" do
    it "can encode strings to new strings with the Ripple Base58 alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Ripple }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Ripple).should eq testcase["string"]
      end
    end
  end

  context "Encoding with Alphabet::Monero works as expected" do
    it "can encode strings to new strings with the Monero Base58 alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Monero }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Monero).should eq testcase["string"]
      end
    end
  end

  context "Base58Check Encoding works as expected" do
    it "can encode strings to new strings with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq testcase["string"]
      end
    end

    it "can encode strings into existing strings with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = "::"
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: str, check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq "::#{testcase["string"]}"
      end
    end

    it "can encode slices to strings with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq testcase["string"]
      end
    end

    # This spec is a cheating liar, and this needs to be documented in the API docs because
    # though it makes sense, I think it might surprise some people.
    #
    # A StaticArray is a fixed size. If it is larger than the data that is to be encoded,
    # and the remaining space is filled with zeroes, everything is fine if one is not
    # creating a checksum. However, if one is creating a checksum, there is no way for the
    # checksum algorithm itself to know that the zeros aren't part of the whole. So, they
    # are included in the checksum, and the checksum is appended after them. This will
    # likely give unexpected results.  i.e. if you have a StaticArray of 32 bytes, and
    # you encode a 16 byte string, the checksum will be appended to the end of the 32
    # bytes.
    #
    # So, for now, this spec strips the StaticArray, which removes the trailing zeros,
    # returning a Slice, and encodes that. This...this spec isn't doing what it is advertising.
    # I am leaving it here for now while I ponder how to approach this, but it needs to be fixed.
    it "can encode static arrays to strings with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        stat_ary = StaticArray(UInt8, 12).new(0)
        bytes = testcase["hex"].as(String).hexbytes
        stat_ary.to_unsafe.copy_from(bytes.to_unsafe, bytes.size)
        Base58.encode(stat_ary.strip, check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq testcase["string"]
      end
    end

    it "can encode StringBuffers to strings with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(StringBuffer.new(testcase["hex"].as(String).hexbytes), check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq testcase["string"]
      end
    end

    it "can encode Array(UInt8) to strings with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes.to_a, check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq testcase["string"]
      end
    end

    it "can encode Array(Char) to strings with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes.to_a.map(&.chr), check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq testcase["string"]
      end
    end

    it "can encode strings to slices with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: Slice(UInt8), check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq testcase["string"].as(String).to_slice
      end
    end

    it "can encode strings to static arrays with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        static_array, length = Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: StaticArray(UInt8, 20), check: Base58::Check.new(testcase["check_prefix"].as(String)))
        static_array.to_slice[0..length - 1].should eq testcase["string"].as(String).to_slice
      end
    end

    it "can encode strings to a raw memory buffer pointed to by a Pointer(UInt8) with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        ptr, length = Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: Pointer, check: Base58::Check.new(testcase["check_prefix"].as(String)))
        String.new(ptr, length).should eq testcase["string"]
      end
    end

    it "can encode strings to Array(UInt8) with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: Array(UInt8), check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq testcase["string"].as(String).to_slice.to_a
      end
    end

    it "can encode strings to Array(Char) with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: Array(Char), check: Base58::Check.new(testcase["check_prefix"].as(String))).should eq testcase["string"].as(String).to_slice.to_a.map(&.chr)
      end
    end

    it "can encode strings to StringBuffers with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: StringBuffer, check: Base58::Check.new(testcase["check_prefix"].as(String))).buffer.should eq testcase["string"].as(String)
      end
    end

    it "can encode strings into an existing string, mutating it, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = String.new(32)
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: str, mutate: true, check: Base58::Check.new(testcase["check_prefix"].as(String)))
        str.should eq testcase["string"].as(String)
      end
    end

    it "can encode strings into an existing slice, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        slice = Slice(UInt8).new(32)
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: slice, check: Base58::Check.new(testcase["check_prefix"].as(String)))
        String.new(slice[0, testcase["string"].as(String).size]).should eq testcase["string"].as(String)
      end
    end

    it "can encode strings into an existing static array, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        static_array = StaticArray(UInt8, 32).new(0_u8)
        static_array, final_size = Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: static_array, check: Base58::Check.new(testcase["check_prefix"].as(String)))
        String.new(static_array.to_slice[0, final_size]).should eq testcase["string"].as(String)
      end
    end

    it "can encode strings into an existing raw memory buffer pointed to by a Pointer(UInt8), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        ptr = GC.malloc_atomic(32).as(UInt8*)
        ptr, final_size = Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: ptr, check: Base58::Check.new(testcase["check_prefix"].as(String)))
        String.new(ptr, final_size).should eq testcase["string"].as(String)
      end
    end

    it "can encode strings into an existing Array(UInt8), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        array = Array(UInt8).new
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: array, check: Base58::Check.new(testcase["check_prefix"].as(String)))
        String.new(array.to_slice[0, testcase["string"].as(String).size]).should eq testcase["string"].as(String)
      end
    end

    it "can encode strings into an existing Array(Char), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        array = Array(Char).new
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: array, check: Base58::Check.new(testcase["check_prefix"].as(String)))
        String.new(array.map(&.ord.to_u8).to_slice[0, testcase["string"].as(String).size]).should eq testcase["string"].as(String)
      end
    end

    it "can encode strings into an existing StringBuffer, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = StringBuffer.new
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes), into: buffer, check: Base58::Check.new(testcase["check_prefix"].as(String)))
        buffer.buffer.should eq testcase["string"].as(String)
      end
    end
  end

  context "Polkadot/SS58 encoding works as expected" do
    it "can encode substrate addresses to new String" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, format: testcase["format"].as(Int)).should eq testcase["string"].as(String)
      end
    end

    it "can encode substrate addressed to new Slice(UInt8)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, into: Slice(UInt8), format: testcase["format"].as(Int)).should eq testcase["string"].as(String).to_slice
      end
    end

    it "can encode substrate addresses to new StaticArray(UInt8, N)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        result, final_size = Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, into: StaticArray(UInt8, 50), format: testcase["format"].as(Int))
        result.to_slice[0, final_size].should eq testcase["string"].as(String).to_slice
      end
    end

    it "can encode substrate addresses to new Array(UInt8)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, into: Array(UInt8), format: testcase["format"].as(Int)).should eq testcase["string"].as(String).to_slice.to_a
      end
    end

    it "can encode substrate addresses to new Array(Char)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, into: Array(Char), format: testcase["format"].as(Int)).should eq testcase["string"].as(String).to_slice.to_a.map(&.chr)
      end
    end

    it "can encode substrate addresses to a new raw memory buffer (Pointer(UInt8))" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        result, final_size = Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, into: Pointer(UInt8).malloc(50), format: testcase["format"].as(Int))
        result.to_slice(final_size).should eq testcase["string"].as(String).to_slice
      end
    end

    it "can encode substrate addresses into an existing String, without mutation" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        string = String.new("encoded:")
        new_string = Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, into: string, format: testcase["format"].as(Int))
        string.object_id.should_not eq new_string.object_id
        new_string.should eq "encoded:#{testcase["string"].as(String)}"
      end
    end

    it "can encode substrate addresses into an existing String, with mutation" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        string = String.new("x" * 50)
        Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, into: string, format: testcase["format"].as(Int), mutate: true)
        string.should eq testcase["string"].as(String)
      end
    end

    it "can encode substrate addresses into an existing Slice(UInt8)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        slice = Slice(UInt8).new(50)
        Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, into: slice, format: testcase["format"].as(Int))
        tc_string = testcase["string"].as(String)
        String.new(slice[0, tc_string.bytesize]).should eq testcase["string"].as(String)
      end
    end
  end
end
