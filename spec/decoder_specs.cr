require "./spec_helper"

describe Base58::Decoder do
  context "Decoding via Base58.decode" do
    it "decodes strings to strings with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: String))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a slice to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8)))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a static array to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        static_array, len = Base58.encode(testcase["hex"].as(String).hexbytes, into: StaticArray(UInt8, 32))
        Base58.decode(
          Slice.new(static_array.to_unsafe, len))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a raw pointer and length to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        pointer, len = Base58.encode(testcase["hex"].as(String).hexbytes, into: Pointer(UInt8))
        Base58.decode(pointer, len)
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes an Array(UInt8) to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Array(UInt8)))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes an Array(Char) to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Array(Char)))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a StringBuffer to a string with the default (Bitcoin) alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: StringBuffer))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice(UInt8) to a new Slice(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8)))
          .to_slice.hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice(UInt8) to an existing Slice(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        slice = Slice(UInt8).new(32)
        should_be_the_same, len = Base58.decode(
          Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8)),
          into: slice)
        slice[..(len - 1)].hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice(UInt8) to a new StaticArray(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
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
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        static_array = StaticArray(UInt8, 32).new(0_u8)
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        should_be_the_same, len = Base58.decode(buffer, into: static_array)
        should_be_the_same.to_slice[..(len - 1)].hexstring.should eq testcase["hex"]
      end
    end

    it "decodes a Slice() to a new Array(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
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
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
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
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
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
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
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
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
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
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        string = String.new(32)
        string = Base58.decode(buffer, into: string, mutate: true)
        (string == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end

    it "decodes a Slice(UInt8) into a new StringBuffer" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        stringbuffer = Base58.decode(buffer, into: StringBuffer)
        (stringbuffer.buffer == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end

    it "decodes a Slice(UInt8) into an existing StringBuffer" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buffer = Base58.encode(testcase["hex"].as(String).hexbytes, into: Slice(UInt8))
        stringbuffer = StringBuffer.new(32)
        should_be_the_same_buffer = Base58.decode(buffer, into: stringbuffer)
        (stringbuffer.buffer == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end
  end

  context "Decoding via Base58::Decoder.into()" do
    it "uses the Decoder.into() syntax to decode strings to strings" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        (Base58::Decoder.into(String).decode(Base58.encode(testcase["hex"].as(String).hexbytes)) == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end

    it "uses the Decoder.into() syntax to decode strings to new Slice(UInt8)" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        (Base58::Decoder.into(Slice(UInt8)).decode(Base58.encode(testcase["hex"].as(String).hexbytes)) == testcase["hex"].as(String).hexbytes).should be_true
      end
    end
  end

  context "Decoding with Alphabet::Flickr works as expected" do
    it "can decode strings to new strings with the Flickr Base58 alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Flickr }.each do |testcase|
        (Base58.decode(Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Flickr), alphabet: Base58::Alphabet::Flickr) == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end
  end

  context "Decoding with Alphabet::Ripple works as expected" do
    it "can decode strings to new strings with the Ripple Base58 alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Ripple }.each do |testcase|
        (Base58.decode(Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Ripple), alphabet: Base58::Alphabet::Ripple) == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end
  end

  context "Decoding with Alphabet::Monero works as expected" do
    it "can decode strings to new strings with the Monero Base58 alphabet" do
      TestData::Strings.reject { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Monero }.each do |testcase|
        (Base58.decode(Base58.encode(testcase["hex"].as(String).hexbytes, alphabet: Base58::Alphabet::Monero), alphabet: Base58::Alphabet::Monero) == String.new(testcase["hex"].as(String).hexbytes)).should be_true
      end
    end
  end

  context "Base58Check Decoding works as expected" do
    it "can decode encoded strings to new strings with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          check: Base58::Check.new).should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end

    it "can decode encoded strings to new slices with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: Slice(UInt8),
          check: Base58::Check.new)
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to new static arrays with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        static_array, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: StaticArray(UInt8, 32),
          check: Base58::Check.new)

        static_array.to_slice[0, length].should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to a new raw memory buffer with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        ptr, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: Pointer,
          check: Base58::Check.new)

        ptr.to_slice(length).should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to a new Array(UInt8), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: Array(UInt8),
          check: Base58::Check.new)
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice.to_a
      end
    end

    it "can decode encoded strings to a new Array(Char), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: Array(Char),
          check: Base58::Check.new)
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".chars
      end
    end

    it "can decode encoded strings to a new StringBuffer, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        res = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: StringBuffer,
          check: Base58::Check.new)
          .buffer
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end

    it "can decode encoded strings to an existing string, with Base58Check, without mutation" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = "::"
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: str,
          check: Base58::Check.new)
          .should eq "::#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end

    it "can decode encoded strings to an existing string, with Base58Check, with mutation" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = String.new(32)
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: str,
          mutate: true,
          check: Base58::Check.new)
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end

    it "can decode encoded strings to an existing slice, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        slice = Slice(UInt8).new(32)
        _, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: slice,
          check: Base58::Check.new)
        slice[0, length].should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to an existing static array, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        arr = StaticArray(UInt8, 32).new(0_u8)
        arr, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: arr,
          check: Base58::Check.new)
        arr.to_slice[0, length].should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to an existing raw memory buffer, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buf = Pointer(UInt8).malloc(32)
        buf, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: buf,
          check: Base58::Check.new)
        Slice.new(buf, length).should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can encode encoded strings to an existing Array(UInt8), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        arr = Array(UInt8).new
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: arr,
          check: Base58::Check.new)
        arr.should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".bytes
      end
    end

    it "can encode encoded strings to an existing Array(Char), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        arr = Array(Char).new
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: arr,
          check: Base58::Check.new)
        arr.should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".chars
      end
    end

    it "can decode encoded strings to an existing StringBuffer, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buf = StringBuffer.new
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String))
          ),
          into: buf,
          check: Base58::Check.new)
        buf.buffer.should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end
  end

  context "CB58 Decoding works as expected" do
    it "can decode encoded strings to new strings with CB58 checksumming" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(testcase["check_prefix"].as(String), type: :CB58)
          ),
          check: Base58::Check.new(type: :CB58)).should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end

    it "can decode encoded strings to new slices with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: Slice(UInt8),
          check: Base58::Check.new(type: :CB58))
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to new static arrays with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        static_array, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: StaticArray(UInt8, 32),
          check: Base58::Check.new(type: :CB58))

        static_array.to_slice[0, length].should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to a new raw memory buffer with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        ptr, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: Pointer,
          check: Base58::Check.new(type: :CB58))

        ptr.to_slice(length).should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to a new Array(UInt8), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: Array(UInt8),
          check: Base58::Check.new(type: :CB58))
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice.to_a
      end
    end

    it "can decode encoded strings to a new Array(Char), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: Array(Char),
          check: Base58::Check.new(type: :CB58))
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".chars
      end
    end

    it "can decode encoded strings to a new StringBuffer, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        res = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: StringBuffer,
          check: Base58::Check.new(type: :CB58))
          .buffer
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end

    it "can decode encoded strings to an existing string, with Base58Check, without mutation" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = "::"
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: str,
          check: Base58::Check.new(type: :CB58))
          .should eq "::#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end

    it "can decode encoded strings to an existing string, with Base58Check, with mutation" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        str = String.new(32)
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: str,
          mutate: true,
          check: Base58::Check.new(type: :CB58))
          .should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end

    it "can decode encoded strings to an existing slice, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        slice = Slice(UInt8).new(32)
        _, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: slice,
          check: Base58::Check.new(type: :CB58))
        slice[0, length].should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to an existing static array, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        arr = StaticArray(UInt8, 32).new(0_u8)
        arr, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: arr,
          check: Base58::Check.new(type: :CB58))
        arr.to_slice[0, length].should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can decode encoded strings to an existing raw memory buffer, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buf = Pointer(UInt8).malloc(32)
        buf, length = Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: buf,
          check: Base58::Check.new(type: :CB58))
        Slice.new(buf, length).should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".to_slice
      end
    end

    it "can encode encoded strings to an existing Array(UInt8), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        arr = Array(UInt8).new
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: arr,
          check: Base58::Check.new(type: :CB58))
        arr.should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".bytes
      end
    end

    it "can encode encoded strings to an existing Array(Char), with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        arr = Array(Char).new
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: arr,
          check: Base58::Check.new(type: :CB58))
        arr.should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}".chars
      end
    end

    it "can decode encoded strings to an existing StringBuffer, with Base58Check" do
      TestData::Strings.select { |tc| tc["check_prefix"]? }.select { |tc| tc["alphabet"] == Base58::Alphabet::Bitcoin }.each do |testcase|
        buf = StringBuffer.new
        Base58.decode(
          Base58.encode(
            String.new(testcase["hex"].as(String).hexbytes),
            check: Base58::Check.new(type: :CB58, prefix: testcase["check_prefix"].as(String))
          ),
          into: buf,
          check: Base58::Check.new(type: :CB58))
        buf.buffer.should eq "#{testcase["check_prefix"]}#{String.new(testcase["hex"].as(String).hexbytes)}"
      end
    end
  end

  context "Polkadot/SS58 decoding works as expected" do
    it "can decode substrate addresses" do
      TestData::Strings.select { |tc| tc["alphabet"] == Base58::Alphabet::Polkadot }.each do |testcase|
        Base58::SS58.decode_address(
          Base58::SS58.encode_address(testcase["hex"].as(String).hexbytes, format: testcase["format"].as(Int))
        ).to_slice.should eq testcase["hex"].as(String).hexbytes
      end
    end
  end
end
