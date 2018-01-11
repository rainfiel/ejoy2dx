package com.ejoy2dx.example;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.text.Layout.Alignment;
import android.text.StaticLayout;
import android.text.TextPaint;

public class ImageSystem {
	
	private final Context mContext;
	private Typeface tf;
	public ImageSystem(final Context pContext) {
		this.mContext = pContext;
		 tf = Typeface.createFromAsset(mContext.getAssets(), "font/font.ttf");
	}
	
	/*
	private static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
	    // Raw height and width of image
	    final int height = options.outHeight;
	    final int width = options.outWidth;
	    int inSampleSize = 1;
	
	    if (height > reqHeight || width > reqWidth) {
	
	        final int halfHeight = height / 2;
	        final int halfWidth = width / 2;
	
	        // Calculate the largest inSampleSize value that is a power of 2 and keeps both
	        // height and width larger than the requested height and width.
	        while ((halfHeight / inSampleSize) > reqHeight
	                && (halfWidth / inSampleSize) > reqWidth) {
	            inSampleSize *= 2;
	        }
	    }
	
	    return inSampleSize;
	}
	*/
	public int[] readImage(String filename, int width, int height) {
		Bitmap bmp = BitmapFactory.decodeFile(filename);
        Matrix matrix=new Matrix();
        matrix.postScale((float)width/bmp.getWidth(), (float)height/bmp.getHeight());
        Bitmap scaled=Bitmap.createBitmap(bmp,0,0,bmp.getWidth(),bmp.getHeight(),matrix,true);
        assert(scaled.getWidth() == width && scaled.getHeight() == height);

	    int w = scaled.getWidth();
	    int h = scaled.getHeight();
	    int[] buffer = new int[w * h];
	    scaled.getPixels(buffer, 0, w, 0, 0, w, h);
	    for (int i = 0, n = w*h; i < n; ++i) {
	    	int pixel = buffer[i];
			int a = (pixel & 0xff000000) >>> 24;
			int r = (pixel & 0x00ff0000) >>> 16;
			int g = (pixel & 0x0000ff00) >>> 8;
			int b = (pixel & 0x000000ff);
			buffer[i] = a << 24 | b << 16 | g << 8 | r;
	    }
	    
	    return buffer;
	}	
	
//	public int[] readImage(String filename, int width, int height) {		
//		final BitmapFactory.Options options = new BitmapFactory.Options();
//	    options.inJustDecodeBounds = true;
//	    BitmapFactory.decodeFile(filename, options);
//	    
//	    options.inSampleSize = calculateInSampleSize(options, width, height);
//	    
//	    options.inJustDecodeBounds = false;
//	    Bitmap bmp = BitmapFactory.decodeFile(filename, options);
//	    
//	    int w = bmp.getWidth();
//	    int h = bmp.getHeight();
//	    int[] buffer = new int[w * h];
//	    bmp.getPixels(buffer, 0, w, 0, 0, w, h);
//	    for (int i = 0, n = w*h; i < n; ++i) {
//	    	int pixel = buffer[i];
//	    	
//			int a = (pixel & 0xff000000) >>> 24;
//			int r = (pixel & 0x00ff0000) >>> 16;
//			int g = (pixel & 0x0000ff00) >>> 8;
//			int b = (pixel & 0x000000ff);
//	    	
////	    	int rgb = (pixel & 0x00ffffff) << 8;
////	    	int a = (pixel & 0xff000000) >>> 24;    	
////	    	int dst = rgb | a;
//			
//	    //	buffer[i] = r << 24 | g << 16 | b << 8 | a;
//			buffer[i] = a << 24 | b << 16 | g << 8 | r;
//	    }
//	    return buffer;
//	}
	
	public void writeImage(String filename, byte[] bytes, int oldWidth, int oldHeight, int newWidth, int newHeight) {
		Bitmap oldBmp = BitmapFactory.decodeByteArray(bytes, 0, oldWidth * oldHeight * 4);
		Bitmap scaled = Bitmap.createScaledBitmap(oldBmp, newWidth, newHeight, true);
		
		OutputStream outStream = null;
		File file = new File(filename);
		try {
			outStream = new FileOutputStream(file);
			scaled.compress(Bitmap.CompressFormat.JPEG, 80, outStream);
			outStream.flush();
			outStream.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public void writeImage(String filename, byte[] bytes, int width, int height) {
//		Bitmap bmp = BitmapFactory.decodeByteArray(bytes, 0, width * height * 4);
		
		int[] data = new int[width*height];
		for (int i = 0; i < height; ++i) {
			for (int j = 0; j < width; ++j) {
				int ptr_src = i*width+j;
				int r = bytes[ptr_src*4] & 0xff;
				int g = bytes[ptr_src*4+1] & 0xff;
				int b = bytes[ptr_src*4+2] & 0xff;
				int a = bytes[ptr_src*4+3] & 0xff;
				
				int ptr_dst = i*width+(width-1-j);
				data[ptr_dst] = a << 24 | r << 16 | g << 8 | b;
			}
		}
		
		Bitmap bmp = Bitmap.createBitmap(data, width, height, Bitmap.Config.ARGB_8888);
        Matrix matrix=new Matrix();
        matrix.postScale(-1, -1);
        bmp=Bitmap.createBitmap(bmp,0,0,bmp.getWidth(),bmp.getHeight(),matrix,true);
        
		OutputStream outStream = null;
		File file = new File(filename);
		try {
			outStream = new FileOutputStream(file);
			bmp.compress(Bitmap.CompressFormat.JPEG, 80, outStream);
			outStream.flush();
			outStream.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	public ImageData drawTextToBitmap(byte[] bytes, int size, int color) {
		
		String text = "";
		try {
			text = new String(bytes, "utf-8");
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	    TextPaint paint = new TextPaint(Paint.ANTI_ALIAS_FLAG);
	    paint.setTypeface(tf);
	    paint.bgColor = 0;
	    paint.setTextSize(size-1);
	    paint.setColor(color);
	    paint.setDither(true);
	    paint.setTextAlign(Paint.Align.LEFT);
	    
	    int width = (int) (paint.measureText(text) + 0.5f); // round
	    float baseline = -paint.ascent(); // ascent() is negative
	    int height = (int) (baseline + paint.descent() + 1);

	    if (width <= 0 || height <= 0) {
	    	paint.setTypeface(Typeface.SANS_SERIF);
	    	paint.bgColor = 0;
		    paint.setTextSize(size-1);
		    paint.setColor(color);
		    paint.setDither(true);
		    paint.setTextAlign(Paint.Align.LEFT);
		    
		    width = (int) (paint.measureText(text) + 0.5f); // round
		    baseline = -paint.ascent(); // ascent() is negative
		    height = (int) (baseline + paint.descent() + 1);
		    if (width <= 0 || height <= 0){
		    	paint.setTypeface(Typeface.DEFAULT);
		    	paint.bgColor = 0;
			    paint.setTextSize(size-1);
			    paint.setColor(color);
			    paint.setDither(true);
			    paint.setTextAlign(Paint.Align.LEFT);
			    
			    width = (int) (paint.measureText(text) + 0.5f); // round
			    baseline = -paint.ascent(); // ascent() is negative
			    height = (int) (baseline + paint.descent() + 1);
			    if (width <= 0 || height <= 0){
				    ImageData img = new ImageData();
				    img.pixels = new byte[0];
				    img.width = 0;
				    img.height = 0;
				    return img;			    	
			    }	    	
		    }
	    }
	    
	    Bitmap image = Bitmap.createBitmap(width, height/*layout.getHeight() + 1*/, Bitmap.Config.ALPHA_8);
	    Canvas canvas = new Canvas(image);
	    canvas.drawText(text, 0, baseline, paint);
	    
	    int w = image.getWidth();
	    int h = image.getHeight();
	    
		ByteBuffer byteBuffer = ByteBuffer.allocate(image.getRowBytes() * image.getHeight());
		image.copyPixelsToBuffer(byteBuffer);

	    ImageData img = new ImageData();
	    img.pixels = byteBuffer.array();
	    img.width = w;
	    img.height = h;
	    
	    return img;
	}
}
