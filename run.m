clear
% Read file
filename = 'C:\data\basketball_player_vox11_00000001.ply';
quanfilePath = strcat(filename,'enc.ply');
binPath = strcat(filename,'bin');
p = pcread(filename);
pointNum = p.Count;
points = p.Location;

% Quantization
qs = 1;% qs must be integer 
points = round((points - min(points))/qs);
pt = unique(points,'rows');

% Save file after quantization
if ~exist(quanfilePath,'file')
    pcwrite(pointCloud(pt),quanfilePath);
end
fprintf('input file: %s\n',filename);
fprintf('quantized  file Path: %s\n',quanfilePath);
fprintf('encoding points: %d\n',pointNum);
save('pathfile.mat','quanfilePath','filename','binPath');

% Generate octree
[code,Octree] = GenOctree(pt);
% Codes = dec2hex(code);
% disp(["codes:",Codes])
% dlmwrite(strcat(filename,'Octree.txt'),Codes,'delimiter','');
fprintf('bpp before entropy coding:%f bit\n',length(code)*8/pointNum);
% Entropy Coding
text = code;
binsize = entropyCoding(text,binPath);
fprintf('bpp after entropy coding:%f bit\n',binsize*8/pointNum);
fprintf('bin file: %s\n',binPath);

%% Decoding
% clear
disp('decoding...')
load('pathfile.mat')
disp(['binPath: ',binPath])
fileID = fopen(binPath);
lenthtext =  fread(fileID,1,'uint32');
feqC =  fread(fileID,255,'uint8');
bin =  fread(fileID,'ubit1');
fclose(fileID);
% Entropy decoding
feq = double(feqC(feqC~=0));
dtext = arithdeco(bin,feq,lenthtext);
feqT = find(feqC);
dtext = feqT(dtext);
assert(isequal(dtext,text))

% Decode Octree
ptRec = qs*DeOctree(dtext);

% Evaluate
disp('evaluate...')
decodPath = strcat(filename,'dec.ply');
pcwrite(pointCloud(single(ptRec)),decodPath);
Cmd=['pc_error.exe' ,' -a ',quanfilePath ,' -b ',decodPath, ' -r ','1023']; %psnr = 10log10(3*p^2/max(mse)) e.g. p = 1023
system(Cmd);
