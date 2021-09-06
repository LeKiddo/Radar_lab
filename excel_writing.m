%matlab forum user's code modified

data = load('variables'); % load back in and assign to struct variable
fn = fieldnames(data);       % cell containing variable names
nf = numel(fn);              % number of variables
sz = zeros(nf,1);       % array to hold dimensions of variables
% Here we get variable dimensions for each variable
for j = 1:nf
    dataj = data.(fn{j});    % load in variable j
    
    % convert char arrays to string
    if ischar(dataj)
        dataj = convertCharsToStrings(dataj);
        data.(fn{j}) = dataj;
    end
    
    sz(j) = numel(dataj);   % size of variable j
end
mxsz = max(sz);  % max variable size
c = cell(mxsz+1,nf); % cell array to hold data
%c(1,:) = fn'; % column headers
c(1,1)= {'Bin index'};
for i = 1: FFT_size
   c(1,i+1)=num2cell(i); 
end

c(2,1)={'Bin number'};
z=1;
    for i = (FFT_size/2)-1 : -1 : 1 
     c(2,z+1)=num2cell(i); 
     z=z+1;
    end
    
    for i = FFT_size/2:(FFT_size/2 +1)
       c(2,z+1)=num2cell(0);
        z=z+1;
    end

    for i = 1 : (FFT_size/2)-1 
       c(2,z+1)=num2cell(-i); 
        z=z+1;
    end



for j = 1:nf
   
    c(j+2,1)=fn(j);
    dataj = data.(fn{j})(:); % variable j (turned into a column vector if necessary)
    c(j+2,2:sz(j)+1) = num2cell(dataj); % assign to cell array
end

c(12,2)={'Do not forget to close the excel file before running the program again'};
writecell(c,'variables.xlsx')
winopen('variables.xlsx')