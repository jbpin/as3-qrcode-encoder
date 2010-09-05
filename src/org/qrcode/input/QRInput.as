package org.qrcode.input
{
	
	import org.qrcode.QRbitstream;
	import org.qrcode.enum.QRCodeEncodeType;
	import org.qrcode.enum.QRCodeErrorLevel;
	import org.qrcode.specs.QRSpecs;

	public class QRInput
	{		
		public var items:Array;
		
		private var _version:int;
		private var _level:int;
		
		public function QRInput(qrversion:int = 0, qrlevel:int = QRCodeErrorLevel.QRCODE_ERROR_LEVEL_LOW)
		{
			if (qrversion < 0 || qrversion > QRSpecs.QRSPEC_VERSION_MAX || qrlevel > QRCodeErrorLevel.QRCODE_ERROR_LEVEL_HIGH) {
				throw new Error('Invalid version no');
				return null;
			}
			this.items = [];
			this._version = qrversion;
			this._level = qrlevel;
		}
		
		public function get version():int
		{
			return this._version;
		}
		
		public function set version(value:int):void
		{
			if(value < 0 || value > QRSpecs.QRSPEC_VERSION_MAX) {
				throw new Error('Invalid version no');
				return;
			}
			this._version = value;
		}
		
		public function get errorCorrectionLevel():int{
			return this._level;
		}
		
		public function set errorCorrectionLevel(value:int):void
		{
			if(value > QRCodeErrorLevel.QRCODE_ERROR_LEVEL_HIGH) {
				throw new Error('Invalid ECLEVEL');
			}
			
			this._level = value;
			
		}
		
		public function appendEntry(entry:QRInputItem):void
		{
			this.items.addItem(entry);
		}
		
		public function append(mode:int, size:int, data:Array):int
		{
			try {
				var entry:QRInputItem = new QRInputItem(mode, size, data);
				this.items.push(entry);
				return 0;
			} catch (e:Error) {
				return -1;
			}
			return 0;
		}
		
		public function insertStructuredAppendHeader(size:int, index:int, parity:int):int
		{
			if( size > QRInputItem.MAX_STRUCTURED_SYMBOLS ) {
				throw new Error('insertStructuredAppendHeader wrong size');
			}
			
			if( index <= 0 || index > QRInputItem.MAX_STRUCTURED_SYMBOLS ) {
				throw new Error('insertStructuredAppendHeader wrong index');
			}
			
			var buf:Array = [size, index, parity];
			
			try {
				var entry:QRInputItem = new QRInputItem(QRCodeEncodeType.QRCODE_ENCODE_STRUCTURE, 3, buf);
				this.items.unshift(entry);
				return 0;
			} catch (e:Error) {
				return -1;
			}
			return 0;
		}
		
		public function calcParity():Number
		{
			var parity:Number = 0;
			
			for each(var item:QRInputItem in items) {
				if(item.mode != QRCodeEncodeType.QRCODE_ENCODE_STRUCTURE) {
					for(var i:int=item.size-1; i>=0; i--) {
						parity ^= item.data[i];
					}
				}
			}
			
			return parity;
		}
		
		public static function checkModeNum(size:int, data:Array):Boolean
		{
			for(var i:int=0; i<size; i++) {
				if((data[i].toString().charCodeAt() < '0'.charCodeAt() || data[i].toString().charCodeAt() > '9'.charCodeAt())){
					return false;
				}
			}
			
			return true;
		}
		
		public static function estimateBitsModeNum(size:int):int
		{
			var w:int = size / 3;
			var bits:int = w * 10;
			
			switch(size - w * 3) {
				case 1:
					bits += 4;
					break;
				case 2:
					bits += 7;
					break;
				default:
					break;
			}
			
			return bits;
		}
		
		public static const anTable:Array = [
			-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
			36, -1, -1, -1, 37, 38, -1, -1, -1, -1, 39, 40, -1, 41, 42, 43,
			0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 44, -1, -1, -1, -1, -1,
			-1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
			25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
			-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
		];
		
		public static function lookAnTable(c:int):int
		{
			return ((c > 127)?-1:anTable[c]);
		}
		
		public static function checkModeAn(size:int, data:Array):Boolean
		{
			for(var i:int=0; i<size; i++) {
				if (lookAnTable(data[i].toString().charCodeAt()) == -1) {
					return false;
				}
			}
			return true;
		}
		
		public static function estimateBitsModeAn(size:int):int
		{
			var w:int = size / 2;
			var bits:int = w * 11;
			
			if(size & 1) {
				bits += 6;
			}
			
			return bits;
		}
		
		public static function estimateBitsMode8(size:int):int
		{
			return size * 8;
		}
		
		public static function estimateBitsModeKanji(size:int):int
		{
			return (size / 2) * 13;
		}
		
		public static function checkModeKanji(size:int, data:Array):Boolean
		{
			if(size & 1)
				return false;
			
			for(var i:int=0; i<size; i+=2) {
				var val:int = (data[i] << 8) | data[i+1];
				if( val < 0x8140 
					|| (val > 0x9ffc && val < 0xe040) 
					|| val > 0xebbf) {
					return false;
				}
			}
			
			return true;
		}
		
		/***********************************************************************
		 * Validation
		 **********************************************************************/
		
		public static function check(mode:int, size:int, data:Array):Boolean
		{
			if(size <= 0) 
				return false;
			
			switch(mode) {
				case QRCodeEncodeType.QRCODE_ENCODE_NUMERIC:
					return checkModeNum(size, data);   
				break;
				case QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC: 
					return checkModeAn(size, data);
				break;
				case QRCodeEncodeType.QRCODE_ENCODE_KANJI:
					return checkModeKanji(size, data);
				break;
				case QRCodeEncodeType.QRCODE_ENCODE_BYTES:
					return true;
				break;
				case QRCodeEncodeType.QRCODE_ENCODE_STRUCTURE:
					return true;
				break;
				default:
					break;
			}
			
			return false;
		}
		
		public function estimateBitStreamSize(version:int):int
		{
			var bits:int = 0;
			
			for each(var item:QRInputItem in this.items) {
				bits += item.estimateBitStreamSizeOfEntry(version);
			}
			
			return bits;
		}
		
		public function estimateVersion():int
		{
			var version:int = 0;
			var prev:int = 0;
			do {
				prev = version;
				var bits:int = this.estimateBitStreamSize(prev);
				version = QRSpecs.getMinimumVersion(((bits + 7) / 8), _level);
				if (version < 0) {
					return -1;
				}
			} while (version > prev);
			
			return version;
		}
		
		public static function lengthOfCode(mode:int, version:int, bits:int):int
		{
			var payload:int = bits - 4 - QRSpecs.lengthIndicator(mode, version);
			var chunks:int;
			var remain:Number;
			var size:int
			switch(mode) {
				case QRCodeEncodeType.QRCODE_ENCODE_NUMERIC:
					chunks = payload / 10;
					remain = payload - chunks * 10;
					size = chunks * 3;
					if(remain >= 7) {
						size += 2;
					} else if(remain >= 4) {
						size += 1;
					}
					break;
				case QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC:
					chunks = payload / 11;
					remain = payload - chunks * 11;
					size = chunks * 2;
					if(remain >= 6) 
						size++;
					break;
				case QRCodeEncodeType.QRCODE_ENCODE_BYTES:
					size = payload / 8;
					break;
				case QRCodeEncodeType.QRCODE_ENCODE_KANJI:
					size = (payload / 13) * 2;
					break;
				case QRCodeEncodeType.QRCODE_ENCODE_STRUCTURE:
					size = payload / 8;
					break;
				default:
					size = 0;
					break;
			}
			
			var maxsize:int = QRSpecs.maximumWords(mode, version);
			if(size < 0) size = 0;
			if(size > maxsize) size = maxsize;
			
			return size;
		}
		
		public function createBitStream():int
		{
			var total:int = 0;
			
			for each(var item:QRInputItem in this.items) {
				var bits:int = item.encodeBitStream(this.version);
				
				if(bits < 0) 
					return -1;
				
				total += bits;
			}
			
			return total;
		}
		
		public function convertData():int
		{
			var ver:int = this.estimateVersion();
			if(ver > this.version) {
				this.version = ver;
			}
			
			for(;;) {
				var bits:int = this.createBitStream();
				
				if(bits < 0) 
					return -1;
				
				ver = QRSpecs.getMinimumVersion((bits + 7) / 8, _level);
				if(ver < 0) {
					throw new Error('WRONG VERSION');
					return -1;
				} else if(ver > this.version) {
					this.version = ver;
				} else {
					break;
				}
			}
			
			return 0;
		}
		
		public function appendPaddingBit(bstream:QRbitstream):QRbitstream
		{
			var bits:int = bstream.size;
			var maxwords:int = QRSpecs.getDataLength(_version, _level);
			var maxbits:int = maxwords * 8;
			
			if (maxbits == bits) {
				return bstream;
			}
			
			if (maxbits - bits < 5) {
				bstream.appendNum(maxbits - bits, 0);
				return bstream;
			}
			
			bits += 4;
			var words:int = (bits + 7) / 8;
			
			var padding:QRbitstream = new QRbitstream();
			padding.appendNum(words * 8 - bits + 4, 0);
			
			var padlen:int = maxwords - words;
			
			if(padlen > 0) {
				
				var padbuf:Array = [];
				for(var i:int=0; i<padlen; i++) {
					padbuf[i] = (i&1)?0x11:0xec;
				}
				
				padding.appendBytes(padlen, padbuf);
				
			}
			
			bstream.append(padding);
			
			return bstream;
		}
		
		public function mergeBitStream():QRbitstream
		{
			if(this.convertData() < 0) {
				return null;
			}
			
			var bstream:QRbitstream = new QRbitstream();
			
			for each(var item:QRInputItem in this.items) {
				bstream.append(item.bstream);
			}
			
			return bstream;
		}
		
		public function getBitStream():QRbitstream
		{
			
			var bstream:QRbitstream = this.mergeBitStream();
			
			if(bstream == null) {
				return null;
			}
			
			this.appendPaddingBit(bstream);
			
			return bstream;
		}
		
		public function getByteStream():Array
		{
			var bstream:QRbitstream = this.getBitStream();
			if(bstream == null) {
				return null;
			}
			
			return bstream.toByte();
		}
	}
}