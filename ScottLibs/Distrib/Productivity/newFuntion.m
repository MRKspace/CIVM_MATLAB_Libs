function newFuntion()

edit

fid = fopen(filename,'wt');
    fprintf(fid,'function %s\n',synopsis);
    fprintf(fid,'%%%s\n',desc);
    fprintf(fid,'%%\n');
    fprintf(fid,'%% SYNOPSIS: %s\n',synopsis);
    fprintf(fid,'%%\n');
    fprintf(fid,['%% INPUT ',inputtext,'\n']);
    fprintf(fid,'%%\n');
    fprintf(fid,['%% OUTPUT ',outputtext,'\n']);
    fprintf(fid,'%%\n');
    fprintf(fid,'%% REMARKS\n');
    fprintf(fid,'%%\n');
    fprintf(fid,'%% created with MATLAB ver.: %s on %s\n',vers,os);
    fprintf(fid,'%%\n');
    fprintf(fid,'%% created by: %s\n',username);
    fprintf(fid,'%% DATE: %s\n',datetoday);
    fprintf(fid,'%%\n');
    fprintf(fid,'%s\n',repmat('%',1,75));
    fclose(fid);