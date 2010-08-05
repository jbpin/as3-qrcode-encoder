package org.qrencode
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	
	import org.qrencode.encode.QRRawCode;
	import org.qrencode.enum.QRCodeEncodeType;
	import org.qrencode.enum.QRCodeErrorLevel;
	import org.qrencode.input.QRInput;
	import org.qrencode.specs.QRSpecs;
	import org.qrencode.utils.FrameFiller;
	import org.qrencode.utils.QRCodeTool;

	public class QRCode
	{
		private var data:Array = [];
		
		private var level:int;
		private var type:int;
		private var version:int = 1;
		private var items:ArrayCollection;
		private var width:int;
		
		private var text:String;
		
		public var bitmapData:BitmapData;
		
		public function QRCode(text:String, encodeType:int = QRCodeEncodeType.QRCODE_ENCODE_BYTES, errorLevel:int=QRCodeErrorLevel.QRCODE_ERROR_LEVEL_LOW) {
			this.level = errorLevel;
			this.type = encodeType;
			this.text = text;
			//encodeString8bit(text,version,level);
			encodeString();
			encodeBitmap();
		}
		
		public function createFrame(version:int):void{
			var ar:Array = QRSpecs.createFrame(version);
			this.data = QRCodeTool.binarize(ar);
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
		
		//----------------------------------------------------------------------
		public function encodeMask(input:QRInput,mask:int):QRCode
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
		
		public function encodeInput(input:QRInput):Array
		{
			return this.encodeMask(input, -1).data;
		}
		
		public function encodeString8bit(string:String, version:int, level:int):Array
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