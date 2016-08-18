package org.qrcode
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	

	public class QRImage
	{
		
		public static function image(frame:Array, pixelPerPoint:int = 4, outerFrame:int = 4):BitmapData {
			var h:int = frame.length;
			var w:int = frame[0].length;
			
			var imgW:int = w + 2 * outerFrame;
			var imgH:int = h + 2 * outerFrame;
			
			var image:BitmapData = new BitmapData(imgW , imgH , false,0xffffff);
			
			for(var y:int=0; y<h; y++) {
				for(var x:int=0; x<w; x++) {
					if (frame[y][x] == 1) {
							image.setPixel(x+outerFrame,y+outerFrame,0x000000);
					}
				}
			}
			
			//return image;
			var matrix:Matrix = new Matrix();
			matrix.scale(pixelPerPoint,pixelPerPoint);
			
			var bitData:BitmapData = new BitmapData(imgW*pixelPerPoint,imgH*pixelPerPoint,false,0xffffff);
			bitData.draw(image,matrix);
			image.dispose();
			//image = null;
			
			return bitData;
		}
	}
}
