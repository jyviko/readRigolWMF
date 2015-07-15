function data = readRigolWMF(filename)
%Reads a binary waveform (.wfm) file stored by a Rigol 1000z oscilloscope.
%
% data = readRigolWaveform(filename) Reads the signal(s) of the
% specified file.
%
% filename - filename of Rigol binary waveform
% data     - structure with channel data

if ~exist('filename', 'var')
    error('Error using this function. For help type: help readRigolWFM');
end

if nargout == 0
    fprintf('---\nFilename: %s\n', filename);
end

%% Open the file and check the header
if ~exist(filename, 'file')
    error('Specified file (%s) doesn''t exist.', filename);
end

fid = fopen(filename, 'r');
if fid == -1
    error('Unable to open %s for reading.', filename);
end

% Check first two bytes
fileVersion = fread(fid, 1, 'uint32');
if (fileVersion ~= hex2dec('FFFFFF01'))
    error('Incorrect first two bytes. This files does not seem to be a Rigol 1000z waveform file.');
end

%% Parse funcStoreHeadStru structure
funcStoreHeadStru.ID =       fread(fid, 1, 'uint16');
if (funcStoreHeadStru.ID ~= hex2dec('a5a6'))
    error('Incorrect magic number. This files does not seem to be a Rigol waveform file.');
end
funcStoreHeadStru.Len      = fread(fid, 1, 'uint16');
funcStoreHeadStru.Module   = char(fread(fid, 20, 'char')');
funcStoreHeadStru.Version  = char(fread(fid, 20, 'char')');
funcStoreHeadStru.BlockNum = fread(fid, 1, 'uint16');
funcStoreHeadStru.Version  = fread(fid, 1, 'uint16');
funcStoreHeadStru.CRC      = fread(fid, 1, 'uint32');
funcStoreHeadStru.Reserved = fread(fid, 1, 'uint16');
funcStoreHeadStru.Reserved1= fread(fid, 1, 'uint16');

fread(fid, 1, 'uint32');


%% Parse wfmInfoStru structure
wfmInfoStru.TimeScale      = fread(fid, 1, 'uint64');
wfmInfoStru.TimeOffset     = fread(fid, 1, 'int64');
wfmInfoStru.CRC            = fread(fid, 1, 'uint32');
wfmInfoStru.StruSize       = fread(fid, 1, 'uint16');
wfmInfoStru.StruVer        = fread(fid, 1, 'uint16');
wfmInfoStru.ChanMask       = fread(fid, 1, 'uint32'); % TODO: from ChanMask 
wfmInfoStru.PtCh1          = fread(fid, 1, 'uint32');
wfmInfoStru.PtCh2          = fread(fid, 1, 'uint32');
wfmInfoStru.PtCh3          = fread(fid, 1, 'uint32');
wfmInfoStru.PtCh3          = fread(fid, 1, 'uint32');
wfmInfoStru.PtLa           = fread(fid, 1, 'uint32');
wfmInfoStru.AcqMode        = fread(fid, 1, 'uint8');
wfmInfoStru.AvgTime        = fread(fid, 1, 'uint8');
wfmInfoStru.SampMode       = fread(fid, 1, 'uint8');
wfmInfoStru.TimeMode       = fread(fid, 1, 'uint8');
wfmInfoStru.MempDepth      = fread(fid, 1, 'uint32');
wfmInfoStru.SampRate       = fread(fid, 1, 'float32'); % in GHz
wfmInfoStru.ChPara         = char(fread(fid, 112, 'char')');
wfmInfoStru.LaPara         = char(fread(fid, 12, 'char')');
wfmInfoStru.SetupSize      = fread(fid, 1, 'uint32');
wfmInfoStru.SetupOffset    = fread(fid, 1, 'uint32');
wfmInfoStru.HorizSize      = fread(fid, 1, 'uint32');
wfmInfoStru.HorizOffset    = fread(fid, 1, 'uint32');
wfmInfoStru.DispDelay      = fread(fid, 1, 'uint32');
wfmInfoStru.DispAddr       = fread(fid, 1, 'uint32');
wfmInfoStru.DispFine       = fread(fid, 1, 'uint32');
wfmInfoStru.MemAddr        = fread(fid, 1, 'uint32');

funcStoreBlockStru.ID      = fread(fid, 1, 'int16');
funcStoreBlockStru.Len     = fread(fid, 1, 'uint16');
funcStoreBlockStru.CellLen = fread(fid, 1, 'uint16');
fread(fid, 2, 'uint8');
funcStoreBlockStru.CellNum = fread(fid, 1, 'uint32');

% TODO: read WFM SetUp Param
% size  : wfmInfoStru.SetupSize    
% offset: wfmInfoStru.SetupOffset 

% TODO: read WFM Horiz Param
% size  : wfmInfoStru.HorizSize 
% offset: wfmInfoStru.HorizOffset

% TODO: parse CVertParam data

% TODO: need to understand the WFM data section
% use information in CVertParam to adjust scale and offset
u32val=2^32;
fseek(fid,wfmInfoStru.PtCh1,'bof');
data.ch1 = fread(fid, funcStoreBlockStru.CellNum/4-1, 'uint32')/u32val-0.5;
fseek(fid,wfmInfoStru.PtCh2+1,'bof');
data.ch2 = fread(fid, funcStoreBlockStru.CellNum/4, 'uint32')/u32val-0.5;

fclose(fid)