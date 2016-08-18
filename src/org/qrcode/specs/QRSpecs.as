package org.qrcode.specs
{
	
	import flash.utils.ByteArray;
	
	
	import org.qrcode.enum.QRCodeEncodeType;
	import org.qrcode.utils.QRUtil;
	

	public class QRSpecs
	{
		public static const QRSPEC_VERSION_MAX:int = 40;
		
		public static const QRSPEC_WIDTH_MAX:int = 177;
		
		
		public static var frames:Array = [];
		
		
		public static function getCapacity(version:int):QRSpecCapacity{
			return new QRSpecCapacity(version);
		}
		
		/**
		 * return the data lenght for a given version
		 */
		public static function getDataLength(version:int, level:int):int{
			var qrcap:QRSpecCapacity = getCapacity(version);
			return qrcap.words - qrcap.ec[level];
		}
		
		/**
		 * Get ecc length form version and level
		 */
		public static function getECCLength(version:int, level:int):int{
			return getCapacity(version).ec[level];;
		}
		
		/**
		 * Get Edge length of the symbol from version
		 */
		public static function getWidth(version:int):int{
			return getCapacity(version).width;
		}
		
		/**
		 * get Remainder form version
		 */
		public static function getRemainder(version:int):Number{
			return getCapacity(version).remainder;
		}
		
		/**
		 * Get the miminum version regarding the level and the size
		 */
		public static function getMinimumVersion(size:int, level:int):int{
			for(var i:int=1; i<= QRSPEC_VERSION_MAX; i++) {
				var cp:QRSpecCapacity = getCapacity(i);
				var words:int  = cp.words - cp.ec[level];
				if(words >= size)
					return i;
			}
			
			return -1;
		}
		
		///-------------------------------///
		///     Length indicator          ///
		///-------------------------------///
		
		public static const lengthTableBits:Array = [
			[10, 12, 14],
			[ 9, 11, 13],
			[ 8, 16, 16],
			[ 8, 10, 12]
		];
		
		/**
		 * return lenght indicator
		 * @param mode int QREncodeType value
		 * @param version int the version of qrcode
		 * @return int the length indicator
		 */
		public static function lengthIndicator(mode:int, version:int):int
		{
			if (mode == QRCodeEncodeType.QRCODE_ENCODE_STRUCTURE)
				return 0;
			var l:int;
			if (version <= 9) {
				l = 0;
			} else if (version <= 26) {
				l = 1;
			} else {
				l = 2;
			}
			
			return lengthTableBits[mode][l];
		}
		
		/**
		 * Return the maximum data capacity for a mode and a version
		 */
		public static function maximumWords(mode:int, version:int):int
		{
			if(mode ==QRCodeEncodeType.QRCODE_ENCODE_STRUCTURE)
				return 3;
			var l:int;
			if(version <= 9) {
				l = 0;
			} else if(version <= 26) {
				l = 1;
			} else {
				l = 2;
			}
			
			var bits:int = lengthTableBits[mode][l];
			var words:int = (1 << bits) - 1;
			
			if(mode == QRCodeEncodeType.QRCODE_ENCODE_KANJI) {
				words *= 2; // the number of bytes is required
			}
			
			return words;
		}
		
		
		
		public static const eccTable:Array = [
			[[ 0,  0], [ 0,  0], [ 0,  0], [ 0,  0]],
			[[ 1,  0], [ 1,  0], [ 1,  0], [ 1,  0]], // 1
			[[ 1,  0], [ 1,  0], [ 1,  0], [ 1,  0]],
			[[ 1,  0], [ 1,  0], [ 2,  0], [ 2,  0]],
			[[ 1,  0], [ 2,  0], [ 2,  0], [ 4,  0]],
			[[ 1,  0], [ 2,  0], [ 2,  2], [ 2,  2]], // 5
			[[ 2,  0], [ 4,  0], [ 4,  0], [ 4,  0]],
			[[ 2,  0], [ 4,  0], [ 2,  4], [ 4,  1]],
			[[ 2,  0], [ 2,  2], [ 4,  2], [ 4,  2]],
			[[ 2,  0], [ 3,  2], [ 4,  4], [ 4,  4]],
			[[ 2,  2], [ 4,  1], [ 6,  2], [ 6,  2]], //10
			[[ 4,  0], [ 1,  4], [ 4,  4], [ 3,  8]],
			[[ 2,  2], [ 6,  2], [ 4,  6], [ 7,  4]],
			[[ 4,  0], [ 8,  1], [ 8,  4], [12,  4]],
			[[ 3,  1], [ 4,  5], [11,  5], [11,  5]],
			[[ 5,  1], [ 5,  5], [ 5,  7], [11,  7]], //15
			[[ 5,  1], [ 7,  3], [15,  2], [ 3, 13]],
			[[ 1,  5], [10,  1], [ 1, 15], [ 2, 17]],
			[[ 5,  1], [ 9,  4], [17,  1], [ 2, 19]],
			[[ 3,  4], [ 3, 11], [17,  4], [ 9, 16]],
			[[ 3,  5], [ 3, 13], [15,  5], [15, 10]], //20
			[[ 4,  4], [17,  0], [17,  6], [19,  6]],
			[[ 2,  7], [17,  0], [ 7, 16], [34,  0]],
			[[ 4,  5], [ 4, 14], [11, 14], [16, 14]],
			[[ 6,  4], [ 6, 14], [11, 16], [30,  2]],
			[[ 8,  4], [ 8, 13], [ 7, 22], [22, 13]], //25
			[[10,  2], [19,  4], [28,  6], [33,  4]],
			[[ 8,  4], [22,  3], [ 8, 26], [12, 28]],
			[[ 3, 10], [ 3, 23], [ 4, 31], [11, 31]],
			[[ 7,  7], [21,  7], [ 1, 37], [19, 26]],
			[[ 5, 10], [19, 10], [15, 25], [23, 25]], //30
			[[13,  3], [ 2, 29], [42,  1], [23, 28]],
			[[17,  0], [10, 23], [10, 35], [19, 35]],
			[[17,  1], [14, 21], [29, 19], [11, 46]],
			[[13,  6], [14, 23], [44,  7], [59,  1]],
			[[12,  7], [12, 26], [39, 14], [22, 41]], //35
			[[ 6, 14], [ 6, 34], [46, 10], [ 2, 64]],
			[[17,  4], [29, 14], [49, 10], [24, 46]],
			[[ 4, 18], [13, 32], [48, 14], [42, 32]],
			[[20,  4], [40,  7], [43, 22], [10, 67]],
			[[19,  6], [18, 31], [34, 34], [20, 61]]//40
		];
		
		
		/**
		 * Get Error correction code for a version and a level
		 * @return the array spec
		 */
		public static function getEccSpec(version:int, level:int, spec:Array=null):Array
		{
			if (spec == null || spec.length < 5) {
				spec = [0,0,0,0,0];
			}
			
			var b1:int = eccTable[version][level][0];
			var b2:int = eccTable[version][level][1];
			var data:int = getDataLength(version, level);
			var ecc:int = getECCLength(version, level);
			
			if(b2 == 0) {
				spec[0] = b1;
				spec[1] = (data / b1) as int;
				spec[2] = (ecc / b1) as int;
				spec[3] = 0;
				spec[4] = 0;
			} else {
				spec[0] = b1;
				spec[1] = int(data / (b1 + b2));
				spec[2] = int(ecc  / (b1 + b2));
				spec[3] = b2;
				spec[4] = spec[1] + 1;
			}
			return spec;
		}
		
		
		public static const alignmentPattern:Array = [
			[ 0,  0],
			[ 0,  0], [18,  0], [22,  0], [26,  0], [30,  0], // 1- 5
			[34,  0], [22, 38], [24, 42], [26, 46], [28, 50], // 6-10
			[30, 54], [32, 58], [34, 62], [26, 46], [26, 48], //11-15
			[26, 50], [30, 54], [30, 56], [30, 58], [34, 62], //16-20
			[28, 50], [26, 50], [30, 54], [28, 54], [32, 58], //21-25
			[30, 58], [34, 62], [26, 50], [30, 54], [26, 52], //26-30
			[30, 56], [34, 60], [30, 58], [34, 62], [30, 54], //31-35
			[24, 50], [28, 54], [32, 58], [26, 54], [30, 58], //35-40
		];
		
		
		/** --------------------------------------------------------------------
		 * Put an alignment marker.
		 * @param frame Array array of ByteArray
		 * @param width
		 * @param ox,oy center coordinate of the pattern
		 * @return Array the frame with alignement marker
		 */
		public static function putAlignmentMarker(frame:Array, ox:int, oy:int):Array
		{
			
			var finder:Vector.<uint> = new Vector.<uint>();
			finder.push(
				0xa1, 0xa1, 0xa1, 0xa1, 0xa1,
				0xa1, 0xa0, 0xa0, 0xa0, 0xa1,
				0xa1, 0xa0, 0xa1, 0xa0, 0xa1,
				0xa1, 0xa0, 0xa0, 0xa0, 0xa1,
				0xa1, 0xa1, 0xa1, 0xa1, 0xa1
			);
			
			var finderpos:int = 0;
			
			for(var x:int=0; x<5; x++) {
				for(var y:int=0; y<5; y++) {
					(frame[ox+x-2] as Array)[oy+y-2] = finder[finderpos+y];
				}
				finderpos += 5;
			}
			
			return frame;
			
		}
		
		/**
		 * put Alignement pattern in the frame
		 */
		public static function putAlignmentPattern(version:int, frame:Array, width:int):Array
		{
			if(version < 2)
				return frame;
			
			var d:int = alignmentPattern[version][1] - alignmentPattern[version][0];
			var w:int;
			if(d < 0) {
				w = 2;
			} else {
				w = int((width - alignmentPattern[version][0]) / d + 2);
			}
			
			var x:int;
			var y:int;
			if(w * w - 3 == 1) {
				x = alignmentPattern[version][0];
				y = alignmentPattern[version][0];
				frame = putAlignmentMarker(frame, x, y);
				return frame;
			}
			
			var cx:int = alignmentPattern[version][0];
			for(x=1; x< w - 1; x++) {
				frame = putAlignmentMarker(frame, 6, cx);
				frame = putAlignmentMarker(frame, cx,  6);
				cx += d;
			}
			
			var cy:int = alignmentPattern[version][0];
			for(y=0; y<w-1; y++) {
				cx = alignmentPattern[version][0];
				for(x=0; x<w-1; x++) {
					frame = putAlignmentMarker(frame, cx, cy);
					cx += d;
				}
				cy += d;
			}
			return frame;
		}
		
		
		public static const versionPattern:Array = [
			0x07c94, 0x085bc, 0x09a99, 0x0a4d3, 0x0bbf6, 0x0c762, 0x0d847, 0x0e60d,
			0x0f928, 0x10b78, 0x1145d, 0x12a17, 0x13532, 0x149a6, 0x15683, 0x168c9,
			0x177ec, 0x18ec4, 0x191e1, 0x1afab, 0x1b08e, 0x1cc1a, 0x1d33f, 0x1ed75,
			0x1f250, 0x209d5, 0x216f0, 0x228ba, 0x2379f, 0x24b0b, 0x2542e, 0x26a64,
			0x27541, 0x28c69
		];
		
		//----------------------------------------------------------------------
		public static function getVersionPattern(version:int):uint
		{
			if(version < 7 || version > QRSPEC_VERSION_MAX)
				return 0;
			
			return versionPattern[version -7];
		}
		
		
		public static const formatInfo:Array = [
			[0x77c4, 0x72f3, 0x7daa, 0x789d, 0x662f, 0x6318, 0x6c41, 0x6976],
			[0x5412, 0x5125, 0x5e7c, 0x5b4b, 0x45f9, 0x40ce, 0x4f97, 0x4aa0],
			[0x355f, 0x3068, 0x3f31, 0x3a06, 0x24b4, 0x2183, 0x2eda, 0x2bed],
			[0x1689, 0x13be, 0x1ce7, 0x19d0, 0x0762, 0x0255, 0x0d0c, 0x083b]
		];
		
		public static function getFormatInfo(mask:int, level:int):uint
		{
			if(mask < 0 || mask > 7)
				return 0;
			
			if(level < 0 || level > 3)
				return 0;
			
			return formatInfo[level][mask];
		}
		
		
		/** --------------------------------------------------------------------
		 * Put a finder pattern.
		 * @param frame
		 * @param width
		 * @param ox,oy upper-left coordinate of the pattern
		 */
		public static function putFinderPattern(frame:Array, ox:int, oy:int):Array
		{
			var finder:Array = [
				0xc1, 0xc1, 0xc1, 0xc1, 0xc1, 0xc1, 0xc1,
				0xc1, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc1,
				0xc1, 0xc0, 0xc1, 0xc1, 0xc1, 0xc0, 0xc1,
				0xc1, 0xc0, 0xc1, 0xc1, 0xc1, 0xc0, 0xc1,
				0xc1, 0xc0, 0xc1, 0xc1, 0xc1, 0xc0, 0xc1,
				0xc1, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc1,
				0xc1, 0xc1, 0xc1, 0xc1, 0xc1, 0xc1, 0xc1,
			];
			
			var finderpos:int = 0;
			
			for(var x:int=0; x<7; x++) {
				for(var y:int=0; y<7; y++) {
					(frame[ox+x] as Array)[oy+y] = finder[finderpos+y];
				}
				finderpos += 7;
			}
			
			return frame;
		}
		
		
		public static function createFrame(version:int):Array
		{
			var width:int = getCapacity(version).width;
			var frameLine:Array =  QRUtil.array_fill(0, width,0x00);
			var frame:Array =  QRUtil.array_fill(0, width, frameLine);
			
			
			// Finder pattern
			frame = putFinderPattern(frame ,0, 0);
			frame = putFinderPattern(frame, width - 7, 0);
			frame = putFinderPattern(frame, 0, width - 7);
			
			// Separator
			var yOffset:int = width - 7;
			
			for(var y:int=0; y<7; y++,yOffset++) {
				frame[y][7] = 0xc0;
				frame[y][width - 8] = 0xc0;
				frame[yOffset][7] = 0xc0;
			}
			
			var setPattern:Array = QRUtil.array_fill(0,8,0xc0);
			
			var p:int = 0;
			var q:int = width - 7;
			for(y=0; y<7; y++,q++,p++) {
				frame[p][7] = 0xc0;
				frame[p][width - 8] = 0xc0;
				frame[q][7] = 0xc0;
			}
			
			frame = QRUtil.memset(frame, 7, 0, 0xc0, 8);
			frame = QRUtil.memset(frame, 7, width-8, 0xc0, width - 8);
			frame = QRUtil.memset(frame, width-8 , 0, 0xc0, 8);
			
			// Format info
			yOffset = width - 8;
			
			frame = QRUtil.memset(frame, 8 ,0, 0x84, 9);
			frame = QRUtil.memset(frame, 8 ,width-8, 0x84, 8);
			
			for(y=0; y<8; y++,yOffset++) {
				frame[y][8] = 0x84;
				frame[yOffset][8] = 0x84;
			}
			
			// Timing pattern
			
			for(var i:int=1; i<width-15; i++) {
				frame[6][7+i] = 0x90 | (i & 1);
				frame[7+i][6] = 0x90 | (i & 1);
			}
			
			// Alignment pattern
			frame = putAlignmentPattern(version, frame, width);
			
			// Version information
			if(version >= 7) {
				var vinf:int = getVersionPattern(version);;
				
				var v:int = vinf;
				
				for(var x:int=0; x<6; x++) {
					for(y=0; y<3; y++) {
						frame[(width - 11)+y][x] = 0x88 | (v & 1);
						v = v >> 1;
					}
				}
				
				v = vinf;
				for(y=0; y<6; y++) {
					for(x=0; x<3; x++) {
						frame[y][x+(width - 11)] = 0x88 | (v & 1);
						v = v >> 1;
					}
				}
			}
			// and a little bit...
			frame[width - 8][8] = 0x81;
			
			return frame;
		}
		
		
		public static function serial(frame:Array):ByteArray{
			var ba:ByteArray = new ByteArray();
			ba.writeObject(frame);
			ba.compress();
			return ba;
		}
		
		public static function unserial(code:ByteArray):Array
		{
			code.uncompress()
			return code.readObject() as Array;
		}
		
		public static function newFrame(version:int):Array{
			if(version < 1 || version > QRSPEC_VERSION_MAX)
				return null
			if(frames[version] == null){
				frames[version] = createFrame(version);
			}
			if(frames[version] == null){
				return [];
			}
			return frames[version];
		}
		
		public static function rsBlockNum(spec:Array):int     { return spec[0] + spec[3]; }
		public static function rsBlockNum1(spec:Array):int    { return spec[0]; }
		public static function rsDataCodes1(spec:Array):int   { return spec[1]; }
		public static function rsEccCodes1(spec:Array):int    { return spec[2]; }
		public static function rsBlockNum2(spec:Array):int    { return spec[3]; }
		public static function rsDataCodes2(spec:Array):int   { return spec[4]; }
		public static function rsEccCodes2(spec:Array):int    { return spec[2]; }
		public static function rsDataLength(spec:Array):int   { return (spec[0] * spec[1]) + (spec[3] * spec[4]);    }
		public static function rsEccLength(spec:Array):int    { return (spec[0] + spec[3]) * spec[2]; }

	}
}
