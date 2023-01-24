require "./spec_helper"

describe Base58::Encoder do
  context "Encoding via Base58.encode" do
    it "encodes strings to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(String.new(testcase["hex"].as(String).hexbytes)).should eq testcase["string"]
      end
    end

    it "encodes slices to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes).should eq testcase["string"]
      end
    end

    it "encodes static arrays to strings with the default (Bitcoin) alphabet" do
      testcase = TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.first
      stat_ary = StaticArray(UInt8, 12).new(0)
      bytes = testcase["hex"].as(String).hexbytes
      stat_ary.to_unsafe.copy_from(bytes.to_unsafe, bytes.size)
      Base58.encode(stat_ary).should eq testcase["string"]
    end

    it "encodes stringbuffers to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = StringBuffer.new(testcase["hex"].as(String).hexbytes)
        Base58.encode(buffer).should eq testcase["string"]
      end
    end

    it "encodes arrays of UInt8 to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes.to_a).should eq testcase["string"]
      end
    end

    it "encodes arrays of Char to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes.to_a.map(&.chr)).should eq testcase["string"]
      end
    end

    it "encodes strings to strings to String" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: String).should eq testcase["string"]
      end
    end

    it "encodes strings into an existing string, concatenating them and returning a new string" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = "foo"
        Base58.encode(testcase["hex"].as(String).hexbytes, into: str).should eq "foo#{testcase["string"]}"
      end
    end

    it "encodes strings into and existing string, mutating the string in place and replacing the original contents" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = "X" * testcase["hex"].as(String).bytesize
        should_be_the_same_str = Base58.encode(testcase["hex"].as(String).hexbytes, into: str, mutate: true)
        should_be_the_same_str.should eq testcase["string"]
        str.object_id.should eq should_be_the_same_str.object_id
      end
    end

    it "encodes strings to new Slice(UInt8)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8)).should eq testcase["string"].as(String).to_slice
      end
    end

    it "encodes strings to new StaticArray(UInt8, _)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        static_array, len = Base58.encode(bytes, into: StaticArray(UInt8, 256))
        Slice.new(static_array.to_unsafe, len).should eq testcase["string"].as(String).to_slice
      end
    end

    it "encodes strings into a raw buffer, returning a pointer and a length to the encoded string" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        ptr, len = Base58.encode(bytes, into: Pointer)
        Slice.new(ptr, len).should eq testcase["string"].as(String).to_slice
      end
    end

    it "encodes strings to new Array(UInt8)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: Array(UInt8)).should eq testcase["string"].as(String).bytes.to_a
      end
    end

    it "encodes strings to new Array(Char)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: Array(Char)).should eq testcase["string"].as(String).chars.to_a
      end
    end

    it "encodes strings to new StringBuffer" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, into: StringBuffer).buffer.should eq testcase["string"]
      end
    end

    it "encodes strings into an existing Slice(UInt8)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        buffer = Slice(UInt8).new(len)
        should_be_the_same_buffer = Base58.encode(bytes, into: buffer)
        buffer.should eq testcase["string"].as(String).to_slice
        should_be_the_same_buffer.to_unsafe.should eq buffer.to_unsafe
      end
    end

    it "encodes strings into an existing StaticArray(UInt8, _)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        buffer = StaticArray(UInt8, 256).new(0)
        should_be_the_same_buffer = Base58.encode(bytes, into: buffer) # But it really isn't, since StaticArrays are passed by Copy.
        Slice.new(should_be_the_same_buffer.to_unsafe, len).should eq testcase["string"].as(String).to_slice
      end
    end

    it "encodes strings into an existing Array(UInt8)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        buffer = Array(UInt8).new(len)
        should_be_the_same_buffer = Base58.encode(bytes, into: buffer)
        buffer.should eq testcase["string"].as(String).bytes.to_a
        should_be_the_same_buffer.object_id.should eq buffer.object_id
      end
    end

    it "encodes strings into an existing Array(Char)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        buffer = Array(Char).new(len)
        should_be_the_same_buffer = Base58.encode(bytes, into: buffer)
        buffer.should eq testcase["string"].as(String).chars.to_a
        should_be_the_same_buffer.object_id.should eq buffer.object_id
      end
    end

    it "encodes strings into an existing StringBuffer" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
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
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58::Encoder.into(String).encode(testcase["hex"].as(String).hexbytes).should eq testcase["string"]
      end
    end

    it "uses the Encoder.into() syntax to encode strings to new Slice(UInt8)" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58::Encoder.into(Slice(UInt8)).encode(testcase["hex"].as(String).hexbytes).should eq testcase["string"].as(String).to_slice
      end
    end

    it "uses the Encoder.into() syntax to encode strings to a raw buffer" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        len = testcase["string"].as(String).size
        ptr, len = Base58::Encoder.into(Pointer).encode(bytes).as(Tuple(Pointer(UInt8), Int32))
        Slice.new(ptr, len.as(Int32)).should eq testcase["string"].as(String).to_slice
      end
    end

    it "uses the Encoder.into() syntax to encode strings to new StringBuffer instances" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        bytes = testcase["hex"].as(String).hexbytes
        Base58::Encoder.into(StringBuffer).encode(bytes).as(StringBuffer).buffer.should eq testcase["string"].as(String)
      end
    end
  end

  context "Encoding with Alphabet::Flickr works as expected" do
    it "can encode strings to new strings with the Flickr Base58 alphabet" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Flickr }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Flickr).should eq testcase["string"]
      end
    end
  end

  context "Encoding with Alphabet::Ripple works as expected" do
    it "can encode strings to new strings with the Ripple Base58 alphabet" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Ripple }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Ripple).should eq testcase["string"]
      end
    end
  end

  context "Encoding with Alphabet::Monero works as expected" do
    it "can encode strings to new strings with the Monero Base58 alphabet" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Monero }.each do |testcase|
        Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Monero).should eq testcase["string"]
      end
    end
  end
end
