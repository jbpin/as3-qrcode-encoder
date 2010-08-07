package org.qrcode.utils
{
	
	import org.qrcode.rs.QRRsItem;

	public class QRUtil
	{
		
		public static function memset(src:Array, index:int, start:int, value:int, length:int):Array{
			for(var x:int=0;x<length;x++){
				src[index][x+start] = value;
			}
			return src;
		}
		
		public static function str_repeat(pattern:String,lenght:int):String{
			var st:String="";
			for(var i:int=0; i<lenght;i++){
				st += pattern;
			}
			return st;
		}
		
		public static function array_fill(startIndex:int,length:int,value:Object):Array{
			var ar:Array = new Array();
			for(var i:int = 0; i<length;i++){
				if(value is Array){
					ar[startIndex+i] = copyArray(value as Array); 	
				}else{
					ar[startIndex+i] = value;
				}
			}
			return ar;
		}
		
		public static function array_merge(array:Array,array2:Array):Array{
			for(var i:int=0;i<array2.length;i++){
				array.push(array2[i]);
			}
			return array;
		}
		
		public static function copyFrame(f:Array):Array{
			var d:Array = new Array();
			for(var a:String in f){
				d[a] = QRUtil.copyArray(f[a]);
			}
			return d;
		}
		
		public static function copyArray(a:Array):Array{
			var ar:Array = new Array();
			for each(var obj:* in a){
				ar.push(obj);
			}
			return ar;
		}
		
		
		public static var items:Array = [];
		
		public static function initRs(symsize:int, gfpoly:int, fcr:int, prim:int, nroots:int, pad:int):QRRsItem
		{
			for each(var rs:QRRsItem in items) {
				if(rs.pad != pad)       continue;
				if(rs.nroots != nroots) continue;
				if(rs.mm != symsize)    continue;
				if(rs.gfpoly != gfpoly) continue;
				if(rs.fcr != fcr)       continue;
				if(rs.prim != prim)     continue;
				
				return rs;
			}
			
			var retrs:QRRsItem = QRRsItem.init_rs_char(symsize, gfpoly, fcr, prim, nroots, pad);
			items.unshift(retrs);
			
			return retrs;
		}
		
	}
}