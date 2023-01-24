![Base58 CI](https://img.shields.io/github/workflow/status/wyhaines/base58.cr/Base58%20CI?style=for-the-badge&logo=GitHub)
[![GitHub release](https://img.shields.io/github/release/wyhaines/base58.cr.svg?style=for-the-badge)](https://github.com/wyhaines/base58.cr/releases)
![GitHub commits since latest release (by SemVer)](https://img.shields.io/github/commits-since/wyhaines/base58.cr/latest?style=for-the-badge)


# base58

This library provides a very fast implementation of Base58 encoding and decoding for Crystal. It supports the Bitcoin Base58 alphabet, which is the default alphabet, as well
as the Flickr alphabet, the Ripple alphabet, and the Minero alphabet.

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

The `encode` and `decode` methods should operate off of just about any sensible input, and can return most output types that a person may want. To encode into Base58, the basic form is this:

```crystal
Base58.encode("Hello, World!")
```

This will return the Base58 version of `Hello, World!` as a `String`.

You might want that value returned as a `Slice(UInt8)` instead:

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

There are four supported alphabets. These are the Bitcoin alphabet, the Flickr alphabet, the Ripple alphabet, and the Monero alphabet. Of these, all are encoded and decoded the same except for the Monero alphabet, which for encoding operates on blocks of 8 bytes, padding to 11 bytes, except for the final block. For decoding, it operates on blocks of 11 bytes, returning 8 bytes of decoded data, except for the final block which can be smaller. For the other three alphabets, the final size of the encoded data is variable, but the Monero encoding ensures a consistent final size. Thus, Monero addresses, which are 69 bytes of data, always encode to 95 byte Base58 strings.

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