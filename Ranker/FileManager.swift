//TODO from the Recorder Widget View we are saving files for recording and transcript
//we want to perhaps have the save and read file methods here. We need to be able to read the complete list of
//files. we need to be able to get lists of files filtered by seedWord
//We need to be able to export all files that have been recorded and save to Google Drive for instance
//ideally they could all be zipped and exported. Please give me feedback if zipping hundreds of recording files
//would be resource prohibitive. I need your help to develop a method to do lots of recordings an export them to a safe location
//I also want to store in the database a mapping of

// seedword, daterecorded, transcript string, transcript filename, recording filename,  exported (boolean)

// if the value was exported we consider it safe for deletion, otherwise the files should not be deleted.
// we maintain the entry in the database even after the fale was deleted.