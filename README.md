# UpdaterNG-RepairNG-2018
UpdaterNg with new features


Functions

CheckUpdates(
  (num)Version, 
  (string)UpdaterAdress, 
  (string)TempFolder, 
  (string)DestinationFolder, 
  (string)AppToRun);

ForceUpdate(
  (num)Version, 
  (string)UpdaterAdress, 
  (string)TempFolder, 
  (string)DestinationFolder, 
  (string)AppToRun);

MakeRepairFile(
	(string)Hostname, 
	(table)Exceptions);
	
Repair(
	(string)RepairAdress,
	(string)RepairFolderAdress,
	(string)TempFolder,
	(string)DestinationFolder,
	(string)AppToRun)
