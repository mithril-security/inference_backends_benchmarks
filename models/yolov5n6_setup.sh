if [ -f ./yolov5n6.onnx ]; then
    echo "Nothing to do."
    exit
fi

[ ! -d ./tmp ] && mkdir tmp
[ ! -d ./tmp/yolov5 ] && git clone https://github.com/ultralytics/yolov5 --depth 1 ./tmp/yolov5 && \
                    wget -O ./tmp/yolov5 https://github.com/ultralytics/yolov5/releases/download/v6.0/yolov5n6.pt             

wget -q -O ./tmp/zidane.jpg https://huggingface.co/spaces/zhiqwang/assets/resolve/main/zidane.jpg

python3 ./tmp/yolov5/export.py --weights ./tmp/yolov5/yolov5n6.pt --include onnx
python3 ./yolov5n6_setup.py

python3 -m onnxsim ./tmp/yolov5/yolov5n6.onnx ./yolov5n6.onnx
