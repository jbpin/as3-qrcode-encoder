package org.qrcode
{
	import flash.geom.Point;
	
	import org.qrcode.enum.QRCodeEncodeType;
	import org.qrcode.input.QRInput;
	import org.qrcode.specs.QRSpecs;

	public class QRSplit
	{
		public var dataStr:Array = [];
		public var input:QRInput;
		public var modeHint:int;
		
		public function QRSplit(dataStr:String, input:QRInput, modeHint:int){
			this.dataStr  = dataStr.split("");
			this.input    = input;
			this.modeHint = modeHint;
		}
		
		public static function isdigitat(str:Array, pos:int):Boolean
		{
			if (pos >= str.length)
				return false;
			
			return ((str[pos].toString().charCodeAt() >= '0'.charCodeAt())&&(str[pos].toString().charCodeAt() <= '9'.charCodeAt()));
		}
		
		public static function isalnumat(str:Array, pos:int):Boolean
		{
			if (pos >= str.length)
				return false;
			
			return (QRInput.lookAnTable(str[pos].toString().charCodeAt()) >= 0);
		}
		
		public function identifyMode(pos:int):int
		{
			if (pos >= this.dataStr.length)
				return -1;
			
			var c:String = this.dataStr[pos];
			
			if(isdigitat(this.dataStr, pos)) {
				return QRCodeEncodeType.QRCODE_ENCODE_NUMERIC;
			} else if(isalnumat(this.dataStr, pos)) {
				return QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC;
			} else if(this.modeHint == QRCodeEncodeType.QRCODE_ENCODE_KANJI) {
				
				if (pos+1 < this.dataStr.length)
				{
					var d:String = this.dataStr[pos+1];
					var word:int = (c.charCodeAt() << 8) | d.charCodeAt();
					if((word >= 0x8140 && word <= 0x9ffc) || (word >= 0xe040 && word <= 0xebbf)) {
						return QRCodeEncodeType.QRCODE_ENCODE_KANJI;
					}
				}
			}
			
			return QRCodeEncodeType.QRCODE_ENCODE_BYTES;
		}
		
		public function eatNum():int
		{
			var ln:int = QRSpecs.lengthIndicator(QRCodeEncodeType.QRCODE_ENCODE_NUMERIC, this.input.version);
			
			var p:int = 0;
			while(isdigitat(this.dataStr, p)) {
				p++;
			}
			
			var run:int = p;
			var mode:int = this.identifyMode(p);
			
			if(mode == QRCodeEncodeType.QRCODE_ENCODE_BYTES) {
				var dif:int = QRInput.estimateBitsModeNum(run) + 4 + ln
					+ QRInput.estimateBitsMode8(1)         // + 4 + l8
					- QRInput.estimateBitsMode8(run + 1); // - 4 - l8
				if(dif > 0) {
					return this.eat8();
				}
			}
			if(mode == QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC) {
				dif = QRInput.estimateBitsModeNum(run) + 4 + ln
					+ QRInput.estimateBitsModeAn(1)        // + 4 + la
					- QRInput.estimateBitsModeAn(run + 1);// - 4 - la
				if(dif > 0) {
					return this.eatAn();
				}
			}
			
			var ret:int = this.input.append(QRCodeEncodeType.QRCODE_ENCODE_NUMERIC, run, this.dataStr);
			if(ret < 0)
				return -1;
			
			return run;
		}
		
		public function eatAn():int
		{
			var la:int = QRSpecs.lengthIndicator(QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC,  this.input.version);
			var ln:int = QRSpecs.lengthIndicator(QRCodeEncodeType.QRCODE_ENCODE_NUMERIC, this.input.version);
			
			var p:int = 0;
			
			while(isalnumat(this.dataStr, p)) {
				if(isdigitat(this.dataStr, p)) {
					var q:int = p;
					while(isdigitat(this.dataStr, q)) {
						q++;
					}
					
					var dif:int = QRInput.estimateBitsModeAn(p) // + 4 + la
						+ QRInput.estimateBitsModeNum(q - p) + 4 + ln
						- QRInput.estimateBitsModeAn(q); // - 4 - la
					
					if(dif < 0) {
						break;
					} else {
						p = q;
					}
				} else {
					p++;
				}
			}
			
			var run:int = p;
			
			if(!isalnumat(this.dataStr, p)) {
				dif = QRInput.estimateBitsModeAn(run) + 4 + la
					+ QRInput.estimateBitsMode8(1) // + 4 + l8
					- QRInput.estimateBitsMode8(run + 1); // - 4 - l8
				if(dif > 0) {
					return this.eat8();
				}
			}
			
			var ret:int = this.input.append(QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC, run, this.dataStr);
			if(ret < 0)
				return -1;
			
			return run;
		}
		
		public function eatKanji():int
		{
			var p:int = 0;
			
			while(this.identifyMode(p) == QRCodeEncodeType.QRCODE_ENCODE_KANJI) {
				p += 2;
			}
			
			var run:int = p;
			var ret:int = this.input.append(QRCodeEncodeType.QRCODE_ENCODE_KANJI, p, this.dataStr);
			if(ret < 0)
				return -1;
			
			return run;
		}
		
		public function eat8():int
		{
			var la:int = QRSpecs.lengthIndicator(QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC, this.input.version);
			var ln:int = QRSpecs.lengthIndicator(QRCodeEncodeType.QRCODE_ENCODE_NUMERIC, this.input.version);
			
			var p:int = 1;
			var dataStrLen:int = this.dataStr.length;
			
			while(p < dataStrLen) {
				
				var mode:int = this.identifyMode(p);
				if(mode == QRCodeEncodeType.QRCODE_ENCODE_KANJI) {
					break;
				}
				if(mode == QRCodeEncodeType.QRCODE_ENCODE_NUMERIC) {
					var q:int = p;
					while(isdigitat(this.dataStr, q)) {
						q++;
					}
					var dif:int = QRInput.estimateBitsMode8(p) // + 4 + l8
						+ QRInput.estimateBitsModeNum(q - p) + 4 + ln
						- QRInput.estimateBitsMode8(q); // - 4 - l8
					if(dif < 0) {
						break;
					} else {
						p = q;
					}
				} else if(mode == QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC) {
					q = p;
					while(isalnumat(this.dataStr, q)) {
						q++;
					}
					dif = QRInput.estimateBitsMode8(p)  // + 4 + l8
						+ QRInput.estimateBitsModeAn(q - p) + 4 + la
						- QRInput.estimateBitsMode8(q); // - 4 - l8
					if(dif < 0) {
						break;
					} else {
						p = q;
					}
				} else {
					p++;
				}
			}
			
			var run:int = p;
			var ret:int = this.input.append(QRCodeEncodeType.QRCODE_ENCODE_BYTES, run, this.dataStr);
			
			if(ret < 0)
				return -1;
			
			return run;
		}
		
		public function splitString():int
		{
			while (this.dataStr.length > 0)
			{
				var mode:int = this.identifyMode(0);
				var length:int;
				switch (mode) {
					case QRCodeEncodeType.QRCODE_ENCODE_NUMERIC: length = this.eatNum(); break;
					case QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC:  length = this.eatAn(); break;
					case QRCodeEncodeType.QRCODE_ENCODE_KANJI:
						if (modeHint == QRCodeEncodeType.QRCODE_ENCODE_KANJI)
							length = this.eatKanji();
						else    length = this.eat8();
						break;
					default: length = this.eat8(); break;
					
				}
				
				if(length == 0) return 0;
				if(length < 0)  return -1;
				
				this.dataStr = this.dataStr.slice(length);
			}
			return length;
		}
		
		public function toUpper():Array
		{
			var stringLen:int = this.dataStr.length;
			var p:int = 0;
			
			while (p<stringLen) {
				var mode:int = identifyMode(this.modeHint);
				if(mode == QRCodeEncodeType.QRCODE_ENCODE_KANJI) {
					p += 2;
				} else {
					if (this.dataStr[p].charCodeAt() >= 'a'.charCodeAt() && this.dataStr[p].charCodeAt() <= 'z'.charCodeAt()) {
						this.dataStr[p] = String.fromCharCode(this.dataStr[p].charCodeAt() - 32);
					}
					p++;
				}
			}
			
			return this.dataStr;
		}
		
		public static function splitStringToQRinput(string:String, input:QRInput, modeHint:int, casesensitive:Boolean = true):QRInput
		{
			if(string == null || string == '\0' || string == '') {
				throw new Error('empty string!!!');
			}
			
			var split:QRSplit = new QRSplit(string, input, modeHint);
			
			if(!casesensitive)
				split.toUpper();
			
			split.splitString();
			return split.input;
		}
	}
}
