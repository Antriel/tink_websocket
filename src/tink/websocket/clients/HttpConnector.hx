
package tink.websocket.clients;

import haxe.io.Bytes;
import tink.Url;
import tink.websocket.Client;
import tink.websocket.RawMessage;
import tink.websocket.MaskingKey;
import tink.websocket.IncomingHandshakeResponseHeader;
import tink.websocket.OutgoingHandshakeRequestHeader;
import tink.http.Request;
import tink.http.Response;
import tink.streams.Stream;
import tink.streams.IdealStream;
import tink.streams.RealStream;
import tink.Url;
import js.html.*;

using tink.io.Source;
using tink.CoreApi;

/**
 *  Only works if the http client supports streaming
 */
class HttpConnector implements Connector {
	
	var url:Url;
	var client:tink.http.Client;
	
	public function new(url, client) {
		this.url = url;
		this.client = client;
	}
	
	public function connect(outgoing:RawMessageStream<Noise>):RawMessageStream<Error> {
		
		var requestHeader = new OutgoingHandshakeRequestHeader(url);
		var promise = client.request(new OutgoingRequest(
			requestHeader,
			RawMessageStream.lift(outgoing).toMaskedChunkStream(MaskingKey.random)
		))
			.next(function(res) {
				return Promise.lift((res.header:IncomingHandshakeResponseHeader).validate(requestHeader.accept))
					.next(function(_) return RawMessageStream.ofChunkStream(res.body.parseStream(new Parser())));
			});
		
		return Stream.promise(promise);
	}
}