import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;
  Function(Map<String, dynamic>)? _onOrderStatusChanged;

  void connect() {
    _socket = IO.io(
      'https://thevillage-backend.onrender.com',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      },
    );

    _socket!.connect();

    _socket!.on('order_status_or_driver_changed', (data) {
      if (_onOrderStatusChanged != null) {
        _onOrderStatusChanged!(data);
      }
    });
  }

  void setOnOrderStatusChanged(Function(Map<String, dynamic>) callback) {
    _onOrderStatusChanged = callback;
  }

  void disconnect() {
    _socket?.disconnect();
  }
}
