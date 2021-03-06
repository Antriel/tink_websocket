package tink.websocket.clients;

import haxe.io.Bytes;
import tink.Url;
import tink.websocket.Client;
import tink.websocket.RawMessage;
import tink.streams.Stream;
import tink.streams.IdealStream;
import tink.streams.RealStream;
import js.html.*;

using tink.CoreApi;

class JsConnector implements Connector {
	
	var url:String;
	
	public function new(url)
		this.url = url;
	
	public function connect(outgoing:RawMessageStream<Noise>):RawMessageStream<Error> {
		var ws = new WebSocket(url);
		ws.binaryType = BinaryType.ARRAYBUFFER;
		
		var trigger = Signal.trigger();
		var incoming = new SignalStream(trigger.asSignal());
		
		var opened = Future.async(function(cb) ws.onopen = cb.bind(Noise));
		ws.onclose = function() trigger.trigger(End);
		ws.onerror = function(e) trigger.trigger(Fail(Error.withData('WebSocket Error', e)));
		ws.onmessage = function(m:{data:Any}) trigger.trigger(Data(
			if(Std.is(m.data, String)) Text(m.data);
			else Binary(Bytes.ofData(m.data))
		));
		
		opened.handle(function(_) {
			outgoing.forEach(function(message) {
				switch message {
					case Text(v): ws.send(v);
					case Binary(v): ws.send(v.toBytes().getData());
					case _: // js client cannot handle raw messages
				}
				return Resume;
			}).handle(function(o) switch o {
				case Depleted: ws.close();
				case Halted(_): throw 'unreachable';
			});
		});
		
		return incoming;
	}
}