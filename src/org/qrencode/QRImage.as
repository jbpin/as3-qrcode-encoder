package org.qrencode
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import spark.primitives.Rect;
	import spark.utils.BitmapUtil;

	public class QRImage
	{	
		public static const QR_IMAGE:Boolean = true;
	
		/*
		//----------------------------------------------------------------------
		public static function png(frame:Array, filename:String="", pixelPerPoint:int = 4, outerFrame:int = 4,saveandprint:Boolean=false) 
		{
			var image:Bitmap = image(frame, pixelPerPoint, outerFrame);
			
			if (filename == "") {
				ImagePng(image);
			} else {
				if(saveandprint===TRUE){
					ImagePng(image, filename);
					header("Content-type: image/png");
					ImagePng(image);
				}else{
					ImagePng(image, filename);
				}
			}
			
			ImageDestroy(image);
		}
		
		//----------------------------------------------------------------------
		public static function jpg($frame, $filename = false, $pixelPerPoint = 8, $outerFrame = 4, $q = 85) 
		{
			$image = self::image($frame, $pixelPerPoint, $outerFrame);
			
			if ($filename === false) {
				Header("Content-type: image/jpeg");
				ImageJpeg($image, null, $q);
			} else {
				ImageJpeg($image, $filename, $q);            
			}
			
			ImageDestroy($image);
		}
		*/
		//----------------------------------------------------------------------
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
			matrix.scale(4,4);
			
			var bitData:BitmapData = new BitmapData(imgW*pixelPerPoint,imgH*pixelPerPoint,false,0xffffff);
			bitData.draw(image,matrix);
			image.dispose();
			//image = null;
			
			return bitData;
		}
	}
}