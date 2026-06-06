from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/')
def get_script():
    # 1. Thu thập toàn bộ thông tin từ request
    request_info = {
        "client_ip": request.remote_addr,                     # IP của người gửi
        "method": request.method,                             # Phương thức (GET, POST...)
        "full_url": request.url,                              # URL đầy đủ
        "headers": dict(request.headers),                     # Toàn bộ HTTP Headers
        "query_args": dict(request.args),                     # Các tham số trên URL (?key=value)
        "body_data": request.get_data(as_text=True)           # Dữ liệu gửi kèm (nếu có)
    }
    
    # 2. In ra Console (Terminal) của server để dễ debug
    print("\n" + "="*30 + " NEW REQUEST " + "="*30)
    for key, value in request_info.items():
        print(f"{key.upper()}: {value}")
    print("="*73 + "\n")
    
    # Kiểm tra thử User-Agent như cũ
    user_agent = request.headers.get('User-Agent', '')
    if "Roblox/WinInet" in user_agent or "Synapse" in user_agent:
        request_info["status"] = "Request hợp lệ từ Executor"
    else:
        request_info["status"] = "Không có dấu hiệu của Executor"

    # 3. Trả về toàn bộ dữ liệu dưới dạng JSON
    return jsonify(request_info)

if __name__ == '__main__':
    # Bật debug=True để server tự reload khi sửa code
    # host='0.0.0.0' giúp nhận request từ thiết bị khác trong cùng mạng LAN (nếu cần)
    app.run(debug=True, host='0.0.0.0', port=5000)