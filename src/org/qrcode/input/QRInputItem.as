package org.qrcode.input
{
	import org.qrcode.QRbitstream;
	import org.qrcode.enum.QRCodeEncodeType;
	import org.qrcode.specs.QRSpecs;
	import org.qrcode.utils.QRUtil;
	
	

	public class QRInputItem
	{
		public static const STRUCTURE_HEADER_BITS:int = 20;
		public static const MAX_STRUCTURED_SYMBOLS:int = 16;
		
		public var mode:int;
		public var size:int;
		public var data:Array;
		public var bstream:QRbitstream;
		
		public function QRInputItem(mode:int, size:int, data:Array, bstream:QRbitstream = null)
		{
			var setData:Array =  data.slice(0,size);
			
			if (setData.length < size) {
				setData = QRUtil.array_merge(setData,QRUtil.array_fill(0,size-setData.length,0x00));
			}
			
			if(!QRInput.check(mode, size, setData)) {
				throw new Error('Error m:'+mode+',s:'+size+',d:'+setData.join(','));
			}
			
			this.mode = mode;
			this.size = size;
			this.data = setData;
			this.bstream = bstream;
		}
		
		public function encodeModeNum(version:int):int
		{
			try {
				
				var words:int = this.size / 3;
				var bs:QRbitstream = new QRbitstream();
				
				var val:int = 0x01;
				bs.appendNum(4, val);
				bs.appendNum(QRSpecs.lengthIndicator(QRCodeEncodeType.QRCODE_ENCODE_NUMERIC, version), size);
				
				for(var i:int=0; i<words; i++) {
					val  =  (this.data[i*3].toString().charCodeAt() - "0".charCodeAt()) * 100;
					val += (this.data[i*3+1].toString().charCodeAt() - "0".charCodeAt()) * 10;
					val += (this.data[i*3+2].toString().charCodeAt() - "0".charCodeAt());
					bs.appendNum(10, val);
				}
				
				if(this.size - words * 3 == 1) {
					val = (this.data[words*3]).toString().charCodeAt() - '0'.charCodeAt();
					bs.appendNum(4, val);
				} else if(this.size - words * 3 == 2) {
					val  = ((this.data[words*3  ]).toString().charCodeAt() - '0'.charCodeAt()) * 10;
					val += this.data[words*3+1].toString().charCodeAt() - '0'.charCodeAt();
					bs.appendNum(7, val);
				}
				
				this.bstream = bs;
				return 0;
				
			} catch (e:Error) {
				return -1;
			}
			return 0;
		}
		
		public function encodeModeAn(version:int):int
		{
			try {
				var words:int = this.size / 2;
				
				var bs:QRbitstream = new QRbitstream();
				
				bs.appendNum(4, 0x02);
				bs.appendNum(QRSpecs.lengthIndicator(QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC, version), this.size);
				
				for(var i:int=0; i<words; i++) {
					var val:int  = QRInput.lookAnTable(this.data[i*2].toString().charCodeAt()) * 45;
					val += QRInput.lookAnTable(this.data[i*2+1].toString().charCodeAt());
					
					bs.appendNum(11, val);
				}
				
				if(this.size & 1) {
					val = QRInput.lookAnTable(this.data[words * 2].toString().charCodeAt());
					bs.appendNum(6, val);
				}
				
				this.bstream = bs;
				return 0;
				
			} catch (e:Error) {
				return -1;
			}
			return 0;
		}
		
		public function encodeMode8(version:int):int
		{
			try {
				var bs:QRbitstream = new QRbitstream();
				
				bs.appendNum(4, 0x4);
				bs.appendNum(QRSpecs.lengthIndicator(QRCodeEncodeType.QRCODE_ENCODE_BYTES, version), this.size);
				
				for(var i:int=0; i<this.size; i++) {
					bs.appendNum(8, this.data[i].toString().charCodeAt());
				}
				
				this.bstream = bs;
				return 0;
				
			} catch (e:Error) {
				return -1;
			}
			return 0;
		}
		
		public function encodeModeKanji(version:int):int
		{
			try {
				var bs:QRbitstream = new QRbitstream();
				
				bs.appendNum(4, 0x8);
				bs.appendNum(QRSpecs.lengthIndicator(QRCodeEncodeType.QRCODE_ENCODE_KANJI, version), this.size / 2);
				
				for(var i:int=0; i<this.size; i+=2) {
					var val:int = (this.data[i].toString().charCodeAt() << 8) | this.data[i+1].toString().charCodeAt();
					if(val <= 0x9ffc) {
						val -= 0x8140;
					} else {
						val -= 0xc140;
					}
					
					var h:int = (val >> 8) * 0xc0;
					val = (val & 0xff) + h;
					
					bs.appendNum(13, val);
				}
				
				this.bstream = bs;
				return 0;
				
			} catch (e:Error) {
				return -1;
			}
			return 0;
		}
		
		public function encodeModeStructure():int
		{
			try {
				var bs:QRbitstream =  new QRbitstream();
				
				bs.appendNum(4, 0x03);
				bs.appendNum(4, this.data[1].toString().charCodeAt() - 1);
				bs.appendNum(4, this.data[0].toString().charCodeAt() - 1);
				bs.appendNum(8, this.data[2].toString().charCodeAt());
				
				this.bstream = bs;
				return 0;
				
			} catch (e:Error) {
				return -1;
			}
			return 0;
		}
		
		public function estimateBitStreamSizeOfEntry(version:int):int
		{
			var bits:int = 0;
			
			if(version == 0)
				version = 1;
			
			switch(this.mode) {
				case QRCodeEncodeType.QRCODE_ENCODE_NUMERIC:
					bits = QRInput.estimateBitsModeNum(this.size);
				break;
				case QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC:
					bits = QRInput.estimateBitsModeAn(this.size);
				break;
				case QRCodeEncodeType.QRCODE_ENCODE_BYTES:
					bits = QRInput.estimateBitsMode8(this.size);
				break;
				case QRCodeEncodeType.QRCODE_ENCODE_KANJI:
					bits = QRInput.estimateBitsModeKanji(this.size);
				break;
				case QRCodeEncodeType.QRCODE_ENCODE_STRUCTURE:
					return STRUCTURE_HEADER_BITS;
				default:
					return 0;
			}
			
			var l:int = QRSpecs.lengthIndicator(this.mode, version);
			var m:int = 1 << l;
			var num:int = (this.size + m - 1) / m;
			
			bits += num * (4 + l);
			
			return bits;
		}
		
		public function encodeBitStream(version:int):int
		{
			try {
				
				this.bstream = null;
				var words:int = QRSpecs.maximumWords(this.mode, version);
				
				if(this.size > words) {
					
					var st1:QRInputItem = new QRInputItem(this.mode, words, this.data);
					var st2:QRInputItem = new QRInputItem(this.mode, this.size - words, this.data.slice(words));
					
					st1.encodeBitStream(version);
					st2.encodeBitStream(version);
					
					this.bstream = new QRbitstream();
					this.bstream.append(st1.bstream);
					this.bstream.append(st2.bstream);
					
					
				} else {
					
					var ret:int = 0;
					
					switch(this.mode) {
						case QRCodeEncodeType.QRCODE_ENCODE_NUMERIC:
							ret = this.encodeModeNum(version);
							break;
						case QRCodeEncodeType.QRCODE_ENCODE_ALPHA_NUMERIC:
							ret = this.encodeModeAn(version);
							break;
						case QRCodeEncodeType.QRCODE_ENCODE_BYTES:
							ret = this.encodeMode8(version);
							break;
						case QRCodeEncodeType.QRCODE_ENCODE_KANJI:
							ret = this.encodeModeKanji(version);
						case QRCodeEncodeType.QRCODE_ENCODE_STRUCTURE:
							ret = this.encodeModeStructure();
						default:
							return 0;
					}
					
					if(ret < 0)
						return -1;
				}
				
				return this.bstream.size;
				
			} catch (e:Error) {
				return -1;
			}
			return 0;
		}
	}
}
