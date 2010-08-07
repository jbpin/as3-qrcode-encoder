package org.qrcode.utils
{
	import flash.display.FrameLabel;

	public class QRCodeTool
	{
		
		public static function binarize(frame:Array):Array
		{
			var len:int = frame.length;
			for(var frindex:String in frame) {
				var frameLine:Array = frame[frindex];
				for(var i:int=0; i<len; i++) {
					frameLine[i] = (frameLine[i]&1);
				}
				frame[frindex] = frameLine;
			}
			return frame;
		}
		
		public static function dumpMask(frame:Array):String
		{
			var st:String = ''; 
			var width:int = frame.length;
			for(var y:int=0;y<width;y++) {
				for(var x:int=0;x<width;x++) {
					st += frame[y][x].toString().charCodeAt()+',';
				}
			}
			return st;
		}
	}
}