require "./spec_helper"

describe Base58::Decoder do
  context "Decoding via Base58.decode" do
    it "decodes strings to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: String))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a slice to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8)))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a static array to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        static_array, len = Base58.encode(testcase["hex"].as(String).hexbytes, into: StaticArray(UInt8, 32))
        Base58.decode(
          Slice.new(static_array.to_unsafe, len))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a raw pointer and length to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        pointer, len = Base58.encode(testcase["hex"].as(String).hexbytes, into: Pointer(UInt8))
        Base58.decode(pointer, len)
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes an Array(UInt8) to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Array(UInt8)))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes an Array(Char) to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Array(Char)))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a StringBuffer to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: StringBuffer))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice(UInt8) to a new Slice(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8)))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice(UInt8) to an existing Slice(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        slice = Slice(UInt8).new(32)
        should_be_the_same, len = Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8)),
          into: slice)
        slice[..(len - 1)].hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice(UInt8) to a new StaticArray(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        static_array, len = Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8)),
          into: StaticArray(UInt8, 32))
        static_array.to_slice[..(len - 1)].hexstring.should eq testcase["hex"]
      end
    end

    # This is, of course, a lie. Because a StaticArray is passed by Copy, it is quite
    # impossible to modify the contents of an existing StaticArray in this way. So, while
    # the code is written as if this will work, this set of tests is here really to
    # confirm that +A+ StaticArray is returned by this style of decoding.
    it "decodes a Slice(UInt8) to an existing StaticArray(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        static_array = StaticArray(UInt8, 32).new(0_u8)
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        should_be_the_same, len = Base58.decode(buffer, into: static_array)
        should_be_the_same.to_slice(len)[..(len - 1)].hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice() to a new Array(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        array = Base58.decode(buffer, into: Array(UInt8))
        _, slice = array.reduce({0, Slice(typeof(array.first)).new(array.size)}) do |(i, slice), byte|
          slice[i] = byte
          {i + 1, slice}
        end
        slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice(UInt8) to an existing Array(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        array = Array(UInt8).new(32)
        Base58.decode(buffer, into: array)
        array.should eq Base58.decode(buffer, into: Array(UInt8))
        _, slice = array.reduce({0, Slice(typeof(array.first)).new(array.size)}) do |(i, slice), byte|
          slice[i] = byte
          {i + 1, slice}
        end
        slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice(UInt8) to a new Array(Char)" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        array = Base58.decode(buffer, into: Array(Char))
        _, slice = array.reduce({0, Slice(UInt8).new(array.size)}) do |(i, slice), byte|
          slice[i] = byte.ord.to_u8
          {i + 1, slice}
        end
        slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice(UInt8) to an existing Array(Char)" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        array = [] of Char
        Base58.decode(buffer, into: array)
        _, slice = array.reduce({0, Slice(UInt8).new(array.size)}) do |(i, slice), byte|
          slice[i] = byte.ord.to_u8
          {i + 1, slice}
        end
        slice.hexstring.should eq testcase["hex"]
      end
    end

    # This form returns a new string, as it honors String immutability.
    it "decodes a Slice(UInt8) into an existing String, safely" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        string = "abc123:"
        string = Base58.decode(buffer, into: string)
        (string == "abc123:#{String.new(testcase["hex"].as(String).hexbytes)}").should be_true
      end
    end

    # This does _not_ honor String immutability. If you try to decode into a string that doesn't
    # have a large enough allocated capacity, there _will be_ an error. So, do this only if you
    # know that the string was allocated with enough space.
    it "decodes a Slice(UInt8) into an existing String, unsafely" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        string = String.new(32)
        string = Base58.decode(buffer, into: string, mutate: true)
        (string == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end

    it "decodes a Slice(UInt8) into a new StringBuffer" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        stringbuffer = Base58.decode(buffer, into: StringBuffer)
        (stringbuffer.buffer == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end

    it "decodes a Slice(UInt8) into an existing StringBuffer" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        stringbuffer = StringBuffer.new(32)
        should_be_the_same_buffer = Base58.decode(buffer, into: stringbuffer)
        (stringbuffer.buffer == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end
  end

  context "Decoding via Base58::Decoder.into()" do
    it "uses the Decoder.into() syntax to decode strings to strings" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        (Base58::Decoder.into(String).decode(Base58.encode(testcase["hex"].as(String).hexbytes)) == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end

    it "uses the Decoder.into() syntax to decode strings to new Slice(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        (Base58::Decoder.into(Slice(UInt8)).decode(Base58.encode(testcase["hex"].as(String).hexbytes)) == testcase["hex"].as(String).hexbytes).should be_true
      end
    end
  end

  context "Decoding with Alphabet::Flickr works as expected" do
    it "can decode strings to new strings with the Flickr Base58 alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Flickr }.each do |testcase|
        (Base58.decode(Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Flickr), alphabet: Base58::Alphabet::Flickr) == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end
  end

  context "Decoding with Alphabet::Ripple works as expected" do
    it "can decode strings to new strings with the Ripple Base58 alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Ripple }.each do |testcase|
        (Base58.decode(Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Ripple), alphabet: Base58::Alphabet::Ripple) == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end
  end

  context "Decoding with Alphabet::Monero works as expected" do
    it "can decode strings to new strings with the Monero Base58 alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Monero }.each do |testcase|
        (Base58.decode(Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Monero), alphabet: Base58::Alphabet::Monero) == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end
  end

  context "Base58Check Decoding works as expected" do
    it "can decode encoded strings to new strings with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          check: Base58::Check.new).should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end
  end

  context "CB58 Decoding works as expected" do
    it "can decode encoded strings to new strings with CB58 checksumming" do
      TestData::Strings.select { |tc| tc["check_prefix"] }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String), type: :CB58)
          ),
          check: Base58::Check.new(type: :CB58)).should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end
  end
end
