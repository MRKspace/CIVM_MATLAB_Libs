% File locations
import_dir = 'E:\import_pfile_dir';
tmp_dir = 'E:\tmp';
backup_dir = 'E:\pfiles';
delete_import_file_after_backup = 1;

% Start backup
unpackAndBackupDir(delete_import_file_after_backup, ...
    import_dir, tmp_dir,backup_dir);