[![Base58 CI](https://github.com/wyhaines/base58.cr/actions/workflows/ci.yml/badge.svg)](https://github.com/wyhaines/base58.cr/actions/workflows/ci.yml)
[![Base58 Build Docs](https://github.com/wyhaines/base58.cr/actions/workflows/build_docs.yml/badge.svg)](https://github.com/wyhaines/base58.cr/actions/workflows/build_docs.yml)

[![GitHub release](https://img.shields.io/github/release/wyhaines/base58.cr.svg?style=for-the-badge)](https://github.com/wyhaines/base58.cr/releases)
![GitHub commits since latest release (by SemVer)](https://img.shields.io/github/commits-since/wyhaines/base58.cr/latest?style=for-the-badge)


# base58

This library provides a very fast implementation of Base58 encoding and decoding for Crystal. This implementation supports all of the major Base58 alphabet variations, including Bitcoin, Flickr, Ripple, and Monero. In addition, it supports Monero's block based encoding approach, and it supports checksums using the Bitcoin Base58Check algorithm, the Avalanche CB58 algorithm, and the Polkadot SS58 algorithm along with encoding and decoding of Substrate addresses.

## API Documentation

Full generated API documentation can be found at: [https://wyhaines.github.io/base58.cr/](https://wyhaines.github.io/base58.cr/).

## Benchmarks

A benchmark is provided in the [benchmark/](https://github.com/wyhaines/base58.cr/tree/main/benchmark) directory. To build it and then run it:

```bash
cd benchmark
shards build --release
bin/benchmark
```

It will run a variety of encode/decode tests against both this package as well as against the other Crystal Base 58 packages. In addition if Rust is available on the system, it will run a small benchmark of Rust's fastest Base58 package, bs58, against some of the same data sets. A full run will look something like this:

![Benchmark](https://raw.githubusercontent.com/wyhaines/base58.cr/main/img/benchmark.jpg)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     base58:
       github: wyhaines/base58
   ```

2. Run `shards install`

## Usage

```crystal
require "base58"
```

Basic usage is via two methods, `Base58.encode` and `Base58.decode`. These methods can take a variety of input types, and can decode/encode into a variety of output types -- `String.class`, `Slice(UInt8).class`, `StaticArray(UInt8, N).class`, `Array(UInt8).class`, `Array(Char).class`, `StringBuffer.class`, `Pointer(UInt8).class`, `String`, `Slice(UInt8)`, `StaticArray(UInt8, N)`, `Array(UInt8)`, `Array(Char)`, `StringBuffer`, and `Pointer(UInt8)`.


```crystal
Base58.encode("Hello, World!")
```

The default return type is `String.class`, which returns a new instance of `String`. Thus, this example will return the Base58 version of `Hello, World!` as a `String`.

If you wanted that value returned as a `Slice(UInt8)` instead:

```crystal
Base58.encode("Hello, World!", into: Slice(UInt8))
```

If you have an existing `Slice(UInt8)` that you are using as a reusable buffer, you can use that, too:

```crystal
buffer = Slice(UInt8).new(100)
Base58.encode("Hello, World!", into: buffer)
```

Or maybe you have a `Slice(UInt8)` of bytes to encode, and you want to encode them into a `StringBuffer`.

```crystal
buffer = Slice(UInt8).new(100)
# Stuff happens to get data into `buffer`.
Base58.encode(buffer, into: StringBuffer)
```

Decoding works in the same way, with the same flexibility.

So, perhaps you have received a Base58 encoded piece of data into a StringBuffer, and want to decode it into another, already-existing StringBuffer:

```crystal
decoded_buffer = StringBuffer.new(256)

# receive data into `recv_buffer`

Base58.decode(recv_buffer, into: decoded_buffer)
```

### Alphabets

There are four supported alphabets, the Bitcoin alphabet, the Flickr alphabet, the Ripple alphabet, and the Monero alphabet. Of these, all are encoded and decoded the same except for the Monero alphabet, which for encoding operates on blocks of 8 bytes, padding to 11 bytes, except for the final block. For decoding, it operates on blocks of 11 bytes, returning 8 bytes of decoded data, except for the final block which can be smaller. For the other three alphabets, the final size of the encoded data is variable, but the Monero encoding ensures a consistent final size. Thus, Monero addresses, which are 69 bytes of data, always encode to 95 byte Base58 strings.

The bitcoin alphabet is the default. To use another alphabet, pass the class of the alphabet as an argument:

```crystal
Base58.encode("Hello, World!", into: Slice(UInt8), alphabet: Base58::Alphabet::Monero)
```

Alphabets support both forward and inverse lookup. Thus, the following will return the original character:

```crystal
Base58::Alphabet::Bitcoin.inverse(Base58::Alphabet::Bitcoin['a'.ord]).chr
```

The alphabets encode the ASCII codes for the characters, since Base58 alphabets all utilize single byte ASCII characters. Thus, to lookup a `Char`, it has to be cast to a `UInt8` first.

Nil-returning variants of both forward and backward lookups are also supported:

```crystal
Base58::Alphabet::Bitcoin.inverse?(Base58::Alphabet::Bitcoin[some_UTF8_character]?)
```

If the character is not found in the alphabet, the forward lookup, via `#[]`, will return an exception, but if called via `#[]?`, `nil` will be returned if it is not found. The inverse lookup returns a `0` for any ASCII character code that is not found in the alphabet when called with `#inverse`, and an exception for any non-ASCII character code. When called with `inverse?`, it returns nil for any code that is not found in the alphabet, ASCII or not.  

### Checksumming

In addition to the various alphabets, three different checksum algorithms are supported, Base58Check, CB58, and SS58. To use a checksum, pass an instance of `Base58::Check` into the `encode` or `decode` methods:

```crystal
base58check_data = Base58.encode(
  "Hello, World!",
  into: Slice(UInt8),
  check: Base58::Check.new)
```

Without parameters, an instance of `Check` specifies Base58Check encoding with a prefix of `0x31` (`1`). To specify a different prefix, pass is as the first argument to `new`, or via a named argument, `prefix`.

```crystal
base58check_data = Base58.encode(
  "Hello, World!",
  into: StringBuffer,
  check: Base58::Check.new(0x32))
)
```

```crystal
base58check_data = Base58.encode(
  "Hello, World!",
  into: StringBuffer,
  check: Base58::Check.new(prefix: 0x32))
)
```

To specify a different checksum algorithm, use the `type` named argument:

```crystal
cb58_data = Base58.encode(
  "Hello, World!",
  into: StringBuffer,
  check: Base58::Check.new(type: Base58::Check::CB58))
)
```

The [SS58 checksum algorithm for Substrate](https://docs.substrate.io/reference/address-formats/) has more moving parts than the Base58Check or the CB58 algorithms, with a variable prefix, variable checksum length, and a prefix that is applied to the data to be checksummed before checksumming. Thus, using it takes a few more parameters:

```crystal
ss58_data = Base58.encode(
  "Hello, World!",
  into: StringBuffer,
  check: Base58::Check.new(
    type: :SS58,
    prefix: "*",
    checksum_length: 2,
    checksum_prefix: "SS58PRE"))
)
```

If you look at the [Substrate Address Format Specification](https://docs.substrate.io/reference/address-formats/), you will see that encoding and decoding Substrate addresses with SS58 is a bit more complicated than just setting a prefix and running a hashing algorithm. The `Base58::SS58` class provides convenience methods for encoding and decoding Substrate addresses, and it is recommended that you are using this library to interact with Substrate, you should use those methods instead of the `Base58.encode` and `Base58.decode` methods directly.

```crystal
substrate_address = Base58::SS58.encode("d172a74cda4c865912c32ba0a80a57ae69abae410e5ccb59dee84e2f4432db4f".hexbytes)
```

Just like the basic `encode`/`decode` methods, the `SS58` variants support all of the same input and output types, and in addition, they support a `format` argument which specifies the format prefix, as defined in the above URL.

```crystal
substrate_address = Base58::SS58.encode(
  "d172a74cda4c865912c32ba0a80a57ae69abae410e5ccb59dee84e2f4432db4f".hexbytes,
  into: Slice(UInt8),
  format: 255)
```

Exceptions will be raised if an invalid format is provided, or if the data to be encoded is not a valid length for SS58 encoding.

The same invocation syntax is used when decoding encoded Substrate addresses.

```crystal
encoded_address = Base58::SS58.encode(
  "d172a74cda4c865912c32ba0a80a57ae69abae410e5ccb59dee84e2f4432db4f".hexbytes,
  into: Slice(UInt8),
  format: 255)

decoded_address = Base58::SS58.decode(encoded_address)
```

If the `format` argument is provided when decoding, it will be used to guarantee that the encoded address was encoded with the same format. An exception will be raised if the format does not match.

### Alternative, method chaining based syntax.

There is an alternative syntax that is supported, though it should be considered to be an experiment. I don't know if I will keep this support as it needs some work to be really transparently usable. Right now `.as(TYPE)` annotations are needed because I have not fleshed out the implementation. If you feel inspired, and want to offer a PR to help make this better, I would be appreciative.

```crystal
Base58::Encoder.into(String).encode("some text").as(String)

buffer = StringBuffer.new(256)
Base58::Decoder.into(buffer).decode(some_encoded_thing)

as_slice = Base58::Encoder.into(Slice(UInt8)).encode("some text).as(Slice(UInt8))
```

## Crystal Extensions and Other Goodies

There are several extensions to Crystal that are bundled into this library pending submitting them as pull requests to Crystal itself.

### Char.static_array

The number types, such as UInt8, have a macro defined on them to facilitate the creation of a prepopulated StaticArray, [static_array](https://crystal-lang.org/api/1.7.1/Number.html#static_array%28%2Anums%29-macro). This extension adds the same macro to `Char`.


### Slice#to_unsafe

This adds a method to a `Slice` that returns a pointer to the first element of the slice. 

### String.static_array

The number types, such as UInt8, have a macro defined on them to facilitate the creation of a prepopulated StaticArray, [static_array](https://crystal-lang.org/api/1.7.1/Number.html#static_array%28%2Anums%29-macro). This extension adds the same macro to `String`.

### String#new(string : String)

This creates a dynamically allocated string, even when passed a string literal. While this is not something that one normally wants, there are times when you want to ensure that a _new_ object, with a new section of memory backing it, is created for a given string literal. This will guarantee that.

### String#new(size : Int)

This is a simple helper that creates an empty string in the requested size. This may seem
useless, as Crystal Strings are immutable. However, this can be useful if you want to say "Not today!" to the god of Immutability and mutate an immutable String as a very very handy buffer with a maximum fixed size.

### StringBuffer

Imagine that you want to take some data that is stuffed into a piece of memory, and you want to be able to treat it as a String, doing all the normal String things. But you
want it to be as fast as possible because you are going to be doing this a lot.

Say "Hello" to StringBuffer. It is a thin wrapper around a String, and it forwards any unknown method calls to the String that it carries in an instance variable, so it generally behaves like a String. However, it defines a `#mutate` method that can be called to _change_ the value of the underlying String, with some limits.

Nothing can be stored in a StringBuffer that is larger than the original capacity of the StringBuffer. However, anything the same size or smaller can be inserted into the String, replacing the previous contents.



## Development

The goals are to have a clear, capable, and easy to use API that sits above an implementation that is the fastest available for Crystal, and that is performance competitive with Rust.

Internals cleanups or optimizations are welcome, as are any bug fixes or improved documentation.

## Contributing

1. Fork it (<https://github.com/wyhaines/base58/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kirk Haines](https://github.com/wyhaines) - creator and maintainer

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/wyhaines/base58.cr?style=for-the-badge)
![GitHub issues](https://img.shields.io/github/issues/wyhaines/base58.cr?style=for-the-badge)