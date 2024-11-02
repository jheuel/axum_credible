use rand_core::{OsRng, RngCore};
use std::error::Error;

pub fn get_cryptographic_key(key_file: &str) -> Result<Vec<u8>, Box<dyn Error>> {
    std::fs::create_dir_all("data")?;
    if let Ok(false) = std::fs::exists(key_file) {
        let key = generate_cryptographic_key();
        std::fs::write(key_file, hex::encode(key))?;
    };
    hex::decode(std::fs::read(key_file)?).map_err(Into::into)
}

pub fn rotate_cryptographic_key(key_file: &str) -> Result<Vec<u8>, Box<dyn Error>> {
    std::fs::create_dir_all("data")?;
    let key = generate_cryptographic_key();
    std::fs::write(key_file, hex::encode(key))?;
    hex::decode(std::fs::read(key_file)?).map_err(Into::into)
}

pub fn generate_cryptographic_key() -> [u8; 64] {
    let mut random_bits = [0u8; 64];
    OsRng.fill_bytes(&mut random_bits);
    random_bits
}
