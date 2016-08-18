package org.qrcode
{
	import org.qrcode.specs.QRSpecs;
	import org.qrcode.utils.QRUtil;

	public class QRMask
	{
		public static const N1:int = 3;
		public static const N2:int = 3;
		public static const N3:int = 40;
		public static const N4:int = 10;
		
		public var frames:Array;
		
		public var runLength:Array;
		
		public function QRMask(frame:Array)
		{
			this.frames = QRUtil.copyArray(frame);
			
		}
		
		public function writeFormatInformation(mask:Array , width:int, maskNo:int, level:int):int
		{
			var blacks:int = 0;
			var format:int =  QRSpecs.getFormatInfo(maskNo, level);
			
			var v:Number;
			for(var i:int=0; i<8; i++) {
				if(format & 1) {
					blacks += 2;
					v = 0x85;
				} else {
					v = 0x84;
				}
				
				mask[8][width - 1 - i] = v;
				if(i < 6) {
					mask[i][8] = v;
				} else {
					mask[i + 1][8] = v;
				}
				format = format >> 1;
			}
			
			for(i=0; i<7; i++) {
				if(format & 1) {
					blacks += 2;
					v = 0x85;
				} else {
					v = 0x84;
				}
				
				mask[width - 7 + i][8] = v;
				if(i == 0) {
					mask[8][7] = v;
				} else {
					mask[8][6 - i] = v;
				}
				
				format = format >> 1;
			}
			
			return blacks;
		}
		
		public function mask0(x:Number, y:Number):int { return int( ( (x + y) & 1) == 0 );                       }
		public function mask1(x:Number, y:Number):int { return int((y&1) == 0);                          }
		public function mask2(x:Number, y:Number):int { return int((x % 3) == 0);                          }
		public function mask3(x:Number, y:Number):int { return int((x+y)%3 == 0);                       }
		public function mask4(x:Number, y:Number):int { return int( ( (int(y*0.5) + int(x/3)) &1) == 0 )}
		public function mask5(x:Number, y:Number):int { return int( ( ( (x*y) % 2 ) + ((x*y) % 3 ) ) == 0 )}
		public function mask6(x:Number, y:Number):int { return int( ( ( ( (x*y) &1 ) + ((x*y) % 3 ) ) &1 ) == 0 );       }
		public function mask7(x:Number, y:Number):int { return int( ( ( ( (x+y) &1 ) + ((x*y) % 3 ) ) &1 ) == 0 )  }
		
		private function generateMaskNo(maskNo:int, width:int):Array
		{
			var bitMask:Array = QRUtil.array_fill(0, width, QRUtil.array_fill(0, width, 0x00));
			
			for(var y:int=0; y<width; y++) {
				for(var x:int=0; x<width; x++) {
					if(frames[y][x] & 0x80) {
						bitMask[y][x] = 0;
					} else {
						switch(maskNo){
							case 0:
								bitMask[y][x] = mask0(x,y);
							break;
							case 1:
								bitMask[y][x] = mask1(x,y);
							break;
							case 2:
								bitMask[y][x] = mask2(x,y);
							break;
							case 3:
								bitMask[y][x] = mask3(x,y);
							break;
							case 4:
								bitMask[y][x] = mask4(x,y);
							break;
							case 5:
								bitMask[y][x] = mask5(x,y);
							break;
							case 6:
								bitMask[y][x] = mask6(x,y);
							break;
							case 7:
								bitMask[y][x] = mask7(x,y);
							break;
							default:
						}
					}
					
				}
			}
			
			return bitMask;
		}
		
		public function makeMaskNo(maskNo:int, width:int, maskGenOnly:Boolean = false):Array
		{
			var b:int = 0;
			var bitMask:Array = [];
			var d:Array = QRUtil.copyFrame(frames);
			
			bitMask = this.generateMaskNo(maskNo, width);
			
			if (maskGenOnly)
				return null;
			
			for(var y:int=0; y<width; y++) {
				for(var x:int=0; x<width; x++) {
					if(bitMask[y][x] == 1) {
						d[y][x] = frames[y][x] ^ 1;
					}
					b += d[y][x] & 1;
				}
			}
			
			return [d,b];
		}
		
		public function makeMask(width:int, maskNo:int, level:int):Array
		{
			var ret:Array = this.makeMaskNo(maskNo, width);
			this.writeFormatInformation(ret[0], width, maskNo, level);
			
			return ret[0];
		}
		
		public function calcN1N3(length:int, runLength:Array):int
		{
			var demerit:int = 0;
			for(var i:int=0; i<length; i++) {
				
				if(runLength[i] >= 5) {
					demerit += N1 + (runLength[i] - 5);
				}
				if((i & 1)) {
					if(i >= 3 && i < (length-2) && runLength[i] % 3 == 0) {
						var fact:int = runLength[i] / 3;
						if((runLength[i-2] == fact) &&
							(runLength[i-1] == fact) &&
							(runLength[i+1] == fact) &&
							(runLength[i+2] == fact)) {
							if((runLength[i-3] < 0) || (runLength[i-3] >= (4 * fact))) {
								demerit += N3;
							} else if(((i+3) >= length) || (runLength[i+3] >= (4 * fact))) {
								demerit += N3;
							}
						}
					}
				}
			}
			return demerit;
		}
		
		public function evaluateSymbol(width:int,frame:Array):int
		{
			var head:int = 0;
			var demerit:int = 0;
			runLength = QRUtil.array_fill(0, QRSpecs.QRSPEC_VERSION_MAX + 1, 0x00);
			
			for(var y:int=0; y<width; y++) {
				head = 0;
				runLength[0] = 1;
				
				var frameY:Array = frame[y];
				
				var frameYM:Array = [];
				if (y>0)
					frameYM = frame[y-1];
				
				for(var x:int=0; x<width; x++) {
					if((x > 0) && (y > 0)) {
						var b22:Number = frameY[x] & frameY[x-1] & frameYM[x] & frameYM[x-1];
						var w22:Number = frameY[x] | frameY[x-1] | frameYM[x] | frameYM[x-1];
						
						if((b22 | (w22 ^ 1))&1) {
							demerit += N2;
						}
					}
					if((x == 0) && (frameY[x] & 1)) {
						runLength[0] = -1;
						head = 1;
						runLength[head] = 1;
					} else if(x > 0) {
						if((frameY[x] ^ frameY[x-1]) & 1) {
							head++;
							runLength[head] = 1;
						} else {
							runLength[head]++;
						}
					}
				}
				
				demerit += this.calcN1N3(head+1,runLength);
			}
			
			for(x=0; x<width; x++) {
				head = 0;
				runLength[0] = 1;
				
				for(y=0; y<width; y++) {
					if(y == 0 && (frame[y][x] & 1)) {
						runLength[0] = -1;
						head = 1;
						runLength[head] = 1;
					} else if(y > 0) {
						if((frame[y][x] ^ frame[y-1][x]) & 1) {
							head++;
							runLength[head] = 1;
						} else {
							runLength[head]++;
						}
					}
				}
				
				demerit += this.calcN1N3(head+1,runLength);
			}
			
			return demerit;
		}
		
		public function mask(width:int, level:int):Array
		{
			var minDemerit:int = int.MAX_VALUE;
			var bestMaskNum:int = 0;
			var bestMask:Array = [];
			
			var checked_masks:Array = [0,2,3,4,5,6,7];
			
			
			bestMask = QRUtil.copyArray(frames);
			
			for each(var i:int in checked_masks) {
				var demerit:int = 0;
				var blacks:int = 0;
				var ar:Array  = this.makeMaskNo(i, width);
				var mask:Array = ar[0];
				blacks = ar[1];
				blacks += this.writeFormatInformation(mask, width, i, level);
				blacks  = 100 * blacks / (width * width);
				demerit = int(Math.abs(blacks - 50) / 5) * N4;
				demerit += this.evaluateSymbol(width, mask);
				
				if(demerit < minDemerit) {
					minDemerit = demerit;
					bestMask = mask;
					bestMaskNum = i;
				}
			}
			return bestMask;
		}
	}
}
