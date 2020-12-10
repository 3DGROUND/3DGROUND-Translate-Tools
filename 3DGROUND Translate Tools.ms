try(closeRolloutFloater fTranslates) catch()
global fTranslates = newRolloutFloater "3DGROUND Translate Tools" 1400 877
global _rTranslatesUI

fn httpGet url =
(	
	t = ""
	url += "&time=" + (timeStamp() as string)
	try
	(
		w = dotNetObject (dotNetClass "System.Net.WebClient")
		s = dotNetClass "System.IO.StreamReader"
		o = w.OpenRead url
		l = dotNetObject s o
		t = l.ReadToEnd()
	)
	catch()
	
	return t
)

fn getDotNetColor r g b = (DotNetClass "System.Drawing.Color").fromargb r g b 

fn handleBr l type: #put = (
	if(type == #get) do (
		l = substituteString l " || " "\n\n" 
		l = substituteString l " | " "\n" 
		return trimRight l "\n"
	)
	
	l = substituteString l "\n\n" " || "
	l = substituteString l "\n" " | "
	return trimRight l "\n"
)

fn b64d s =
(
	dc = dotNetClass "System.Convert"
	u8 = dotNetObject "System.Text.UTF8Encoding"
	bb = dc.FromBase64String s
	return u8.getString bb
)

fn translateText txt: "" f:"ru" t:"en" = (
	u = b64d "aHR0cHM6Ly8zZGdyb3VuZC5uZXQvZ2F0ZS9teHMvbXhzLmdldC50cmFuc2xhdGUucGhwP2xuPQ=="
	url = u + f + "-" + t + "&text=" + txt + "&time=" + timeStamp() as string
	r = httpGet url
	return r
)

fn getScriptsFromInstalled = (
	p = getDir (#temp) + @"\*"
	d = getDirectories p

	lngScripts = #()
	struct ln (script, files)

	for i in 1 to d.count where doesFileExist (d[i] + "english.lng") do (
		lngScripts[i] = #()
		pp = filterString d[i]	@"\"
		n = pp[pp.count]
		f = getFiles (d[i] + "*.lng")
		
		lngScripts[i] = ln script: n files: f
	)
	
	return lngScripts
)

fn getTranslateFiles = (
	ddl = _rTranslatesUI.ddlInstalledScript
	
	p = getFileNamePath(getThisScriptFileName())
	files = getFiles (p + "*.lng")
		
	if(files.count == 0)	do p += @"..\"
		
	files = getFiles (p + "*.lng")
		
	if(files.count == 0)	 do (
		j = getScriptsFromInstalled()
		if(j.count > 0 and ddl != undefined and ddl.items.count == 0) do (
			ddl.enabled = true
			ddl.items = for i in j collect i.script
		)
		
		if(ddl.items.count > 0) do (
			for i in j where ddl.selected == i.script do return i.files
		)
	)
	
	return files
)

fn getTranslatesNames = (
	for f in getTranslateFiles() where (getIniSetting f "INDEX" "TYPE") == "dictionary" collect getIniSetting f "INDEX" "NAME"
)

fn getListUniqueKeys sec: "UI"= (
	files = getTranslateFiles()
	result = #()
	for f in files do (
		join result (getIniSetting f sec)
	)
	
	return makeUniqueArray result
)

fn setSelectedId lbx id = (
	lbx.items.item[id].Selected = true
	lbx.EnsureVisible id
	lbx.Focus()
)

fn getSelectedId lbx = (
	c = lbx.SelectedItems.Count - 1		
	id = -1		
	for i = 0 to c do id = lbx.SelectedItems.Item[i].Index
	return id
)

fn getSelectedItem lbx = (
	item = undefined
	c = lbx.SelectedItems.Count - 1					
	for i = 0 to c do item = lbx.SelectedItems.Item[i]
	return item
)

fn addToLbxList lbx rows = (				
	lbx.Items.Clear()
	lbxRows = #()	
	i = 1
	for x in rows do(
		li = dotNetObject "System.Windows.Forms.ListViewItem" ""
		li.useItemStyleForSubItems = false
		bold = (dotnetclass "System.Drawing.FontStyle").Bold
		
		li.text = (i as string) + "."
		li.tag = x[1]
		for ii in x do (
			cell = li.subitems.add ii[1]
			cell.tag = dotNetMxsValue ii
			if(ii[1] == "") do cell.backColor = getDotNetColor 224 102 102
		)
		
		li.tag = x[1]
		
		append lbxRows li		
		i += 1
	)
	
	lbx.Items.addRange lbxRows
)

fn buildList lbx sec: "UI" filt: "" = (
	filt = _rTranslatesUI.edtFilter.text
	keys = getListUniqueKeys sec: sec
	sort keys
	files = getTranslateFiles()
	rows = #()
	
	lbx.tag = sec
	
	isFilterOn = filt != ""
	
	for key in keys do (
		filtOk = false
		row = #()		
		append row #(key, sec)
		
		if(isFilterOn and matchPattern key pattern: ("*" + filt + "*")) do filtOk = true
			
		for f in files do (
			val = getIniSetting f sec key
			
			if(isFilterOn and matchPattern val pattern: ("*" + filt + "*")) do filtOk = true
			
			lang = getIniSetting f "INDEX" "NAME"
			iso2 = toLower (getIniSetting f "INDEX" "ISO2")
			append row #(val, f, lang, key, iso2)
		)
		
		if(isFilterOn and filtOk) do append rows row
		if(not isFilterOn) do append rows row
	)
	
	addToLbxList lbx rows
)

fn removeItemId lbx id = (
	try(lbx.Items.RemoveAt[id]) catch()
)

fn initDotNet lbx =	(			
	align = dotNetClass "HorizontalAlignment"
	names = getTranslatesNames()
	columnsWidth = (lbx.width - 35 - 18) / (names.count + 1)
	
	lbx.Clear()
	lbx.View = (dotNetClass "System.Windows.Forms.View").Details	
	lbx.FullRowSelect = true
	lbx.GridLines = true	
	--lbx.LabelEdit = true
	lbx.ShowItemToolTips = true
	lbx.MultiSelect = false
	lbx.CheckBoxes = false
	lbx.HideSelection = false
	lbx.Columns.Add "#" 35
	lbx.Columns.Add ("KEY") columnsWidth
	
	
	for n in names do lbx.Columns.Add (n) columnsWidth

	lbx.Update()
	lbx.Refresh()
)

fn handleRow lbx sec: "UI" type: #put key: "" = (
	global rhandleRow
	try(destroyDialog rhandleRow) catch()
	
	global rowSec = sec
	global rowLbx = lbx
	global rowData = #()
	global rowEdts = #()
	global rowTrans = #()
	global rowTrans = #()
	global rowType = type
	global rowKey = key
	global rowTitle = if(rowType == #put) then "Add New Item" else "Edit Item"
	global itemHeight = 65
	
	rollout rhandleRow ""  (
		dropdownlist ddlMainLang "Main Language: " items: #()
		edittext edtKey "Key:            "
		label lblDummy ""
		edittext edtTranslate1 "                  " enabled: false align: #left height: itemHeight width: 545 across: 2
		button btnTranslate1 "T" align: #right height: itemHeight enabled: false
		edittext edtTranslate2 "                  " enabled: false align: #left height: itemHeight width: 545 across: 2
		button btnTranslate2 "T" align: #right height: itemHeight enabled: false
		edittext edtTranslate3 "                  " enabled: false align: #left height: itemHeight width: 545 across: 2
		button btnTranslate3 "T" align: #right height: itemHeight enabled: false
		edittext edtTranslate4 "                  " enabled: false align: #left height: itemHeight width: 545 across: 2
		button btnTranslate4 "T" align: #right height: itemHeight enabled: false
		edittext edtTranslate5 "                  " enabled: false align: #left height: itemHeight width: 545 across: 2
		button btnTranslate5 "T" align: #right height: itemHeight enabled: false
		edittext edtTranslate6 "                  " enabled: false align: #left height: itemHeight width: 545 across: 2
		button btnTranslate6 "T" align: #right height: itemHeight enabled: false
		edittext edtTranslate7 "                  " enabled: false align: #left height: itemHeight width: 545 across: 2
		button btnTranslate7 "T" align: #right height: itemHeight enabled: false
		edittext edtTranslate8 "                  " enabled: false align: #left height: itemHeight width: 545 across: 2
		button btnTranslate8 "T" align: #right height: itemHeight enabled: false
		edittext edtTranslate9 "                  " enabled: false align: #left height: itemHeight width: 545 across: 2
		button btnTranslate9 "T" align: #right height: itemHeight enabled: false
				
		label lblDummy2 ""
		button btnCancel "Cancel" width: 120 height: 35 across: 2
		button btnOk  "Ok" width: 120  height: 35
		
		fn trim t tag: "~"= (
			return trimLeft (trimRight t tag) tag
		)
		
		fn trans i = (
			if(i == ddlMainLang.selection) do return messageBox "You can't translate main language!" title: "Warning!"
			id = ddlMainLang.selection 
			
			txt = rowEdts[id].text
			if(txt == "") do return messageBox ("Please enter the " + ddlMainLang.selected + " text!") title: "Warning!"
						
			f = rowData[id][3]
			t = rowData[i][3]
			
			res = translateText txt: txt f: f t: t
			rowEdts[i].text = res
		)
		
		on btnTranslate1 pressed do trans 1
		on btnTranslate2 pressed do trans 2
		on btnTranslate3 pressed do trans 3
		on btnTranslate4 pressed do trans 4
		on btnTranslate5 pressed do trans 5
		on btnTranslate6 pressed do trans 6
		on btnTranslate7 pressed do trans 7
		on btnTranslate8 pressed do trans 8
		on btnTranslate9 pressed do trans 9
		
		fn setMainLang = (
			i = ddlMainLang.selection
			nn = ddlMainLang.selected
			for i in 1 to rowData.count do (				
				rowTrans[i].enabled = true
				rowTrans[i].visible = true
				rowEdts[i].caption = trimLeft (rowEdts[i].caption) "*"
				rowTrans[i].tooltip = "Google Translate: " + nn + " -> " + rowEdts[i].caption
			)
			
			if(i > 0) do (
				rowTrans[i].enabled = false
				rowTrans[i].visible = false
				rowEdts[i].caption = "*" + rowEdts[i].caption				
			)
		)
		
		on ddlMainLang selected v do (
			setMainLang()
		)
		
		on rhandleRow open do (
			rhandleRow.title = rowTitle
			
			edtKey.text = "~DUMMY~"
			
			rowEdts = for c in rhandleRow.controls where (matchPattern (c as string) pattern: "*edtTranslate*") collect c
			rowTrans = for c in rhandleRow.controls where (matchPattern (c as string) pattern: "*btnTranslate*") collect c
			
			files = getTranslateFiles()
			
			rowData = #()
			rus = #()
			for f in files do (
				iso2 = toLower (getIniSetting f "INDEX" "ISO2")
				n = getIniSetting f "INDEX" "NAME"
				
				append rowData #(f, n, iso2)
			)
				
			langNames = #()
			for i in 1 to rowData.count do (
				if(rowEdts[i] == undefined) do continue
				d = rowData[i]
				rowEdts[i].caption = d[2]
				rowEdts[i].enabled = true
				rowTrans[i].enabled = true
				
				if(d[3] == "ru") do (
					ddlMainLang.selection = i
					rowTrans[i].enabled = false
					rowTrans[i].visible = false
				)
				append langNames d[2]
			)
			
			ddlMainLang.items = langNames
			
			if(rowType == #get) do (
				edtKey.text = rowKey
				for i in 1 to rowData.count do (
					f = rowData[i][1]
					
					rowEdts[i].text = handleBr (getIniSetting f rowSec rowKey) type: #get
				)
			)
			
			setMainLang()
		)
		
		on btnCancel pressed do (	
			try(destroyDialog rhandleRow) catch()
		)
		
		on btnOk pressed do (
			isFilled = true
			for i in 1 to rowData.count where rowEdts[i].text == "" do isFilled = false
				
			id = getSelectedId rowLbx
				
			if(not isFilled) do (
				q = queryBox "Some languages fields not filled!\nDo you want to continue?" title: "Confirm?"
				if(not q) do return false
			)
			
			k = "~" + (trim edtKey.text) + "~"
			edtKey.text = k
			s = rowSec
			
			isExists = (getIniSetting rowData[1][1] s k) != ""
			if(isExists and rowType != #get) do (
				messageBox ("The key: " + k + " already exist! \nPlease choose another name!") title: "Error!"
				return false
			)
			
			if(rowType == #get and k != rowKey) do (
				q = queryBox "Do you really want to change key for all languages?" title: "Confirm?"
				if(not q) do return false
				
				files = getTranslateFiles()
				for f in files do (
					oldVal = getIniSetting f s rowKey
					setIniSetting f s k oldVal
					delIniSetting f s rowKey
				)				
			)
			
			for i in 1 to rowData.count do (
				f = rowData[i][1]
				v = rowEdts[i].text
				
				setIniSetting f s k (handleBr v)
			)
		
			setClipboardText k
			displayTempPrompt  ("Key " + k + " copied!")  10000

			buildList rowLbx sec: s
			try(destroyDialog rhandleRow) catch()
			
			setSelectedId rowLbx id
		)
	)
	
	createDialog rhandleRow  600 770 modal: true
)

fn subItemAtMousePos lbx pos: undefined = (
	try (
		if(pos == undefined) do pos = lbx.mousePosition 
		local posScreen = [pos.x, pos.y] 
	

		pos = lbx.PointToClient pos 
		local posDialog = [pos.x, pos.y]
		
		local li = lbx.getItemAt pos.x pos.y
		local si = li.getSubItemAt pos.x pos.y
		
		local posBounds = [si.Bounds.X, si.Bounds.Y-2]
		
		posFinal = ((posScreen - posDialog) + posBounds)
		
		local idxs = #(li.index , (li.subitems.indexof si))  
		local cell = lbx.Items.item[idxs[1]].subitems.item[idxs[2]]
		local tag = cell.tag.value
		local li = lbx.Items.item[idxs[1]]		
		local key = li.tag[1]
		
		handleRow lbx sec: lbx.tag type: #get key: key		
	)
	catch()
)

fn contextAddRow s a = (
	lbx = s.tag.value
	s = lbx.tag
	handleRow lbx sec: s type: #put
)

fn contextDeleteRow s a = (
	lbx = s.tag.value
	
	id = getSelectedId lbx 
	li = getSelectedItem lbx
	k = li.tag[1]
	s = li.tag[2]
	
	q = queryBox ("Do you really want to delete key " + k + " from all language files?") title: "Confirm?"
	if(not q) do return false
	
	files = getTranslateFiles()
	for f in files do delIniSetting f s k
	
	removeItemId lbx id
)

fn contextEditCell s a = (
	tag = s.tag.value
	
	subItemAtMousePos tag[1] pos: tag[2]
)

fn contextCopyKey s a = (
	lbx = s.tag.value[1]
	
	id = getSelectedId lbx
	if(id == 0) do return false
	
	item = getSelectedItem lbx
	k = item.tag[1]
	setClipboardText k
	displayTempPrompt  ("Key " + k + " copied!")  10000
	--messageBox ("Key " + k + " copied!") title: "Success!" beep: false
)

fn bindContextMenu lbx = (
	id = getSelectedId lbx
	pos = lbx.mousePosition
	
	contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
	
	li1 = contextMenu.Items.Add("Add new row")
	li1.tag = dotNetMxsValue lbx
	dotNet.addEventHandler (li1) "Click" contextAddRow
	
	if(id != -1) do (	
		li2 = contextMenu.Items.Add("Edit cell")
		li2.tag = dotNetMxsValue #(lbx, pos)
		dotNet.addEventHandler (li2) "Click" contextEditCell
		
		contextMenu.Items.Add("-")
		li3 = contextMenu.Items.Add("Copy Key")
		li3.tag = dotNetMxsValue #(lbx, pos)
		dotNet.addEventHandler (li3) "Click" contextCopyKey
		contextMenu.Items.Add("-")
		
		li4 = contextMenu.Items.Add("Delete row")
		li4.tag = dotNetMxsValue lbx
		dotNet.addEventHandler (li4) "Click" contextDeleteRow
	)
				
	lbx.ContextMenuStrip = contextMenu
)

fn addNewLanguage lbx sec: "UI" = (
	try(destroyDialog rAddNewLang) catch()
	global newLangSec = sec
	global newLangLbx = lbx
	
	rollout rAddNewLang "Add New Language" (
		edittext edtLang "*Language Name: "
		edittext edtLangISO2 "*Language ISO2 (ex. RU, VI, UK, EN, PL): "
		edittext edtAuthor "*Author: "
		edittext edtWebSite "Web Site: "
		edittext edtVersion "*Version (ex. 1.0.0): "
		edittext edtDesk "Description: "
		label lblDummy ""
		
		button btnCancel "Cancel" width: 120 height: 35 across: 2
		button btnOk "Ok" width: 120 height: 35
		
		on btnOk pressed do (
			j = getTranslateFiles()			
			p = getFileNamePath (getThisScriptFileName())
				
			if(j.count > 0) do (
				p = getFilenamePath j[1]
			)	
				
			n = edtLang.text
			n[1]	 = toUpper n[1]
				
			fileName = p + (toLower n) + ".lng"
			iso2 = toUpper (edtLangISO2.text)
			authour = edtAuthor.text
			web = edtWebSite.text
			ver = edtVersion.text
			desc = edtDesk.text
				
			if(n.count < 2)	 do  return messageBox ("Please enter correct Language Name!") title: "Error!"
			if(doesFileExist fileName) do return messageBox ("Language file: " + n + ".lng already exists!") title: "Error!"
			if(iso2.count != 2)	do return messageBox ("Please enter correct ISO2!\nExample: RU, VI, UK, EN, PL!\nISO2 Name must be correct for Google Translate!") title: "Error!"
			if(authour.count == 0)	do return messageBox ("Please enter Author Name!") title: "Error!"
			if(ver.count < 3)	do return messageBox ("Please enter correct Version!") title: "Error!"
				
			setIniSetting 	fileName "INDEX" "TYPE" "dictionary"
			setIniSetting 	fileName "INDEX" "NAME" n
			setIniSetting 	fileName "INDEX" "LANGUAGE" (toLower n)
			setIniSetting 	fileName "INDEX" "ISO2" iso2
			setIniSetting 	fileName "INDEX" "AUTHOR" authour
			setIniSetting 	fileName "INDEX" "WEB" web
			setIniSetting 	fileName "INDEX" "DESCRIPTION" desc
			setIniSetting 	fileName "INDEX" "VERSION" ver
			setIniSetting 	fileName "INDEX" "NOTE" "Use symbol \" | \" for break the line. And \" || \" for brake twice. Example: Lorem ipsum | dolor sit amet || Fish text"
			
			initDotNet newLangLbx			
			buildList newLangLbx sec: newLangSec	
				
			try(destroyDialog rAddNewLang) catch()
		)
		
		on btnCancel pressed do (
			try(destroyDialog rAddNewLang) catch()
		)
	)
	
	createDialog rAddNewLang 300 200 modal: true
)

fn exportLanguages = (
	files = getTranslateFiles()
		
	if(files.count == 0) do return messageBox "Nothing to export!" title: "Error!"
		
	d = getSavePath caption:"Export Languages"
		
	if(d == undefined) do return false
	d += @"\"
	
	for f in files do (
		n = filenameFromPath f
		copyFile f (d + n)
		print ("Copy file: "  + f + " to " + (d + n))
	)
	
	messageBox "Export done!" title: "Success!" beep: false
	shellLaunch d ""
)

rollout _rTranslatesUI "Translate Tools" category: 1 (
	dropdownlist ddlInstalledScript "Installed Script: " items: #() enabled: false
	dropdownlist ddlSecType "Section Type: " items: #("UI", "TOOLTIPS")
	edittext edtFilter "Filter: " across: 4
	button btnClearFilter "X" align: #left offset: [5, -2]
	button btnAddNewLanguage "Add New Language" align: #right offset: [180, 0]
	button btnExportLanguages "Export Languages" align: #right
	dotNetControl lbxTranslatesUI "system.windows.forms.listView" height: 700 width: 1390 offset: [-13, 0]
	timer trmFilter "Timer Filter" active: false interval: 300
	
	fn init = (
		initDotNet lbxTranslatesUI		
		s = ddlSecType.selected 		
		buildList lbxTranslatesUI sec: s
	)
	
	on _rTranslatesUI open do (
		init()
	)
	
	on ddlInstalledScript selected v do (
		init()
	)
	
	on btnAddNewLanguage pressed do (
		s = ddlSecType.selected 
		addNewLanguage lbxTranslatesUI sec: s
	)
	
	on btnExportLanguages pressed do (
		exportLanguages()
	)
	
	on ddlSecType selected v do (
		s = ddlSecType.selected 
		
		buildList lbxTranslatesUI sec: s
	)
	
	on btnClearFilter pressed do (
		edtFilter.text = ""
		s = ddlSecType.selected 		
		buildList lbxTranslatesUI sec: s
	)
	
	on trmFilter tick do (
		s = ddlSecType.selected 		
		buildList lbxTranslatesUI sec: s filt: (edtFilter.text)
		trmFilter.active = false
	)
	
	on edtFilter changed v do (
		trmFilter.active = false
		trmFilter.active = true
	)
	
	on lbxTranslatesUI MouseDoubleClick s a do (
		subItemAtMousePos s
	)
	
	on lbxTranslatesUI MouseUp do	(		
		bindContextMenu lbxTranslatesUI
	)
)

rollout _rAbout "About" category: 2 (
	label lbl0 "3DGROUND Translate Tools"
	label lbl1 "3DGROUND"
	label lbl2 "MastaMan"
	label lbl3 "GNU GPLv3"
	label lblDummy ""
	hyperlink hyperLink1 "https://3dground.net" address: "https://3dground.net" align: #center
)

addRollout _rTranslatesUI fTranslates rolledUp: false
addRollout _rAbout fTranslates rolledUp: true