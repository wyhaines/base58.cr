module Base58
  # This is essentially a lightweight Slice. It exists only to provide an Enumerable
  # interface to a Pointer. The jury is still out on whether there is any point to this
  # versus just using Slice. I did some quick benchmarks to justify this, but there needs
  # to be more due diligence.
  #
  # To use this, you need to pass in a pointer, the size of the pointer, and optionally
  # the starting position within the pointer. It is up to you to ensure that the size
  # of the pointer is accurate. No other bounds checking will be done.
  struct PointerCollection
    include Enumerable(UInt8)
    getter pointer : Pointer(UInt8)
    getter size : Int32
    getter position : Int32

    def initialize(@pointer : Pointer(UInt8), @size : Int32, @position = 0)
    end

    def each(&)
      while @position < @size
        yield @pointer[@position]
        @position += 1
      end
    end
  end
end
