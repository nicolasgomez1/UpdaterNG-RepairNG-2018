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
	Paragraph.SetText("Paragraph1", String.GetFormattedSize(Copied, FMTSIZE_AUTOMATIC, true).."/"..String.GetFormattedSize(Total, FMTSIZE_AUTOMATIC, true));
end

function ForceUpdate(Version, UpdaterAdress, TempFolder, DestinationFolder)
	XML.SetXML(SubmitCheckMethod(UpdaterAdress));
	for Count = 1, XML.Count("UpdaterNG", "Update") do
		local UpdateVersion = XML.GetAttribute("UpdaterNG/Update:"..Count.."", "version");
		if(tonumber(Version) < tonumber(UpdateVersion))then
			if(tonumber(Version) ~= tonumber(UpdateVersion))then
				local UpdateUrl = XML.GetValue("UpdaterNG/Update:"..Count.."");
				local FileData = String.SplitPath(UpdateUrl);
				DownloadCheckMethod(UpdateUrl, TempFolder.."\\"..FileData.Filename..String.TrimRight(FileData.Extension, "?dl=1"));
				Zip.Extract(TempFolder.."\\"..FileData.Filename..String.TrimRight(FileData.Extension, "?dl=1"), {"*.*"}, TempFolder.."\\unzip\\", true, true, "", ZIP_OVERWRITE_ALWAYS, ZipCallBack);
				File.Move(TempFolder.."\\unzip\\*.*", DestinationFolder.."\\", true, true, true, true, FileMoveCallBack);
			end
		end
	end
	Error = Application.GetLastError();
	if(Error == 0)then
		Paragraph.SetText("Paragraph1", "Update Completed");
		Folder.DeleteTree(TempFolder, nil);
	else
		Paragraph.SetText("Paragraph1", _tblErrorMessages[Error]);
	end
end

function CheckUpdates(Version, UpdaterAdress, TempFolder, DestinationFolder)
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
		ForceUpdate(Version, UpdaterAdress, TempFolder, DestinationFolder);
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
		--for _, exception in pairs(DelimitedToTable(Exceptions, ",")) do
		for _, exception in pairs(Exceptions) do
			Dialog.Message("", exception);
			if(FileData.Filename..FileData.Extension ~= exception)then
				Status = (false);
			else
				Status = (true);
				break;
			end
		end
		--if(FileData.Filename..FileData.Extension ~= "autorun.exe" and FileData.Filename..FileData.Extension ~= "Test.xml" and FileData.Filename..FileData.Extension ~= "autorun.cdd")then
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

function Repair(RepairAdress, RepairFolderAdress, TempFolder, DestinationFolder)
	local Status = (true);
	XML.SetXML(SubmitCheckMethod(RepairFolderAdress));
	for Count = 1, XML.Count("RepairNG", "*") do
		if(File.DoesExist(XML.GetAttribute("RepairNG/file:"..Count, "path")..XML.GetValue("RepairNG/file:"..Count)))then
			if(XML.GetAttribute("RepairNG/file:"..Count, "checksum") ~= Crypto.MD5DigestFromFile(XML.GetAttribute("RepairNG/file:"..Count, "path")..XML.GetValue("RepairNG/file:"..Count)))then
				Status = (false);
			end
		else
			Status = (false);
		end
		
		if(Status == false)then
			DownloadCheckMethod(RepairFolderAdress..XML.GetAttribute("RepairNG/file:"..Count, "url"), TempFolder.."\\"..XML.GetValue("RepairNG/file:"..Count));
			File.Move(TempFolder.."\\*.*", DestinationFolder.."\\", true, true, true, true, FileMoveCallBack);
		end
	end
	Error = Application.GetLastError();
	if(Error == 0)then
		Paragraph.SetText("Paragraph1", "Repair Completed");
		Progress.SetCurrentPos("Progress1", 100);
		Folder.DeleteTree(TempFolder, nil);
	else
		Paragraph.SetText("Paragraph1", _tblErrorMessages[Error]);
	end
end
