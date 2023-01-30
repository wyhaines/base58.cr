use criterion::{black_box, criterion_group, criterion_main, Criterion};
use std::{fmt::Write, num::ParseIntError};

pub fn decode_hex(s: &str) -> Result<Vec<u8>, ParseIntError> {
    (0..s.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&s[i..i + 2], 16))
        .collect()
}

fn do_encode(string: &str) -> String {
    let encoded = bs58::encode(string).into_string();
    encoded
}

fn criterion_benchmark(c: &mut Criterion) {
    unsafe {
        let monero_bytes = decode_hex("12c09d10f3c5f580ddd0765063d9246007f45ef025a76c7d117fe4e811fa78f3959c66f7487c1bef43c64ee0ace763116456666a389eea3b693cd7670c3515a0c043794fbf").unwrap();
        let monero_addr = std::str::from_utf8_unchecked(&monero_bytes);

        c.bench_function("encode \\xff\\xff\\xff", |b| {
            b.iter(|| {
                do_encode(std::str::from_utf8_unchecked(&[255_u8, 255, 255])).to_string();
            });
        });

        c.bench_function("encode 999", |b| {
            b.iter(|| {
                do_encode("999").to_string();
            });
        });

        c.bench_function("monero string", |b| {
            b.iter(|| {
                bs58::encode(monero_addr)
                    .with_alphabet(bs58::Alphabet::MONERO)
                    .into_string();
            });
        });
    }
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
