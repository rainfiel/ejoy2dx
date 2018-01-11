package com.ejoy2dx.example;

import java.io.RandomAccessFile;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.DecimalFormat;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import android.provider.Settings.Secure;
import android.telephony.TelephonyManager;
import android.util.Log;

public class DeviceInfo {

	private final Context mContext;
	
	public DeviceInfo(final Context pContext) {
		this.mContext = pContext;
	}
	
	public String getDeviceID() {
        //compute DEVICE ID
        String m_szDevIDShort = "35" + //we make this look like a valid IMEI
        	Build.BOARD.length()%10+ Build.BRAND.length()%10 + 
        	Build.CPU_ABI.length()%10 + Build.DEVICE.length()%10 + 
        	Build.DISPLAY.length()%10 + Build.HOST.length()%10 + 
        	Build.ID.length()%10 + Build.MANUFACTURER.length()%10 + 
        	Build.MODEL.length()%10 + Build.PRODUCT.length()%10 + 
        	Build.TAGS.length()%10 + Build.TYPE.length()%10 + 
        	Build.USER.length()%10 ; //13 digits
        
        //android ID - unreliable
        String m_szAndroidID = Secure.getString(this.mContext.getContentResolver(), Secure.ANDROID_ID); 
        
       	//SUM THE IDs
    	String m_szLongID = m_szDevIDShort + m_szAndroidID;
    	MessageDigest m = null;
		try {
			m = MessageDigest.getInstance("MD5");
		} catch (NoSuchAlgorithmException e) {
			e.printStackTrace();
		} 
		m.update(m_szLongID.getBytes(),0,m_szLongID.length());
		byte p_md5Data[] = m.digest();
		
		String m_szUniqueID = new String();
		for (int i=0;i<p_md5Data.length;i++) {
			int b =  (0xFF & p_md5Data[i]);
			// if it is a single digit, make sure it have 0 in front (proper padding)
			if (b <= 0xF) m_szUniqueID+="0";
			// add number to string
			m_szUniqueID+=Integer.toHexString(b); 
		}
		m_szUniqueID = m_szUniqueID.toUpperCase(java.util.Locale.ENGLISH);   
		
		return m_szUniqueID;
	}
	
	public String getSystemVersion() {
		return Integer.toString(Build.VERSION.SDK_INT);
	}
	
	public double getTotalMemory() {
        RandomAccessFile reader = null;
        String load = null;
        DecimalFormat twoDecimalForm = new DecimalFormat("#.##");
        double totRam = 0;
        double val = 0;
        try {
            reader = new RandomAccessFile("/proc/meminfo", "r");
            load = reader.readLine();

            // Get the Number value from the string
            Pattern p = Pattern.compile("(\\d+)");
            Matcher m = p.matcher(load);
            String value = "";
            while (m.find()) {
                value = m.group(1);
            }
            reader.close();

            totRam = Double.parseDouble(value);
            double mb = totRam / 1024.0;
            double gb = totRam / 1048576.0;
            double tb = totRam / 1073741824.0;

            if (tb > 1) {
                Log.d("memory", twoDecimalForm.format(tb).concat(" TB"));
            } else if (gb > 1) {
            	Log.d("memory", twoDecimalForm.format(gb).concat(" GB"));
            } else if (mb > 1) {
            	Log.d("memory", twoDecimalForm.format(mb).concat(" MB"));
            } else {
            	Log.d("memory", twoDecimalForm.format(totRam).concat(" KB"));
            }
            val = mb;
        } catch (Exception ex) {
            ex.printStackTrace();
        } finally {
            // Streams.close(reader);
        }
        return val;
	}
	
	public double getUsedMemory() {
//		MemoryInfo mi = new ActivityManager.MemoryInfo();
//		ActivityManager activityManager = (ActivityManager)this.mContext.getSystemService(Context.ACTIVITY_SERVICE);
//		activityManager.getMemoryInfo(mi);
//		return mi.availMem / 1048576L;
		return 0;
	}
	
	public int getDPI() {
		return mContext.getResources().getDisplayMetrics().densityDpi;
	}
	
	public String getPreferredLanguage() {
		return this.mContext.getResources().getConfiguration().locale.getDisplayName();
	}

    public String getDeviceNetworkType() {
    	String strNetworkType = "";
    	
        ConnectivityManager connectMgr = (ConnectivityManager)mContext.getSystemService(Context.CONNECTIVITY_SERVICE);
        if (connectMgr == null)
            return strNetworkType;

        NetworkInfo networkInfo = connectMgr.getActiveNetworkInfo();
        if (networkInfo != null && networkInfo.isConnected())
        {
            if (networkInfo.getType() == ConnectivityManager.TYPE_WIFI)
            {
                strNetworkType = "WIFI";
            }
            else if (networkInfo.getType() == ConnectivityManager.TYPE_MOBILE)
            {
                String _strSubTypeName = networkInfo.getSubtypeName();
                
                Log.e("device", "Network getSubtypeName : " + _strSubTypeName);
                
                // TD-SCDMA   networkType is 17
                int networkType = networkInfo.getSubtype();
                switch (networkType) {
                    case TelephonyManager.NETWORK_TYPE_GPRS:
                    case TelephonyManager.NETWORK_TYPE_EDGE:
                    case TelephonyManager.NETWORK_TYPE_CDMA:
                    case TelephonyManager.NETWORK_TYPE_1xRTT:
                    case TelephonyManager.NETWORK_TYPE_IDEN: //api<8 : replace by 11
                        strNetworkType = "2G";
                        break;
                    case TelephonyManager.NETWORK_TYPE_UMTS:
                    case TelephonyManager.NETWORK_TYPE_EVDO_0:
                    case TelephonyManager.NETWORK_TYPE_EVDO_A:
                    case TelephonyManager.NETWORK_TYPE_HSDPA:
                    case TelephonyManager.NETWORK_TYPE_HSUPA:
                    case TelephonyManager.NETWORK_TYPE_HSPA:
                    case TelephonyManager.NETWORK_TYPE_EVDO_B: //api<9 : replace by 14
                    case TelephonyManager.NETWORK_TYPE_EHRPD:  //api<11 : replace by 12
                    case TelephonyManager.NETWORK_TYPE_HSPAP:  //api<13 : replace by 15
                        strNetworkType = "3G";
                        break;
                    case TelephonyManager.NETWORK_TYPE_LTE:    //api<11 : replace by 13
                        strNetworkType = "4G";
                        break;
                    default:
                        // http://baike.baidu.com/item/TD-SCDMA 中国移动 联通 电信 三种3G制式
                        if (_strSubTypeName.equalsIgnoreCase("TD-SCDMA") 
                        		|| _strSubTypeName.equalsIgnoreCase("WCDMA") 
                        		|| _strSubTypeName.equalsIgnoreCase("CDMA2000")) 
                        {
                            strNetworkType = "3G";
                        }
                        else
                        {
                            strNetworkType = _strSubTypeName;
                        }
                        
                        break;
                 }
                 
                Log.e("device", "Network getSubtype : " + Integer.valueOf(networkType).toString());
            }
        }
        
        Log.e("device", "Network Type : " + strNetworkType);
        
        return strNetworkType;
    }
}
