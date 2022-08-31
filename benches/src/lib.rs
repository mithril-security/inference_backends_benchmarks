use anyhow::{bail, Context, Result};
use std::{fs, path::Path, time::Instant, io::Write};
use tract_onnx::prelude::*;

pub fn read_npz(npz: &mut ndarray_npy::NpzReader<fs::File>, name: &str) -> Result<Tensor> {
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<f32>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<f64>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<i8>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<i16>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<i32>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<i64>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<u8>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<u16>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<u32>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<u64>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    if let Ok(t) = npz.by_name::<tract_ndarray::OwnedRepr<bool>, tract_ndarray::IxDyn>(name) {
        return Ok(t.into_tensor());
    }
    bail!("Can not extract tensor from {}", name);
}

pub fn main(
    is_enclave: bool,
    path: &str,
    npz: &str,
    repeats: usize,
    samples: usize,
) -> Result<()> {
    env_logger::init();

    let mut npz = ndarray_npy::NpzReader::new(fs::File::open(npz)?)?;
    println!("Running in enclave: {}", is_enclave);

    let mut model = tract_onnx::onnx().with_ignore_output_shapes(true).model_for_path(path)?;

    println!("Inputs:");
    let mut inputs = tvec![];
    for (i, name) in npz.names()?.into_iter().enumerate() {
        let tensor = read_npz(&mut npz, &name)
            .with_context(|| format!("reading npz tensor with name: {}", name))?;
        let fact = InferenceFact::dt_shape_from_tensor(&tensor);
        println!("{}: {:?}", name, fact);
        inputs.push(tensor);
        model = model.with_input_fact(i, fact)?;
    }

    let model = model.into_optimized()?.into_runnable()?;
    println!("Optimized!");

    bench(
        is_enclave,
        path,
        repeats,
        samples,
        || {
            let _result = model.run(inputs.clone()).unwrap();
        },
    )?;

    Ok(())
}

fn bench(
    is_enclave: bool,
    model_path: &str,
    repeats: usize,
    samples: usize,
    f: impl Fn(),
) -> Result<()> {
    let mut results = vec![];
    results.reserve(samples);

    for i in 1..=samples {
        let start = Instant::now();
        for _ in 0..repeats {
            f();
        }
        let elapsed = start.elapsed().as_micros() / repeats as u128;

        println!("bench (sample {}/{}): {}us/iter, {} iter", i, samples, elapsed, repeats);

        results.push(elapsed);
    }

    let mean = results.iter().copied().sum::<u128>() as f64 / results.len() as f64;
    let variance: f64 = results
        .iter()
        .map(|res| (*res as f64 - mean).powf(2.0))
        .sum::<f64>()
        / results.len() as f64;
    let std_deviation = variance.sqrt();
    println!("Mean {}", mean / 1000.0);
    println!("Variance {}", variance / 1000.0);
    println!("Std deviation {}", std_deviation / 1000.0);

    Ok(())
}
