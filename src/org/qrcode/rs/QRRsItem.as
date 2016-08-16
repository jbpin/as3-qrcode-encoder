package org.qrcode.rs
{
	import org.qrcode.utils.QRUtil;
	
	public class QRRsItem
	{
		
		private static var A0:uint;
		private static var NN:uint;
		
		public var mm:uint;                  // Bits per symbol
		public var nn:uint;                  // Symbols per block (= (1<<mm)-1)
		public var alpha_to:Array = [];  // log lookup table
		public var index_of:Array = [];  // Antilog lookup table
		public var genpoly:Array = [];   // Generator polynomial
		public var nroots:uint;              // Number of generator roots = number of parity symbols
		public var fcr:uint;                 // First consecutive root, index form
		public var prim:uint;                // Primitive element, index form
		public var iprim:uint;               // prim-th root of 1, index form
		public var pad:uint;                 // Padding bytes in shortened block
		public var gfpoly:uint;
		
		public function QRRsItem()
		{
		}

		public function modnn(x:int):int
		{
			while (x >= this.nn) {
				x -= this.nn;
				x = (x >> this.mm) + (x & this.nn);
			}
			
			return x;
		}

		public static function init_rs_char(symsize:int, gfpoly:int, fcr:int, prim:int, nroots:int, pad:int):QRRsItem
		{
			// Common code for intializing a Reed-Solomon control block (char or int symbols)
			// Copyright 2004 Phil Karn, KA9Q
			// May be used under the terms of the GNU Lesser General Public License (LGPL)
			
			var rs:QRRsItem = null;
			
			// Check parameter ranges
			if(symsize < 0 || symsize > 8)                     return rs;
			if(fcr < 0 || fcr >= (1<<symsize))                return rs;
			if(prim <= 0 || prim >= (1<<symsize))             return rs;
			if(nroots < 0 || nroots >= (1<<symsize))          return rs; // Can't have more roots than symbol values!
			if(pad < 0 || pad > ((1<<symsize) -1 - nroots)) return rs; // Too much padding
			
			rs = new QRRsItem();
			rs.mm = symsize;
			rs.nn = (1<<symsize)-1;
			rs.pad = pad;
			
			rs.alpha_to = QRUtil.array_fill(0, rs.nn+1, 0x00);
			rs.index_of = QRUtil.array_fill(0, rs.nn+1, 0x00);
			
			// PHP style macro replacement ;)
			NN = rs.nn;
			A0 = NN;
			
			
			
			// Generate Galois field lookup tables
			rs.index_of[0] = A0; // log(zero) = -inf
			rs.alpha_to[A0] = 0; // alpha**-inf = 0
			var sr:int = 1;
			
			for(var i:int=0; i<rs.nn; i++) {
				rs.index_of[sr] = i;
				rs.alpha_to[i] = sr;
				sr <<= 1;
				if(sr & (1<<symsize)) {
					sr ^= gfpoly;
				}
				sr &= rs.nn;
			}
			
			if(sr != 1){
				// field generator polynomial is not primitive!
				rs = null;
				return rs;
			}
			
			/* Form RS code generator polynomial from its roots */
			rs.genpoly = QRUtil.array_fill(0, nroots+1, 0x00);
			
			rs.fcr = fcr;
			rs.prim = prim;
			rs.nroots = nroots;
			rs.gfpoly = gfpoly;
			
			/* Find prim-th root of 1, used in decoding */
			var iprim:uint;
			for(iprim=1;(iprim % prim) != 0;iprim += rs.nn)
				; // intentional empty-body loop!
			
			rs.iprim = int(iprim / prim);
			rs.genpoly[0] = 1;
			
			var root:Number;
			for (i = 0,root=fcr*prim; i < nroots; i++, root += prim) {
				rs.genpoly[i+1] = 1;
				
				// Multiply rs.genpoly[] by  @**(root + x)
				for (var j:int = i; j > 0; j--) {
					if (rs.genpoly[j] != 0) {
						rs.genpoly[j] = rs.genpoly[j-1] ^ rs.alpha_to[rs.modnn(rs.index_of[rs.genpoly[j]] + root)];
					} else {
						rs.genpoly[j] = rs.genpoly[j-1];
					}
				}
				// rs.genpoly[0] can never be zero
				rs.genpoly[0] = rs.alpha_to[rs.modnn(rs.index_of[rs.genpoly[0]] + root)];
			}
			
			// convert rs.genpoly[] to index form for quicker encoding
			for (i = 0; i <= nroots; i++)
				rs.genpoly[i] = rs.index_of[rs.genpoly[i]];
			
			return rs;
		}
		
		public function encode_rs_char(data:Array):Array
		{
			var rc:QRRsItem = this;
			var a0:Number = rc.nn;
			
			var parity:Array = QRUtil.array_fill(0, rc.nroots, 0x00);
			
			for(var i:int=0; i< (rc.nn-rc.nroots-rc.pad); i++) {
				
				var feedback:int = rc.index_of[data[i] ^ parity[0]];
				if(feedback != a0) {
					// feedback term is non-zero
					
					// This line is unnecessary when GENPOLY[NROOTS] is unity, as it must
					// always be for the polynomials constructed by init_rs()
					feedback = this.modnn(rc.nn - rc.genpoly[rc.nroots] + feedback);
					
					for(var j:int=1;j<rc.nroots;j++) {
						parity[j] ^= rc.alpha_to[this.modnn(feedback + rc.genpoly[rc.nroots-j])];
					}
				}
				
				// Shift
				parity.shift();
				if(feedback != this.nn) {
					parity.push(rc.alpha_to[this.modnn(feedback + rc.genpoly[0])]);
				} else {
					parity.push(0);
				}
			}
			return parity;
		}
	}
}
