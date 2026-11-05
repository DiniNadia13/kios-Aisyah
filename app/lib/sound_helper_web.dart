import 'dart:js_interop' as js;

@js.JS('notifyNewOrder')
external void _notifyNewOrder(js.JSString orderCode, js.JSString customerName, js.JSString total);

void playOrderChime({String orderCode = '', String customerName = '', String total = ''}) {
  try {
    _notifyNewOrder(orderCode.toJS, customerName.toJS, total.toJS);
  } catch (_) {}
}

