package org.qrcode.encode
{
	
	import org.qrcode.input.QRInput;
	import org.qrcode.rs.QRRsBlock;
	import org.qrcode.rs.QRRsItem;
	import org.qrcode.specs.QRSpecs;
	import org.qrcode.utils.QRUtil;
	

	public class QRRawCode
	{
		public var version:int;
		public var datacode:Array;
		public var ecccode:Array = [];
		public var blocks:int;
		public var rsblocks:Array; //of RSblock
		public var count:int;
		public var dataLength:int;
		public var eccLength:int;
		public var b1:int;
		
		public function QRRawCode(input:QRInput){
			rsblocks = [];
			
			var spec:Array = [0,0,0,0,0];
			
			this.datacode = input.getByteStream();
			if(this.datacode == null) {
				throw new Error('null imput string');
			}
			
			spec = QRSpecs.getEccSpec(input.version, input.errorCorrectionLevel, spec);
			
			this.version = input.version;
			this.b1 = QRSpecs.rsBlockNum1(spec);
			this.dataLength = QRSpecs.rsDataLength(spec);
			this.eccLength = QRSpecs.rsEccLength(spec);
			this.ecccode = QRUtil.array_fill(0, this.eccLength, 0x00);
			this.blocks = QRSpecs.rsBlockNum(spec);
			
			var ret:int = this.init(spec);
			if(ret < 0) {
				throw new Error('block alloc error');
			}
			
			this.count = 0;
		}
		

		public function init(spec:Array):int
		{
			var dl:int = QRSpecs.rsDataCodes1(spec);
			var el:int = QRSpecs.rsEccCodes1(spec);
			var rs:QRRsItem = QRUtil.initRs(8, 0x11d, 0, 1, el, 255 - dl - el);
			
			
			var dataPos:int = 0;
			var eccPos:int = 0;
			var blockNo:int = 0;
			for(var i:int=0; i<QRSpecs.rsBlockNum1(spec); i++) {
				var ecc:Array = this.ecccode.slice(eccPos);
				this.rsblocks[i] = new QRRsBlock(dl, this.datacode.slice(dataPos), el,  ecc, rs);
				ecc = rs.encode_rs_char((rsblocks[i] as QRRsBlock).data);
				(rsblocks[i] as QRRsBlock).ecc = ecc;
				this.ecccode = QRUtil.array_merge(this.ecccode.slice(0, eccPos), ecc);
				dataPos += dl;
				eccPos += el;
				blockNo++;
			}
			
			if(QRSpecs.rsBlockNum2(spec) == 0)
				return 0;
			
			dl = QRSpecs.rsDataCodes2(spec);
			el = QRSpecs.rsEccCodes2(spec);
			rs = QRUtil.initRs(8, 0x11d, 0, 1, el, 255 - dl - el);
			
			if(rs == null) return -1;
			
			for(i=0; i<QRSpecs.rsBlockNum2(spec); i++) {
				ecc = this.ecccode.slice(eccPos);
				this.rsblocks.push(new QRRsBlock(dl, this.datacode.slice(dataPos), el, ecc, rs),blockNo);
				this.ecccode = QRUtil.array_merge(this.ecccode.slice(0, eccPos), ecc);
				
				dataPos += dl;
				eccPos += el;
				blockNo++;
			}
			
			return 0;
		}
		

		public function getCode():int
		{
			var ret:int;
			
			if(this.count < this.dataLength) {
				var row:int = this.count % this.blocks;
				var col:int = this.count / this.blocks;
				if(col >= this.rsblocks[0].dataLength) {
					row += this.b1;
				}
				ret = this.rsblocks[row].data[col];
			} else if(this.count < this.dataLength + this.eccLength) {
				row = (this.count - this.dataLength) % this.blocks;
				col = (this.count - this.dataLength) / this.blocks;
				ret = this.rsblocks[row].ecc[col];
			} else {
				return 0;
			}
			this.count++;
			
			return ret;
		}
		
	}
}
