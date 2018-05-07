# UpdaterNG-RepairNG-2018
UpdaterNG with new features


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
  (string)TempFolder,
  (string)DestinationFolder,
  (string)AppToRun);
