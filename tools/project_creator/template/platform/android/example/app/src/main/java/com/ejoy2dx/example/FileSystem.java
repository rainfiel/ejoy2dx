package com.ejoy2dx.example;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

import android.content.Context;
import android.os.Environment;

public class FileSystem {
	
	private final Context mContext;
	
	public FileSystem(final Context pContext) {
		this.mContext = pContext;
		mkdir(mContext.getFilesDir().getPath() + "/doc");
		mkdir(mContext.getFilesDir().getPath() + "/lib");
		mkdir(mContext.getFilesDir().getPath() + "/cache");
	}
	
	public boolean isExternalStorageStateMounted() {
		return Environment.getExternalStorageState().equals(android.os.Environment.MEDIA_MOUNTED);
	}
	
	public void mkdir(String path) {
		File dir = new File(path);
		dir.mkdirs();
	}
	
	public String getPath(String filename, String mode) {
		String dir = "";
		if (mode == "d") {
			dir = "doc";
		} else if (mode == "l") {
			dir = "lib";
		} else if (mode == "c") {
			dir = "cache";
		}
		
		if (dir == "") {
			return mContext.getFilesDir().getPath() + "/" + filename;
		} else {
			return mContext.getFilesDir().getPath() + "/" + dir + "/" + filename;
		}
	}

	public boolean fileExists(String filename) {
		File file = new File(filename);
		return file.exists();
	}
	
	public byte[] readFile(String filename) {		
		if (!fileExists(filename)) 
			return new byte[0];
			
	     try {
//	    	 File file = new File(filename);
//	    	 FileInputStream fis = new FileInputStream(file);
	    	 
	    	 FileInputStream fis = this.mContext.openFileInput(filename);
	    	 
	    	 byte[] buffer = new byte[fis.available()];
	    	 fis.read(buffer);
	    	 fis.close();
	    	 return buffer;
	    } catch (Exception e) {
	    	e.printStackTrace();
	    }
	    return null;
	}
	
	public void writeFile(String filename, byte[] bytes) {
        try {
//	    	 File file = new File(filename);
//	    	 FileOutputStream fos = new FileOutputStream(file);
	    	 
            FileOutputStream fos = this.mContext.openFileOutput(filename, Context.MODE_PRIVATE);
	    	 
            fos.write(bytes);
            fos.close();
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }	
	
	public void clearFile(String filename) {
//		if (!fileExists(filename)) return;
//		this.mContext.deleteFile(filename);
		
		File file = new File(filename);
		if (file != null) {
			if (file.isDirectory()) {
				String[] children = file.list();
				for (int i =0; i < children.length; i++) {
					new File(file, children[i]).delete();
				}
			} else {
				file.delete();
			}
		}
	}
	
	public void loadFromKeychain() {
		
	}
	
	public void createFileDirectory(String filename) {
		String path = filename.substring(0, filename.lastIndexOf("/"));
		File file = new File(path);
		file.mkdirs();
	}
}
