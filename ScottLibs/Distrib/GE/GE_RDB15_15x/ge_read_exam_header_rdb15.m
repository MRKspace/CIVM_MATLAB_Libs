function strct = ge_read_exam_header(pfile_name,offset, byte_order)

if(nargin == 0)
	[file, path] = uigetfile('*.*', 'Select Pfile');
	pfile_name = strcat(path, file);
	offset = 0; %Assume no offset
	byte_order = 'ieee-le'; %Assume little endian
end

% Open the PFile
fid=fopen(pfile_name,'r',byte_order);         %Little-Endian format
if (fid == -1)
	error(sprintf('Could not open %s file.',pfile_name));
end

% start at correct offset
fseek(fid,offset,'bof');

strct = struct('base_p_file',pfile_name);
strct = setfield(strct, 'firstaxtime', fread(fid,1,'double',byte_order)); % Start time(secs) of first axial in exam
strct = setfield(strct, 'double_padding', fread(fid,9,'double',byte_order)); % Please use this if you are adding any doubles
strct = setfield(strct, 'zerocell', fread(fid,1,'float32',byte_order)); % Cell number at theta
strct = setfield(strct, 'cellspace', fread(fid,1,'float32',byte_order)); % Cell spacing
strct = setfield(strct, 'srctodet', fread(fid,1,'float32',byte_order)); % Distance from source to detector
strct = setfield(strct, 'srctoiso', fread(fid,1,'float32',byte_order)); % Distance from source to iso
strct = setfield(strct, 'float_padding', fread(fid,8,'float32',byte_order)); % Please use this if you are adding any floats
strct = setfield(strct, 'ex_delta_cnt', fread(fid,1,'int32',byte_order)); % Indicates number of updates to header
strct = setfield(strct, 'ex_complete', fread(fid,1,'int32',byte_order)); % Exam Complete Flag
strct = setfield(strct, 'ex_seriesct', fread(fid,1,'int32',byte_order)); % Last Series Number Used
strct = setfield(strct, 'ex_numarch', fread(fid,1,'int32',byte_order)); % Number of Series Archived
strct = setfield(strct, 'ex_numseries', fread(fid,1,'int32',byte_order)); % Number of Series Existing
strct = setfield(strct, 'ex_numunser', fread(fid,1,'int32',byte_order)); % Number of Unstored Series
strct = setfield(strct, 'ex_toarchcnt', fread(fid,1,'int32',byte_order)); % Number of Unarchived Series
strct = setfield(strct, 'ex_prospcnt', fread(fid,1,'int32',byte_order)); % Number of Prospective/Scout Series
strct = setfield(strct, 'ex_modelnum', fread(fid,1,'int32',byte_order)); % Last Model Number used
strct = setfield(strct, 'ex_modelcnt', fread(fid,1,'int32',byte_order)); % Number of ThreeD Models
strct = setfield(strct, 'ex_checksum', fread(fid,1,'uint32',byte_order)); % Exam Record Checksum
strct = setfield(strct, 'long_padding', fread(fid,8,'int32',byte_order)); % Please use this if you are adding any longs
strct = setfield(strct, 'numcells', fread(fid,1,'int32',byte_order)); % Number of cells in det
strct = setfield(strct, 'magstrength', fread(fid,1,'int32',byte_order)); % Magnet strength (in gauss)
strct = setfield(strct, 'patweight', fread(fid,1,'int32',byte_order)); % Patient Weight
strct = setfield(strct, 'ex_datetime', fread(fid,1,'int32',byte_order)); % Exam date/time stamp
strct = setfield(strct, 'ex_lastmod', fread(fid,1,'int32',byte_order)); % Date/Time of Last Change
strct = setfield(strct, 'int_padding', fread(fid,12,'int32',byte_order)); % Please use this if you are adding any ints
strct = setfield(strct, 'ex_no', fread(fid,1,'uint16',byte_order)); % Exam Number
strct = setfield(strct, 'ex_uniq', fread(fid,1,'int16',byte_order)); % The Make-Unique Flag
strct = setfield(strct, 'detect', fread(fid,1,'int16',byte_order)); % Detector Type
strct = setfield(strct, 'tubetyp', fread(fid,1,'int16',byte_order)); % Tube type
strct = setfield(strct, 'dastyp', fread(fid,1,'int16',byte_order)); % DAS type
strct = setfield(strct, 'num_dcnk', fread(fid,1,'int16',byte_order)); % Number of Decon Kernals
strct = setfield(strct, 'dcn_len', fread(fid,1,'int16',byte_order)); % Number of elements in a Decon Kernal
strct = setfield(strct, 'dcn_density', fread(fid,1,'int16',byte_order)); % Decon Kernal density
strct = setfield(strct, 'dcn_stepsize', fread(fid,1,'int16',byte_order)); % Decon Kernal stepsize
strct = setfield(strct, 'dcn_shiftcnt', fread(fid,1,'int16',byte_order)); % Decon Kernal Shift Count
strct = setfield(strct, 'patage', fread(fid,1,'int16',byte_order)); % Patient Age (years, months or days)
strct = setfield(strct, 'patian', fread(fid,1,'int16',byte_order)); % Patient Age Notation
strct = setfield(strct, 'patsex', fread(fid,1,'int16',byte_order)); % Patient Sex
strct = setfield(strct, 'ex_format', fread(fid,1,'int16',byte_order)); % Exam Format
strct = setfield(strct, 'trauma', fread(fid,1,'int16',byte_order)); % Trauma Flag
strct = setfield(strct, 'protocolflag', fread(fid,1,'int16',byte_order)); % Non-Zero indicates Protocol Exam
strct = setfield(strct, 'study_status', fread(fid,1,'int16',byte_order)); % indicates if study has complete info(DICOM/genesis)
strct = setfield(strct, 'short_padding', fread(fid,11,'int16',byte_order)); % Please use this if you are adding any shorts
strct = setfield(strct, 'hist', char(fread(fid,61,'char',byte_order))); % Patient History
strct = setfield(strct, 'reqnum', char(fread(fid,13,'char',byte_order))); % Requisition Number
strct = setfield(strct, 'refphy', char(fread(fid,33,'char',byte_order))); % Referring Physician
strct = setfield(strct, 'diagrad', char(fread(fid,33,'char',byte_order))); % Diagnostician/Radiologist
strct = setfield(strct, 'op', char(fread(fid,4,'char',byte_order))); % Operator
strct = setfield(strct, 'ex_desc', char(fread(fid,65,'char',byte_order))); % Exam Description
strct = setfield(strct, 'ex_typ', char(fread(fid,3,'char',byte_order))); % Exam Type
strct = setfield(strct, 'ex_sysid', char(fread(fid,9,'char',byte_order))); % Creator Suite and Host
strct = setfield(strct, 'ex_alloc_key', char(fread(fid,13,'char',byte_order))); % Process that allocated this record
strct = setfield(strct, 'ex_diskid', char(fread(fid,1,'char',byte_order))); % Disk ID for this Exam
strct = setfield(strct, 'hospname', char(fread(fid,33,'char',byte_order))); % Hospital Name
strct = setfield(strct, 'patid', char(fread(fid,13,'char',byte_order))); % Patient ID for this Exam
strct = setfield(strct, 'patname', char(fread(fid,25,'char',byte_order))); % Patient Name
strct = setfield(strct, 'ex_suid', char(fread(fid,4,'char',byte_order))); % Suite ID for this Exam
strct = setfield(strct, 'ex_verscre', char(fread(fid,2,'char',byte_order))); % Genesis Version - Created
strct = setfield(strct, 'ex_verscur', char(fread(fid,2,'char',byte_order))); % Genesis Version - Now
strct = setfield(strct, 'uniq_sys_id', char(fread(fid,16,'char',byte_order))); % Unique System ID
strct = setfield(strct, 'service_id', char(fread(fid,16,'char',byte_order))); % Unique Service ID
strct = setfield(strct, 'mobile_loc', char(fread(fid,4,'char',byte_order))); % Mobile Location Number
strct = setfield(strct, 'study_uid', char(fread(fid,32,'char',byte_order))); % Study Entity Unique ID
strct = setfield(strct, 'refsopcuid', char(fread(fid,32,'char',byte_order))); % Ref SOP Class UID 
strct = setfield(strct, 'refsopiuid', char(fread(fid,32,'char',byte_order))); % Ref SOP Instance UID 
%                                                   /* Part of Ref Study Seq */
strct = setfield(strct, 'patnameff', char(fread(fid,65,'char',byte_order))); % FF Patient Name 
strct = setfield(strct, 'patidff', char(fread(fid,65,'char',byte_order))); % FF Patient ID 
strct = setfield(strct, 'reqnumff', char(fread(fid,17,'char',byte_order))); % FF Requisition No 
strct = setfield(strct, 'dateofbirth', char(fread(fid,9,'char',byte_order))); % Date of Birth 
strct = setfield(strct, 'mwlstudyuid', char(fread(fid,32,'char',byte_order))); % Genesis Exam UID 
strct = setfield(strct, 'mwlstudyid', char(fread(fid,16,'char',byte_order))); % Genesis Exam No 
strct = setfield(strct, 'ex_padding', char(fread(fid,62,'char',byte_order))); % Spare Space only for BLOCKs
%                                                   /* It doesn't affect the offsets on IRIX */
fclose(fid);
