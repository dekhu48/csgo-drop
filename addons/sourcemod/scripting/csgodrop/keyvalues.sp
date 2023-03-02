bool ReadKeyValues(int iDefIndex, char[] sItemName, int itemname_maxlen, char[] sImageUrl, int imageurl_maxlen) {
	char filename[PLATFORM_MAX_PATH];

	KeyValues kv = new KeyValues("csgodrop");
	BuildPath(Path_SM, filename, sizeof(filename), "configs/csgodrop.ini");
	kv.ImportFromFile(filename);

	char defIndex[8];

	IntToString(iDefIndex, defIndex, sizeof(defIndex));

	if(!kv.JumpToKey(defIndex)) {
		delete kv;
		return false;
	}

	kv.GetString("item_name", sItemName, itemname_maxlen);
	kv.GetString("image_url", sImageUrl, imageurl_maxlen);

	delete kv;
	return true;
}