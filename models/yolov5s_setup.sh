if [ -f ./yolov5s.onnx ]; then
    echo "Nothing to do."
    exit
fi

[ ! -d ./tmp ] && mkdir tmp
[ ! -d ./tmp/yolov5 ] && git clone https://github.com/ultralytics/yolov5 --depth 1 ./tmp/yolov5

wget -q -O ./tmp/zidane.jpg https://huggingface.co/spaces/zhiqwang/assets/resolve/main/zidane.jpg

python3 ./tmp/yolov5/export.py --weights ./tmp/yolov5/yolov5s.pt --include onnx
python3 ./yolov5s_setup.py

python3 -m onnxsim ./tmp/yolov5/yolov5s.onnx ./yolov5s.onnx
