package org.qrcode
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	
	import org.qrcode.encode.QRRawCode;
	import org.qrcode.enum.QRCodeEncodeType;
	import org.qrcode.enum.QRCodeErrorLevel;
	import org.qrcode.input.QRInput;
	import org.qrcode.specs.QRSpecs;
	import org.qrcode.utils.FrameFiller;
	import org.qrcode.utils.QRCodeTool;

	public class QRCode
	{
		private var data:Array = [];
		
		private var level:int;
		private var type:int;
		private var version:int = 1;
		private var width:int;
		
		private var text:String;
		
		[Bindable]
		public var bitmapData:BitmapData;
		
		public function QRCode(errorLevel:int=QRCodeErrorLevel.QRCODE_ERROR_LEVEL_LOW,encodeType:int = QRCodeEncodeType.QRCODE_ENCODE_BYTES) {
			this.level = errorLevel;
			this.type = encodeType;
			
		}
		
		public function encode(content:String):void{
			this.version = 1;
			this.text = content;
			encodeString(true);
			encodeBitmap();
		}
		
		
		private function encodeBitmap():void{
			this.bitmapData = QRImage.image(this.data);
		}
		
		private function encodeString(casesensitive:Boolean = true):void{
			if(type != QRCodeEncodeType.QRCODE_ENCODE_BYTES && type != QRCodeEncodeType.QRCODE_ENCODE_KANJI) {
				throw new Error('bad hint');
			}
			
			var input:QRInput = new QRInput(version, level);
			if(input == null) 
				return;
			
			input = QRSplit.splitStringToQRinput(text, input, type, casesensitive);
			
			var ar:Array = this.encodeInput(input);
			this.data = QRCodeTool.binarize(ar);
		}
		
		private function encodeMask(input:QRInput,mask:int):QRCode
		{
			if(input.version < 0 || input.version > QRSpecs.QRSPEC_VERSION_MAX) {
				throw new Error('wrong version');
			}
			if(input.errorCorrectionLevel > QRCodeErrorLevel.QRCODE_ERROR_LEVEL_HIGH) {
				throw new Error('wrong level');
			}
			
			var raw:QRRawCode = new QRRawCode(input);
			
			version = raw.version;
			width = QRSpecs.getWidth(version);
			var frame:Array = QRSpecs.newFrame(version);
			
			//this.data = frame;
			//return this;
			
			
			var filler:FrameFiller = new FrameFiller(width, frame);
			if(filler == null) {
				return null;
			}
			
			 
			// inteleaved data and ecc codes
			for(var i:int=0; i<raw.dataLength + raw.eccLength; i++) {
				var code:int = raw.getCode();
				var bit:int = 0x80;
				for(var j:int=0; j<8; j++) {
					var addr:Point = filler.next();
					filler.setFrameAt(addr, 0x02 | int((bit & code) != 0));
					bit = bit >> 1;
				}
			}
			
			
			// remainder bits
			var j:int = QRSpecs.getRemainder(version);
			for(var i:int=0; i<j; i++) {
				var addr:Point = filler.next();				
				filler.setFrameAt(addr, 0x02);
			}
			frame = filler.frame;
			
			// masking
			var maskObj:QRMask = new QRMask(frame);
			var masked:Array;
			if(mask < 0) {
				masked = maskObj.mask(width, input.errorCorrectionLevel);
			} else {
				masked = maskObj.makeMask(width, mask, input.errorCorrectionLevel);
			}
			
			if(masked == null) {
				return null;
			}
			this.data = masked;
			
			return this;
		}
		
		private function encodeInput(input:QRInput):Array
		{
			return this.encodeMask(input, -1).data;
		}
		
		private function encodeString8bit(string:String, version:int, level:int):Array
		{
			if(string == "") {
				throw new Error('empty string!');
			}
			
			var input:QRInput = new QRInput(version, level);
			if(input == null) return null;
			
			var ret:int = input.append(QRCodeEncodeType.QRCODE_ENCODE_BYTES, string.length, string.split(""));
			if(ret < 0) {
				return null;
			}
			return this.data = QRCodeTool.binarize(this.encodeInput(input));
		}
	}
}