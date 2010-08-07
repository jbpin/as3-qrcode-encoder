package org.qrcode.utils
{
	import flash.geom.Point;

	public class FrameFiller
	{
		public var width:int;
		public var frame:Array;
		public var x:int;
		public var y:int;
		public var dir:int;
		public var bit:int;
		
		public function FrameFiller(width:int,frame:Array)
		{
			this.width = width;
			this.frame = frame;
			this.x = width - 1;
			this.y = width - 1;
			this.dir = -1;
			this.bit = -1;
		}
		
		public function setFrameAt(at:Point, val:Object):void
		{
			this.frame[at.y][at.x] = val;
		}
		
		public function getFrameAt(at:Point):Object
		{
			return this.frame[at.y][at.x];
		}
		
		public function next():Point
		{
			do {
				
				if(this.bit == -1) {
					this.bit = 0;
					return new Point(this.x,this.y);
				}
				
				var xt:int = this.x;
				var yt:int = this.y;
				var w:int = this.width;
				
				if(this.bit == 0) {
					xt--;
					this.bit++;
				} else {
					xt++;
					yt += this.dir;
					this.bit--;
				}
				
				if(this.dir < 0) {
					if(yt < 0) {
						yt = 0;
						xt -= 2;
						this.dir = 1;
						if(xt == 6) {
							xt--;
							yt = 9;
						}
					}
				} else {
					if(yt == w) {
						yt = w - 1;
						xt -= 2;
						this.dir = -1;
						if(xt == 6) {
							xt--;
							yt -= 8;
						}
					}
				}
				if(xt < 0 || yt < 0) 
					return null;
				
				this.x = xt;
				this.y = yt;
				
			} while(this.frame[y][x] & 0x80);
			
			return new Point(this.x,this.y);
		}
	}
}