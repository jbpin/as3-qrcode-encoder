package org.qrcode
{
	import org.qrcode.utils.QRUtil;

	public class QRbitstream
	{
		
		public var data:Array = [];
		
		public function QRbitstream()
		{
		}
		
		public function get size():int
		{
			return this.data.length;
		}
		
		public function allocate(setLength:int):void
		{
			this.data = QRUtil.array_fill(0, setLength, 0x00);
		}
		
		public static function newFromNum(bits:Number, num:Number):QRbitstream
		{
			var bstream:QRbitstream = new QRbitstream();
			bstream.allocate(bits);
			
			var mask:int = 1 << (bits - 1);
			for(var i:int=0; i<bits; i++) {
				if(num & mask) {
					bstream.data[i] = 1;
				} else {
					bstream.data[i] = 0;
				}
				mask = mask >> 1;
			}
			
			return bstream;
		}
		
		public static function newFromBytes(size:int, data:Array):QRbitstream
		{
			var bstream:QRbitstream = new QRbitstream();
			bstream.allocate(size * 8);
			var p:int =0;
			
			for(var i:int=0; i<size; i++) {
				var mask:Number = 0x80;
				for(var j:int=0; j<8; j++) {
					if(data[i] & mask) {
						bstream.data[p] = 1;
					} else {
						bstream.data[p] = 0;
					}
					p++;
					mask = mask >> 1;
				}
			}
			
			return bstream;
		}
		
		public function append(arg:QRbitstream):void
		{
			if (arg == null) {
				return;
			}
			
			if(arg.size == 0) {
				return;
			}
			
			if(this.size == 0) {
				this.data = arg.data;
				return;
			}
			
			QRUtil.array_merge(this.data,arg.data);
		}
		
		public function appendNum(bits:Number, num:Number):void
		{
			if (bits == 0)
				return;
			
			var b:QRbitstream = QRbitstream.newFromNum(bits, num);
			
			if(b == null)
				return;
			
			this.append(b);
		}
		
		public function appendBytes(size:int, data:Array):void
		{
			if (size == 0)
				return;
			
			var b:QRbitstream = QRbitstream.newFromBytes(size, data);
			
			if(b == null)
				return;
			
			this.append(b);
		}
		
		public function toByte():Array
		{
			
			var size:int = this.size;
			
			if(size == 0) {
				return [];
			}
			
			var databyte:Array = QRUtil.array_fill(0, (size + 7) / 8, 0x00);
			var bytes:int = size / 8;
			
			var p:int = 0;
			
			for(var i:int=0; i<bytes; i++) {
				var v:Number = 0x00;
				for(var j:int=0; j<8; j++) {
					v = v << 1;
					v |= this.data[p];
					p++;
				}
				databyte[i] = v;
			}
			
			if(size & 7) {
				v = 0x00;
				for(j=0; j<(size & 7); j++) {
					v = v << 1;
					v |= this.data[p];
					p++;
				}
				databyte[bytes] = v;
			}
			
			return databyte;
		}
		
	}
}
