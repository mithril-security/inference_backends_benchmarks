use std::{ffi::CStr, os::raw::c_char};

extern crate benches;
extern crate sgx_types;

use sgx_types::*;

#[no_mangle]
pub extern "C" fn sgx_main(
    path: *const c_char,
    npz: *const c_char,
    repeats: size_t,
    samples: size_t
) {
    benches::main(
        true,
        unsafe { CStr::from_ptr(path) }.to_str().unwrap(),
        unsafe { CStr::from_ptr(npz) }.to_str().unwrap(),
        repeats,
        samples,
    )
    .unwrap();
}
