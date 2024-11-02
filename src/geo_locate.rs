use flate2::read::GzDecoder;
use maxminddb::geoip2::City;
use maxminddb::Reader;
use std::error::Error;
use std::fs::File;
use std::io::copy;
use std::net::IpAddr;
use std::path::Path;
use tar::Archive;

pub fn geoip_lookup(
    ip: &str,
    db_path: &str,
) -> Result<(Option<String>, Option<String>), Box<dyn Error>> {
    let reader = Reader::open_readfile(db_path)?;
    let ip: IpAddr = ip.parse()?;

    let Ok(lookup_city) = reader.lookup::<City<'_>>(ip) else {
        return Err("failed to lookup IP address")?;
    };

    let country_name = lookup_city
        .country
        .and_then(|c| c.names)
        .and_then(|mut names| names.remove("en"))
        .map(|country| country.to_string());

    let city_name = lookup_city
        .city
        .and_then(|c| c.names)
        .and_then(|mut names| names.remove("en"))
        .map(|city| city.to_string());
    Ok((country_name, city_name))
}

pub async fn download_geo_db(
    account_id: &str,
    license_key: &str,
    path: &str,
) -> Result<(), Box<dyn Error + 'static>> {
    if Path::new(path).exists() {
        return Ok(());
    }

    let url = "https://download.maxmind.com/geoip/databases/GeoLite2-City/download?suffix=tar.gz";

    // Create the client and set basic authentication
    let client = reqwest::Client::new();
    let response = client
        .get(url)
        .basic_auth(account_id.to_string(), Some(license_key.to_string()))
        .send()
        .await?;

    // Ensure the request was successful
    if !response.status().is_success() {
        eprintln!("Failed to download the file: HTTP {}", response.status());
        return Err("Download failed".into());
    }

    // Determine the filename from the content-disposition header
    let filename = match response.headers().get(http::header::CONTENT_DISPOSITION) {
        Some(content_disposition) => content_disposition
            .to_str()
            .ok()
            .and_then(|v| {
                v.split("filename=")
                    .nth(1)
                    .map(|name| name.trim_matches('"').to_string())
            })
            .unwrap_or_else(|| "downloaded_file".to_string()),
        None => "downloaded_file".to_string(),
    };

    let output_directory = Path::new(path).parent().unwrap();
    std::fs::create_dir_all(output_directory)?;

    // Create a file to save the response body
    let path = output_directory.join(&filename);
    let mut file = File::create(&path)?;

    // Copy the response body to the file
    let content = response.bytes().await?;
    copy(&mut content.as_ref(), &mut file)?;

    unpack_mmdb_file(&path, output_directory)?;
    Ok(())
}

fn unpack_mmdb_file(archive_path: &Path, output_dir: &Path) -> Result<(), Box<dyn Error>> {
    // Open the .tar.gz file
    let tar_gz = File::open(archive_path)?;

    // Create a GzDecoder to handle decompression
    let decompressed = GzDecoder::new(tar_gz);

    // Create an Archive from the decompressed stream
    let mut archive = Archive::new(decompressed);

    // Iterate over the entries in the archive
    for entry in archive.entries()? {
        let mut file = entry?;

        // Get the path of the file in the archive
        let Ok(path) = file.path() else {
            continue;
        };
        if path.extension().map(|ext| ext == "mmdb").unwrap_or(false) {
            // Extract the file to the output directory
            let filename = path.file_name().unwrap();
            let output_path = std::path::Path::new(output_dir).join(filename);
            println!("Extract: {:?}", &path);
            file.unpack(output_path)?;
        }
    }

    Ok(())
}
