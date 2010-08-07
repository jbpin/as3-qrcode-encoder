package org.jbpin.qrcodegen.component
{
	import flash.events.Event;
	
	import mx.containers.Canvas;
	
	[Event(name="generate")]
	public class QRGenerator extends Canvas
	{
		
		public static const GENERATE_EVENT:String = "generate";
		
		public var stToEncode:String;
		
		public function QRGenerator()
		{
			super();
		}
		
		public function generate():void{
			dispatchEvent(new Event(GENERATE_EVENT));
		}
	}
}