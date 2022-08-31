if [ -f ./bert.onnx ]; then
    echo "Nothing to do."
    exit
fi

[ ! -d ./tmp ] && mkdir tmp

python3 ./bert_setup.py
python3 -m onnxsim ./tmp/bert_nooptim.onnx ./bert.onnx
