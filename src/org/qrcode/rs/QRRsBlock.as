package org.qrcode.rs
{

	public class QRRsBlock
	{
		public var dataLength:int;
		public var data:Array = [];
		public var eccLength:int;
		public var ecc:Array = [];
		
		public function QRRsBlock(dl:int, data:Array, el:int, ecc:Array, rs:QRRsItem)
		{
			rs.encode_rs_char(data);
			
			this.dataLength = dl;
			this.data = data;
			this.eccLength = el;
			this.ecc = ecc;
		}
		
	}
}