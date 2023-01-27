use bs58;

fn do_encode(string : &str) -> String {
    let encoded = bs58::encode(string).into_string();
    encoded
  }

fn main() {
    //let input = "2NEpo7TZRRrLZSi2U";
    //let input = "2UzHL";
    let input = "4gj";
    let decoded = bs58::decode(input.trim()).into_vec().unwrap();
    println!("{:?}", String::from_utf8(decoded));

    let mut buffer = String::with_capacity(8);
    let mut i = 0;
    while i < 100000000 {
        // let encoded = bs58::encode("01234567890123456789012345678901234567890123456789012345678901234").into_string();
        //bs58::encode("999").into(&mut buffer);
        do_encode("999").to_string();
        i += 1
    }
    
    println!("{:?}", i);
    println!("{:?}", buffer);
    println!("{:?}", bs58::encode("\x00\x00\x00").into_string());
    println!("{:?}", bs58::encode("\x00ab").into_string());
    println!("{:?}", bs58::encode("999").into_string());
    println!("{:?}", bs58::encode("abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz").into_string());
}
