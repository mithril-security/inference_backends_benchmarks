if [ -f ./gpt-neo-2.7b/gpt-neo-2.7b.onnx ]; then
    echo "Nothing to do."
    exit
fi

[ ! -d ./gpt-neo-2.7b ] && mkdir gpt-neo-2.7b
python3 ./gpt-neo-2.7b_setup.py

# python3 -m onnxsim ./tmp/gpt-neo-2.7b/gpt-neo-2.7b_nooptim.onnx ./gpt-neo-2.7b/gpt-neo-2.7b.onnx
