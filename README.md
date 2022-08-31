# Bench

This is a script to quickly compare tract, tract-sgx and ort backends for onnx models. It records the results in a .csv file.

## Requirements

You have to use this repo on an SGX enabled machine.

Vscode is preferable.

## Usage

If you're in vscode you can reopen the folder in container using the vscode containers extension.
Else you can build the dockerfile while mounting the root of this folder. Don't forget to specify the sgx devices in the run command.

Then set up the github repo:
```sh
git config --global --add safe.directory `pwd`
git submodule update --init
```

Then you can run the benchs with:
```sh
make
bash bench.sh [model1,model2,...] |& tee logs.txt
```

You have to explicitely run the gpt2.7b, as it is not present in the default list.

If you want to test a model not present in the models folder, you should:
- Add a bash and a python script that generate a .onnx and a .npz file.
- Ensure that each time you run the .sh script, the generated .onnx file is the same (if you can't manage to do it, you have to push your .onnx file somewhere).
- Check that the tensors in the npz files are nommed with the names of their corresponding input nodes. 
- Add your model to the MODELS list in bench.sh (you have to add it at 2 emplacements)

If you need to change the tract version, open an issue as everything might break very quickly


## Bonus: compare with tract cli output for sanity check

```sh
git clone https://github.com/sonos/tract tmp/tract -b 0.17.0 --depth 1
# curl https://raw.githubusercontent.com/mithril-security/tract-sgx-xargo/aux-patches/onnx/src/ops/resize.rs > ./tmp/tract/onnx/src/ops/resize.rs
cd ./tmp/tract/cli
cargo run --release -- --input-bundle ../../../models/yolov5s.npz ../../../models/yolov5s.onnx -O bench
# or: cargo run --release -- --input-bundle ../../../models/yolov5s.npz ../../../models/yolov5s.onnx -O criterion
# or: cargo run --release -- --input-bundle ../../../models/yolov5s.npz ../../../models/yolov5s.onnx -O dump --profile --cost
```
