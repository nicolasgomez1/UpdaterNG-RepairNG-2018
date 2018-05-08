function SubmitCheckMethod(Url)
	if(String.Left(Url, 5) == "https")then
		return HTTP.SubmitSecure(Url, {}, SUBMITWEB_GET, 20, 443, nil, nil);
	else
		return HTTP.Submit(Url, {}, SUBMITWEB_GET, 20, 80, nil, nil);
	end
end

function DownloadCheckMethod(Url, Path)
	if(String.Left(Url, 5) == "https")then
		HTTP.DownloadSecure(Url, Path, MODE_BINARY, 20, 443, nil, nil, DownloadCallback);
	else
		HTTP.Download(Url, Path, MODE_BINARY, 20, 80, nil, nil, DownloadCallback);
	end
end

function DownloadCallback(nDownloaded, nTotal, nTransferRate, SecondLeft, SecondsLeftFormat, Message)
	if(nTotal ~= 0)then
	    --Convert total and downloaded bytes into formatted strings
	    local sDownloaded = String.GetFormattedSize(nDownloaded, FMTSIZE_AUTOMATIC, true);
	    local sTotal = String.GetFormattedSize(nTotal, FMTSIZE_AUTOMATIC, true);
	    local DownloadTransferRate = String.GetFormattedSize(nTransferRate*100.0, FMTSIZE_MB, true);
	    --Returns
	    local DownloadTimeLeft = ("Time Left: "..SecondsLeftFormat);
	    local Downloaded = ("Downloaded: "..sDownloaded.."/"..sTotal);
	    --Set meter position (fraction downloaded * max meter range)
	    local DownloadProgress = (nDownloaded / nTotal * 100);
	    Paragraph.SetText("Paragraph1", DownloadTimeLeft.." - "..Downloaded.." - "..DownloadTransferRate);
	    Progress.SetCurrentPos("Progress1", DownloadProgress);
	else
	    Progress.SetCurrentPos("Progress1", 1000);
    end
end

function ZipCallBack(File, Percent, Status)
	if(Status == ZIP_STATUS_MAJOR)then
		Progress.SetCurrentPos("Progress1", Percent)
	else
		Progress.SetCurrentPos("Progress1", Percent)	
		Paragraph.SetText("Paragraph1", File);
	end
	
	if(Abort)then
		return false;
	else
		return true;
	end
end

function FileMoveCallBack(Source, Destination, Copied, Total, FileCopied, FileTotal)
	Paragraph.SetText("Paragraph1", "Applied"..String.GetFormattedSize(Copied, FMTSIZE_AUTOMATIC, true).." Of "..String.GetFormattedSize(Total, FMTSIZE_AUTOMATIC, true));
end

function ForceUpdate(Version, UpdaterAdress, TempFolder, DestinationFolder, AppToRun)
	for PID, FilePath in pairs(System.EnumerateProcesses()) do
		if(String.Lower(String.SplitPath(FilePath).Filename..String.SplitPath(FilePath).Extension) == String.Lower(String.SplitPath(AppToRun).Filename..String.SplitPath(AppToRun).Extension))then
			System.TerminateProcess(PID);
			break;
		end
	end
	XML.SetXML(SubmitCheckMethod(UpdaterAdress));
	for Count = 1, XML.Count("UpdaterNG", "Update") do
		local UpdateVersion = XML.GetAttribute("UpdaterNG/Update:"..Count.."", "version");
		if(tonumber(Version) < tonumber(UpdateVersion))then
			if(tonumber(Version) ~= tonumber(UpdateVersion))then
				local UpdateUrl = XML.GetValue("UpdaterNG/Update:"..Count.."");
				local FileData = String.SplitPath(UpdateUrl);
				DownloadCheckMethod(UpdateUrl, TempFolder.."\\"..FileData.Filename..FileData.Extension);
				Zip.Extract(TempFolder.."\\"..FileData.Filename..FileData.Extension, {"*.*"}, TempFolder.."\\unzip\\", true, true, "", ZIP_OVERWRITE_ALWAYS, ZipCallBack);
				File.Move(TempFolder.."\\unzip\\*.*", DestinationFolder.."\\", true, true, true, true, FileMoveCallBack);
			end
		end
	end
	Error = Application.GetLastError();
	if(Error == 0)then
		Paragraph.SetText("Paragraph1", "Update Completed");
		Folder.DeleteTree(TempFolder, nil);
		File.Open(AppToRun, "", SW_SHOWNORMAL);
	else
		Paragraph.SetText("Paragraph1", _tblErrorMessages[Error]);
	end
end

function CheckUpdates(Version, UpdaterAdress, TempFolder, DestinationFolder, AppToRun)
	XML.SetXML(SubmitCheckMethod(UpdaterAdress));
	for Count = 1, XML.Count("UpdaterNG", "Update") do
		local UpdateVersion = XML.GetAttribute("UpdaterNG/Update:"..Count.."", "version");
		if(tonumber(Version) < tonumber(UpdateVersion))then
			if(tonumber(Version) ~= tonumber(UpdateVersion))then
				Status = (true);
				break;
			else
				Status = (false);
			end
		end
	end
	if(Status == true)then
		ForceUpdate(Version, UpdaterAdress, TempFolder, DestinationFolder, AppToRun);
	else
		Paragraph.SetText("Paragraph1", "Aplication Updated");
	end
end

function MakeRepairFile(Hostname, Exceptions)
	XML.SetXML("<RepairNG></RepairNG>");
	local Counter = (1);
	for _, Path in pairs(File.Find(_SourceFolder.."", "*", true, false, nil, nil)) do
		local FileData = String.SplitPath(Path);
		local Status = (false);
		for _, exception in pairs(Exceptions) do
			if(FileData.Filename..FileData.Extension ~= exception)then
				Status = (false);
			else
				Status = (true);
				break;
			end
		end
		if(Status == false)then
			XML.SetValue("RepairNG/file:"..Counter, FileData.Filename..FileData.Extension, false);
			XML.SetAttribute("RepairNG/file:"..Counter, "checksum", Crypto.MD5DigestFromFile(Path));
			XML.SetAttribute("RepairNG/file:"..Counter, "path", String.Replace(String.MakePath({Folder=FileData.Drive..FileData.Folder}), Folder.GetCurrent().."\\", "", false));
			XML.SetAttribute("RepairNG/file:"..Counter, "url", Hostname..String.Replace(String.Replace(String.MakePath({Folder=FileData.Drive..FileData.Folder}), Folder.GetCurrent().."\\", "", false), "\\", "/", false)..FileData.Filename..FileData.Extension);
			Counter = (Counter+1);
		end
	end
	XML.Save(_SourceFolder.."\\RepairNG.xml");
end

function Repair(RepairAdress, TempFolder, DestinationFolder, AppToRun)
	local Status = (true);
	XML.SetXML(SubmitCheckMethod(RepairAdress));
	for Count = 1, XML.Count("RepairNG", "*") do
		if(File.DoesExist(XML.GetAttribute("RepairNG/file:"..Count, "path")..XML.GetValue("RepairNG/file:"..Count)))then
			if(XML.GetAttribute("RepairNG/file:"..Count, "checksum") ~= Crypto.MD5DigestFromFile(XML.GetAttribute("RepairNG/file:"..Count, "path")..XML.GetValue("RepairNG/file:"..Count)))then
				Status = (false);
			end
		else
			Status = (false);
		end
		
		if(Status == false)then
			DownloadCheckMethod(XML.GetAttribute("RepairNG/file:"..Count, "url"), TempFolder.."\\"..XML.GetValue("RepairNG/file:"..Count));
			File.Move(TempFolder.."\\*.*", DestinationFolder.."\\", true, true, true, true, FileMoveCallBack);
		end
	end
	Error = Application.GetLastError();
	if(Error == 0)then
		Paragraph.SetText("Paragraph1", "Update Completed");
		Folder.DeleteTree(TempFolder, nil);
		File.Open(AppToRun, "", SW_SHOWNORMAL);
	else
		Paragraph.SetText("Paragraph1", _tblErrorMessages[Error]);
	end
end

function UpdateTheUpdater(Version, UpdaterAdress, TempFolder, AppToRun)
	XML.SetXML(SubmitCheckMethod(UpdaterAdress));
	if(tonumber(Version) < tonumber(XML.GetAttribute("UpdaterNG/Updater", "version")))then
		if(tonumber(Version) ~= tonumber(XML.GetAttribute("UpdaterNG/Updater", "Version")))then
			local URL = XML.GetValue("UpdaterNG/Updater");
			DownloadCheckMethod(XML.GetValue("UpdaterNG/Updater"), TempFolder.."\\Update.zip");
			Zip.Extract(TempFolder.."\\Update.zip", {"*.*"}, TempFolder.."\\NewUpdate\\", true, true, "", ZIP_OVERWRITE_ALWAYS, ZipCallBack);
			TextFile.WriteFromString(_TempFolder..'\\MoveUpdate.bat', [[
				@ECHO OFF
				title UpdaterNG
				timeout /t 5
				move "]]..''..TempFolder..''..[[\NewUpdate\*"]]..' "'.._SourceFolder..'"\r\n'..[[
				start]]..' "" "'..AppToRun..'"\r\n'..[[
				del ]]..'"'..TempFolder..'\\*" /s /q\r\n'..[[
				del "%~f0"
			]], false);
			Dialog.Message("UpdaterNG", "The application is updated in the background, this may take a few minutes...", MB_OK, MB_ICONINFORMATION, MB_DEFBUTTON1)
			File.Run(_TempFolder..'\\MoveUpdate.bat', '', '', SW_HIDE, false);
			Application.Exit(0);
		end
	end
end
