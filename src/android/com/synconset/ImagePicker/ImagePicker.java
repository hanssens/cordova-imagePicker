/**
 * An Image Picker Plugin for Cordova/PhoneGap.
 */
package com.synconset;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONStringer;

import com.google.gson.Gson;
import com.google.gson.JsonArray;

import java.util.ArrayList;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import mediachooser.FileThumbModel;
import mediachooser.MediaChooser;

public class ImagePicker extends CordovaPlugin {
	public static String TAG = "ImagePicker";
	 
	private CallbackContext callbackContext;
	private JSONObject params;
	 
	public boolean execute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
		 this.callbackContext = callbackContext;
		 this.params = args.getJSONObject(0);
		if (action.equals("getPictures")) {
			Intent intent = new Intent(cordova.getActivity(), mediachooser.activity.BucketHomeFragmentActivity.class);
			int max = 100;
			int desiredWidth = 0;
			int desiredHeight = 0;
			int quality = 100;
			int thumbSize = 100;
			if (this.params.has("maximumImagesCount")) {
				max = this.params.getInt("maximumImagesCount");
			}
			if (this.params.has("width")) {
				desiredWidth = this.params.getInt("width");
			}
			if (this.params.has("height")) {
				desiredWidth = this.params.getInt("height");
			}
			if (this.params.has("quality")) {
				quality = this.params.getInt("quality");
			}
			if(this.params.has("thumbSize")) {
				thumbSize = this.params.getInt("thumbSize");
			}
			intent.putExtra("MAX_IMAGES", max);
			intent.putExtra("WIDTH", desiredWidth);
			intent.putExtra("HEIGHT", desiredHeight);
			intent.putExtra("QUALITY", quality);
			intent.putExtra("THUMB_SIZE", thumbSize);

			// Set the selection limit so users cannot select more than the given amount
			MediaChooser.setSelectionLimit(max);

			// Reset selected image count because of re-initializing the imagepicker
			MediaChooser.setSelectedMediaCount(0);

			if (this.cordova != null) {
				this.cordova.startActivityForResult((CordovaPlugin) this, intent, 0);
			}
		}
		return true;
	}
	
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		if (resultCode == Activity.RESULT_OK && data != null) {
			ArrayList<FileThumbModel> fileThumbModels = new ArrayList();
			Bundle bundle = data.getExtras();
			if(bundle != null){
				fileThumbModels = bundle.getParcelableArrayList("MULTIPLEFILENAMES");
			}

			Gson gson = new Gson();
			String str_json = gson.toJson(fileThumbModels);
			JSONArray res;
			try{
				res = new JSONArray(str_json);
			} catch (JSONException e){
				String error = "error";
				this.callbackContext.error(error);
				return;
			}

			this.callbackContext.success(res);
		} else if (resultCode == Activity.RESULT_CANCELED && data != null) {
			String error = data.getStringExtra("ERRORMESSAGE");
			this.callbackContext.error(error);
		} else if (resultCode == Activity.RESULT_CANCELED) {
			JSONArray res = new JSONArray();
			this.callbackContext.success(res);
		} else {
			this.callbackContext.error("No images selected");
		}
	}
}