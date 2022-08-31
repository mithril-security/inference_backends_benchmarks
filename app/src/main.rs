extern crate benches;
extern crate sgx_types;
extern crate sgx_urts;
use std::ffi::CString;

use anyhow::{anyhow, bail, Context, Result};
use sgx_types::*;
use sgx_urts::SgxEnclave;

extern "C" {
    fn sgx_main(
        eid: sgx_enclave_id_t,
        path: *const c_char,
        npz: *const c_char,
        repeats: size_t,
        samples: size_t,
    ) -> sgx_status_t;
}

fn init_enclave() -> SgxResult<SgxEnclave> {
    let mut launch_token: sgx_launch_token_t = [0; 1024];
    let mut launch_token_updated: i32 = 0;
    // call sgx_create_enclave to initialize an enclave instance
    // Debug Support: set 2nd parameter to 1
    let debug = 0;
    let mut misc_attr = sgx_misc_attribute_t {
        secs_attr: sgx_attributes_t { flags: 0, xfrm: 0 },
        misc_select: 0,
    };
    let mut path = std::env::current_exe().expect("getting current executable");
    path.pop(); // get parent
    path.push("enclave.signed.so");
    let path = path.to_str().expect("path to string");

    SgxEnclave::create(
        path,
        debug,
        &mut launch_token,
        &mut launch_token_updated,
        &mut misc_attr,
    )
}

fn main() -> Result<()> {
    let mut args = std::env::args().skip(1);
    let use_enclave = match args
        .next()
        .ok_or_else(|| anyhow!("please specify use_enclave (sgx/plain)"))?
        .as_str()
    {
        "sgx" => true,
        "plain" => false,
        _ => bail!("use_enclave must be 'sgx' or 'plain'"),
    };
    let path = args.next().ok_or_else(|| anyhow!("please specify path"))?;
    let npz = args
        .next()
        .ok_or_else(|| anyhow!("please specify npz input"))?;
    let repeats = args
        .next()
        .ok_or_else(|| anyhow!("please specify number of repeats"))?
        .parse::<usize>()
        .map_err(|_| anyhow!("number of repeats must be a usize"))?;
    let samples = args
        .next()
        .ok_or_else(|| anyhow!("please specify number of samples"))?
        .parse::<usize>()
        .map_err(|_| anyhow!("number of samples must be a usize"))?;

    // run

    if use_enclave {
        let encl = init_enclave()
            .map_err(|err| anyhow!("SGX Error: {}", err.as_str()))
            .context("initializing enclave")?;

        let result = unsafe {
            sgx_main(
                encl.geteid(),
                CString::new(path)?.as_ptr(),
                CString::new(npz)?.as_ptr(),
                repeats,
                samples,
            )
        };
        if result != sgx_status_t::SGX_SUCCESS {
            bail!("SGX Error: {}", result.as_str());
        }
    } else {
        benches::main(
            false,
            &path,
            &npz,
            repeats,
            samples,
        )
        .unwrap();
    }

    Ok(())
}
