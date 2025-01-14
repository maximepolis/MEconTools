%% Save A Table Matrix as a Table with Column Names or MAT file

%%
function [st_fil_path_name_full] = ff_sup_save_prep(varargin)
%% Save a matrix to file
% ff_sup_save_prep(st_path_folder, st_file_name, bl_exp_csv, mt_data, ar_st_colnames)

%% Catch Error
optional_params_len = length(varargin);
if optional_params_len > 5
    error('ff_sup_savemat_prep:TooManyOptionalParameters', ...
          'allows at most 5 optional parameters');
end

%% Default Folder Parameters
% by default all go to Sandbox folder with sub folders by dates
st_path_folder = "C:/Users/fan/MEconTools/MEconTools/table/_data/table_test/";
st_file_name = "ff_sup_save_prep";
% Save file to csv. If false, save all workspace results to .mat
bl_exp_csv = false;
mt_data = rand(3,4);
% This does not need to be specified, column names will be expanded later if not sufficient
ar_st_colnames = ["col1", "col2", "col3", "col4"];

optional_params = {st_path_folder st_file_name ...
                   bl_exp_csv mt_data ar_st_colnames};

if (optional_params_len == 0) 
    verbose = true;
end

%% Parse Parameters
% numvarargs is the number of varagin inputted
[optional_params{1:optional_params_len}] = varargin{:};
st_path_folder = optional_params{1};
st_file_name = optional_params{2};
bl_exp_csv = optional_params{3};
mt_data = cell2mat(optional_params(4));
ar_st_colnames = optional_params{5};

%% Save
% Directory if does not exist
mkdir(st_path_folder)

% Save Results to Mat
if (bl_exp_csv)
    % Save All Results in Workspace to mat
    tb_mt_data = ff_mat2tab(mt_data, ar_st_colnames);
    % Genreate Path
    st_fil_path_name_full = strcat(st_path_folder, st_file_name, '.csv');
    % Save to CSV
    writetable(tb_mt_data, st_fil_path_name_full)
else
    % Genreate Path
    st_fil_path_name_full = strcat(st_path_folder, st_file_name);
    % Save All Results in Workspace to mat
    save(st_fil_path_name_full);
end

if (verbose)
    disp(st_fil_path_name_full);
    disp(mt_data);
end

end
